#!/bin/bash
# Script per compilare senza PostgreSQL attivo

echo "🔧 Compilazione in modalità offline (senza PostgreSQL)..."
echo ""

export SQLX_OFFLINE=true

echo "📦 Building backend..."
cargo build --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Compilazione completata con successo!"
    echo ""
    echo "📍 Binary disponibile in: target/release/vulnerability-manager"
else
    echo ""
    echo "❌ Errore durante la compilazione"
    echo ""
    echo "💡 Se vedi ancora errori SQLx, prova:"
    echo "   1. Avvia PostgreSQL: sudo systemctl start postgresql"
    echo "   2. Genera cache: cargo sqlx prepare"
    echo "   3. Riprova: ./compile-offline.sh"
fi
