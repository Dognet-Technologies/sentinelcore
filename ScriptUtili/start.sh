#!/bin/bash
# Script master per gestire Sentinel Core

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                              ║${NC}"
echo -e "${BLUE}║         🛡️  SENTINEL CORE MANAGER  🛡️         ║${NC}"
echo -e "${BLUE}║                                              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Funzioni helper
check_postgres() {
    if pg_isready > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PostgreSQL: Running${NC}"
        return 0
    else
        echo -e "${RED}❌ PostgreSQL: Not running${NC}"
        return 1
    fi
}

check_database() {
    if psql "postgresql://vlnman:DogNET@localhost/vulnerability_manager" -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Database: Connected${NC}"
        return 0
    else
        echo -e "${RED}❌ Database: Not accessible${NC}"
        return 1
    fi
}

# Menu
show_menu() {
    echo ""
    echo -e "${YELLOW}Seleziona un'opzione:${NC}"
    echo ""
    echo "  1) 🔍 Verifica Prerequisiti"
    echo "  2) 📊 Esegui Migrations Database"
    echo "  3) 🚀 Avvia Backend (Rust)"
    echo "  4) 🌐 Avvia Frontend (React)"
    echo "  5) 🔥 Avvia Tutto (Backend + Frontend)"
    echo "  6) 📖 Mostra Guida Quick Start"
    echo "  7) 🧹 Pulisci Build (Clean)"
    echo "  8) ❌ Esci"
    echo ""
    echo -n "Scelta [1-8]: "
}

# Opzione 1: Verifica prerequisiti
check_prerequisites() {
    echo ""
    echo -e "${BLUE}🔍 Verifica Prerequisiti...${NC}"
    echo ""

    # PostgreSQL
    check_postgres

    # Database
    if check_postgres; then
        check_database
    fi

    # Rust
    if command -v cargo > /dev/null 2>&1; then
        RUST_VERSION=$(cargo --version)
        echo -e "${GREEN}✅ Rust: $RUST_VERSION${NC}"
    else
        echo -e "${RED}❌ Rust: Not installed${NC}"
    fi

    # Node.js
    if command -v node > /dev/null 2>&1; then
        NODE_VERSION=$(node --version)
        echo -e "${GREEN}✅ Node.js: $NODE_VERSION${NC}"
    else
        echo -e "${RED}❌ Node.js: Not installed${NC}"
    fi

    # npm
    if command -v npm > /dev/null 2>&1; then
        NPM_VERSION=$(npm --version)
        echo -e "${GREEN}✅ npm: v$NPM_VERSION${NC}"
    else
        echo -e "${RED}❌ npm: Not installed${NC}"
    fi

    # Tools opzionali
    echo ""
    echo -e "${YELLOW}Tool opzionali per Network Scan:${NC}"

    if command -v arp-scan > /dev/null 2>&1; then
        echo -e "${GREEN}✅ arp-scan: Installed${NC}"
    else
        echo -e "${YELLOW}⚠️  arp-scan: Not installed (opzionale)${NC}"
        echo -e "   Install: ${BLUE}sudo apt install arp-scan${NC}"
    fi

    if command -v nmap > /dev/null 2>&1; then
        echo -e "${GREEN}✅ nmap: Installed${NC}"
    else
        echo -e "${YELLOW}⚠️  nmap: Not installed (opzionale)${NC}"
        echo -e "   Install: ${BLUE}sudo apt install nmap${NC}"
    fi

    if command -v traceroute > /dev/null 2>&1; then
        echo -e "${GREEN}✅ traceroute: Installed${NC}"
    else
        echo -e "${YELLOW}⚠️  traceroute: Not installed (opzionale)${NC}"
        echo -e "   Install: ${BLUE}sudo apt install traceroute${NC}"
    fi

    echo ""
}

# Main loop
while true; do
    show_menu
    read choice

    case $choice in
        1)
            check_prerequisites
            ;;
        2)
            echo ""
            echo -e "${BLUE}📊 Esecuzione Migrations...${NC}"
            ./run-migrations.sh
            ;;
        3)
            echo ""
            echo -e "${BLUE}🚀 Avvio Backend...${NC}"
            ./start-backend.sh
            ;;
        4)
            echo ""
            echo -e "${BLUE}🌐 Avvio Frontend...${NC}"
            ./start-frontend.sh
            ;;
        5)
            echo ""
            echo -e "${BLUE}🔥 Avvio Backend e Frontend in background...${NC}"
            echo ""
            echo "Backend log: tail -f backend.log"
            echo "Frontend log: tail -f frontend.log"
            echo ""
            ./start-backend.sh > backend.log 2>&1 &
            BACKEND_PID=$!
            echo -e "${GREEN}✅ Backend avviato (PID: $BACKEND_PID)${NC}"

            sleep 3

            ./start-frontend.sh > frontend.log 2>&1 &
            FRONTEND_PID=$!
            echo -e "${GREEN}✅ Frontend avviato (PID: $FRONTEND_PID)${NC}"
            echo ""
            echo -e "${YELLOW}Per fermare:${NC}"
            echo "  kill $BACKEND_PID $FRONTEND_PID"
            echo ""
            ;;
        6)
            less QUICKSTART.md
            ;;
        7)
            echo ""
            echo -e "${BLUE}🧹 Pulizia build...${NC}"
            cd vulnerability-manager && cargo clean
            cd ../vulnerability-manager-frontend && rm -rf build/ node_modules/.cache/
            echo -e "${GREEN}✅ Pulizia completata${NC}"
            cd ..
            ;;
        8)
            echo ""
            echo -e "${GREEN}👋 Arrivederci!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opzione non valida. Riprova.${NC}"
            ;;
    esac

    echo ""
    echo -n "Premi ENTER per continuare..."
    read
    clear
done
