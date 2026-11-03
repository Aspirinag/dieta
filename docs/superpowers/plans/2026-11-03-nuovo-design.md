# Forma — nuovo design: piano di lavoro

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rifare l'interfaccia di Forma secondo il progetto: quattro schede (Oggi, Dieta, Palestra, Progressi), Impostazioni in un foglio, un solo aspetto verde salvia, testi rivisti.

**Architecture:** La logica nuova (dosi, reparti, spesa per reparto, riepiloghi della palestra) va in funzioni pure su `Profilo` / `StatoPalestra`, coperte da test Swift Testing. Le viste si riscrivono una schermata alla volta riusando i pezzi esistenti (grafico BIA, dettaglio allenamento, editor). Ogni schermata si verifica con le schermate del simulatore (`ui-checker`) contro le bozze approvate.

**Tech Stack:** SwiftUI (iOS 18+, Liquid Glass su iOS 26), Swift Charts, Swift Testing, XCTest UI.

**Spec:** `docs/superpowers/specs/2026-11-03-nuovo-design-design.md`. Bozze vincolanti: `.superpowers/brainstorm/85159-1793700809/content/` → `oggi-v3.html`, `dieta-spesa-v3.html`, `palestra-progressi-v2.html`, Impostazioni in `schermate.html`.

## Global Constraints

- Lavoro nel worktree `/Users/rl/app-iphone/dieta-design`, branch `design`. Mai su `main`.
- Simulatore per test e schermate: **iPhone 17** (`A6AA3395-85B4-4939-A786-28AB4C41E59E`); l'iPhone 18 Pro è usato dall'altra sessione.
- Comando di test (output in un file, leggere la coda):
  `cd iOS && xcodebuild test -project Forma.xcodeproj -scheme Forma -destination 'id=A6AA3395-85B4-4939-A786-28AB4C41E59E' -derivedDataPath /private/tmp/claude-501/forma-design/dd > /private/tmp/claude-501/forma-design/test.log 2>&1; tail -30 /private/tmp/claude-501/forma-design/test.log`
- `dieta.json` compatibile con la web app: solo campi nuovi, opzionali, decodificati con `c.valore(chiave, predefinito)`. `palestra.json` invariato.
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; i file nuovi non richiedono modifiche al `.pbxproj`.
- Colori: accento `#2F6B4F` (scuro: `#7FB89A`), olio `#D6A21E`, acqua `#3D7FA6`, oltre la dose `.orange`. Nessuna emoji nell'interfaccia; icone SF Symbols o `Pittogrammi.swift`.
- Testi in italiano, frasi brevi, maiuscola solo iniziale, numeri sempre con unità (regole complete nella spec, sezione «Testi»).
- Argomenti di avvio: `-demo`, `-tab oggi|dieta|allenamento|progressi|impostazioni|inCorso`, `-vista spesa`. `-tab profilo` resta come sinonimo di `impostazioni` (script e test vecchi).
- Il branch `correzioni-bug` (altra sessione) tocca le stesse viste: **prima del Task 4** e prima della fine si unisce `correzioni-bug` in `design` se ha commit nuovi (`git merge correzioni-bug`), risolvendo i conflitti a favore della struttura nuova e tenendo le correzioni.

## Review Focus

1. Dati esistenti di un utente reale (piani, spunte, spesa della settimana, misurazioni, allenamenti) si vedono tutti nella nuova struttura: niente resta irraggiungibile (es. editor dei piani, copie dei dati non letti, schede pronte, libreria, calendario, dettaglio esercizio).
2. Testo molto grande (accessibilità XXXL): striscia dei giorni, cucchiaini/gocce, righe della spesa restano leggibili e toccabili.
3. VoiceOver: cucchiaini e gocce leggibili e regolabili («Olio, 2 di 6 cucchiaini», su/giù).
4. Settimana senza piano, giorno senza pasti, nessuna misurazione, nessuna scheda: stati vuoti della spec, nessun crash.
5. Un solo profilo vs due: il selettore compare solo con due o più.

---

### Task 1: Aspetto unico

