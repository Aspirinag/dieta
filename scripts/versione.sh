#!/bin/bash
# Mostra o cambia il numero di versione dell'app, che sta solo in MARKETING_VERSION.
# Uso: bash scripts/versione.sh           mostra la versione
#      bash scripts/versione.sh 2.3.0     la cambia in tutto il progetto
#      bash scripts/versione.sh --note    stampa le voci del changelog per la versione attuale
set -euo pipefail

CARTELLA=$(cd "$(dirname "$0")/.." && pwd)
PROGETTO="$CARTELLA/iOS/Dieta.xcodeproj/project.pbxproj"
attuale() { grep -m1 'MARKETING_VERSION' "$PROGETTO" | sed -E 's/.*= (.*);/\1/'; }

case "${1:-}" in
  "") attuale ;;
  --note)
    awk -v v="$(attuale)" '
      $0 ~ "^##+ " v "$" { dentro = 1; next }
      dentro && /^##/ { exit }
      dentro && NF { print }
    ' "$CARTELLA/CHANGELOG.md"
    ;;
  *)
    [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Versione non valida: $1 (esempio: 2.3.0)"; exit 1; }
    sed -i '' -E "s/(MARKETING_VERSION = ).*;/\1$1;/" "$PROGETTO"
    attuale
    ;;
esac
