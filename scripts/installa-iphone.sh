#!/bin/bash
# Installa Dieta e Palestra sull'iPhone collegato al Mac, firmate con il tuo Apple ID gratuito.
# Uso (nel Terminale del Mac, con l'iPhone collegato via cavo e sbloccato):
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/aspirinag/dieta/main/scripts/installa-iphone.sh)"
# Con l'Apple ID gratuito le app durano 7 giorni: per rinnovarle basta rilanciare lo stesso comando.
# Per installarne una sola aggiungi in fondo: _ dieta   (oppure _ palestra)
set -euo pipefail

errore() { echo; echo "❌ $*"; exit 1; }
passo() { echo; echo "▶ $*"; }

# ---------- Xcode ----------
passo "Controllo Xcode"
[ -d /Applications/Xcode.app ] || errore "Xcode non è installato: scaricalo dall'App Store (serve Xcode 26), aprilo una volta e rilancia questo comando."
if ! xcode-select -p 2>/dev/null | grep -q "Xcode.app"; then
  echo "Imposto Xcode come strumento predefinito (ti chiede la password del Mac)"
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
fi
xcodebuild -version | head -1
xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1 || {
  echo "Completo la prima configurazione di Xcode (ti chiede la password del Mac)"
  sudo xcodebuild -runFirstLaunch
}
VERSIONE=$(xcodebuild -version | head -1 | grep -oE '[0-9]+' | head -1)
[ "$VERSIONE" -ge 26 ] || errore "Serve Xcode 26 o successivo (hai Xcode $VERSIONE): aggiornalo dall'App Store."

# ---------- Apple ID (team) ----------
passo "Cerco il tuo Apple ID in Xcode"
TEAM=${TEAM:-$( { defaults read com.apple.dt.Xcode IDEProvisioningTeamByIdentifier 2>/dev/null; defaults read com.apple.dt.Xcode IDEProvisioningTeams 2>/dev/null; } \
  | grep -m1 -oE 'teamID = "?[A-Z0-9]{10}' | grep -oE '[A-Z0-9]{10}$' || true)}
if [ -z "$TEAM" ]; then
  open -a Xcode
  errore "In Xcode non c'è nessun Apple ID. Si è aperto Xcode: vai in Xcode → Settings… → Accounts → + → Apple Account, accedi, poi rilancia questo comando."
fi
echo "Team: $TEAM"

# ---------- iPhone ----------
passo "Cerco l'iPhone collegato"
JSON=$(mktemp)
xcrun devicectl list devices --json-output "$JSON" >/dev/null 2>&1 || true
UDID=$(python3 - "$JSON" <<'PY'
import json, sys
try:
    devices = json.load(open(sys.argv[1]))["result"]["devices"]
except Exception:
    devices = []
for d in devices:
    hw = d.get("hardwareProperties", {})
    if hw.get("platform") == "iOS" and hw.get("udid") and d.get("connectionProperties", {}).get("pairingState") == "paired":
        print(hw["udid"]); break
PY
)
rm -f "$JSON"
[ -n "$UDID" ] || errore "Non trovo l'iPhone. Collegalo con il cavo, sbloccalo, tocca 'Autorizza' se te lo chiede e rilancia. Se non basta: Impostazioni → Privacy e sicurezza → Modalità sviluppatore → attiva."
echo "iPhone: $UDID"

# ---------- Compila e installa ----------
LAVORO="$HOME/Library/Caches/app-iphone-aspirinag"
mkdir -p "$LAVORO"
APP_SCELTE=${1:-"dieta palestra"}

for app in $APP_SCELTE; do
  case "$app" in
    dieta) REPO=dieta; NOME=Dieta ;;
    palestra) REPO=Palestra; NOME=Palestra ;;
    *) errore "App sconosciuta: $app (usa dieta o palestra)" ;;
  esac

  passo "$NOME: scarico l'ultima versione"
  rm -rf "$LAVORO/$REPO"
  mkdir -p "$LAVORO/$REPO"
  curl -fsSL "https://github.com/aspirinag/$REPO/archive/refs/heads/main.tar.gz" | tar xz -C "$LAVORO/$REPO" --strip-components 1

  passo "$NOME: compilo e firmo (la prima volta ci vuole qualche minuto)"
  # Identificativo con il tuo team: con l'Apple ID gratuito deve essere unico
  xcodebuild -project "$LAVORO/$REPO/iOS/$NOME.xcodeproj" -scheme "$NOME" -configuration Release \
    -destination "id=$UDID" -derivedDataPath "$LAVORO/$REPO/build" -allowProvisioningUpdates \
    DEVELOPMENT_TEAM="$TEAM" CODE_SIGN_STYLE=Automatic \
    PRODUCT_BUNDLE_IDENTIFIER="io.github.aspirinag.$app.$(echo "$TEAM" | tr 'A-Z' 'a-z')" \
    -quiet build \
    || errore "$NOME: la compilazione non è riuscita. Copia le righe rosse qui sopra e mandamele."

  passo "$NOME: installo sull'iPhone"
  xcrun devicectl device install app --device "$UDID" "$LAVORO/$REPO/build/Build/Products/Release-iphoneos/$NOME.app" \
    || errore "$NOME: installazione non riuscita. Tieni l'iPhone sbloccato e rilancia."
  echo "✅ $NOME installata"
done

echo
echo "Fatto! Se è la prima volta, sull'iPhone vai in Impostazioni → Generali → VPN e gestione dispositivi,"
echo "tocca il tuo Apple ID e scegli 'Autorizza': poi le app si aprono."
echo "Tra 7 giorni rilancia lo stesso comando per rinnovarle (i dati restano)."
