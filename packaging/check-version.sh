#!/usr/bin/env bash
#
# Gate della release: il tag git deve coincidere con la versione dichiarata nel
# codice. Il binario stampa CARGO_PKG_VERSION (usata da upgrade.sh per
# confrontare installato vs nuovo), quindi un tag che diverge produrrebbe un
# pacchetto che si presenta con un'altra versione.
#
# Uso:  packaging/check-version.sh vX.Y.Z[-suffisso]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG="${1:?uso: check-version.sh <tag>}"

# SemVer con suffisso opzionale: v1.2.0, v1.2.1-rc.0, v1.0.1-beta
if [[ ! "$TAG" =~ ^v([0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?)$ ]]; then
  echo "ERRORE: tag '$TAG' non e' nel formato vX.Y.Z[-suffisso]" >&2
  exit 1
fi
EXPECTED="${BASH_REMATCH[1]}"

CARGO="$(sed -n 's/^version = "\(.*\)"/\1/p' "$REPO_ROOT/vulnerability-manager/Cargo.toml" | head -1)"
PKG="$(sed -n 's/^  "version": "\(.*\)",/\1/p' "$REPO_ROOT/vulnerability-manager-frontend/package.json" | head -1)"
LOCK="$(awk '/^name = "vulnerability-manager"$/ {getline; sub(/^version = "/, ""); sub(/"$/, ""); print; exit}' \
  "$REPO_ROOT/vulnerability-manager/Cargo.lock")"

fail=0
check() {
  local label="$1" value="$2"
  if [ "$value" = "$EXPECTED" ]; then
    printf '  ok   %-28s %s\n' "$label" "$value"
  else
    printf '  FAIL %-28s %s (atteso %s)\n' "$label" "${value:-<vuoto>}" "$EXPECTED" >&2
    fail=1
  fi
}

echo "Tag: $TAG  ->  versione attesa: $EXPECTED"
check "vulnerability-manager/Cargo.toml" "$CARGO"
check "vulnerability-manager/Cargo.lock" "$LOCK"
check "frontend/package.json"           "$PKG"

if [ "$fail" -ne 0 ]; then
  echo "ERRORE: versioni nel codice non allineate al tag." >&2
  exit 1
fi
echo "Versioni coerenti."
