#!/usr/bin/env bash
#
# SentinelCore — upgrade IN-PLACE di un'istanza già installata (source/
# binario, OVA, qcow2: stesso meccanismo — sono comunque un host Linux
# provisionato via install.sh, DB locale o su un altro segmento di rete
# tramite DATABASE_URL. Nessuna differenza di logica fra i tre formati.
#
# NON copre il caso "sposta i dati su un'appliance NUOVA di zecca" (quella
# resta una procedura pg_dump/pg_restore manuale, vedi packaging/UPGRADE.md)
# — questo script aggiorna l'istanza ESISTENTE sul posto.
#
# Uso: sudo ./upgrade.sh
#      (eseguito DENTRO la directory del NUOVO pacchetto estratto — stessa
#      convenzione di install.sh: PKG_DIR = directory dello script)
#
# Sequenza: backup DB (pg_dump) → stop servizio → backup artefatti correnti
# (per rollback) → installa nuovi artefatti → `--migrate` col nuovo binario
# → se fallisce: ripristina artefatti vecchi e riavvia, NESSUNA modifica
# silenziosa → se riesce: riavvia e verifica /api/health.
#
# Non-obiettivo (deliberato, vedi documento di design): rollback automatico
# dello SCHEMA. Se il servizio non risponde dopo un upgrade riuscito, lo
# schema resta quello nuovo — il backup pg_dump è per un ripristino manuale.
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Esegui come root (sudo ./upgrade.sh)"; exit 1; }

PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE=/opt/sentinelsuite/sentinelcore
APP="$BASE/app"
FRONTEND="$BASE/frontend"
SVC_USER=sentinelcore
BACKUP_DIR="$BASE/backups"
TS="$(date +%Y%m%d-%H%M%S)"

log() { echo -e "\n\033[1;36m▶ $*\033[0m"; }

[ -x "$APP/vulnerability-manager" ] || {
  echo "ERRORE: nessuna installazione esistente trovata in $APP."
  echo "        Per un primo avvio usa install.sh, non upgrade.sh."
  exit 1
}
[ -x "$PKG_DIR/vulnerability-manager" ] || {
  echo "ERRORE: $PKG_DIR non sembra un pacchetto di release valido (manca vulnerability-manager)."
  exit 1
}

CURRENT_VERSION="$("$APP/vulnerability-manager" --version 2>/dev/null || echo sconosciuta)"
NEW_VERSION="$("$PKG_DIR/vulnerability-manager" --version 2>/dev/null || echo sconosciuta)"
echo "Versione installata: $CURRENT_VERSION   →   Nuova: $NEW_VERSION"

