#!/bin/bash
# Script per aggiornare la password del database in tutti i file

if [ -z "$1" ]; then
    echo "Uso: ./update-db-password.sh NUOVA_PASSWORD"
    echo ""
    echo "Esempio:"
    echo "  ./update-db-password.sh MiaPassword123"
    exit 1
fi

NEW_PASSWORD="$1"
OLD_PASSWORD="DogNET"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."

echo "🔄 Aggiornamento password database..."
echo ""

# Aggiorna .env
echo "📝 Aggiornamento vulnerability-manager/.env..."
sed -i "s/:${OLD_PASSWORD}@/:${NEW_PASSWORD}@/g" "$REPO_ROOT/vulnerability-manager/.env"

# Aggiorna .env.example
echo "📝 Aggiornamento vulnerability-manager/.env.example..."
sed -i "s/:${OLD_PASSWORD}@/:${NEW_PASSWORD}@/g" "$REPO_ROOT/vulnerability-manager/.env.example"

# Aggiorna default.yaml
echo "📝 Aggiornamento vulnerability-manager/config/default.yaml..."
sed -i "s/:${OLD_PASSWORD}@/:${NEW_PASSWORD}@/g" "$REPO_ROOT/vulnerability-manager/config/default.yaml"

# Aggiorna start-backend.sh
echo "📝 Aggiornamento utility/start-backend.sh..."
sed -i "s/:${OLD_PASSWORD}@/:${NEW_PASSWORD}@/g" "$SCRIPT_DIR/start-backend.sh"

# Aggiorna start.sh
echo "📝 Aggiornamento utility/start.sh..."
sed -i "s/:${OLD_PASSWORD}@/:${NEW_PASSWORD}@/g" "$SCRIPT_DIR/start.sh"

# Aggiorna deploy.sh
echo "📝 Aggiornamento utility/deploy.sh..."
sed -i "s/:${OLD_PASSWORD}@/:${NEW_PASSWORD}@/g" "$SCRIPT_DIR/deploy.sh"

echo ""
echo "✅ Password aggiornata in tutti i file!"
echo ""
echo "Nuova connection string:"
echo "postgresql://vlnman:${NEW_PASSWORD}@localhost/vulnerability_manager"
