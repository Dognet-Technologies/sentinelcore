#!/usr/bin/env bash
#
# Costruisce il pacchetto BINARIO di release: compila backend + frontend e
# assembla un tarball auto-installante (binario + frontend + migration + config
# template + install.sh). Da eseguire su un build host con la toolchain
# (cargo, node 20) — NON serve sul target.
#
# Uso:  packaging/build-release.sh [versione]
#       (versione default = git describe, es. v1.0.1-beta)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

VERSION="${1:-$(git describe --tags --always 2>/dev/null || echo v0.0.0)}"
ARCH="linux-x86_64"
NAME="sentinelcore-${VERSION}-${ARCH}"
OUT="$REPO_ROOT/dist"
STAGE="$OUT/$NAME"

echo "▶ Release: $NAME"
rm -rf "$STAGE"; mkdir -p "$STAGE"

# ── build backend (offline sqlx) ────────────────────────────────────────────
echo "▶ Build backend (cargo --release)"
( cd vulnerability-manager && SQLX_OFFLINE=true cargo build --release )
install -m 0755 vulnerability-manager/target/release/vulnerability-manager "$STAGE/vulnerability-manager"

# ── build frontend ──────────────────────────────────────────────────────────
echo "▶ Build frontend (npm run build)"
( cd vulnerability-manager-frontend && npm ci --no-audit --no-fund && CI=false GENERATE_SOURCEMAP=false npm run build )
mkdir -p "$STAGE/frontend"; cp -a vulnerability-manager-frontend/build/. "$STAGE/frontend/"

# ── artefatti di supporto ───────────────────────────────────────────────────
echo "▶ Assemblaggio artefatti"
mkdir -p "$STAGE/migrations"; cp -a vulnerability-manager/migrations/*.sql "$STAGE/migrations/"
[ -d vulnerability-manager/plugins ] && { mkdir -p "$STAGE/plugins"; cp -a vulnerability-manager/plugins/. "$STAGE/plugins/"; } || true
# Avatar predefiniti (2 per ruolo, Profilo → scegli avatar) — asset statici
# nostri, non dati utente, quindi viaggiano nel pacchetto come
# migrations/plugins invece che nella uploads/ dell'installazione target.
[ -d vulnerability-manager/uploads/avatars/presets ] && { mkdir -p "$STAGE/avatar-presets"; cp -a vulnerability-manager/uploads/avatars/presets/. "$STAGE/avatar-presets/"; } || true
cp -a packaging/templates "$STAGE/templates"
install -m 0755 packaging/install.sh "$STAGE/install.sh"
install -m 0755 packaging/upgrade.sh "$STAGE/upgrade.sh"
[ -f INSTALL.md ] && cp INSTALL.md "$STAGE/INSTALL.md" || true
echo "$VERSION" > "$STAGE/VERSION"

# ── tarball + checksum + firma GPG ──────────────────────────────────────────
echo "▶ Tarball + checksum + firma"
( cd "$OUT" && tar czf "$NAME.tar.gz" "$NAME" )
( cd "$OUT" && sha256sum "$NAME.tar.gz" > "$NAME.tar.gz.sha256" )
# Firma GPG (richiede la chiave sul build host). Non-fatale se assente, salvo
# REQUIRE_SIGNATURE=1 (usato dalla CI: una release non firmata deve fallire).
# Se GPG_PASSPHRASE e' impostata la firma e' non interattiva (CI).
# (valutazione in $(...) e non `| grep -q`: con pipefail grep che esce subito puo' dare SIGPIPE a gpg)
if [ -n "$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '$1=="sec"{print "y"}')" ]; then
  GPG_ARGS=(--armor --detach-sign)
  [ -n "${GPG_PASSPHRASE:-}" ] && GPG_ARGS+=(--batch --yes --pinentry-mode loopback --passphrase-fd 3)
  ( cd "$OUT" && gpg "${GPG_ARGS[@]}" --output "$NAME.tar.gz.asc" "$NAME.tar.gz" 3<<<"${GPG_PASSPHRASE:-}" ) \
    && echo "  firma: $NAME.tar.gz.asc"
elif [ "${REQUIRE_SIGNATURE:-0}" = "1" ]; then
  echo "ERRORE: REQUIRE_SIGNATURE=1 ma nessuna chiave GPG disponibile" >&2
  exit 1
else
  echo "  (nessuna chiave GPG sul build host: firma saltata)"
fi

rm -rf "$STAGE"
echo "▶ Fatto:"
ls -lh "$OUT/$NAME".tar.gz* | sed 's#.*/##'
echo "Artefatti in: $OUT/"
