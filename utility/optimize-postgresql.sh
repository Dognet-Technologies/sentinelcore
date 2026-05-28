#!/bin/bash
# optimize_postgresql.sh - PostgreSQL Performance Tuning
# Applies recommended optimizations for SentinelCore production deployment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  PostgreSQL Performance Optimization Tool                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ This script must be run as root${NC}"
    echo "Usage: sudo bash optimize_postgresql.sh"
    exit 1
fi

# Detect PostgreSQL major version
PG_VERSION=$(psql --version | grep -oP '\d+(?=\.)' | head -1)
PG_CONFIG_DIR="/etc/postgresql/$PG_VERSION/main"
PG_CONFIG_FILE="$PG_CONFIG_DIR/postgresql.conf"

echo -e "${YELLOW}[1/5] Detecting PostgreSQL Installation${NC}"
if [ ! -f "$PG_CONFIG_FILE" ]; then
    echo -e "${RED}✗ PostgreSQL configuration not found at $PG_CONFIG_FILE${NC}"
    echo "Trying alternative locations..."
    if [ -f "/var/lib/postgresql/$PG_VERSION/main/postgresql.conf" ]; then
        PG_CONFIG_FILE="/var/lib/postgresql/$PG_VERSION/main/postgresql.conf"
    else
        echo -e "${RED}✗ Cannot locate PostgreSQL configuration${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓ Found PostgreSQL v$PG_VERSION${NC}"
echo -e "  Config: $PG_CONFIG_FILE"
echo ""

# Backup original config
echo -e "${YELLOW}[2/5] Backing Up Original Configuration${NC}"
BACKUP_FILE="$PG_CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
cp "$PG_CONFIG_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✓ Backup created: $BACKUP_FILE${NC}"
echo ""

# Calculate optimized settings based on system resources
echo -e "${YELLOW}[3/5] Calculating Optimized Settings${NC}"

TOTAL_RAM=$(free -b | awk 'NR==2 {print $2}')
TOTAL_RAM_MB=$(( $TOTAL_RAM / 1024 / 1024 ))
TOTAL_RAM_GB=$(( $TOTAL_RAM / 1024 / 1024 / 1024 ))

# PostgreSQL should use 25% of total RAM (conservative)
SHARED_BUFFERS_MB=$(( $TOTAL_RAM_MB / 4 ))
# Effective cache should be 50% of total RAM
EFFECTIVE_CACHE_MB=$(( $TOTAL_RAM_MB / 2 ))
# Work memory: (RAM - shared_buffers) / (max_connections * 2)
WORK_MEMORY_MB=$(( ($TOTAL_RAM_MB - $SHARED_BUFFERS_MB) / (30 * 2) ))

echo -e "  System RAM: ${GREEN}${TOTAL_RAM_GB}GB${NC}"
echo -e "  Shared buffers: ${YELLOW}${SHARED_BUFFERS_MB}MB${NC} (25% of RAM)"
echo -e "  Effective cache: ${YELLOW}${EFFECTIVE_CACHE_MB}MB${NC} (50% of RAM)"
echo -e "  Work memory: ${YELLOW}${WORK_MEMORY_MB}MB${NC} (per operation)"
echo ""

# Apply optimizations
echo -e "${YELLOW}[4/5] Applying Optimizations${NC}"

# Temporary file for new config
TEMP_CONFIG=$(mktemp)

