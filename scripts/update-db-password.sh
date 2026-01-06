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

echo "🔄 Aggiornamento password database..."
echo ""

# Aggiorna .env
echo "📝 Aggiornamento vulnerability-manager/.env..."
sed -i "s/:${OLD_PASSWORD}@/:${NEW_PASSWORD}@/g" vulnerability-manager/.env

# Aggiorna .env.example
echo "📝 Aggiornamento vulnerability-manager/.env.example..."
sed -i "s/:${OLD_PASSWORD}@/:${NEW_PASSWORD}@/g" vulnerability-manager/.env.example

# Aggiorna default.yaml
echo "📝 Aggiornamento vulnerability-manager/config/default.yaml..."
sed -i "s/:${OLD_PASSWORD}@/:${NEW_PASSWORD}@/g" vulnerability-manager/config/default.yaml

# Aggiorna run-migrations.sh
echo "📝 Aggiornamento run-migrations.sh..."
sed -i "s/:${OLD_PASSWORD}@/:${NEW_PASSWORD}@/g" run-migrations.sh

# Aggiorna check-migrations.sh
echo "📝 Aggiornamento check-migrations.sh..."
sed -i "s/:${OLD_PASSWORD}@/:${NEW_PASSWORD}@/g" check-migrations.sh

# Aggiorna start-backend.sh
echo "📝 Aggiornamento start-backend.sh..."
sed -i "s/:${OLD_PASSWORD}@/:${NEW_PASSWORD}@/g" start-backend.sh

echo ""
echo "✅ Password aggiornata in tutti i file!"
echo ""
echo "Nuova connection string:"
echo "postgresql://vlnman:${NEW_PASSWORD}@localhost/vulnerability_manager"
