# Forma — istruzioni per Claude Code

App iOS in SwiftUI (dieta + palestra). Il README descrive app, struttura e passi di lavoro: questo file aggiunge solo ciò che serve a Claude.

## Regole
- Testi dell'app, commit, PR e risposte in **italiano**, semplice e senza gergo.
- Mai lavorare su `main`: un branch per argomento, poi PR. Unire in `main` solo su richiesta.
- Novità: spec in `docs/superpowers/specs/`, piano in `docs/superpowers/plans/`, poi esecuzione con test prima del codice.
- Il JSON della dieta (`dieta.json`) deve restare compatibile con la web app (`index.html`): niente rinomine di campi.
- I modelli `Codable` si decodificano in modo tollerante (`c.valore(chiave, predefinito)`): un campo nuovo ha sempre un valore predefinito.
- Il target dell'app usa `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. I gruppi sono sincronizzati con il file system: un file nuovo non richiede modifiche al `.pbxproj`.

## Comandi
- Test: `cd iOS && xcodebuild test -project Forma.xcodeproj -scheme Forma -destination 'platform=iOS Simulator,name=iPhone 17' -quiet` (output lungo in un file, leggere la coda).
- Dati di prova: argomenti di avvio `-demo -tab oggi|dieta|allenamento|profilo|inCorso`, `-vista spesa`.
- Schermate: subagent `ui-checker` dopo ogni modifica alle viste.
- iPhone: `bash scripts/installa-iphone.sh` (iPhone collegato e **sbloccato**; con l'Apple ID gratuito l'app dura 7 giorni).

## Modello
Usa la skill `scegli-modello` prima di avviare subagent o lavori lunghi: il modello più capace solo dove serve.
