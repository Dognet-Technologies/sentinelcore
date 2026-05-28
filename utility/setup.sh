#!/bin/bash
# 🚀 Setup completo Sentinel Core - Installa tutte le dipendenze corrette
# Testato su: Ubuntu 20.04+, Debian 11+, Parrot OS

set -e  # Exit on error

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Setup Sentinel Core - Installazione Dipendenze"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================
# 📋 VERSIONI RICHIESTE
# ============================================
RUST_VERSION="1.75.0"        # Rust 2021 edition (minimo 1.56, raccomandato 1.75+)
NODE_VERSION="20"             # Node.js 20 LTS (supporta React 18, npm 10+)
POSTGRES_VERSION="14"         # PostgreSQL 14+ (supporto completo INET types)

echo "📦 Versioni da installare:"
echo "   • Rust: ${RUST_VERSION}+ (edition 2021)"
echo "   • Node.js: ${NODE_VERSION}"
echo "   • PostgreSQL: ${POSTGRES_VERSION}+"
echo "   • React: 18.2.0"
echo "   • Axum: 0.6"
echo "   • SQLx: 0.8"
echo ""

# ============================================
# 1️⃣ INSTALLA RUST + CARGO
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  Installazione Rust ${RUST_VERSION}+"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v rustc &> /dev/null; then
    CURRENT_RUST=$(rustc --version | awk '{print $2}')
    echo "✅ Rust già installato: ${CURRENT_RUST}"
    echo "   Aggiornamento in corso..."
    rustup update stable
else
    echo "📥 Download e installazione Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

    # Carica Rust nel PATH corrente
    source "$HOME/.cargo/env"
fi

# Installa componenti essenziali
echo "📦 Installazione componenti Rust..."
rustup component add rustfmt clippy

echo ""
echo "✅ Rust installato: $(rustc --version)"
echo "✅ Cargo: $(cargo --version)"
echo ""

# ============================================
# 2️⃣ INSTALLA NODE.JS + NPM
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  Installazione Node.js ${NODE_VERSION}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v node &> /dev/null; then
    CURRENT_NODE=$(node --version)
    echo "✅ Node.js già installato: ${CURRENT_NODE}"

    # Verifica se è la versione corretta
    NODE_MAJOR=$(node --version | cut -d'.' -f1 | sed 's/v//')
    if [ "$NODE_MAJOR" -lt 20 ]; then
        echo "⚠️  Versione Node.js troppo vecchia (richiesta: 20+)"
        echo "   Aggiornamento in corso..."

        # Aggiungi repository NodeSource
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
else
    echo "📥 Download e installazione Node.js ${NODE_VERSION}..."

    # Installa Node.js 20 LTS
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Verifica versione npm (Node 20 include npm 10.x)
NPM_MAJOR=$(npm --version | cut -d'.' -f1)
if [ "$NPM_MAJOR" -lt 9 ]; then
    echo "📦 Aggiornamento npm a versione compatibile..."
    sudo npm install -g npm@10
fi

echo ""
echo "✅ Node.js: $(node --version)"
echo "✅ npm: $(npm --version)"
echo ""

# ============================================
# 3️⃣ INSTALLA POSTGRESQL
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  Installazione PostgreSQL ${POSTGRES_VERSION}+"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v psql &> /dev/null; then
    CURRENT_PG=$(psql --version | awk '{print $3}')
    echo "✅ PostgreSQL già installato: ${CURRENT_PG}"
else
    echo "📥 Installazione PostgreSQL ${POSTGRES_VERSION}..."

    # Aggiungi repository PostgreSQL ufficiale
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

    sudo apt-get update
    sudo apt-get install -y postgresql-${POSTGRES_VERSION} postgresql-contrib-${POSTGRES_VERSION} libpq-dev

    # Avvia PostgreSQL
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
fi

echo ""
echo "✅ PostgreSQL: $(psql --version)"
echo ""

# ============================================
# 4️⃣ INSTALLA DIPENDENZE DI SISTEMA
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  Installazione dipendenze di sistema"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "📦 Installazione librerie necessarie..."
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    libpq-dev \
    git \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release

echo ""
echo "✅ Dipendenze di sistema installate"
echo ""

# ============================================
# 5️⃣ INSTALLA DIPENDENZE BACKEND (RUST)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5️⃣  Installazione dipendenze Backend (Rust)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd ~/Repos/Progetti/sentinelcore/vulnerability-manager

echo "📦 Download dipendenze Rust..."
echo "   • Axum 0.6 (web framework)"
echo "   • SQLx 0.7 (database ORM)"
echo "   • Tokio 1.28 (async runtime)"
echo "   • Argon2 0.5 (password hashing)"
echo "   • JsonWebToken 9.0 (JWT auth)"
echo ""