**Files:**
- Modify: `iOS/Forma/Comune/Tema.swift`
- Modify: `iOS/Forma/FormaApp.swift`, `iOS/Forma/Dieta/ProfiloView.swift` (via `SezioneTema`)
- Test: `iOS/FormaTests/AspettoTests.swift`

**Interfaces:**
- Produces: `enum Colori { static let accento, olio, acqua: Color }` (accento con variante scura via `Color(light:dark:)` o `UIColor { trait in }`); i modificatori esistenti `sfondoTema()`, `righeTema()`, `applicaTema(_:)` restano con lo stesso nome ma applicano l'aspetto unico (sfondo di sistema raggruppato, righe bianche / di sistema). `Tema` e `SezioneTema` vengono eliminati; `applicaTema()` diventa senza argomenti.

- [ ] **Step 1: Test che fallisce** — `AspettoTests.accentoHaDueVarianti`: risolvendo `Colori.accento` con `UITraitCollection(userInterfaceStyle: .light/.dark)` si ottengono `#2F6B4F` e `#7FB89A` (confronto dei componenti RGB con tolleranza 0,01).
- [ ] **Step 2:** eseguire il test → FAIL (`Colori` non esiste).
- [ ] **Step 3:** implementare `Colori`, semplificare i modificatori, togliere `Tema`, `SezioneTema`, `@AppStorage(Tema.chiave)` e ogni `applicaTema(tema)` (diventa `applicaTema()`).
- [ ] **Step 4:** test → PASS; build senza errori.
- [ ] **Step 5:** commit «Forma: un solo aspetto, verde salvia».

### Task 2: Logica nuova (dosi, reparti, spesa, palestra)

**Files:**
- Create: `iOS/Forma/Comune/Dosi.swift`, `iOS/Forma/Dieta/Reparti.swift`
- Modify: `iOS/Forma/Dieta/Modelli.swift` (`Spesa`, `Profilo`), `iOS/Forma/Dieta/Archivio.swift` (`vociSpesa`), `iOS/Forma/Palestra/ArchivioPalestra.swift` (estensione `StatoPalestra`)
- Test: `iOS/FormaTests/DosiTests.swift`, `iOS/FormaTests/RepartiTests.swift`, `iOS/FormaTests/SpesaTests.swift` (aggiornare), `iOS/FormaTests/PalestraTests.swift` (aggiungere)

**Interfaces (Produces):**
- `enum Dosi { static func gocce(dose litri: Double) -> Int; static let litriPerGoccia = 0.25 }` — `ceil(dose / 0.25)`, minimo 1.
- `enum Reparto: String, CaseIterable, Codable { case fruttaVerdura, carnePesceUova, latticini, panePastaCereali, dispensa, altro }` con `var nome: String` («Frutta e verdura», «Carne, pesce, uova», «Latticini», «Pane, pasta, cereali», «Dispensa», «Altro») e `static func indovina(_ nome: String) -> Reparto` (parole chiave in minuscolo, senza accenti; nessuna corrispondenza → `.altro`).
- `Spesa` + `var extra: [String] = []` (chiave JSON `extra`, opzionale).
- `Profilo` + `var repartiSpesa: [String: String]?` (chiave JSON `reparti_spesa`; nome in minuscolo → `Reparto.rawValue`).
- `VoceSpesa` diventa: `chiave, nome, quanto: String, reparto: Reparto, giorni: [(giorno: String, quanto: String)], aggiunta: Bool`.
  - `quanto`: grammi sommati; `≥ 1000 g` → «1,05 kg» (due decimali al massimo, senza zeri finali), altrimenti «420 g»; ml/l analoghi («1,5 L», «250 ml»); solo cibi senza quantità → «7 porzioni» / «1 porzione».
  - `giorni`: abbreviazione del giorno («lun») e quantità di quel giorno.
- `Profilo.reparto(di chiave: String) -> Reparto` (manuale se presente, altrimenti `indovina`), `mutating func sposta(_ chiave: String, in r: Reparto)`, `mutating func aggiungiExtra(_ nome: String, lunedi: String)`, `mutating func togliExtra(_ nome: String, lunedi: String)`. Le voci extra compaiono in `vociSpesa` con `aggiunta = true`, `quanto = ""`.
- `StatoPalestra.giorniAllenati(settimanaDi iso: String) -> Set<Int>` (indici 0…6 lun…dom con almeno un allenamento o cardio), `durataSettimana(_ iso: String) -> TimeInterval`, `volumiSettimanali(ultime n: Int, oggi: String) -> [Double]` (dalla più vecchia alla corrente).

