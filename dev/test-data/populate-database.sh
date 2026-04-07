#!/bin/bash
# Script per popolare il database SentinelCore con dati di test

set -e

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                              ║${NC}"
echo -e "${BLUE}║   📊 SENTINEL CORE - DATABASE POPULATOR 📊  ║${NC}"
echo -e "${BLUE}║                                              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Database config (from default.yaml)
DB_HOST="localhost"
DB_USER="vlnman"
DB_PASS="DogNET"
DB_NAME="vulnerability_manager"
DB_URL="postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}/${DB_NAME}"

# Verifica PostgreSQL
echo -e "${YELLOW}🔍 Verifica connessione PostgreSQL...${NC}"
if pg_isready -h $DB_HOST > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PostgreSQL: Running${NC}"
else
    echo -e "${RED}❌ PostgreSQL: Not running${NC}"
    echo -e "${YELLOW}Tentativo di avvio PostgreSQL...${NC}"
    sudo service postgresql start 2>/dev/null || sudo systemctl start postgresql 2>/dev/null || {
        echo -e "${RED}Impossibile avviare PostgreSQL. Avvialo manualmente e riprova.${NC}"
        exit 1
    }
    sleep 2
fi

# Verifica connessione database
echo -e "${YELLOW}🔍 Verifica connessione database...${NC}"
if PGPASSWORD=$DB_PASS psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Database: Connected${NC}"
else
    echo -e "${RED}❌ Database: Connection failed${NC}"
    echo -e "${YELLOW}Verifica che il database esista e le credenziali siano corrette.${NC}"
    exit 1
fi

# Conta record esistenti
echo ""
echo -e "${YELLOW}📊 Conteggio record esistenti...${NC}"
EXISTING_USERS=$(PGPASSWORD=$DB_PASS psql -h $DB_HOST -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM users;")
EXISTING_VULNS=$(PGPASSWORD=$DB_PASS psql -h $DB_HOST -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM vulnerabilities;")
EXISTING_ASSETS=$(PGPASSWORD=$DB_PASS psql -h $DB_HOST -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM assets;")

echo -e "   Utenti: ${EXISTING_USERS}"
echo -e "   Vulnerabilità: ${EXISTING_VULNS}"
echo -e "   Asset: ${EXISTING_ASSETS}"

# Warning se ci sono già dati
if [ $EXISTING_USERS -gt 0 ] || [ $EXISTING_VULNS -gt 0 ] || [ $EXISTING_ASSETS -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  ATTENZIONE: Il database contiene già dei dati!${NC}"
    echo -e "${YELLOW}   Vuoi continuare? I dati esistenti NON saranno cancellati.${NC}"
    echo -e "${YELLOW}   (Potrebbero verificarsi conflitti di UUID)${NC}"
    echo ""
    read -p "Continuare? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Operazione annullata.${NC}"
        exit 0
    fi
fi

# Esegui lo script SQL
echo ""
echo -e "${BLUE}🚀 Popolamento database in corso...${NC}"
echo ""

PGPASSWORD=$DB_PASS psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f populate-test-data.sql

# Verifica successo
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                              ║${NC}"
    echo -e "${GREEN}║      ✅ DATABASE POPOLATO CON SUCCESSO! ✅   ║${NC}"
    echo -e "${GREEN}║                                              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}📊 Nuovi record inseriti:${NC}"
    echo ""

    # Mostra statistiche finali
    PGPASSWORD=$DB_PASS psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "
    SELECT
        'Users' as table_name, COUNT(*) as records FROM users
    UNION ALL SELECT 'Teams', COUNT(*) FROM teams
    UNION ALL SELECT 'Assets', COUNT(*) FROM assets
    UNION ALL SELECT 'Vulnerabilities', COUNT(*) FROM vulnerabilities
    UNION ALL SELECT 'Network Devices', COUNT(*) FROM network_devices
    UNION ALL SELECT 'Reports', COUNT(*) FROM reports
    ORDER BY table_name;
    "

    echo ""
    echo -e "${GREEN}🔑 CREDENZIALI DI TEST:${NC}"
    echo -e "${GREEN}   Username: admin    | Password: Admin123!${NC}"
    echo -e "${GREEN}   Username: jdoe     | Password: User123!${NC}"
    echo -e "${GREEN}   Username: asmith   | Password: User123!${NC}"
    echo ""
    echo -e "${YELLOW}🚀 Prossimi passi:${NC}"
    echo -e "   1. Avvia il backend: cd vulnerability-manager && cargo run"
    echo -e "   2. Avvia il frontend: cd vulnerability-manager-frontend && npm start"
    echo -e "   3. Login con admin / Admin123!"
    echo -e "   4. Testa tutte le pagine!"
    echo ""
else
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                              ║${NC}"
    echo -e "${RED}║        ❌ ERRORE POPOLAMENTO DATABASE ❌    ║${NC}"
    echo -e "${RED}║                                              ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Controlla gli errori sopra e riprova.${NC}"
    exit 1
fi