# Verifica solo le dipendenze senza compilare
cargo fetch

echo ""
echo "✅ Dipendenze Rust scaricate ($(du -sh ~/.cargo/registry/cache | awk '{print $1}'))"
echo ""

# ============================================
# 6️⃣ INSTALLA DIPENDENZE FRONTEND (REACT)
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6️⃣  Installazione dipendenze Frontend (React)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd ~/Repos/Progetti/sentinelcore/vulnerability-manager-frontend

echo "📦 Download dipendenze npm..."
echo "   • React 18.2.0"
echo "   • TypeScript 4.9.5"
echo "   • Material-UI 5.17"
echo "   • Cytoscape.js 3.27"
echo "   • xterm.js 5.3"
echo ""

npm install

echo ""
echo "✅ Dipendenze npm installate ($(du -sh node_modules | awk '{print $1}'))"
echo ""

# ============================================
# 7️⃣ CONFIGURA DATABASE
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7️⃣  Configurazione Database PostgreSQL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "🔐 Creazione database e utente..."

# Crea database e utente
sudo -u postgres psql << EOF
-- Crea utente se non esiste
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'vlnman') THEN
        CREATE USER vlnman WITH PASSWORD 'DogNET';
    END IF;
END
\$\$;

-- Crea database se non esiste
SELECT 'CREATE DATABASE vulnerability_manager'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'vulnerability_manager')\gexec

-- Assegna permessi
GRANT ALL PRIVILEGES ON DATABASE vulnerability_manager TO vlnman;
EOF

echo ""
echo "✅ Database configurato:"
echo "   • Database: vulnerability_manager"
echo "   • User: vlnman"
echo "   • Password: DogNET"
echo ""

# Crea file .env
cd ~/Repos/Progetti/sentinelcore/vulnerability-manager
echo "DATABASE_URL=postgresql://vlnman:DogNET@localhost/vulnerability_manager" > .env

echo "✅ File .env creato"
echo ""

# ============================================
# 8️⃣ ESEGUI MIGRATIONS
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "8️⃣  Esecuzione Database Migrations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd ~/Repos/Progetti/sentinelcore

if [ -f "./run-migrations.sh" ]; then
    echo "📊 Esecuzione migrations..."
    ./run-migrations.sh
    echo ""
    echo "✅ Migrations completate"
else
    echo "⚠️  Script migrations non trovato, esegui manualmente:"
    echo "   cd ~/Repos/Progetti/sentinelcore"
    echo "   ./run-migrations.sh"
fi

echo ""

# ============================================
# ✅ RIEPILOGO FINALE
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup Completato con Successo!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📦 Versioni installate:"
echo "   • Rust: $(rustc --version)"
echo "   • Cargo: $(cargo --version)"
echo "   • Node.js: $(node --version)"
echo "   • npm: $(npm --version)"
echo "   • PostgreSQL: $(psql --version | awk '{print $3}')"
echo ""
echo "📚 Dipendenze Backend (Rust):"
echo "   • Axum 0.6 (web framework)"
echo "   • SQLx 0.7 (database ORM)"
echo "   • Tokio 1.28 (async runtime)"
echo "   • Argon2 0.5 (password hashing)"
echo ""
echo "📚 Dipendenze Frontend (React):"
echo "   • Node.js 20 LTS"
echo "   • React 18.2.0"
echo "   • TypeScript 4.9.5"
echo "   • Material-UI 5.17"
echo "   • Cytoscape.js 3.27"
echo ""
echo "🗄️  Database:"
echo "   • PostgreSQL 14+"
echo "   • Database: vulnerability_manager"
echo "   • User: vlnman / DogNET"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Prossimi Passi:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1️⃣  Compila il backend:"
echo "   cd ~/Repos/Progetti/sentinelcore/vulnerability-manager"
echo "   cargo build --release"
echo ""
echo "2️⃣  Avvia il backend:"
echo "   cd ~/Repos/Progetti/sentinelcore"
echo "   ./start-backend.sh"
echo ""
echo "3️⃣  Avvia il frontend (in un altro terminale):"
echo "   cd ~/Repos/Progetti/sentinelcore"
echo "   ./start-frontend.sh"
echo ""
echo "4️⃣  Accedi all'applicazione:"
echo "   http://localhost:3000"
echo "   Username: admin"
echo "   Password: Admin123!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📖 Documentazione:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   • START-HERE.md          - Guida di avvio rapido"
echo "   • QUICKSTART.md          - Setup dettagliato"
echo "   • RESET-PASSWORD.md      - Recupero credenziali"
echo "   • FIX-COMPILATION-ERRORS.md - Risoluzione problemi"
echo ""
echo "🎉 Buon lavoro con Sentinel Core!"
echo ""