- [ ] **Step 1: Test che falliscono**
  - `DosiTests`: `gocce(dose: 2) == 8`, `gocce(dose: 1.9) == 8`, `gocce(dose: 0.1) == 1`.
  - `RepartiTests`: `indovina("Petto di pollo") == .carnePesceUova`, `"Mela" → .fruttaVerdura`, `"Yogurt greco" → .latticini`, `"Pasta integrale" → .panePastaCereali`, `"Olio extravergine" → .dispensa`, `"Quinoa soffiata bio" → .altro`.
  - `SpesaTests` (aggiornare l'esistente): `voci.first?.quanto == "560 g"`; nuovo `kgSopraIlChilo` (150 g × 7 → «1,05 kg»); `porzioniSenzaGrammi` («Insalata», quantità «a piacere» × 7 → «7 porzioni»); `giorniDellaVoce` (`giorni.first == ("lun", "80 g")`); `repartoManualeVinceSullaStima` (dopo `sposta("riso", in: .dispensa)` il reparto è `.dispensa`); `extraCompareNellaSettimana` (aggiunto per la settimana 2026-11-02, presente lì e assente in 2026-11-09); `jsonVecchioSenzaCampiNuovi` (decodifica di `{"settimana":"2026-11-02","presi":{}}` → `extra == []`).
  - `PalestraTests`: `giorniAllenatiDellaSettimana`, `volumiDelleUltimeSettimane` (3 allenamenti in 2 settimane → valori attesi), `durataDellaSettimana`.
- [ ] **Step 2:** eseguire → FAIL (simboli mancanti).
- [ ] **Step 3:** implementare; l'elenco delle parole chiave dei reparti lo sceglie l'implementatore (almeno 15 parole per reparto tra le più comuni nei piani italiani).
- [ ] **Step 4:** test → PASS, anche tutti quelli preesistenti.
- [ ] **Step 5:** commit «Forma: logica per spesa a reparti, dosi e riepiloghi della palestra».

### Task 3: Navigazione e Impostazioni

**Files:**
- Modify: `iOS/Forma/FormaApp.swift` (`Scheda`, `Navigazione`, `Radice`)
- Create: `iOS/Forma/ImpostazioniView.swift`
- Modify: `iOS/Forma/Dieta/ProfiloView.swift` (le sezioni diventano sottopagine riusabili), `iOS/Forma/Comune/Utilita.swift` o dove sta `MenuProfilo`
- Test: `iOS/FormaUITests/NavigazioneTests.swift`

**Interfaces:**
- `enum Scheda: String { case oggi, dieta, allenamento, progressi }`; `Navigazione.impostazioniAperte: Bool` (vera se `-tab impostazioni` o `-tab profilo`).
- `ImpostazioniView`: foglio con «Fine»; gruppi **Dieta** (Piani alimentari → `PianiDietaView`; Olio e acqua), **Palestra** (Pagamento; Apple Watch → sezioni di `SezioniPalestra`), **Generali** (Promemoria; Backup, con «Copie dei dati non letti»; Profili). Il programma della settimana (`PianoSettimanaleView`, con A/B) **non** va qui: si apre dal menu + di Palestra (Task 7), così le voci restano sette.
- `MenuProfilo` visibile solo se `archivio.stato.profili.count >= 2`, e solo in Oggi.
- Il testo dell'avviso «Dati non letti» punta a «Impostazioni → Backup».

- [ ] **Step 1: Test UI che fallisce** — `NavigazioneTests.testQuattroSchedeEImpostazioniDalIngranaggio`: con `-demo -tab oggi` la tab bar ha i pulsanti «Oggi», «Dieta», «Palestra», «Progressi» e non «Impostazioni»; il pulsante «Impostazioni» (ingranaggio) apre un foglio con «Piani alimentari», «Promemoria», «Backup»; «Fine» lo chiude.
- [ ] **Step 2:** eseguire con `-only-testing:FormaUITests/NavigazioneTests` → FAIL.
- [ ] **Step 3:** implementare; `Progressi` inizialmente mostra il vecchio `AndamentoPagina` (sostituito nel Task 8).
- [ ] **Step 4:** test → PASS; aggiornare `OggiPastiTests`/`AndamentoTests` solo se rotti dalla navigazione (il loro contenuto cambia nei Task 4 e 8).
- [ ] **Step 5:** commit «Forma: quattro schede, Impostazioni dall'ingranaggio».

### Task 4: Oggi

**Files:**
- Modify: `iOS/Forma/HomeView.swift` (riscrittura)
- Create: `iOS/Forma/Comune/Dosaggio.swift` (vista cucchiaini/gocce)
- Modify: `iOS/Forma/Comune/Pittogrammi.swift` (cucchiaino, goccia se mancano)
- Test: `iOS/FormaUITests/OggiPastiTests.swift` (riscrivere)

**Interfaces:**
- `struct Dosaggio: View { let nome: String; let unita: String; @Binding var valore: Int; let dose: Int; let colore: Color; let pittogramma: Pittogramma }` — tocco sull'elemento n → `valore = n`, sull'ultimo segnato → `valore = n - 1`; elementi extra arancioni fino a `2 × dose`; `.accessibilityElement`, `.accessibilityValue("2 di 6 cucchiaini")`, `.accessibilityAdjustableAction`.
- Acqua: `valore` in bicchieri (litri / 0,25) convertito da/verso il registro esistente.

Contenuto e ordine come la spec, sezione «Oggi»: Pasti (barra a segmenti + righe con cerchio; identificatore `riga-pasto`, cerchio con etichetta «Segna Colazione»), Allenamento (prossima scheda / riposo con «Allenati lo stesso» / cardio), Olio e acqua, Peso (tocco → scheda Progressi). Stati vuoti della spec.

- [ ] **Step 1: Test UI che fallisce** — `OggiPastiTests.testSegnareUnPastoDaOggi`: con `-demo -tab oggi`, tocca «Segna Pranzo» → il contatore diventa «2 di 4»; `testOlioSiSegnaConUnTocco`: l'elemento «Olio» ha valore «2 di 6 cucchiaini», dopo `increment()` «3 di 6 cucchiaini».
- [ ] **Step 2:** eseguire → FAIL.
- [ ] **Step 3:** implementare.
- [ ] **Step 4:** test → PASS; schermate con `ui-checker` (chiaro, scuro, testo XXXL) confrontate con `oggi-v3.html`.
- [ ] **Step 5:** commit «Forma: nuova schermata Oggi».

### Task 5: Dieta — la settimana

**Files:**
- Create: `iOS/Forma/Dieta/DietaView.swift` (sostituisce `PastiView` come scheda), `iOS/Forma/Dieta/DettaglioPastoView.swift`
- Modify/Delete: `iOS/Forma/Dieta/PastiView.swift` (le parti riusabili — `SezionePasto` — passano nel dettaglio; il resto si elimina)
- Test: `iOS/FormaUITests/DietaTests.swift`

**Interfaces:**
- `DietaView`: titolo «Dieta», sottotitolo piano («Schema ottobre · dal 1 ottobre»), striscia dei 7 giorni della settimana corrente (`StrisciaGiorni(lunedi:selezionato:)`, puntini = pasti segnati), riquadri pasto (nome, cibi in una riga, «oppure …» per le alternative), riga «Spesa della settimana · N prodotti · M presi» (nascosta se nessun piano nella settimana), stati vuoti della spec.
- `DettaglioPastoView(giorno:indice:)`: quantità riga per riga, scelta dell'alternativa, spunta del pasto (stessa di Oggi).
- Destinazioni per valore (`PaginaDieta`: `.pasto(giorno, indice)`, `.spesa`) registrate sulla radice, come la correzione dell'Andamento.

- [ ] **Step 1: Test UI che fallisce** — `DietaTests.testSettimanaEPasto`: `-demo -tab dieta` mostra 7 pulsanti giorno; tocca «mercoledì 4» → compare «Colazione»; tocca «Colazione» → si apre il dettaglio con «Yogurt greco» e «150 g»; indietro torna a Dieta.
- [ ] **Step 2:** FAIL. **Step 3:** implementare. **Step 4:** PASS + `ui-checker` contro `dieta-spesa-v3.html` (sinistra).
- [ ] **Step 5:** commit «Forma: Dieta mostra la settimana».

### Task 6: Spesa

**Files:**
- Create: `iOS/Forma/Dieta/SpesaView.swift` (sostituisce la parte spesa di `SettimanaView`)
- Delete: `iOS/Forma/Dieta/SettimanaView.swift` (dopo aver spostato ciò che serve; `-vista spesa` apre la Spesa da Dieta)
- Test: `iOS/FormaUITests/SpesaUITests.swift`

**Interfaces:** usa `vociSpesa`, `reparto(di:)`, `sposta`, `aggiungiExtra`, `spunta` del Task 2. Intestazione «per la settimana 2 – 8 novembre · 5 di 14» con frecce e `ProgressView`; sezioni per reparto nell'ordine di `Reparto.allCases`; riga con cerchio (presi: sbiaditi e barrati, restano al posto); tocco sul nome → riga dei giorni; menu contestuale «Sposta in…»; «Aggiungi qualcos'altro» (campo di testo); condivisione (testo semplice per reparto).

- [ ] **Step 1: Test UI che fallisce** — `SpesaUITests.testSpesaPerRepartoEAggiunta`: `-demo -tab dieta -vista spesa` mostra le intestazioni «Frutta e verdura» e «Carne, pesce, uova»; tocca il cerchio di «Petto di pollo» → «1 di N» aumenta; «Aggiungi qualcos'altro», scrivi «Caffè», invio → «Caffè» compare in «Altro».
- [ ] **Step 2:** FAIL. **Step 3:** implementare. **Step 4:** PASS + `ui-checker` contro `dieta-spesa-v3.html` (destra).
- [ ] **Step 5:** commit «Forma: spesa della settimana per reparto».

### Task 7: Palestra

**Files:**
- Modify: `iOS/Forma/Palestra/AllenamentoView.swift` (riscrittura della scheda; restano `EditorSchedaView` e le pagine raggiunte dal +)
- Test: `iOS/FormaUITests/PalestraUITests.swift`

**Interfaces:** riquadro «Prossima scheda» (`prossimaRoutine()`, esercizi in una frase, «Inizia»); «Questa settimana» (`giorniAllenati`, `durataSettimana`); righe delle schede con ▶ (etichetta «Inizia Push») e tocco sul nome → `EditorSchedaView`; «Allenamento libero»; menu **+**: «Nuova scheda», «Schede pronte» (`ModelliView`), «Libreria esercizi» (`LibreriaView`), «Programma della settimana» (`PianoSettimanaleView`). Nessuno storico, calendario o impostazioni qui. Stato vuoto: «Crea la prima scheda» / «Scegli tra le schede pronte».

- [ ] **Step 1: Test UI che fallisce** — `PalestraUITests.testInizia`: `-demo -tab allenamento` mostra «Prossima scheda» e un pulsante «Inizia»; toccandolo si apre l'allenamento in corso (barra di navigazione con «Fine»); il menu + contiene «Libreria esercizi».
- [ ] **Step 2:** FAIL. **Step 3:** implementare. **Step 4:** PASS + `ui-checker` contro `palestra-progressi-v2.html` (prima).
- [ ] **Step 5:** commit «Forma: Palestra serve a iniziare».

### Task 8: Progressi — Corpo

**Files:**
- Create: `iOS/Forma/ProgressiView.swift` (scheda con scelta Corpo / Palestra), `iOS/Forma/Dieta/CorpoView.swift`
- Modify/Delete: `iOS/Forma/Dieta/AndamentoView.swift` (il grafico si riusa; il resto si elimina), `AndamentoPagina` in `PianiView.swift`
- Test: `iOS/FormaUITests/AndamentoTests.swift` (riscrivere come `ProgressiCorpoTests`)

**Interfaces:** peso grande e variazione; grafico con periodo (1 mese / 3 mesi / Tutto) e metrica scelta toccando un riquadro (Grasso, Magra, Vita); riga aderenza («Pasti segnati negli ultimi 7 giorni: 86%»); «Misurazioni» (ultime 2, «Tutte» → elenco completo con modifica ed eliminazione via `PaginaDieta.misura`); menu + «Aggiungi misurazione» / «Carica referto BIA (PDF)». Stato vuoto «Aggiungi il primo peso».

- [ ] **Step 1: Test UI che fallisce** — come l'attuale `AndamentoTests` ma da `-tab progressi`: «Tutte» → tocca una misurazione → «Modifica misurazione» → indietro → elenco, nessun avviso.
- [ ] **Step 2:** FAIL. **Step 3:** implementare. **Step 4:** PASS + `ui-checker` contro `palestra-progressi-v2.html` (seconda).
- [ ] **Step 5:** commit «Forma: Progressi, il corpo».

### Task 9: Progressi — Palestra

**Files:**
- Create: `iOS/Forma/Palestra/ProgressiPalestraView.swift`
- Modify: `iOS/Forma/Palestra/StoricoView.swift`, `iOS/Forma/Palestra/CalendarioView.swift` (diventano pagine raggiunte da qui)
- Test: `iOS/FormaUITests/ProgressiPalestraTests.swift`

**Interfaces:** grafico a barre `volumiSettimanali(ultime: 7, oggi:)` (ultima barra piena); «Record recenti» (2, «Tutti» → record per esercizio, tocco → `DettaglioEsercizioView`); «Allenamenti» (ultimi 5 inclusi i cardio dal Watch, «Calendario» → `CalendarioContenuto`; tocco → `DettaglioAllenamentoView`). Destinazioni per valore registrate sulla radice di Progressi (lezione del bug dell'Andamento: nessuna `navigationDestination` su pagine aperte con collegamento diretto).

- [ ] **Step 1: Test UI che fallisce** — `ProgressiPalestraTests.testDettaglioETorna`: `-demo -tab progressi`, scelta «Palestra», tocca il primo allenamento → la barra «Progressi» sparisce (dettaglio aperto); indietro → «Progressi» di nuovo.
- [ ] **Step 2:** FAIL. **Step 3:** implementare. **Step 4:** PASS + `ui-checker` contro `palestra-progressi-v2.html` (terza).
- [ ] **Step 5:** commit «Forma: Progressi, la palestra».

### Task 10: Revisione dei testi

**Files:** tutte le viste in `iOS/Forma/**` con testi (`Text`, `Label`, `Button`, `.navigationTitle`, `alert`, notifiche in `Notifiche.swift` e `Archivio.swift`, `BenvenutoView.swift`).

- [ ] **Step 1:** estrarre l'elenco dei testi (`grep -rhoE '"[^"]{3,}"' iOS/Forma --include=*.swift`) in un file di lavoro nello scratchpad; segnare per ognuno: tenere / riscrivere / togliere, con le regole della spec.
- [ ] **Step 2:** applicare le riscritture; i test UI che cercano testi per etichetta vanno aggiornati nello stesso commit.
- [ ] **Step 3:** suite completa → PASS.
- [ ] **Step 4:** commit «Forma: testi più chiari».

### Task 11: Pulizia e verifica finale

**Files:** `scripts/schermate.sh`, `.claude/agents/ui-checker.md`, `README.md`, `CLAUDE.md` (argomenti `-tab`), file rimasti senza uso.

- [ ] **Step 1:** unire `correzioni-bug` se ha commit nuovi; risolvere i conflitti.
- [ ] **Step 2:** eliminare codice non più raggiungibile (temi, vecchie viste) e aggiornare script/documenti agli argomenti nuovi (`oggi dieta dieta:spesa allenamento progressi inCorso impostazioni`).
- [ ] **Step 3:** suite completa → PASS; `ui-checker` su tutte le schede in chiaro, scuro e testo XXXL; verifica a mano dei punti del Review Focus.
- [ ] **Step 4:** commit «Forma: pulizia dopo il nuovo design».
