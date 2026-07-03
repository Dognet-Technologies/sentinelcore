#!/usr/bin/env bash
#
# Eseguito DENTRO la VM di build da cloud-init.
# Scarica il tarball binario da build host (via QEMU NAT 10.0.2.2), esegue
# install.sh, poi installa il servizio di first-boot per i cloni futuri.
#
# Variabili richieste (passate dall'environment o da /tmp/build-env.sh):
#   TARBALL_NAME  — es. sentinelcore-v1.0.1-beta-linux-x86_64.tar.gz
#   HTTP_BASE     — es. http://10.0.2.2:18080
set -euo pipefail

LOG=/var/log/sentinelcore-provision.log
exec > >(tee -a "$LOG") 2>&1
echo "[provision] $(date '+%Y-%m-%d %H:%M:%S') avvio"

: "${TARBALL_NAME:?TARBALL_NAME non impostato}"
: "${HTTP_BASE:?HTTP_BASE non impostato}"

INSTALL_DIR="/tmp/${TARBALL_NAME%.tar.gz}"

# ── 1. Scarica il pacchetto binario ─────────────────────────────────────────
echo "[provision] Download: $HTTP_BASE/dist/$TARBALL_NAME"
wget -q --tries=5 --timeout=120 \
    "$HTTP_BASE/dist/$TARBALL_NAME" -O "/tmp/$TARBALL_NAME"

echo "[provision] Estrazione..."
tar xzf "/tmp/$TARBALL_NAME" -C /tmp

# ── 2. Installa SentinelCore (no-toolchain) ──────────────────────────────────
echo "[provision] Esecuzione install.sh..."
chmod +x "$INSTALL_DIR/install.sh"
"$INSTALL_DIR/install.sh"

# ── 3. Installa il first-boot service ───────────────────────────────────────
echo "[provision] Installazione sentinelcore-first-boot..."

wget -q "$HTTP_BASE/packaging/appliance/first-boot.sh" \
    -O /opt/sentinelsuite/sentinelcore/app/first-boot.sh
chmod 755 /opt/sentinelsuite/sentinelcore/app/first-boot.sh
chown sentinelcore:sentinelcore /opt/sentinelsuite/sentinelcore/app/first-boot.sh

wget -q "$HTTP_BASE/packaging/appliance/sentinelcore-first-boot.service" \
    -O /etc/systemd/system/sentinelcore-first-boot.service
systemctl daemon-reload
systemctl enable sentinelcore-first-boot.service

# ── 4. Ferma sentinelcore prima di esportare (snapshot pulito) ───────────────
echo "[provision] Stop servizi prima dell'export..."
systemctl stop sentinelcore 2>/dev/null || true
systemctl stop postgresql 2>/dev/null || true

# ── 5. Pulizia pre-export: generics per ogni clone ───────────────────────────
echo "[provision] Pulizia per export..."
# Machine-id vuoto → rigenerato per ogni clone da systemd
truncate -s 0 /etc/machine-id

# SSH host keys → rimosse, first-boot le rigenera
rm -f /etc/ssh/ssh_host_*_key /etc/ssh/ssh_host_*_key.pub

# Temp e artefatti di build
rm -rf "/tmp/$TARBALL_NAME" "$INSTALL_DIR"
apt-get clean -qq 2>/dev/null || true

# Reset cloud-init (non rieseguire al prossimo avvio)
cloud-init clean --logs 2>/dev/null || true

echo "[provision] $(date '+%Y-%m-%d %H:%M:%S') completato — poweroff"
sync
poweroff -f
