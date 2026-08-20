#!/usr/bin/env bash
#
# SentinelCore — rigenerazione segreti al primo avvio (VM appliance).
#
# Chiamato da sentinelcore-first-boot.service (Type=oneshot) una volta sola.
# Al termine disabilita se stesso: dai prossimi avvii sentinelcore parte
# normalmente. Progettato per essere idempotente se interrotto e rilanciato.
set -euo pipefail

CONFIG=/opt/sentinelsuite/sentinelcore/app/config/production.yaml
DB_NAME=vulnerability_manager
DB_USER=vlnman
LOG=/var/log/sentinelsuite/sentinelcore/first-boot.log

mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1
echo "=== first-boot $(date '+%Y-%m-%d %H:%M:%S') ==="

# ── 1. Rigenera SSH host keys se rimosse durante build ──────────────────────
if ! ls /etc/ssh/ssh_host_*_key 2>/dev/null | grep -q .; then
    echo "[1/7] Rigenerazione SSH host keys..."
    ssh-keygen -A 2>/dev/null || dpkg-reconfigure openssh-server 2>/dev/null || true
    systemctl restart ssh 2>/dev/null || true
else
    echo "[1/7] SSH host keys presenti — skip"
fi

# ── 2. Estrai DB password corrente da production.yaml ───────────────────────
echo "[2/7] Lettura config..."
# URL formato: postgresql://vlnman:<password>@127.0.0.1:5432/vulnerability_manager
CURRENT_DB_PASS="$(grep -oP 'postgresql://[^:]+:\K[^@]+' "$CONFIG" 2>/dev/null || true)"
if [ -z "$CURRENT_DB_PASS" ]; then
    echo "ERRORE: impossibile leggere DB password da $CONFIG"
    exit 1
fi

# ── 3. Genera nuovi segreti ──────────────────────────────────────────────────
echo "[3/7] Generazione nuovi segreti..."
NEW_DB_PASS="$(openssl rand -hex 24)"
NEW_JWT="$(openssl rand -hex 32)"
# Credenziali web fisse per il primo accesso
ADMIN_USER="microcyber"
ADMIN_PASS="Admin2026!!"
# Password root fissa e documentabile (da cambiare dopo il primo accesso)
ROOT_PASS="SentinelCore1st!"

# ── 4. Aggiorna production.yaml ──────────────────────────────────────────────
echo "[4/7] Aggiornamento config..."
sed -i \
    -e "s|postgresql://$DB_USER:[^@]*@|postgresql://$DB_USER:$NEW_DB_PASS@|" \
    -e "s|secret_key: \"[^\"]*\"|secret_key: \"$NEW_JWT\"|" \
    "$CONFIG"

# ── 5. Aggiorna password utente PostgreSQL ───────────────────────────────────
echo "[5/7] Aggiornamento credenziali DB..."
sudo -u postgres psql -v ON_ERROR_STOP=1 \
    -c "ALTER ROLE $DB_USER PASSWORD '$NEW_DB_PASS';" >/dev/null

# ── 6. Riavvia sentinelcore con la nuova config, ricrea admin ────────────────
echo "[6/7] Riavvio backend e verifica admin..."
systemctl restart sentinelcore || true

echo "    Attendo risposta backend (max 60s)..."
HEALTH_OK=0
for i in $(seq 1 60); do
    CODE="$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/api/health 2>/dev/null || true)"
    if [ "$CODE" = "200" ]; then
        HEALTH_OK=1; break
    fi
    sleep 1
done

ADMIN_STATUS="ERRORE"
if [ "$HEALTH_OK" = "1" ]; then
    # L'utente è già stato creato da install.sh con le credenziali fisse.
    # Qui verifichiamo solo che esista ed abbia ruolo admin.
    ROLE="$(PGPASSWORD="$NEW_DB_PASS" psql -h 127.0.0.1 -U "$DB_USER" -d "$DB_NAME" -tAc \
        "SELECT role FROM users WHERE username='$ADMIN_USER'" 2>/dev/null || true)"
    [ "$ROLE" = "admin" ] && ADMIN_STATUS="OK"
else
    echo "    WARN: backend non risponde (health=$CODE)"
fi

# ── 7. Scrivi credenziali su /etc/motd ───────────────────────────────────────
echo "[7/7] Credenziali iniziali → /etc/motd"
SERVER_IP="$(ip -4 route get 1.1.1.1 2>/dev/null \
    | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')" || SERVER_IP="<ip-vm>"

if [ "$ADMIN_STATUS" = "OK" ]; then
    CRED_BLOCK="  Web UI:
    Utente:   $ADMIN_USER
    Password: $ADMIN_PASS

  SSH / Console:
    Utente:   root
    Password: $ROOT_PASS

  CAMBIA entrambe le password al primo accesso."
else
    CRED_BLOCK="  Credenziali web admin: creazione non riuscita.
  Vedi: $LOG

  SSH / Console:
    Utente:   root
    Password: $ROOT_PASS"
fi

# Scrivi anche in /etc/issue.d/ — visibile PRIMA del login prompt
mkdir -p /etc/issue.d
cat > /etc/issue.d/sentinelcore.issue <<ISSUE

╔══════════════════════════════════════════════════════════════╗
║          SentinelCore — Credenziali iniziali istanza         ║
╠══════════════════════════════════════════════════════════════╣
  URL:        http://$SERVER_IP
$CRED_BLOCK
╚══════════════════════════════════════════════════════════════╝

ISSUE

cat > /etc/motd <<MOTD

╔══════════════════════════════════════════════════════════════╗
║          SentinelCore — Credenziali iniziali istanza         ║
╠══════════════════════════════════════════════════════════════╣
  URL:        http://$SERVER_IP
$CRED_BLOCK
╚══════════════════════════════════════════════════════════════╝
MOTD

echo ""
cat /etc/motd
echo ""

# ── Disabilita questo servizio ───────────────────────────────────────────────
systemctl disable sentinelcore-first-boot.service
echo "=== first-boot completato — servizio disabilitato. ==="
