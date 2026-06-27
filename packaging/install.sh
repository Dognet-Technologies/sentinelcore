#!/usr/bin/env bash
#
# SentinelCore — installer del pacchetto BINARIO (no-source, no-toolchain).
# Installa i build gia' compilati su una Debian 12/13 pulita: runtime deps,
# PostgreSQL, migration, config con segreti generati per-istanza, systemd, nginx.
#
# Uso:  sudo ./install.sh [--server-name <ip-o-host>] [--iface <nic>]
#
# Idempotenza: pensato per un host PULITO. Se il DB esiste gia', si ferma
# (usa --force per riprovare, a tuo rischio: le migration verrebbero riapplicate).
set -euo pipefail

# ── parametri ────────────────────────────────────────────────────────────────
SERVER_NAME=""
NET_IFACE=""
FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --server-name) SERVER_NAME="$2"; shift 2 ;;
    --iface)       NET_IFACE="$2"; shift 2 ;;
    --force)       FORCE=1; shift ;;
    *) echo "Argomento sconosciuto: $1"; exit 2 ;;
  esac
done

[ "$(id -u)" -eq 0 ] || { echo "Esegui come root (sudo ./install.sh)"; exit 1; }

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── layout ───────────────────────────────────────────────────────────────────
BASE=/opt/sentinelsuite/sentinelcore
APP="$BASE/app"
FRONTEND="$BASE/frontend"
LOGDIR=/var/log/sentinelsuite/sentinelcore
SVC_USER=sentinelcore
DB_NAME=vulnerability_manager
DB_USER=vlnman

log() { echo -e "\n\033[1;36m▶ $*\033[0m"; }

# ── rilevamento rete (per CORS + discovery) ─────────────────────────────────
if [ -z "$SERVER_NAME" ]; then
  SERVER_NAME="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')"
  [ -z "$SERVER_NAME" ] && SERVER_NAME="$(hostname -I | awk '{print $1}')"
fi
if [ -z "$NET_IFACE" ]; then
  NET_IFACE="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')"
  [ -z "$NET_IFACE" ] && NET_IFACE="eth0"
fi
echo "Server origin (CORS): http://$SERVER_NAME   |   NIC discovery: $NET_IFACE"

# ── 1. runtime deps (NIENTE toolchain di build) ─────────────────────────────
log "1/8 Installazione dipendenze runtime"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends \
  postgresql nginx nmap arp-scan ca-certificates curl openssl libssl3 sudo >/dev/null

# ── 2. utente di servizio + directory ───────────────────────────────────────
log "2/8 Utente di servizio e directory"
id -u "$SVC_USER" >/dev/null 2>&1 || \
  useradd --system --home "$BASE" --shell /usr/sbin/nologin "$SVC_USER"
mkdir -p "$APP" "$FRONTEND" "$LOGDIR" "$APP/plugins" "$APP/reports" "$APP/uploads" "$APP/config"

