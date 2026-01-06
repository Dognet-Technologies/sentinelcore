#!/bin/bash
# Script per compilare il backend Sentinel Core
# Assicurati che PostgreSQL sia in esecuzione prima di compilare!

set -e

echo "🔧 Compilazione Sentinel Core Backend..."
echo ""

# Verifica PostgreSQL
echo "📊 Verifica connessione PostgreSQL..."
if psql "postgresql://vlnman:DogNET@localhost/vulnerability_manager" -c "SELECT 1" > /dev/null 2>&1; then
    echo "✅ PostgreSQL connesso"
else
    echo "❌ PostgreSQL non raggiungibile!"
    echo ""
    echo "⚠️  SQLx richiede PostgreSQL attivo per compilare (verifica query a compile-time)"
    echo "   Avvia PostgreSQL con: sudo systemctl start postgresql"
    exit 1
fi

echo ""
echo "🧹 Pulizia cache Cargo..."
cd vulnerability-manager
cargo clean

echo ""
echo "🔨 Compilazione in modalità release..."
echo "   (La prima compilazione scaricherà il crate ipnetwork)"
echo ""

cargo build --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ ✅ ✅ COMPILAZIONE RIUSCITA! ✅ ✅ ✅"
    echo ""
    echo "Binary disponibile in: vulnerability-manager/target/release/vulnerability-manager"
    echo ""
    echo "🚀 Avvia il backend con:"
    echo "   cd vulnerability-manager"
    echo "   ./target/release/vulnerability-manager"
    echo ""
    echo "   Oppure usa: ../start-backend.sh"
else
    echo ""
    echo "❌ Compilazione fallita. Controlla gli errori sopra."
    exit 1
fi
