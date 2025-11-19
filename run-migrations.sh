#!/bin/bash
# Script per eseguire le migrations del database

set -e  # Exit on error

DB_URL="postgresql://vlnman:DogNET@localhost/vulnerability_manager"

echo "🔄 Esecuzione migrations per Sentinel Core..."
echo ""

# Migration 001: Schema iniziale
echo "📊 [1/4] Esecuzione 001_initial_schema.sql..."
psql "$DB_URL" -f vulnerability-manager/migrations/001_initial_schema.sql
echo "✅ Migration 001 completata"
echo ""

# Migration 002: Conversione INET
echo "📊 [2/4] Esecuzione 002_initial_schema.sql (INET conversion)..."
psql "$DB_URL" -f vulnerability-manager/migrations/002_initial_schema.sql
echo "✅ Migration 002 completata"
echo ""

# Migration 003: Network Topology (NUOVA!)
echo "📊 [3/4] Esecuzione 003_network_topology.sql (Network Scan)..."
psql "$DB_URL" -f vulnerability-manager/migrations/003_network_topology.sql
echo "✅ Migration 003 completata"
echo ""

# Seed data (opzionale)
echo "📊 [4/4] Caricamento dati di test (seed_data.sql)..."
psql "$DB_URL" -f vulnerability-manager/migrations/seed_data.sql
echo "✅ Seed data caricati"
echo ""

echo "🎉 Tutte le migrations sono state eseguite con successo!"
echo ""
echo "📋 Verifica tabelle create:"
psql "$DB_URL" -c "\dt"
