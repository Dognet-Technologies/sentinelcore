#!/bin/bash
# debug_database.sh - PostgreSQL Diagnostic Tool
# Analyzes database health, connections, and performance issues

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
DB_USER="${DB_USER:-vlnman}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-vulnerability_manager}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  SentinelCore Database Diagnostic Tool                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test database connection
echo -e "${YELLOW}[1/8] Testing PostgreSQL Connection${NC}"
if psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Connected to PostgreSQL${NC}"
else
    echo -e "${RED}✗ Cannot connect to PostgreSQL at $DB_HOST:$DB_PORT${NC}"
    echo "Make sure PostgreSQL is running and credentials are correct."
    exit 1
fi
echo ""

# Check PostgreSQL Version
echo -e "${YELLOW}[2/8] PostgreSQL Version${NC}"
psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -c "SELECT version();"
echo ""

# Check Database Size
echo -e "${YELLOW}[3/8] Database Size & Growth${NC}"
psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -c "
SELECT 
    datname as database,
    pg_size_pretty(pg_database_size(datname)) as size
FROM pg_database 
WHERE datname LIKE '%vulnerability%' OR datname LIKE '%sentinelcore%'
ORDER BY pg_database_size(datname) DESC;"
echo ""

# Check Active Connections
echo -e "${YELLOW}[4/8] Active Database Connections${NC}"
psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -c "
SELECT 
    datname as database,
    usename as user,
    count(*) as connections,
    max(EXTRACT(EPOCH FROM (NOW() - query_start))) as longest_running_sec
FROM pg_stat_activity
GROUP BY datname, usename
ORDER BY count(*) DESC;"
echo ""

# Check Connection Limit
echo -e "${YELLOW}[5/8] Connection Limits${NC}"
psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -c "
SHOW max_connections;"
CURRENT=$(psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SELECT count(*) FROM pg_stat_activity;")
echo "Current connections: $CURRENT"
echo ""

# Check for Slow Queries
echo -e "${YELLOW}[6/8] Running Queries (Last 30 seconds)${NC}"
psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -c "
SELECT 
    pid,
    usename,
    state,
    EXTRACT(EPOCH FROM (NOW() - query_start)) as duration_sec,
    LEFT(query, 100) as query
FROM pg_stat_activity
WHERE query NOT LIKE '%pg_stat_activity%'
  AND state != 'idle'
  AND query_start > NOW() - INTERVAL '30 seconds'
ORDER BY query_start DESC;"
echo ""

# Check Table Sizes
echo -e "${YELLOW}[7/8] Largest Tables (Potential Growth Issues)${NC}"
psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -c "
SELECT 
    schemaname,
    relname as table_name,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||relname)) as size,
    n_live_tup as row_count
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(schemaname||'.'||relname) DESC
LIMIT 15;" 2>/dev/null || echo "(No table statistics available)"
echo ""

# Check Index Usage
echo -e "${YELLOW}[8/8] Unused Indexes (Optimization Opportunity)${NC}"
psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -c "
SELECT 
    schemaname,
    relname as table_name,
    indexrelname,
    idx_scan as scan_count
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelname) DESC;" 2>/dev/null || echo "(No unused indexes or statistics available)"
echo ""

# Final recommendations
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  RECOMMENDATIONS                                           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if connection pool is approaching limit
CURRENT=$(psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SELECT count(*) FROM pg_stat_activity;")
MAX=$(psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SHOW max_connections;" | tr -d ' ')

if [ "$CURRENT" -gt "$((MAX * 80 / 100))" ]; then
    echo -e "${RED}⚠ WARNING: Connection usage > 80% ($CURRENT / $MAX)${NC}"
    echo "  Action: Increase max_connections or optimize queries"
    echo ""
fi

# Check for idle connections
IDLE=$(psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'idle';")
if [ "$IDLE" -gt 10 ]; then
    echo -e "${YELLOW}⚠ NOTE: Many idle connections ($IDLE)${NC}"
    echo "  These may be from connection pooling or unclosed connections"
    echo "  Consider setting idle_in_transaction_session_timeout"
    echo ""
fi

# Check for long-running transactions
LONG_TXN=$(psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "
SELECT count(*) FROM pg_stat_activity 
WHERE state != 'idle' 
AND EXTRACT(EPOCH FROM (NOW() - query_start)) > 60;")

if [ "$LONG_TXN" -gt 0 ]; then
    echo -e "${YELLOW}⚠ WARNING: $LONG_TXN long-running queries (> 60s)${NC}"
    echo "  These may be blocking other transactions"
    echo "  Review slow query logs: SHOW log_min_duration_statement"
    echo ""
fi

# Check table bloat
BLOAT=$(psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d $DB_NAME -t -c "
SELECT count(*) FROM pg_stat_user_tables 
WHERE n_dead_tup > n_live_tup * 0.5;")

if [ "$BLOAT" -gt 0 ]; then
    echo -e "${YELLOW}⚠ NOTE: $BLOAT tables have > 50% dead tuples${NC}"
    echo "  Consider running: VACUUM ANALYZE"
    echo ""
fi

echo -e "${GREEN}✓ Diagnostic complete${NC}"
echo ""
echo "Next steps:"
echo "1. Monitor query performance with: EXPLAIN ANALYZE <query>"
echo "2. Check logs: sudo journalctl -u postgresql -f"
echo "3. Enable slow query logging if not already enabled"
echo "4. Run VACUUM ANALYZE regularly for maintenance"
echo ""
