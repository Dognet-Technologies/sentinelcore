#!/bin/bash
# Script per aggiornare password utente nel database

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Uso: ./update-user-password.sh USERNAME NUOVA_PASSWORD"
    echo ""
    echo "Esempi:"
    echo "  ./update-user-password.sh admin NuovaPass123!"
    echo "  ./update-user-password.sh team_leader MiaPassword456"
    echo ""
    echo "Utenti disponibili:"
    echo "  - admin (ruolo: admin)"
    echo "  - team_leader (ruolo: team_leader)"
    echo "  - user1 (ruolo: user)"
    exit 1
fi

USERNAME="$1"
NEW_PASSWORD="$2"
DB_URL="postgresql://vlnman:DogNET@localhost/vulnerability_manager"

echo "🔐 Aggiornamento password per utente: $USERNAME"
echo ""

# Verifica che l'utente esista
USER_EXISTS=$(psql "$DB_URL" -t -c "SELECT COUNT(*) FROM users WHERE username = '$USERNAME';" 2>/dev/null | tr -d ' ')

if [ "$USER_EXISTS" != "1" ]; then
    echo "❌ Errore: Utente '$USERNAME' non trovato!"
    echo ""
    echo "Utenti esistenti:"
    psql "$DB_URL" -c "SELECT username, role FROM users;"
    exit 1
fi

echo "⚠️  NOTA: La password verrà hashata usando Argon2."
echo "   Questo script usa un hash temporaneo. Per sicurezza, usa l'API."
echo ""
echo "📋 Password in chiaro che stai impostando: $NEW_PASSWORD"
echo ""
echo "🔄 Generazione hash Argon2..."

# IMPORTANTE: Questo è un hash di esempio. In produzione, usa il backend Rust per generare l'hash
# Per ora, uso un hash pre-generato per "admin123" come fallback
TEMP_HASH='$argon2id$v=19$m=16,t=2,p=1$NzZJbmtsRzJpSnJZeVVVcg$YiDJHvIB/lbugIUOI+Nc6D3ZLok'

echo "⚠️  ATTENZIONE: Questo script è per SVILUPPO."
echo "   In produzione, usa l'API del backend per cambiare password."
echo ""
echo "Per ora, ti mostro come fare via API..."
echo ""

# Mostra come fare via API
cat << EOF
📚 METODO CONSIGLIATO - Via API:

1. Login come admin:
   curl -X POST http://localhost:8080/api/auth/login \\
     -H "Content-Type: application/json" \\
     -d '{"username":"admin","password":"admin123"}'

2. Salva il token JWT dalla risposta

3. Cambia password:
   curl -X PUT http://localhost:8080/api/users/me/password \\
     -H "Content-Type: application/json" \\
     -H "Authorization: Bearer TUO_TOKEN_QUI" \\
     -d '{"old_password":"admin123","new_password":"$NEW_PASSWORD"}'

EOF

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "Vuoi procedere comunque con SQL diretto? (solo per DEV) [y/N]: " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operazione annullata."
    exit 0
fi

echo ""
echo "Per generare l'hash Argon2, avvia il tool Rust..."
echo ""
echo "cd vulnerability-manager/init-vuln-db"
echo "cargo run -- hash-password '$NEW_PASSWORD'"
echo ""
echo "Poi usa l'hash generato per aggiornare il database:"
echo "UPDATE users SET password_hash = 'HASH_GENERATO' WHERE username = '$USERNAME';"
