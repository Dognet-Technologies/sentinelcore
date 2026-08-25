#!/usr/bin/env bash
#
# Rigenera il PDF del Manuale Utente da questi capitoli Markdown.
#
# Richiede: pandoc, chromium (o google-chrome/chromium-browser).
#   sudo apt-get install -y pandoc
#
# Uso:  ./build-pdf.sh [versione]
#       (versione default = "dev")
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

VERSION="${1:-dev}"
OUT_DIR="$DIR/../../dist"
OUT_HTML="$(mktemp --suffix=.html)"
OUT_PDF="$OUT_DIR/SentinelCore-Manuale-Utente-${VERSION}.pdf"

mkdir -p "$OUT_DIR"

CHAPTERS=(
  00-introduzione.md
  01-installazione.md
  02-primo-accesso.md
  03-ruoli-e-permessi.md
  04-configurazione.md
  05-team-e-utenti.md
  06-vulnerabilita-e-rischio.md
  07-rete-e-asset.md
  08-scanner-e-integrazioni.md
  09-report-e-remediation.md
  10-domande-frequenti.md
)

echo "▶ pandoc: capitoli → HTML"
pandoc "${CHAPTERS[@]}" \
  --standalone --embed-resources --css=_manual.css \
  --toc --toc-depth=2 \
  --include-before-body=_cover.html \
  --metadata title="SentinelCore — Manuale Utente" \
  --metadata toc-title="Indice" \
  -o "$OUT_HTML"

CHROME_BIN="$(command -v chromium || command -v chromium-browser || command -v google-chrome || command -v google-chrome-stable || true)"
[ -n "$CHROME_BIN" ] || { echo "ERRORE: nessun binario Chromium/Chrome trovato per il rendering PDF."; exit 1; }

echo "▶ $CHROME_BIN: HTML → PDF"
"$CHROME_BIN" --headless --no-sandbox --disable-gpu \
  --print-to-pdf="$OUT_PDF" --no-pdf-header-footer \
  "file://$OUT_HTML"

rm -f "$OUT_HTML"
echo "▶ Fatto: $OUT_PDF"