# ── 3. copia artefatti compilati ────────────────────────────────────────────
log "3/8 Copia binario + frontend + migration"
install -m 0755 "$PKG_DIR/vulnerability-manager" "$APP/vulnerability-manager"
rm -rf "$FRONTEND"/*; cp -a "$PKG_DIR/frontend/." "$FRONTEND/"
mkdir -p "$APP/migrations"; cp -a "$PKG_DIR/migrations/." "$APP/migrations/"
[ -d "$PKG_DIR/plugins" ] && cp -a "$PKG_DIR/plugins/." "$APP/plugins/" || true

# ── 4. PostgreSQL: user + db (password per-istanza) ─────────────────────────
log "4/8 PostgreSQL: utente e database"
systemctl enable --now postgresql >/dev/null 2>&1 || true
DB_EXISTS="$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" 2>/dev/null || true)"
if [ "$DB_EXISTS" = "1" ] && [ "$FORCE" -ne 1 ]; then
  echo "ERRORE: il database '$DB_NAME' esiste gia'. Installer pensato per host pulito."
  echo "        Usa --force per riapplicare (rischioso) o rimuovi il DB prima."
  exit 1
fi
DB_PASSWORD="$(openssl rand -hex 24)"   # esadecimale: niente caratteri da URL-encodare
sudo -u postgres psql -v ON_ERROR_STOP=1 >/dev/null <<SQL
DO \$\$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='$DB_USER') THEN
    CREATE ROLE $DB_USER LOGIN PASSWORD '$DB_PASSWORD';
  ELSE
    ALTER ROLE $DB_USER PASSWORD '$DB_PASSWORD';
  END IF;
END \$\$;
SQL
sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1 || \
  sudo -u postgres createdb -O "$DB_USER" "$DB_NAME"

# ── 5. migration (in ordine) ────────────────────────────────────────────────
log "5/8 Applicazione migration"
DBURL="postgresql://$DB_USER:$DB_PASSWORD@127.0.0.1:5432/$DB_NAME"
for f in $(ls "$APP/migrations"/*.sql | sort); do
  PGPASSWORD="$DB_PASSWORD" psql -h 127.0.0.1 -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 -q -f "$f" \
    || { echo "Migration fallita: $f"; exit 1; }
done
echo "Applicate $(ls "$APP/migrations"/*.sql | wc -l) migration."

# ── 6. config con segreti generati ──────────────────────────────────────────
log "6/8 Configurazione (segreti per-istanza)"
JWT_SECRET="$(openssl rand -hex 32)"
sed -e "s#@@DB_PASSWORD@@#$DB_PASSWORD#g" \
    -e "s#@@JWT_SECRET@@#$JWT_SECRET#g" \
    -e "s#@@SERVER_NAME@@#$SERVER_NAME#g" \
    -e "s#@@NET_IFACE@@#$NET_IFACE#g" \
    "$PKG_DIR/templates/production.yaml.tmpl" > "$APP/config/production.yaml"
chmod 600 "$APP/config/production.yaml"

# ── 7. systemd + nginx ──────────────────────────────────────────────────────
log "7/8 systemd + nginx"
chown -R "$SVC_USER:$SVC_USER" "$BASE" "$LOGDIR"
install -m 0644 "$PKG_DIR/templates/sentinelcore.service" /etc/systemd/system/sentinelcore.service
install -m 0644 "$PKG_DIR/templates/nginx-sentinelcore.conf" /etc/nginx/sites-available/sentinelcore
ln -sf /etc/nginx/sites-available/sentinelcore /etc/nginx/sites-enabled/sentinelcore
rm -f /etc/nginx/sites-enabled/default
# discovery: nmap/arp-scan via sudo NOPASSWD per l'utente di servizio
echo "$SVC_USER ALL=(root) NOPASSWD: /usr/bin/nmap, /usr/sbin/arp-scan" > /etc/sudoers.d/sentinelcore-scan
chmod 440 /etc/sudoers.d/sentinelcore-scan
nginx -t >/dev/null 2>&1 && systemctl reload nginx
systemctl daemon-reload
systemctl enable --now sentinelcore >/dev/null 2>&1

# ── 8. health + admin ───────────────────────────────────────────────────────
log "8/8 Verifica e creazione admin"
# Da qui i fallimenti NON devono abortire l'install (gia' a posto a monte).
set +e
for i in $(seq 1 30); do
  [ "$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/api/health 2>/dev/null)" = "200" ] && break
  sleep 1
done
HEALTH="$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/api/health 2>/dev/null)"

ADMIN_USER="admin"
# Password conforme alla policy (>=12, maiusc+minusc+numero+speciale).
ADMIN_PASS="$(openssl rand -base64 12 | tr -dc 'A-Za-z0-9' | cut -c1-14)Aa1!"
ADMIN_OK=0
if [ "$HEALTH" = "200" ]; then
  # Flusso register-then-promote (vedi INSTALL.md): CSRF = cookie XSRF-TOKEN su
  # una GET qualsiasi, poi register con skip_email_verification, poi promote.
  JAR="$(mktemp)"
  curl -s -c "$JAR" http://127.0.0.1:8080/api/health >/dev/null 2>&1
  CSRF="$(awk '/XSRF-TOKEN/{print $7}' "$JAR" 2>/dev/null)"
  curl -s -b "$JAR" -H "X-CSRF-Token: $CSRF" -H 'Content-Type: application/json' \
    -X POST http://127.0.0.1:8080/api/auth/register \
    -d "{\"username\":\"$ADMIN_USER\",\"email\":\"admin@local\",\"password\":\"$ADMIN_PASS\",\"skip_email_verification\":true}" \
    >/dev/null 2>&1
  PGPASSWORD="$DB_PASSWORD" psql -h 127.0.0.1 -U "$DB_USER" -d "$DB_NAME" -q \
    -c "UPDATE users SET role='admin' WHERE username='$ADMIN_USER';" >/dev/null 2>&1
  ROLE="$(PGPASSWORD="$DB_PASSWORD" psql -h 127.0.0.1 -U "$DB_USER" -d "$DB_NAME" -tAc \
        "SELECT role FROM users WHERE username='$ADMIN_USER'" 2>/dev/null)"
  [ "$ROLE" = "admin" ] && ADMIN_OK=1
  rm -f "$JAR"
fi

# ── summary ─────────────────────────────────────────────────────────────────
cat <<EOF

────────────────────────────────────────────────────────────────────
 ✅ SentinelCore installato.
   URL:        http://$SERVER_NAME
   Backend:    127.0.0.1:8080  (health: $HEALTH)
   Servizio:   systemctl status sentinelcore
   Config:     $APP/config/production.yaml  (segreti generati, chmod 600)
EOF
if [ "$ADMIN_OK" = "1" ]; then
  cat <<EOF
   Admin:      $ADMIN_USER  /  $ADMIN_PASS
               ⚠️  CAMBIA questa password al primo accesso.
EOF
else
  cat <<EOF
   Admin:      creazione automatica non riuscita — crealo a mano:
               vedi la sezione "Create the first admin user" in INSTALL.md.
EOF
fi
cat <<EOF
   Nota CORS:  se l'IP cambia (DHCP), aggiorna security.cors.allowed_origins
               in production.yaml e: sudo systemctl restart sentinelcore
────────────────────────────────────────────────────────────────────
EOF
