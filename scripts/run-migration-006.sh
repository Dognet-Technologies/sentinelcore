#!/bin/bash
# Script per eseguire solo migration 006 (TIMESTAMPTZ)

set -e  # Exit on error

DB_URL="postgresql://vlnman:DogNET@localhost/vulnerability_manager"

echo "🔄 Esecuzione migration 006..."
echo ""

# Migration 006: Convert to TIMESTAMPTZ
echo "📊 Esecuzione 006_convert_to_timestamptz.sql (Timezone support)..."
psql "$DB_URL" -f vulnerability-manager/migrations/006_convert_to_timestamptz.sql
echo "✅ Migration 006 completata"
echo ""

echo "🎉 Migration 006 eseguita con successo!"
echo ""

# Verifica tipi timestamp
echo "📋 Verifica tipi timestamp (dovrebbero essere 'timestamp with time zone'):"
psql "$DB_URL" -c "
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'users'
  AND column_name IN ('created_at', 'updated_at', 'last_login')
ORDER BY column_name;
"
echo ""
