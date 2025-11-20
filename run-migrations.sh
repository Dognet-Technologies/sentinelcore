#!/bin/bash
# Script per eseguire le migrations del database

set -e  # Exit on error

DB_URL="postgresql://vlnman:DogNET@localhost/vulnerability_manager"

echo "🔄 Esecuzione migrations per Sentinel Core..."
echo ""

# Migration 001: Schema iniziale
echo "📊 [1/7] Esecuzione 001_initial_schema.sql..."
psql "$DB_URL" -f vulnerability-manager/migrations/001_initial_schema.sql
echo "✅ Migration 001 completata"
echo ""

# Migration 002: User Features & Security
echo "📊 [2/7] Esecuzione 002_add_user_features.sql (User Features)..."
psql "$DB_URL" -f vulnerability-manager/migrations/002_add_user_features.sql
echo "✅ Migration 002 completata"
echo ""

# Migration 003: Network Topology
echo "📊 [3/7] Esecuzione 003_network_topology.sql (Network Scan)..."
psql "$DB_URL" -f vulnerability-manager/migrations/003_network_topology.sql
echo "✅ Migration 003 completata"
echo ""

# Migration 004: Convert IP to INET
echo "📊 [4/7] Esecuzione 004_convert_to_inet.sql (INET conversion)..."
psql "$DB_URL" -f vulnerability-manager/migrations/004_convert_to_inet.sql
echo "✅ Migration 004 completata"
echo ""

# Migration 005: Add Missing Columns
echo "📊 [5/7] Esecuzione 005_add_missing_columns.sql (Missing columns)..."
psql "$DB_URL" -f vulnerability-manager/migrations/005_add_missing_columns.sql
echo "✅ Migration 005 completata"
echo ""

# Migration 006: Convert to TIMESTAMPTZ
echo "📊 [6/7] Esecuzione 006_convert_to_timestamptz.sql (Timezone support)..."
psql "$DB_URL" -f vulnerability-manager/migrations/006_convert_to_timestamptz.sql
echo "✅ Migration 006 completata"
echo ""

# Seed data (opzionale)
echo "📊 [7/7] Caricamento dati di test (seed_data.sql)..."
psql "$DB_URL" -f vulnerability-manager/migrations/seed_data.sql
echo "✅ Seed data caricati"
echo ""

echo "🎉 Tutte le migrations sono state eseguite con successo!"
echo ""
echo "📋 Verifica tabelle create:"
psql "$DB_URL" -c "\dt"
