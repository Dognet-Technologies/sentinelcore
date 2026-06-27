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
cp -a packaging/templates "$STAGE/templates"
install -m 0755 packaging/install.sh "$STAGE/install.sh"
[ -f INSTALL.md ] && cp INSTALL.md "$STAGE/INSTALL.md" || true
echo "$VERSION" > "$STAGE/VERSION"

# ── tarball + checksum + firma GPG ──────────────────────────────────────────
echo "▶ Tarball + checksum + firma"
( cd "$OUT" && tar czf "$NAME.tar.gz" "$NAME" )
( cd "$OUT" && sha256sum "$NAME.tar.gz" > "$NAME.tar.gz.sha256" )
# Firma GPG (richiede la chiave sul build host). Non-fatale se assente.
if gpg --list-secret-keys >/dev/null 2>&1; then
  ( cd "$OUT" && gpg --armor --detach-sign --output "$NAME.tar.gz.asc" "$NAME.tar.gz" ) \
    && echo "  firma: $NAME.tar.gz.asc"
else
  echo "  (nessuna chiave GPG sul build host: firma saltata)"
fi

rm -rf "$STAGE"
echo "▶ Fatto:"
ls -lh "$OUT/$NAME".tar.gz* | sed 's#.*/##'
echo "Artefatti in: $OUT/"
