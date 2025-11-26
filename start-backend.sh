#!/bin/bash
# Script per avviare il backend Sentinel Core

set -e

<<<<<<< HEAD
cd "$(dirname "$0")/sentinelcore/vulnerability-manager"
=======
cd "$(dirname "$0")/vulnerability-manager"
>>>>>>> ef5bd9490ba8ebe970c3c0eaf0486e18b7f619e2

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
psql "$DATABASE_URL" -c "SELECT version();" > /dev/null 2>&1
if [ $? -eq 0 ]; then
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
