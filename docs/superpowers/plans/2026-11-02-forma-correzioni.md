# Forma — correzioni dall'analisi completa

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** correggere i problemi trovati nell'analisi di logica, interfaccia e accessibilità di Forma (uso personale, non vendita).

**Architecture:** SwiftUI, dati in `dieta.json` e `palestra.json` (Application Support) tramite `Archivio` e `Palestra` (`@Observable`). La logica nuova va in funzioni pure testabili in Swift Testing (`iOS/FormaTests`); la UI si verifica con le schermate del simulatore.

**Tech Stack:** Swift 6, SwiftUI, iOS 18+, Swift Testing, XCTest UI, pdf.js (in `Risorse/lettore.html`).

**Spec:** l'analisi in conversazione del 2026-11-02 (logica + interfaccia), riassunta qui sotto in ogni task.

## Global Constraints

- Testi dell'app in italiano; commenti in italiano come nel resto del codice.
- I dati salvati e i backup vecchi devono continuare a leggersi (campi nuovi con valori predefiniti via `c.valore`).
- Il formato JSON della dieta resta compatibile con la web app (chiavi `slot` per indice, `profili`, ecc.).
- Test: `xcodebuild test -project iOS/Forma.xcodeproj -scheme Forma -destination 'id=2EBCA585-D94F-4A12-BBCB-D9844DC1A70C'` deve finire con `** TEST SUCCEEDED **`.
- Fuori ambito (da decidere a parte): profili separati per la palestra, sincronizzazione iCloud.

## Review Focus

- File dati illeggibile all'avvio → i dati non vanno mai sovrascritti; il file resta da parte e l'utente viene avvisato.
- Schema ricaricato con la stessa data d'inizio → vale il nuovo; le spunte di quei giorni seguono il nome del pasto.
- Backup con orari fuori scala → orari riportati nell'intervallo valido.
- Testo molto grande (accessibilità) → righe alimento leggibili, nessun testo tagliato.
- iPhone Duo aperto / orizzontale → l'app usa tutto lo schermo, contenuto a larghezza leggibile.

---

### Task 1: Dati illeggibili non vengono più sovrascritti

**Files:** Create `iOS/Forma/Comune/FileDati.swift`; Modify `Dieta/Archivio.swift` (`carica`), `Palestra/ArchivioPalestra.swift` (`carica`), `FormaApp.swift` (avviso); Test `iOS/FormaTests/FileDatiTests.swift`

**Interfaces:** Produces `enum FileDati { static func leggi<T: Decodable>(_ url: URL, come: T.Type) -> Esito<T> }` con `enum Esito<T> { case ok(T), assente, illeggibile(copia: URL) }`; la copia è `<nome>.illeggibile-<yyyyMMdd-HHmmss>.json` nella stessa cartella. `Archivio.fileIlleggibile: URL?`, `Palestra.fileIlleggibile: URL?`.

- [ ] Test: file assente → `.assente`; JSON valido → `.ok`; JSON rotto → `.illeggibile` e la copia esiste con lo stesso contenuto.
- [ ] Implementa; `carica()` usa `FileDati.leggi`; su `.illeggibile` parte dai dati iniziali e memorizza l'URL.
- [ ] `Radice` mostra un alert «Non riesco a leggere i dati salvati: ne ho tenuto una copia (nome). Puoi ripristinarla da Impostazioni → Importa backup.»
- [ ] Test verdi, commit.

### Task 2: Piani con la stessa data e spunte che seguono il pasto

**Files:** Modify `Dieta/Archivio.swift` (`aggiungiPiano`), `Dieta/Archivio.swift` (`Profilo.piano(per:)`); Test `iOS/FormaTests/PianiTests.swift`

**Interfaces:** `aggiungiPiano(_:)` invariata.

- [ ] Test: piano A dal 2026-11-02, poi B (altro nome) dal 2026-11-02 → `piano(per: "2026-11-02")` è B e A non c'è più.
- [ ] Test: spunta su «Cena» (indice 2 in A); B ha «Cena» all'indice 1 → dopo `aggiungiPiano(B)` lo slot "1" di quel giorno è fatto, "2" non esiste.
- [ ] Implementa: un piano con la stessa `dal` sostituisce quello esistente; per i giorni ≥ `dal` già registrati, le chiavi `slot` vengono rimappate per nome del pasto (pasti senza corrispondenza si scartano). In `piano(per:)` a parità di `dal` vince l'ultimo inserito.
- [ ] Test verdi, commit.

### Task 3: Backup e promemoria più robusti

