#!/usr/bin/env bash
# Installa il wrapper privilegiato di scansione e la regola sudoers che
# autorizza SOLO quel wrapper (non piu' /usr/bin/nmap e /usr/sbin/arp-scan).
# Usato da install.sh e upgrade.sh (uguale per installazione nuova e update).
#
# Uso (come root):  install-scan-privileges.sh <utente-servizio> <sentinelcore-scan>
#
# Ordine voluto: 1) valida il sudoers in un file temporaneo, 2) installa il
# wrapper, 3) installa il sudoers. Se il 3) fallisce il wrapper viene tolto:
# senza wrapper il backend ricade su `sudo -n nmap` (regola legacy), mentre
# un wrapper presente ma non autorizzato farebbe fallire ogni scansione.
set -euo pipefail

SVC_USER="${1:?uso: $0 <utente-servizio> <sentinelcore-scan>}"
SRC="${2:?uso: $0 <utente-servizio> <sentinelcore-scan>}"
WRAPPER_DIR="/usr/local/libexec/sentinelcore"
WRAPPER="$WRAPPER_DIR/scan"
SUDOERS_FILE="/etc/sudoers.d/sentinelcore-scan"
LEGACY_SUDOERS="/etc/sudoers.d/sentinelcore-discovery"

[ "$(id -u)" -eq 0 ] || { echo "Esegui come root" >&2; exit 1; }
[ -f "$SRC" ] || { echo "ERRORE: wrapper sorgente non trovato: $SRC" >&2; exit 1; }
sh -n "$SRC" || { echo "ERRORE: $SRC ha errori di sintassi" >&2; exit 1; }

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
printf '%s ALL=(root) NOPASSWD: %s\n' "$SVC_USER" "$WRAPPER" > "$TMP"
visudo -cf "$TMP" >/dev/null || { echo "ERRORE: sudoers generato non valido" >&2; exit 1; }

install -d -o root -g root -m 0755 "$WRAPPER_DIR"
install -o root -g root -m 0755 "$SRC" "$WRAPPER"
if ! install -o root -g root -m 0440 "$TMP" "$SUDOERS_FILE"; then
  rm -f "$WRAPPER"
  echo "ERRORE: installazione del sudoers fallita, wrapper rimosso" >&2
  exit 1
fi

# Un sudoers manuale (vecchia INSTALL.md) con la regola larga su nmap/arp-scan
# resterebbe attivo accanto alla nuova e vanificherebbe il wrapper: lo segnaliamo,
# non lo cancelliamo di nascosto.
if [ -f "$LEGACY_SUDOERS" ] && grep -qE 'NOPASSWD:.*(/nmap|/arp-scan)' "$LEGACY_SUDOERS"; then
  echo "⚠️  $LEGACY_SUDOERS autorizza ancora nmap/arp-scan direttamente:" >&2
  echo "    rimuovilo per rendere effettivo il wrapper:  sudo rm $LEGACY_SUDOERS" >&2
fi
echo "Wrapper di scansione installato: $WRAPPER"
