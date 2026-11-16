# inForma — istruzioni per agenti

Leggi prima [README.md](README.md) (cos'è l'app, struttura e flusso di lavoro) e [CLAUDE.md](CLAUDE.md) (regole e comandi SwiftUI): valgono per qualsiasi agente (Antigravity, Claude Code, modelli locali).

## Regole di lavoro
- Rispondi e scrivi commit e PR in **italiano** semplice, senza gergo.
- **Mai lavorare direttamente su `main`** (è protetto: si entra solo con una PR). Prima di modificare: `git switch -c <argomento>`.
- Fai modifiche piccole e mirate per volta. Non riscrivere file interi e non rinominare chiavi del JSON della dieta (`dieta.json`).
- Non toccare `.github/`, `iOS/Forma.xcodeproj/project.pbxproj` (i gruppi sono sincronizzati con il file system) e la storia git (niente force-push, niente `git stash`).
- Non scrivere mai email, nomi reali o dati di salute in file, commit o PR.

## Sistema visivo e accessibilità
- Tutti i colori stanno in `iOS/Condiviso/Colori.swift` (mai colori scritti a mano nelle viste):
  - **Verde salvia (`Colori.accento`):** azione principale, stato «fatto», spunte, giorno scelto e grafici Dieta/Corpo.
  - **Terracotta calda (`Colori.terracotta`):** sezione Palestra, grafici allenamento, trofei, icone delle righe, azioni secondarie.
  - **Olio / Acqua / Oltre:** solo per cucchiaini, gocce ed eccessi (`+N`).
- Solo stili di testo dinamici (`.numero(_:)` o stili di sistema) e bersagli toccabili di almeno `44 × 44 pt` (`Misure.tocco`).
- Unico formato data in tutta l'app: `Testi.data(...)` e `Testi.periodo(...)`.
- Ogni modifica ai colori va verificata in chiaro, scuro e *Aumenta contrasto* tramite `SistemaVisivoTests`.

## Comandi principali
- **Test di unità:**
  ```bash
  cd iOS && xcodebuild test -project Forma.xcodeproj -scheme Forma \
    -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -only-testing:FormaTests -quiet
  ```
- **Schermate nel simulatore (chiaro e scuro, in italiano di base):**
  ```bash
  bash scripts/schermate.sh <App.app> io.github.aspirinag.forma "oggi dieta dieta:spesa allenamento progressi inCorso impostazioni"
  ```
- **Web app (`index.html`):**
  ```bash
  node scripts/controlla-lettore.mjs && node scripts/prova-dati-web.mjs
  ```
- **Installazione su iPhone collegato e sbloccato:**
  ```bash
  bash scripts/installa-iphone.sh
  ```

## Chiusura
- Lancia i test pertinenti dopo ogni modifica; se falliscono, sistemali o annulla la modifica.
- Alla fine: `git push -u origin <branch>` e `gh pr create`. Unisci in `main` solo su richiesta esplicita dell'utente.
