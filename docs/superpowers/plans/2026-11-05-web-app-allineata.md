# Web app allineata a Forma — piano

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** la dieta della web app (`index.html`) legge i PDF, si vede e parla come Forma, senza perdere i dati di chi la usa.

**Architecture:** un unico `index.html` con `vendor/`. Il codice di lettura dei PDF è un blocco tra marcatori, identico in `index.html` e `iOS/Forma/Risorse/lettore.html`; uno script Node lo controlla in CI. L'aspetto passa dal tema attuale a quello di Forma con variabili CSS chiaro/scuro.

**Tech Stack:** HTML, CSS, JavaScript senza build; pdf.js in `vendor/`; Node 20 per i controlli; GitHub Actions su Ubuntu.

**Spec:** `docs/superpowers/specs/2026-11-05-web-app-allineata-design.md`

## Global Constraints

- Chiave `localStorage` invariata: `dieta:v1`; nessun campo rinominato, i campi sconosciuti (da Forma) si conservano.
- Indirizzo invariato (`https://aspirinag.github.io/dieta/`), nessun service worker, stessi nomi in `vendor/` e per `apple-touch-icon.png`; un file in `vendor/` che cambia prende `?v=N`.
- Meta `apple-mobile-web-app-*` e `viewport-fit=cover` restano; aree sicure rispettate; tocchi ≥ 44 px.
- Accento di Forma: chiaro `#2F6B4F`, scuro `#7FB89A`; sfondi stile iOS a gruppi (chiaro `#F2F2F7` con riquadri `#FFFFFF`, scuro `#000000` con riquadri `#1C1C1E`).
- Testi in italiano, con le parole di Forma (`docs/revisione-testi.md`, `iOS/Forma/Localizable.xcstrings`).
- Nessuna libreria da internet.

## Review Focus

1. Dati già salvati con il vecchio `index.html` (profili `raffaele`/`alessandra`, spunte, BIA): dopo l'aggiornamento tutto ricompare uguale.
2. Backup di Forma importato nella web app e riesportato: nessun campo perso (`spesa_prossima`, `promemoria` con orari, profili con chiavi diverse da quelle predefinite).
3. Tema scuro di iOS: testi e cerchi di spunta leggibili, niente sfondi chiari rimasti.
4. Piano con un pasto a più alternative: tutte visibili, l'alternativa scelta resta scelta dopo un ricaricamento.
5. Pagina aperta dalla schermata Home con la barra di stato trasparente: niente contenuto sotto la tacca o sotto la barra delle schede.

---

### Task 1: Codice di lettura condiviso e controllo in CI

**Files:**
- Modify: `index.html` (blocco da `const GIORNI` a `leggiBiaPdf` incluso)
- Modify: `iOS/Forma/Risorse/lettore.html` (stesso blocco)
- Create: `scripts/controlla-lettore.mjs`
- Create: `.github/workflows/web.yml`

**Interfaces:**
- Produces: marcatori `// --- lettore: inizio ---` e `// --- lettore: fine ---` in entrambi i file; `node scripts/controlla-lettore.mjs` esce con 0 se i blocchi sono uguali riga per riga (spazi a inizio/fine riga ignorati, righe vuote ignorate), altrimenti 1 con la prima riga diversa.

- [ ] **Step 1:** scrivi `scripts/controlla-lettore.mjs` e aggiungi i marcatori ai due file **senza** ancora copiare il codice nuovo in `index.html`.
- [ ] **Step 2:** `node scripts/controlla-lettore.mjs` — Expected: exit 1, segnala la differenza su `PASTI`.
- [ ] **Step 3:** copia in `index.html` il blocco di `lettore.html` (PASTI senza maiuscole con `ePasto`, soglia al 40% della pagina). Adatta nel resto di `index.html` gli usi di `PASTI.includes` se ce ne sono.
- [ ] **Step 4:** `node scripts/controlla-lettore.mjs` — Expected: exit 0.
- [ ] **Step 5:** prova locale con il PDF dell'utente (fuori dal repo): estrai il blocco da ciascun file, eseguilo con `vendor/pdf.min.js` in Node su `/Users/rl/Downloads/Schema Dietetico Liguori Raffaele.pdf` — Expected: stesso JSON, 7 giorni × 4 pasti.
- [ ] **Step 6:** `.github/workflows/web.yml`: su `push`/`pull_request` con `paths: [index.html, iOS/Forma/Risorse/lettore.html, scripts/controlla-lettore.mjs, .github/workflows/web.yml]`, job `ubuntu-latest`, `actions/setup-node` 20, `node scripts/controlla-lettore.mjs`.
- [ ] **Step 7:** commit «Web app: stesso lettore dei PDF di Forma, controllo in CI».

