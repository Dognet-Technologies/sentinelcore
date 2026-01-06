#!/bin/bash
# Script per eseguire solo migration 005

set -e  # Exit on error

DB_URL="postgresql://vlnman:DogNET@localhost/vulnerability_manager"

echo "🔄 Esecuzione migration 005..."
echo ""

# Migration 005: Add Missing Columns
echo "📊 Esecuzione 005_add_missing_columns.sql..."
psql "$DB_URL" -f vulnerability-manager/migrations/005_add_missing_columns.sql
echo "✅ Migration 005 completata"
echo ""

echo "🎉 Migration 005 eseguita con successo!"
echo ""

# Verifica le colonne aggiunte
echo "📋 Verifica colonne users:"
psql "$DB_URL" -c "\d users" | grep -E "phone_number|bio"
echo ""

echo "📋 Verifica colonne user_sessions:"
psql "$DB_URL" -c "\d user_sessions" | grep -E "device_info|last_activity"
echo ""
