#!/usr/bin/env bash
#
# Impacchetta il tarball di release in un .deb per Debian 13 (amd64).
#
# Uso: packaging/deb/build-deb.sh <tag-tarball> <versione-deb>
#      packaging/deb/build-deb.sh v2.0.1-pre.12 2.0.1~pre.12
#
# Il tarball dist/sentinelcore-<tag>-linux-x86_64.tar.gz deve esistere
# (packaging/build-release.sh). Installazione: apt install ./sentinelcore_*.deb
set -euo pipefail

TAG="${1:?uso: build-deb.sh <tag-tarball> <versione-deb>}"
DEB_VERSION="${2:?uso: build-deb.sh <tag-tarball> <versione-deb>}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEB_DIR="$REPO_ROOT/packaging/deb"
OUT="$REPO_ROOT/dist"
TARBALL="$OUT/sentinelcore-${TAG}-linux-x86_64.tar.gz"
[ -f "$TARBALL" ] || { echo "ERRORE: tarball non trovato: $TARBALL" >&2; exit 1; }

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

mkdir -p "$STAGE/DEBIAN" "$STAGE/usr/share/sentinelcore/release"
tar xzf "$TARBALL" -C "$STAGE/usr/share/sentinelcore/release" --strip-components=1

# SC_DEB_CONTROL: control alternativo per le build con estensioni (es. il
# pacchetto sentinelcore-pro). Stessi script e stesso payload del Community.
CONTROL_IN="${SC_DEB_CONTROL:-$DEB_DIR/control.in}"
[ -f "$CONTROL_IN" ] || { echo "ERRORE: control non trovato: $CONTROL_IN" >&2; exit 1; }
sed "s/__VERSION__/${DEB_VERSION}/" "$CONTROL_IN" > "$STAGE/DEBIAN/control"
install -m 0755 "$DEB_DIR/postinst" "$DEB_DIR/prerm" "$STAGE/DEBIAN/"

PACKAGE="$(sed -n 's/^Package: *//p' "$STAGE/DEBIAN/control")"
DEB_FILE="$OUT/${PACKAGE}_${DEB_VERSION}_amd64.deb"
dpkg-deb --root-owner-group --build "$STAGE" "$DEB_FILE"
echo "Pacchetto: $DEB_FILE"
