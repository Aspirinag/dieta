# inForma — istruzioni per Claude Code

App iOS in SwiftUI (dieta + palestra). Il [README](README.md) descrive app, struttura e passi di lavoro; [AGENTS.md](AGENTS.md) raccoglie le regole valide per tutti gli agenti.

## Regole tecniche
- Testi dell'app, commit, PR e risposte in **italiano**, semplice e senza gergo.
- Mai lavorare su `main`: un branch per argomento, poi PR. Unire in `main` solo su richiesta.
- Novità: spec in `docs/superpowers/specs/`, piano in `docs/superpowers/plans/`, poi esecuzione con test prima del codice.
- Il JSON della dieta (`dieta.json`) deve restare compatibile con la web app (`index.html`): niente rinomine di campi.
- I modelli `Codable` si decodificano in modo tollerante (`c.valore(chiave, predefinito)`): un campo nuovo ha sempre un valore predefinito.
- Il target dell'app usa `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. I gruppi sono sincronizzati con il file system: un file nuovo non richiede modifiche al `.pbxproj`.

## Comandi
- **Test completi (unità + UI):** `cd iOS && xcodebuild test -project Forma.xcodeproj -scheme Forma -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -quiet`
- **Solo test di unità:** aggiungere `-only-testing:FormaTests`
- **Dati di prova:** argomenti di avvio `-demo -tab oggi|dieta|allenamento|progressi|inCorso|impostazioni`, `-vista spesa` (con `-tab dieta`). Inglese: `-AppleLanguages "(en)" -AppleLocale en_US`.
- **Schermate:** subagent `ui-checker` o `scripts/schermate.sh` dopo ogni modifica alle viste.
- **iPhone:** `bash scripts/installa-iphone.sh` (iPhone collegato e **sbloccato**; con l'Apple ID gratuito l'app dura 7 giorni).