**Files:** Modify `Dieta/Modelli.swift` (`Promemoria.init(from:)`), `Palestra/ModelliPalestra.swift` (`StatoPalestra`), `Dieta/ProfiloView.swift` (testo import, piè di pagina acqua, picker «Alle» ≥ «Dalle»); Test `iOS/FormaTests/PromemoriaTests.swift`

- [ ] Test: JSON con `oraMattino: 1500, acquaOgni: -3, acquaDalle: 900, acquaAlle: 600` → `oraMattino` 1439, `acquaOgni` 1, `acquaAlle` ≥ `acquaDalle`. `oraPagamento: 5000` → 1439.
- [ ] Implementa il clamp (minuti 0…1439, ore 1…6).
- [ ] Testo dell'import: «Un backup di Forma sostituisce tutti i dati (dieta e palestra). Un backup di Dieta sostituisce la dieta. Gli allenamenti di un backup di Palestra si aggiungono.»
- [ ] Test verdi, commit.

### Task 4: Palestra — scheda suggerita, prestazioni, conferme

**Files:** Modify `Palestra/ArchivioPalestra.swift`, `HomeView.swift`, `Palestra/StoricoView.swift`, `Palestra/AllenamentoView.swift`, `Palestra/AllenamentoInCorsoView.swift`; Test `iOS/FormaTests/PalestraTests.swift`

