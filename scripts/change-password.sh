#!/bin/bash
# Script per cambiare password utenti Sentinel Core

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "🔐 Cambia Password Utente - Sentinel Core"
    echo ""
    echo "Uso: ./change-password.sh USERNAME NUOVA_PASSWORD"
    echo ""
    echo "Esempi:"
    echo "  ./change-password.sh admin 'MiaPassword123!'"
    echo "  ./change-password.sh team_leader 'SecurePass456'"
    echo "  ./change-password.sh user1 'UserPass789'"
    echo ""
    echo "📋 Credenziali DEFAULT (se hai eseguito seed_data.sql):"
    echo "  Username: admin          Password: admin123"
    echo "  Username: team_leader    Password: teamleader123"
    echo "  Username: user1          Password: user123"
    echo ""
    exit 1
fi

USERNAME="$1"
NEW_PASSWORD="$2"
DB_URL="postgresql://vlnman:DogNET@localhost/vulnerability_manager"

echo "🔐 Cambio password per utente: $USERNAME"
echo ""

# Verifica connessione database
if ! psql "$DB_URL" -c "SELECT 1;" > /dev/null 2>&1; then
    echo "❌ Errore: Impossibile connettersi al database!"
    echo "   Verifica che PostgreSQL sia avviato e il database creato."
    exit 1
fi

# Verifica che l'utente esista
USER_EXISTS=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM users WHERE username = '$USERNAME';" 2>/dev/null | tr -d ' ')

if [ "$USER_EXISTS" != "1" ]; then
    echo "❌ Errore: Utente '$USERNAME' non trovato!"
    echo ""
    echo "📋 Utenti esistenti nel database:"
    psql "$DB_URL" -c "SELECT username, email, role FROM users;"
    exit 1
fi

echo "✅ Utente trovato nel database"
echo ""
echo "🔄 Generazione hash Argon2..."
echo ""

# Vai alla directory del tool
cd "$(dirname "$0")/vulnerability-manager/init-vuln-db"

# Compila e esegui il tool per generare hash
HASH_OUTPUT=$(cargo run --quiet --bin hash-password "$NEW_PASSWORD" 2>/dev/null)

# Estrai solo la riga dell'hash
HASH=$(echo "$HASH_OUTPUT" | grep '^\$argon2' | head -1)

if [ -z "$HASH" ]; then
    echo "❌ Errore durante la generazione dell'hash!"
    echo ""
    echo "Output completo:"
    echo "$HASH_OUTPUT"
    exit 1
fi

echo "✅ Hash generato:"
echo "   $HASH"
echo ""
echo "🔄 Aggiornamento database..."

# Aggiorna la password nel database
psql "$DB_URL" -c "UPDATE users SET password_hash = '$HASH' WHERE username = '$USERNAME';" > /dev/null

echo "✅ Password aggiornata con successo!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Nuove credenziali:"
echo "   Username: $USERNAME"
echo "   Password: $NEW_PASSWORD"
echo ""
echo "🌐 Puoi ora fare login su: http://localhost:3000"
echo ""
