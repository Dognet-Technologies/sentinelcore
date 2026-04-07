#!/bin/bash
# Script per verificare quali migrations servono

DB_URL="postgresql://vlnman:DogNET@localhost/vulnerability_manager"

echo "🔍 Controllo stato migrations..."
echo ""

# Verifica connessione
if ! psql "$DB_URL" -c "SELECT 1;" > /dev/null 2>&1; then
    echo "❌ Impossibile connettersi al database!"
    echo "   Assicurati che PostgreSQL sia avviato:"
    echo "   sudo systemctl start postgresql"
    exit 1
fi

echo "✅ Connessione database OK"
echo ""

# Controlla tabelle esistenti
echo "📊 Tabelle presenti nel database:"
psql "$DB_URL" -c "\dt" 2>/dev/null | grep "public |" || echo "   Nessuna tabella trovata"
echo ""

# Controlla tabelle specifiche
echo "🔍 Verifica migrations necessarie:"
echo ""

# Migration 001 - Base tables
TABLES_001=("users" "teams" "vulnerabilities" "assets" "reports" "plugins")
MISSING_001=0
for table in "${TABLES_001[@]}"; do
    if psql "$DB_URL" -c "\d $table" > /dev/null 2>&1; then
        echo "  ✅ Tabella '$table' presente"
    else
        echo "  ❌ Tabella '$table' MANCANTE"
        MISSING_001=1
    fi
done

# Migration 003 - Network Topology (NUOVA!)
echo ""
echo "🌐 Nuove tabelle Network Topology:"
TABLES_003=("network_devices" "network_links" "network_scans" "device_vulnerabilities" "remediation_tasks")
MISSING_003=0
for table in "${TABLES_003[@]}"; do
    if psql "$DB_URL" -c "\d $table" > /dev/null 2>&1; then
        echo "  ✅ Tabella '$table' presente"
    else
        echo "  ❌ Tabella '$table' MANCANTE"
        MISSING_003=1
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Raccomandazioni
if [ $MISSING_001 -eq 1 ]; then
    echo "⚠️  DEVI ESEGUIRE:"
    echo "   psql \"$DB_URL\" -f vulnerability-manager/migrations/001_initial_schema.sql"
    echo "   psql \"$DB_URL\" -f vulnerability-manager/migrations/002_initial_schema.sql"
    echo ""
fi

if [ $MISSING_003 -eq 1 ]; then
    echo "🆕 NUOVA MIGRATION DA ESEGUIRE:"
    echo "   psql \"$DB_URL\" -f vulnerability-manager/migrations/003_network_topology.sql"
    echo ""
    echo "   Questa migration aggiunge le tabelle per:"
    echo "   - Network Scan Visualization"
    echo "   - Device Topology Mapping"
    echo "   - Remediation Tasks"
    echo ""
fi

if [ $MISSING_001 -eq 0 ] && [ $MISSING_003 -eq 0 ]; then
    echo "🎉 Tutte le migrations sono già eseguite!"
    echo "   Puoi avviare direttamente l'applicazione."
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