# Read existing config and update values
while IFS= read -r line; do
    # Skip commented lines that we'll replace
    if [[ $line =~ ^#.*shared_buffers ]] || \
       [[ $line =~ ^shared_buffers ]] || \
       [[ $line =~ ^#.*effective_cache_size ]] || \
       [[ $line =~ ^effective_cache_size ]] || \
       [[ $line =~ ^#.*work_mem ]] || \
       [[ $line =~ ^work_mem ]] || \
       [[ $line =~ ^#.*max_connections ]] || \
       [[ $line =~ ^max_connections ]] || \
       [[ $line =~ ^#.*maintenance_work_mem ]] || \
       [[ $line =~ ^maintenance_work_mem ]] || \
       [[ $line =~ ^#.*random_page_cost ]] || \
       [[ $line =~ ^random_page_cost ]] || \
       [[ $line =~ ^#.*log_min_duration_statement ]] || \
       [[ $line =~ ^log_min_duration_statement ]] || \
       [[ $line =~ ^#.*log_line_prefix ]] || \
       [[ $line =~ ^log_line_prefix ]]; then
        continue
    fi
    echo "$line" >> "$TEMP_CONFIG"
done < "$PG_CONFIG_FILE"

# Add optimized settings at the end
cat >> "$TEMP_CONFIG" << EOF

# ============================================
# SentinelCore Performance Optimization
# Applied: $(date)
# ============================================

# Memory Settings
shared_buffers = ${SHARED_BUFFERS_MB}MB
effective_cache_size = ${EFFECTIVE_CACHE_MB}MB
work_mem = ${WORK_MEMORY_MB}MB
maintenance_work_mem = ${SHARED_BUFFERS_MB}MB

# Connection Management
max_connections = 50
max_prepared_transactions = 100

# Query Planning
random_page_cost = 1.1
effective_io_concurrency = 200

# Logging for Performance Monitoring
log_min_duration_statement = 1000  # Log queries > 1 second
log_line_prefix = '%t [%p]: user=%u,db=%d,app=%a,client=%h '
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on

# Vacuuming (Maintenance)
autovacuum = on
autovacuum_naptime = 10s
autovacuum_vacuum_threshold = 50
autovacuum_analyze_threshold = 50

# Connection/Transaction Timeout
idle_in_transaction_session_timeout = '10min'
statement_timeout = '5min'

# Checkpoint Settings (for bulk operations)
checkpoint_timeout = '15min'
checkpoint_completion_target = 0.9
wal_buffers = 16MB

# Parallel Query Execution
max_parallel_workers_per_gather = 2
max_parallel_workers = 4
max_parallel_maintenance_workers = 2
EOF

# Replace config file
cp "$TEMP_CONFIG" "$PG_CONFIG_FILE"
rm "$TEMP_CONFIG"

echo -e "${GREEN}✓ Configuration updated${NC}"
echo ""

# Restart PostgreSQL
echo -e "${YELLOW}[5/5] Restarting PostgreSQL Service${NC}"
systemctl restart postgresql

# Verify restart
sleep 2
if systemctl is-active --quiet postgresql; then
    echo -e "${GREEN}✓ PostgreSQL restarted successfully${NC}"
else
    echo -e "${RED}✗ PostgreSQL failed to start${NC}"
    echo "Restoring backup..."
    cp "$BACKUP_FILE" "$PG_CONFIG_FILE"
    systemctl restart postgresql
    exit 1
fi
echo ""

# Verify settings applied
echo -e "${YELLOW}Verifying Applied Settings:${NC}"
sudo -u postgres psql -c "SHOW shared_buffers;"
sudo -u postgres psql -c "SHOW effective_cache_size;"
sudo -u postgres psql -c "SHOW work_mem;"
sudo -u postgres psql -c "SHOW max_connections;"
echo ""

# Final summary
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  OPTIMIZATION COMPLETE                                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓ PostgreSQL has been optimized for SentinelCore${NC}"
echo ""
echo "Changes Applied:"
echo "  • Increased shared_buffers for better buffer pool"
echo "  • Optimized work_mem for query performance"
echo "  • Enabled slow query logging (> 1s)"
echo "  • Configured autovacuum for maintenance"
echo "  • Added connection timeouts to prevent hanging connections"
echo "  • Enabled parallel query execution"
echo ""
echo "Next Steps:"
echo "  1. Monitor slow queries: tail -f /var/log/postgresql/postgresql.log"
echo "  2. Run: psql -U vlnman -d vulnerability_manager -c 'VACUUM ANALYZE;'"
echo "  3. Rebuild indexes if needed for better performance"
echo "  4. Run test_performance.sh to verify improvements"
echo ""
echo "Backup location: $BACKUP_FILE"
echo ""
