#!/bin/bash
# Script per avviare il backend Sentinel Core

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../vulnerability-manager"

echo "🚀 Avvio Sentinel Core Backend..."
echo ""

# Carica variabili d'ambiente
if [ -f .env ]; then
    echo "📋 Caricamento configurazione da .env..."
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "⚠️  File .env non trovato. Usando valori di default..."
    export DATABASE_URL="postgresql://vlnman:DogNET@localhost/vulnerability_manager"
    export RUST_LOG="info,vulnerability_manager=debug"
fi

echo "✅ Configurazione caricata"
echo ""

# Verifica connessione database
echo "🔍 Verifica connessione database..."
if psql "$DATABASE_URL" -c "SELECT version();" > /dev/null 2>&1; then
    echo "✅ Database connesso"
else
    echo "❌ Impossibile connettersi al database!"
    echo "   Assicurati che PostgreSQL sia avviato e il database creato."
    exit 1
fi
echo ""

# Build e avvio
echo "🔨 Compilazione backend..."
cargo build --release

echo ""
echo "🌐 Avvio server su http://0.0.0.0:8080"
echo "   Premi Ctrl+C per fermare"
echo ""

cargo run --release