CONFIG="$APP/config/production.yaml"
[ -f "$CONFIG" ] || { echo "ERRORE: $CONFIG non trovato."; exit 1; }
DBURL="$(grep -oP 'url:\s*"\K[^"]+' "$CONFIG" | head -1)"
[ -n "$DBURL" ] || { echo "ERRORE: impossibile leggere database.url da $CONFIG"; exit 1; }

# ── 1. Backup database — rete di sicurezza PRIMA di qualunque modifica ─────
log "1/6 Backup database (pg_dump)"
mkdir -p "$BACKUP_DIR"
DUMP_FILE="$BACKUP_DIR/pre-upgrade-$TS.dump"
pg_dump --format=custom --file="$DUMP_FILE" "$DBURL" || {
  echo "ERRORE: backup DB fallito — upgrade interrotto, nessuna modifica applicata."
  exit 1
}
echo "Backup salvato in: $DUMP_FILE"

# ── 2. Ferma il servizio ─────────────────────────────────────────────────────
log "2/6 Stop del servizio"
systemctl stop sentinelcore

# ── 3. Backup artefatti correnti (per rollback se la migration fallisce) ───
log "3/6 Backup artefatti correnti"
ROLLBACK_DIR="$BASE/.upgrade-rollback-$TS"
mkdir -p "$ROLLBACK_DIR"
cp -a "$APP/vulnerability-manager" "$ROLLBACK_DIR/vulnerability-manager"
cp -a "$APP/migrations" "$ROLLBACK_DIR/migrations"
cp -a "$FRONTEND" "$ROLLBACK_DIR/frontend"

rollback() {
  echo ""
  echo "❌ Migration fallite — ripristino gli artefatti precedenti e riavvio il servizio."
  install -m 0755 "$ROLLBACK_DIR/vulnerability-manager" "$APP/vulnerability-manager"
  rm -rf "${FRONTEND:?}"/*
  cp -a "$ROLLBACK_DIR/frontend/." "$FRONTEND/"
  rm -rf "${APP:?}/migrations"
  cp -a "$ROLLBACK_DIR/migrations" "$APP/migrations"
  chown -R "$SVC_USER:$SVC_USER" "$APP" "$FRONTEND"
  systemctl start sentinelcore
  rm -rf "$ROLLBACK_DIR"
  echo "Servizio precedente ($CURRENT_VERSION) ripristinato e riavviato."
  echo "Le migration girano in transazione: il DB non dovrebbe aver subito modifiche"
  echo "parziali, ma il backup pre-upgrade resta disponibile per sicurezza:"
  echo "  $DUMP_FILE"
  exit 1
}

# ── 4. Installa i nuovi artefatti ───────────────────────────────────────────
log "4/6 Installazione nuovi artefatti"
install -m 0755 "$PKG_DIR/vulnerability-manager" "$APP/vulnerability-manager"
rm -rf "${FRONTEND:?}"/*
cp -a "$PKG_DIR/frontend/." "$FRONTEND/"
rm -rf "${APP:?}/migrations"
mkdir -p "$APP/migrations"
cp -a "$PKG_DIR/migrations/." "$APP/migrations/"
[ -d "$PKG_DIR/plugins" ] && cp -a "$PKG_DIR/plugins/." "$APP/plugins/" || true
[ -d "$PKG_DIR/avatar-presets" ] && { mkdir -p "$APP/uploads/avatars/presets"; cp -a "$PKG_DIR/avatar-presets/." "$APP/uploads/avatars/presets/"; } || true
# systemd unit / nginx conf possono cambiare fra versioni (timeout, limiti,
# nuove route proxy) — NON toccano production.yaml, segreti o certificati TLS.
if [ -f "$PKG_DIR/templates/sentinelcore.service" ]; then
  install -m 0644 "$PKG_DIR/templates/sentinelcore.service" /etc/systemd/system/sentinelcore.service
  systemctl daemon-reload
fi
# Certificato TLS self-signed: introdotto DOPO la prima ondata di appliance
# (HTTPS di default) — un'istanza aggiornata da una versione precedente non
# ce l'ha ancora. Lo generiamo se manca, cosi' la nginx conf nuova (che lo
# referenzia) trova qualcosa da caricare invece di rifiutare il reload.
TLS_DIR=/etc/ssl/sentinelcore
if [ ! -f "$TLS_DIR/sentinelcore.crt" ] || [ ! -f "$TLS_DIR/sentinelcore.key" ]; then
  log "Certificato TLS self-signed mancante — lo genero"
  SERVER_NAME="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')"
  [ -z "$SERVER_NAME" ] && SERVER_NAME="$(hostname -I | awk '{print $1}')"
  mkdir -p "$TLS_DIR"
  SAN_TYPE="DNS"
  echo "$SERVER_NAME" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' && SAN_TYPE="IP"
  openssl req -x509 -nodes -newkey rsa:2048 -days 825 \
    -keyout "$TLS_DIR/sentinelcore.key" -out "$TLS_DIR/sentinelcore.crt" \
    -subj "/CN=$SERVER_NAME" \
    -addext "subjectAltName=$SAN_TYPE:$SERVER_NAME" >/dev/null 2>&1
  chmod 600 "$TLS_DIR/sentinelcore.key"
  chmod 644 "$TLS_DIR/sentinelcore.crt"
fi
if [ -f "$PKG_DIR/templates/nginx-sentinelcore.conf" ]; then
  install -m 0644 "$PKG_DIR/templates/nginx-sentinelcore.conf" /etc/nginx/sites-available/sentinelcore
  # MAI soffocare l'esito di `nginx -t`: se la nuova conf non e' valida su
  # questo host, nginx resta silenziosamente su quella vecchia — l'operatore
  # deve saperlo, non scoprirlo da solo mesi dopo.
  #
  # NB: NON usare `nginx -t | tee ... | grep ...` — sotto `set -o pipefail`
  # il risultato del pipe puo' riflettere un problema di tee/grep invece
  # del vero esito del test (visto succedere in pratica: nginx -t passava
  # a mano ma la pipe restituiva comunque errore). Cattura output+exit code
  # separatamente, senza far abortire lo script per via di `set -e`.
  set +e
  NGINX_TEST_OUTPUT="$(nginx -t 2>&1)"
  NGINX_TEST_STATUS=$?
  set -e
  echo "$NGINX_TEST_OUTPUT"
  if [ "$NGINX_TEST_STATUS" -eq 0 ]; then
    systemctl reload nginx
  else
    echo ""
    echo "⚠️  nginx -t ha fallito con la config aggiornata — nginx resta sulla"
    echo "    configurazione precedente (il servizio backend è comunque"
    echo "    raggiungibile su 127.0.0.1:8080). Correggi manualmente e poi:"
    echo "      nginx -t && sudo systemctl reload nginx"
  fi
fi
chown -R "$SVC_USER:$SVC_USER" "$APP" "$FRONTEND"

# ── 5. Applica le migration pendenti col NUOVO binario ──────────────────────
log "5/6 Applicazione migration (--migrate)"
# WorkingDirectory=$APP + APP_ENV=production replicano esattamente quello
# che imposta sentinelcore.service: config::load_config() risolve
# "config/production.yaml" in modo relativo alla cwd del processo. Senza
# questi due, il binario non trova production.yaml e ricade sul default di
# sviluppo (DB sbagliato) — la migration fallisce, ma su un URL diverso da
# quello vero.
(cd "$APP" && sudo -u "$SVC_USER" env APP_ENV=production "$APP/vulnerability-manager" --migrate) || rollback
rm -rf "$ROLLBACK_DIR"

# ── 6. Riavvia e verifica ────────────────────────────────────────────────────
log "6/6 Riavvio e verifica"
systemctl start sentinelcore
set +e
for i in $(seq 1 60); do
  [ "$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/api/health 2>/dev/null)" = "200" ] && break
  sleep 1
done
HEALTH="$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/api/health 2>/dev/null)"
set -e

if [ "$HEALTH" = "200" ]; then
  cat <<EOF

────────────────────────────────────────────────────────────────────
 ✅ Aggiornamento completato: $CURRENT_VERSION → $NEW_VERSION
   Backup DB pre-upgrade: $DUMP_FILE
   Servizio: systemctl status sentinelcore
────────────────────────────────────────────────────────────────────
EOF
else
  cat <<EOF

⚠️  Il servizio non risponde correttamente dopo l'aggiornamento (health=$HEALTH).
    Lo schema è già stato aggiornato e NON viene ripristinato automaticamente
    (rollback dello schema è deliberatamente fuori scope, vedi documento di
    design "Upgrade Manager v0" — solo il backup manuale lo copre).
    Controlla i log:  journalctl -u sentinelcore -n 100 --no-pager
    Backup DB pre-upgrade per un ripristino manuale: $DUMP_FILE
EOF
  exit 1
fi
