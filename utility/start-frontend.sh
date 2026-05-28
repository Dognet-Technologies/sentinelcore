#!/bin/bash
# Script per avviare il frontend Sentinel Core

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../vulnerability-manager-frontend"

echo "🚀 Avvio Sentinel Core Frontend..."
echo ""

# Verifica node_modules
if [ ! -d "node_modules" ]; then
    echo "📦 Installazione dipendenze npm..."
    npm install
    echo ""
fi

echo "🌐 Avvio development server..."
echo "   Frontend: http://localhost:3000"
echo "   Backend proxy: http://localhost:8080"
echo "   Premi Ctrl+C per fermare"
echo ""

npm start