### Task 2: Aspetto e testi di Forma

**Files:**
- Modify: `index.html` (`<style>`, `<nav>`, funzioni di disegno delle schede)

**Interfaces:**
- Consumes: nessuna dal Task 1 oltre al blocco del lettore, che non si tocca.

- [ ] **Step 1:** sostituisci i due temi attuali con variabili CSS (`--sfondo`, `--riquadro`, `--testo`, `--secondario`, `--separatore`, `--accento`, `--sul-accento`) e `@media (prefers-color-scheme: dark)`; `theme-color` con due meta (`media="(prefers-color-scheme: …)"`). Riquadri come liste iOS a gruppi (raggio 10–12 px, separatori sottili), niente gradienti né vetro.
- [ ] **Step 2:** spunte come `CerchioSpunta` di Forma: cerchio vuoto grigio, pieno con l'accento e segno bianco/`--sul-accento`; area di tocco ≥ 44 px.
- [ ] **Step 3:** barra delle schede in basso come la tab bar iOS (icone SVG in linea, etichette in maiuscolo/minuscolo normale): Oggi, Settimana, Andamento, Impostazioni (ex «Dati»).
- [ ] **Step 4:** pasti con alternative: ogni alternativa in una riga separata con il titolo «Alternativa 1», «Alternativa 2»… (o il titolo letto dal PDF) e la scelta evidenziata con l'accento, come `DettaglioPastoView.swift`.
- [ ] **Step 5:** testi: applica le proposte di `docs/revisione-testi.md` che riguardano la dieta (righe 3–28 dove esiste l'equivalente) e i titoli di Forma («Piani e misure», «Carica il piano alimentare (PDF)», «Non riesco a leggere il PDF», «Olio (cucchiaini)», ecc.). `apple-mobile-web-app-title` e `<title>` restano «Dieta».
- [ ] **Step 6:** verifica in locale: `python3 -m http.server` nella radice, apri nel Safari del simulatore iPhone, tema chiaro e scuro, schede Oggi/Settimana/Andamento/Impostazioni; prima di aprire, metti nel `localStorage` un salvataggio nel formato vecchio con un piano letto dal PDF di prova. Expected: dati ritrovati, nessun testo tagliato, niente sotto la tacca.
- [ ] **Step 7:** `node scripts/controlla-lettore.mjs` — Expected: exit 0. Commit «Web app: aspetto e testi di Forma».

### Task 3: Compatibilità dei dati

**Files:**
- Create: `scripts/prova-dati-web.mjs`
- Modify: `.github/workflows/web.yml` (aggiunge lo script)
- Modify: `index.html` solo se lo script trova un problema

**Interfaces:**
- Consumes: `load()` e la funzione di import del backup di `index.html`, eseguite in Node con un `localStorage` finto.

- [ ] **Step 1:** scrivi lo script: estrae da `index.html` `KEY`, `DEFAULT`, `load` e l'import del backup; carica (a) un salvataggio vecchio, (b) un backup di Forma con `spesa_prossima` e `promemoria` con orari; controlla che dopo `load` + salvataggio i campi siano tutti presenti e uguali.
- [ ] **Step 2:** `node scripts/prova-dati-web.mjs` — Expected: PASS; se FAIL, correggi `index.html` e ripeti.
- [ ] **Step 3:** aggiungi lo script al workflow, commit «Web app: controllo della compatibilità dei dati».

### Finale

- [ ] Revisione dell'intero branch (modello più capace), poi PR. Unione in `main` solo su richiesta dell'utente.