**Interfaces:** `Palestra.prossimaRoutine() -> Routine?` (la scheda dopo quella dell'ultimo allenamento fatto con una scheda, a giro; senza storico la prima). `Palestra.conteggioRecord() -> [UUID: Int]` (record battuti per allenamento, in una sola passata cronologica).

- [ ] Test `prossimaRoutine`: schede [A, B, C], ultimo allenamento con B → C; con C → A; nessuno → A.
- [ ] Test `conteggioRecord`: tre allenamenti con pesi 50, 60, 55 sullo stesso esercizio → [0, 1, 0] (il primo non conta come record, come `nuoviRecord`).
- [ ] Implementa; Oggi usa `prossimaRoutine()`; `StoricoAllenamenti` calcola `conteggioRecord()` una volta e lo passa a `RigaAllenamento`.
- [ ] Conferma prima di eliminare: scheda (swipe ed editor), cardio, esercizio durante l'allenamento.
- [ ] Test verdi, commit.

### Task 5: Salvataggio non bloccante

**Files:** Modify `Dieta/Archivio.swift`, `Palestra/ArchivioPalestra.swift`, `FormaApp.swift`

**Interfaces:** `func salvaOra()` su entrambi; `didSet` programma un salvataggio dopo 0,4 s (un solo `Task` pendente, cancellato e riprogrammato); `Radice` chiama `salvaOra()` quando `scenePhase` diventa `.background`.

- [ ] Implementa; il test esistente sui dati continua a passare; verifica manuale: digitare kg non scrive a ogni tasto.
- [ ] Commit.

### Task 6: Dieta — olio, spesa, consigli, note, profili iniziali

**Files:** Modify `Dieta/PastiView.swift` (stepper olio fino a 2× obiettivo, valore oltre obiettivo in arancione), `Dieta/SettimanaView.swift` + `Dieta/Archivio.swift` (`vociSpesa(settimana:)`), `Dieta/AndamentoView.swift` (consigli), `Dieta/Modelli.swift` (`Stato.iniziale`, note); Test `iOS/FormaTests/SpesaTests.swift`

**Interfaces:** `Profilo.vociSpesa(lunedi: String) -> [VoceSpesa]`; `Archivio.spunteSpesa(lunedi:)`, `spunta(_:lunedi:)`.

- [ ] Test: `vociSpesa(lunedi:)` della settimana prossima usa il piano valido in quei giorni.
- [ ] Spesa: selettore «Questa settimana / Prossima»; da venerdì è preselezionata la prossima.
- [ ] Consigli con tono neutro («Indicazioni generali, non sostituiscono il parere del tuo nutrizionista.» nel piè di pagina).
- [ ] `Stato.iniziale`: un solo profilo «Io». Note: profili nuovi senza nota predefinita; profili salvati senza `note` mantengono il testo attuale (migrazione al caricamento).
- [ ] Test verdi, commit.

### Task 7: Piano modificabile a mano

**Files:** Create `iOS/Forma/Dieta/EditorPianoView.swift`; Modify `Dieta/PianiView.swift`

**Interfaces:** `EditorPianoView(idPiano: String)` modifica `archivio.profilo.piani` in place (nome, date, per giorno: pasti, opzioni, alimenti con quantità; aggiungi/elimina/riordina). `PianiDietaView`: tocco su un piano → editor; pulsante «Nuovo piano vuoto» (7 giorni Lunedì…Domenica senza pasti, poi editor). `piano(per:)` accetta anche piani con giorni senza pasti.

- [ ] Implementa e verifica con schermata nel simulatore.
- [ ] Commit.

### Task 8: Lettore PDF più tollerante

**Files:** Modify `iOS/Forma/Risorse/lettore.html`; Test `iOS/FormaTests/LettoreSchemaTests.swift` (PDF generato come in `LettoreBiaTests`)

- [ ] Test: PDF con «Colazione», «Spuntino», «Pranzo», «Merenda», «Cena» per 7 giorni → 7 giorni da 5 pasti, nomi corretti.
- [ ] Implementa: pasti riconosciuti anche Colazione, Merenda, Spuntino mattina/pomeriggio, Spuntino, Pranzo, Cena (confronto senza maiuscole); soglia delle colonne = metà della larghezza della pagina invece di 240 fissi.
- [ ] Test verdi (incluso il test BIA esistente), commit.

### Task 9: Pagamento e piano A/B configurabili

**Files:** Modify `Palestra/ModelliPalestra.swift` (`pagamentoAttivo = true`, `giornoPagamento = 1`, `usaAB = true`), `Palestra/ArchivioPalestra.swift` (`prossimoPagamento`, `promemoriaPagamento`, `settimana`), `Palestra/SezioniPalestra.swift`, `FormaApp.swift`; Test `iOS/FormaTests/PromemoriaTests.swift`

- [ ] Test: `giornoPagamento = 15` → notifiche il 15 e il 16; avviso in Oggi dal giorno 15−7. `pagamentoAttivo = false` → nessuna notifica e nessun avviso. `usaAB = false` → tutte le settimane usano il piano «A».
- [ ] Implementa (valori predefiniti uguali al comportamento attuale), UI in Impostazioni palestra.
- [ ] Test verdi, commit.

### Task 10: Temi con nomi propri, prima apertura e permessi

**Files:** Modify `Comune/Tema.swift` (solo i nomi mostrati: Lime, Notte, Nebbia, Ambra, Bosco, Viola, Classico; rawValue invariati), `FormaApp.swift`, Create `iOS/Forma/BenvenutoView.swift`

- [ ] Prima apertura (nessun `dieta.json`): schermata di benvenuto con nome del profilo e spiegazione di notifiche e Apple Watch; i permessi si chiedono lì o quando si attiva l'opzione, non più all'avvio senza contesto.
- [ ] Verifica con schermata (simulatore senza dati, senza `-demo`), commit.

### Task 11: Accessibilità, testo grande, iPhone Duo e orizzontale

**Files:** Modify `Dieta/PastiView.swift`, `Dieta/SettimanaView.swift`, `Utilita.swift` (`RigaAlimento`), `FormaApp.swift` (`SezionePagamento` compatta), `Palestra/AllenamentoInCorsoView.swift`, `ProgressiView.swift` → rinomina `Palestra/CalendarioView.swift`, `Forma.xcodeproj/project.pbxproj` (orientamenti), `Comune/Notifiche.swift`, `Palestra/Salute.swift`

- [ ] `RigaAlimento(nome:quantita:)`: in riga, a capo (quantità sotto) con taglie di accessibilità.
- [ ] VoiceOver: spunta serie («Serie 2, fatta / da fare»), `RigaSpunta` con valore «fatto/da fare», celle del calendario con etichetta («3 novembre, pesi fatto / programmato cardio / non andato»).
- [ ] Orientamenti iPhone: verticale e orizzontale; liste con larghezza leggibile (`.contentMargins(.horizontal, …, for: .scrollContent)` quando la larghezza > 700).
- [ ] Con l'app aperta, la notifica «recupero» non mostra il banner (c'è già la vibrazione).
- [ ] Watch: anche vogatore, scale, cardio misto, ellittica come cardio.
- [ ] Schermate su iPhone 17e con testo grande e su iPhone 18 Pro Max in orizzontale; test verdi; commit.

### Task 12: Test dell'import PDF dopo la scelta del file

**Files:** Modify `Dieta/PianiView.swift`; Test `iOS/FormaTests/ImportaPDFTests.swift`

**Interfaces:** `enum EsitoLettura { case piano([GiornoPiano]), bia(Misura), errore(String) }`; `static func valuta(_ tipo: TipoPDF, giorni: [GiornoPiano]?, misura: Misura?) -> EsitoLettura` usata da `leggi`.

- [ ] Test: 7 giorni con pasti → `.piano`; 3 giorni → `.errore` con «trovati 3 giorni su 7»; BIA senza data → `.errore`.
- [ ] Implementa, test verdi, commit.
