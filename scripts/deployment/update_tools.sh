#!/bin/bash
# update_tools.sh - Aggiorna SentinelCore alla versione più recente
# Uso: sudo ./scripts/deployment/update_tools.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  SentinelCore Update Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
   echo -e "${RED}Errore: Questo script deve essere eseguito come root o con sudo${NC}"
   exit 1
fi

# Get the actual user (not root if using sudo)
ACTUAL_USER=${SUDO_USER:-$USER}
INSTALL_DIR="/opt/sentinelcore"
BACKUP_DIR="/var/backups/sentinelcore"

# Step 1: Create backup directory if it doesn't exist
echo -e "${YELLOW}[1/8] Creazione directory backup...${NC}"
mkdir -p $BACKUP_DIR
chown $ACTUAL_USER:$ACTUAL_USER $BACKUP_DIR

# Step 2: Backup database
echo -e "${YELLOW}[2/8] Backup database PostgreSQL...${NC}"
BACKUP_FILE="$BACKUP_DIR/sentinelcore_backup_$(date +%Y%m%d_%H%M%S).sql"
sudo -u postgres pg_dump sentinelcore_db > $BACKUP_FILE
echo -e "${GREEN}✓ Database backup salvato: $BACKUP_FILE${NC}"

# Step 3: Stop service
echo -e "${YELLOW}[3/8] Arresto servizio SentinelCore...${NC}"
systemctl stop sentinelcore || echo "Servizio non attivo"

# Step 4: Pull updates from GitHub
echo -e "${YELLOW}[4/8] Download aggiornamenti da GitHub...${NC}"
cd $INSTALL_DIR

# Stash any local changes
sudo -u $ACTUAL_USER git stash

# Pull latest changes
sudo -u $ACTUAL_USER git pull origin main

echo -e "${GREEN}✓ Aggiornamenti scaricati${NC}"

# Step 5: Check if there are new migrations
echo -e "${YELLOW}[5/8] Verifica nuove migrazioni database...${NC}"
cd $INSTALL_DIR/vulnerability-manager

# Apply migrations if any
if [ -d "migrations" ]; then
    echo "Applicazione migrazioni..."
    sudo -u $ACTUAL_USER bash -c "source ~/.cargo/env && cd $INSTALL_DIR/vulnerability-manager && sqlx migrate run"
    echo -e "${GREEN}✓ Migrazioni applicate${NC}"
fi

# Step 6: Regenerate SQLx cache
echo -e "${YELLOW}[6/8] Rigenerazione cache SQLx...${NC}"
if [ -f "$INSTALL_DIR/scripts/deployment/regenerate-sqlx-cache.sh" ]; then
    sudo -u $ACTUAL_USER bash $INSTALL_DIR/scripts/deployment/regenerate-sqlx-cache.sh
    echo -e "${GREEN}✓ Cache SQLx rigenerata${NC}"
else
    echo -e "${YELLOW}⚠ Script rigenerazione cache non trovato, salto questo step${NC}"
fi

# Step 7: Rebuild application
echo -e "${YELLOW}[7/8] Ricompilazione SentinelCore...${NC}"
cd $INSTALL_DIR/vulnerability-manager
sudo -u $ACTUAL_USER bash -c "source ~/.cargo/env && SQLX_OFFLINE=true cargo build --release"
echo -e "${GREEN}✓ Compilazione completata${NC}"

# Copy new binary to install location
if [ -f "target/release/vulnerability-manager" ]; then
    cp target/release/vulnerability-manager /usr/local/bin/sentinelcore
    chmod +x /usr/local/bin/sentinelcore
fi

# Step 8: Restart service
echo -e "${YELLOW}[8/8] Riavvio servizio SentinelCore...${NC}"
systemctl start sentinelcore
sleep 3
systemctl status sentinelcore --no-pager

# Show version info
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Aggiornamento completato!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Versione Git: $(cd $INSTALL_DIR && git describe --tags --always)"
echo -e "Ultimo commit: $(cd $INSTALL_DIR && git log -1 --pretty=format:'%h - %s (%cr)')"
echo ""
echo -e "Backup database: ${GREEN}$BACKUP_FILE${NC}"
echo -e "Servizio: ${GREEN}$(systemctl is-active sentinelcore)${NC}"
echo ""
echo -e "${YELLOW}Nota: In caso di problemi, puoi ripristinare il database con:${NC}"
echo -e "  sudo -u postgres psql sentinelcore_db < $BACKUP_FILE"
echo ""
