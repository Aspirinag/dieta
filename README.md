# Forma

Dieta e palestra in un'unica app per iPhone, in SwiftUI. I dati restano sul telefono: niente account, niente server.

- **Dieta:** piani alimentari letti dal PDF del nutrizionista o scritti a mano, pasti del giorno da spuntare, lista della spesa, andamento della BIA.
- **Palestra:** schede A/B, allenamento in corso con recupero, storico e record, avviso del pagamento, allenamenti dall'Apple Watch tramite Salute.
- **Promemoria:** mattino, pasti, acqua e pagamento, agli orari che scegli.

Serve iOS 18 o successivo (su iOS 26 con l'aspetto Liquid Glass). La web app (`index.html`, su GitHub Pages) è la versione per browser della parte dieta. I dati passano da una all'altra con **Esporta backup** / **Importa backup**: il file è lo stesso.

## Installare sull'iPhone

Con l'iPhone collegato via cavo e sbloccato, nel Terminale del Mac:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/aspirinag/dieta/main/scripts/installa-iphone.sh)"
```

Lo script scarica `main`, compila e firma con il tuo Apple ID gratuito (serve Xcode 26). Con l'Apple ID gratuito l'app dura 7 giorni: per rinnovarla rilancia lo stesso comando, i dati restano.
La prima volta, sull'iPhone: *Impostazioni → Generali → VPN e gestione dispositivi → il tuo Apple ID → Autorizza*.

Da Xcode: apri `iOS/Forma.xcodeproj`, in *Signing & Capabilities* scegli il tuo team, seleziona l'iPhone e premi **▶︎**.

## Struttura

| Percorso | Contenuto |
|---|---|
| `iOS/Forma/` | App: `Dieta/`, `Palestra/`, `Comune/`, risorse (lettore PDF con pdf.js) |
| `iOS/FormaTests/` | Test di unità (Swift Testing) |
| `iOS/FormaUITests/` | Test dell'interfaccia (XCTest) |
| `index.html`, `vendor/` | Web app |
| `scripts/` | Installazione sull'iPhone, schermate nel simulatore |
| `docs/superpowers/` | Progetti (`specs/`) e piani di lavoro (`plans/`) |
| `.claude/agents/` | Subagent di Claude Code (es. `ui-checker`) |

La vecchia app separata «Dieta» è stata ritirata: l'ultima versione è nel tag `dieta-finale`, i branch non uniti nei tag `archivio/*`.

## Come si lavora

Ogni modifica segue gli stessi passi:

1. **Progetto** — per le novità, una descrizione in `docs/superpowers/specs/AAAA-MM-GG-nome-design.md`, approvata prima di scrivere codice.
2. **Piano** — i passi concreti in `docs/superpowers/plans/AAAA-MM-GG-nome.md`, ognuno con il suo test.
3. **Branch** — mai su `main`: un branch per argomento (es. `forma-promemoria-icona`).
4. **Test prima del codice** — il test che fallisce, poi la correzione che lo fa passare.
5. **Revisione** — revisione del codice dell'intero branch; `ui-checker` per le schermate dopo modifiche all'interfaccia.
6. **Pull request** — GitHub Actions compila, esegue i test e salva le schermate nel branch `schermate-forma`.
7. **Unione in `main`** — solo con i controlli verdi; su `main` la CI pubblica la `.ipa` nelle Releases.

### Test in locale

```bash
cd iOS
xcodebuild test -project Forma.xcodeproj -scheme Forma \
  -destination 'platform=iOS Simulator,name=iPhone 17' -quiet
```

Per vedere l'app con i dati di prova, avvia con l'argomento `-demo` (eventualmente `-tab oggi|dieta|allenamento|profilo|inCorso`).
