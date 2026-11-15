# Revisione Forma: parte Dieta e parti comuni

Repo `/Users/rl/app-iphone/dieta` (main), solo lettura. I test temporanei sono in una copia:
`/private/tmp/claude-501/-Users-rl/e1beabfc-0da9-4645-bc6c-bf9681184997/scratchpad/audit-dieta/iOS/FormaTests/AuditDietaTests.swift`
(9 test, tutti verdi: ognuno verifica che il comportamento sbagliato c'è davvero). Log: `.../scratchpad/audit-dieta/test.log`.

---

## CONFERMATI

### 1. Un numero "nan" o "1e999" in una misura svuota il file dei dati (ALTA)
- `Comune/Utilita.swift:132-144` (`leggiNumero`), `Dieta/EditorMisura.swift:89,113`, `Dieta/Archivio.swift:89-93` e `:83`
- **Cosa succede:** `leggiNumero` passa il testo a `Double(...)`, che accetta anche `nan`, `inf`, `infinity` e `1e999` (infinito). Nel modulo Misura (Progressi → Nuova misura / Modifica) basta incollare uno di questi testi, o scriverlo con una tastiera esterna: il pulsante Salva si accende (il controllo è solo `!= nil`) e la misura viene salvata con NaN o infinito. `JSONEncoder` non sa codificare NaN o infinito e lancia un errore; `backup()` lo ingoia con `(try? e.encode(stato)) ?? Data()` e `salva()` scrive **un file vuoto** sopra `dieta.json`. Al riavvio successivo il file non si legge: Forma riparte da zero e mette da parte una "copia" che è vuota anche lei. **Si perdono tutti i dati della dieta.** Anche "Esporta backup" in quella sessione produce un file vuoto.
- **Prova:** test `nanEInfinitoPassanoDaLeggiNumero` (`leggiNumero("nan")` è NaN, `"1e999"` e `"inf"` sono infinito) e `statoConNaNNonSiCodifica` (uno Stato con peso NaN produce `Data()` vuoto con la stessa riga di `backup()`).
- **Correzione:** in `leggiNumero` restituire `nil` se il risultato non è `isFinite` (e accettare solo cifre, separatore e segno). In `salva()` non scrivere mai se la codifica fallisce: `let dati = try e.encode(stato)` dentro il `do`, così il file vecchio resta. Stessa cosa in `Backup.esporta`. Nota fuori dal perimetro: anche `AllenamentoInCorsoView.swift:570` usa `leggiNumero` per i kg; lì `ArchivioPalestra.salva` non scrive file vuoti ma smette di salvare in silenzio finché resta il NaN.

### 2. Il backup esportato da Forma non si importa nella web app (ALTA rispetto a quanto promette il README)
- `Comune/Backup.swift:6-16` contro `index.html:1073-1074`
- **Cosa succede:** Forma esporta `{ "forma": 1, "dieta": {...}, "palestra": {...} }`. La web app accetta solo un file con `profili` in cima (`if (!parsed || typeof parsed.profili !== 'object') throw`) e quindi risponde "Backup non importato". Il README dice "I dati passano da una all'altra con Esporta backup / Importa backup: il file è lo stesso". Funziona solo dalla web app verso Forma.
- **Prova:** lettura del codice delle due parti (i nomi dei campi sono fissi).
- **Correzione:** nella web app, se `parsed.forma && parsed.dieta?.profili`, usare `parsed.dieta` (senza rinominare campi); oppure correggere il README.

### 3. Un piano nuovo con data di fine accorcia per sempre quello vecchio (MEDIA)
- `Dieta/Archivio.swift:228-235` (`inserisci`), usato da `EditorPianoView.swift:111,124`
- **Cosa succede:** in "Nuovo piano a mano" si può togliere "Senza data di fine" e scegliere "Fino al". Se c'è un piano aperto dal 1° gennaio e se ne aggiunge uno dal 1° al 31 marzo, il vecchio viene chiuso al 28 febbraio e dal 1° aprile **non c'è più nessun piano** (Oggi e Dieta mostrano "Nessun piano"). Il piano vecchio non riparte dopo la fine del nuovo.
- **Prova:** test `pianoConFineTroncaIlVecchioPerSempre`.
- **Correzione:** se il piano nuovo ha `al` non vuoto, non chiudere i piani che continuano oltre `al` (non serve, perché `piano(per:)` sceglie già quello iniziato più di recente), oppure dividerli in due pezzi.

### 4. Eliminare l'ultimo piano non fa tornare il precedente (MEDIA)
- `Dieta/PianiView.swift:180-182`
- **Cosa succede:** caricando un piano viene chiuso quello precedente (`al` = giorno prima). Se poi si elimina il piano nuovo, per esempio perché era il PDF sbagliato, il precedente resta chiuso: da quella data in poi "Nessun piano per oggi". Il messaggio "I pasti già segnati restano" fa pensare che basti eliminare. Per rimediare bisogna aprire il vecchio piano e riattivare "Senza data di fine", cosa poco ovvia.
- **Prova:** test `eliminareIlPianoNuovoNonRiapreIlVecchio`.
- **Correzione:** quando si elimina un piano, riaprire (o allungare fino all'`al` del piano eliminato) quelli la cui fine è esattamente il giorno prima del suo `dal`.

### 5. Spesa: i pezzi diventano "a piacere" e le quantità miste si perdono (MEDIA)
- `Dieta/Archivio.swift:358-364` (`testoQuantita`, il parametro `porzioni` non è usato), `:371` e `:390`
- **Cosa succede:**
  - un alimento con quantità "2" (uova, fette, vasetti) compare come **"a piacere"**: in lista non si vede quante uova comprare. Il commento a riga 367 dice "le altre si contano come porzioni", ma il conteggio viene calcolato (`volte`) e poi ignorato. La web app invece mostra "N volte".
  - se lo stesso alimento è "100 g" un giorno e "1 vasetto" un altro, il totale dice solo "100 g": il vasetto sparisce.
  - "1.000 g" (punto delle migliaia all'italiana) diventa **"1 g"**.
- **Prova:** test `spesaPezziDiventanoAPiacere`, `spesaUnitaMisteNascondeIPezzi`, `spesaMigliaiaColPunto`.
- **Correzione:** sommare anche le quantità senza unità (numero iniziale) come pezzi ("2 + 3" → "5"), oppure mostrare "N volte" come la web app; aggiungere le parti non in grammi ("100 g + 1 vasetto"); nella regex trattare `\d{1,3}\.\d{3}` come migliaia.

### 6. Il fuso orario si fissa all'avvio dell'app (BASSA)
- `Comune/Utilita.swift:48-53` (`Giorni.calendario` è uno `static let` creato con il fuso di quel momento)
- **Cosa succede:** chi viaggia con l'app ancora in memoria (es. Italia → USA) continua ad avere "oggi" calcolato nel fuso vecchio fino a quando l'app non viene chiusa: spunte sul giorno sbagliato per alcune ore. Nel frattempo i titoli con `Date.formatted` usano già il fuso nuovo, quindi la data nel titolo e i pasti mostrati non coincidono.
- **Prova:** test `calendarioNonSegueIlCambioDiFuso` (dopo il cambio di `NSTimeZone.default` il fuso del calendario resta quello vecchio).
- **Correzione:** `c.timeZone = .autoupdatingCurrent` e `c.locale = .autoupdatingCurrent`, oppure creare il calendario ogni volta.

(Controllato e corretto: `Giorni.aggiungi`, `indice`, `lunedi` nei giorni del cambio d'ora 2026, test `oraLegale`. Anche le variazioni "in 30 giorni" usano differenze di calendario e non risentono dell'ora legale.)

---

## SOSPETTI (verificati sul codice, senza test automatico)

### 7. "Oggi" resta fermo a ieri se l'app resta aperta oltre la mezzanotte (MEDIA)
- `HomeView.swift:123-136, 277-296` (`let oggi = Giorni.oggi()` calcolato solo quando la vista si ridisegna)
- **Cosa succede:** DietaView e SpesaView si aggiornano quando l'app torna in primo piano (`onChange(of: fase)`); HomeView no: non legge `scenePhase` e non ascolta il cambio di giorno. Se l'app era sospesa ieri sera, la mattina "Oggi" può mostrare ancora i pasti, l'olio e l'acqua di **ieri**, e le spunte toccate finiscono sulla data di ieri (`RigaPasto(giorno: oggi)` e `cambiaRegistro(oggi)` usano la data calcolata la sera prima). Si aggiorna solo quando cambia un dato osservato.
- **Correzione:** come in DietaView, `@State ultimoOggi` aggiornato in `.onChange(of: scenePhase)` e su `UIApplication.significantTimeChangeNotification`, usato al posto di `Giorni.oggi()` nel corpo della vista.

### 8. Lettore PDF: si blocca o fallisce per sempre dopo un errore della pagina nascosta (MEDIA)
- `Dieta/LettorePDF.swift:18-50`
- **Cosa succede:**
  - (a) se il primo caricamento di `lettore.html` fallisce (`didFail`), `pronto` resta falso ma `web` esiste già: alla prossima lettura `prepara()` non ricarica la pagina e aspetta una risposta che non arriva mai. La rotella "Lettura del PDF…" resta per sempre.
  - (b) manca `webViewWebContentProcessDidTerminate`: se iOS chiude il processo della pagina, cosa normale dopo molto tempo in background o con poca memoria, `pronto` resta vero ma la pagina non c'è più. Ogni lettura successiva fallisce con "Il file non è leggibile. Scegli un altro PDF." finché l'app non viene riavviata, e il messaggio fa pensare che il PDF sia sbagliato.
- **Correzione:** in `didFail` e in `webViewWebContentProcessDidTerminate` mettere `web = nil; pronto = false` (e togliere la vista), così la lettura successiva ricrea la pagina; aggiungere un tempo massimo all'attesa.

### 9. Con il file dati non leggibile, i promemoria vengono riprogrammati con i valori di fabbrica (BASSA)
- `FormaApp.swift:140-146`, `Dieta/Archivio.swift:184-194`
- **Cosa succede:** nello stato "Dati non disponibili" (`salvataggioBloccato`), `stato` è `.iniziale` con `promemoria == nil`. La `.task` di Radice chiama comunque `programmaPromemoria()`: toglie i promemoria acqua e pasti dell'utente e mette il solo promemoria del mattino alle 9:00. Restano così finché l'app non viene riaperta correttamente.
- **Correzione:** in `programmaPromemoria` uscire se `salvataggioBloccato` (lo stesso vale per `palestra.programmaPagamento`).

### 10. Importare un backup della web app riaccende il promemoria del mattino (BASSA)
- `Dieta/Modelli.swift:338` (`mattino = c.valore(.mattino, true)`), `ImpostazioniSezioni.swift:235-238`
- **Cosa succede:** la web app salva `promemoria` solo con `acqua` e `pasti`. All'importazione `mattino` vale `true` e il promemoria delle 9:00 viene programmato subito, anche se l'utente lo aveva spento in Forma.
- **Correzione:** se nel JSON c'è `promemoria` ma manca `mattino`, usare `false`; oppure tenere i promemoria attuali quando il backup arriva dalla web app.

### 11. Web app e Forma scelgono piani diversi con la stessa data di inizio (BASSA)
- `Dieta/Archivio.swift:207` (`>=`, vince l'ultimo) contro `index.html:231` (`b.dal > a.dal ? b : a`, vince il primo); `index.html:382` toglie solo i piani con stesso nome **e** stessa data
- **Cosa succede:** un backup della web app con due piani che iniziano lo stesso giorno (possibile caricando due PDF con nomi diversi) mostra in Forma il piano più nuovo e nella web app il più vecchio. Inoltre Forma ignora i piani che non hanno 7 giorni (`piano(per:)` richiede `giorni.count == 7`), mentre la web app li mostra.
- **Correzione:** allineare la regola in entrambe (vince l'ultimo aggiunto) e nella web app sostituire anche i piani con la sola stessa data, come fa Forma.

### 12. La web app sovrascrive la spesa salvata da Forma (BASSA, solo passando dati da Forma alla web app)
- `index.html:548-551` (`spuntaSpesa`) contro `Dieta/Archivio.swift:449-453`
- **Cosa succede:** se in Forma è stata spuntata solo la settimana prossima, la salva in `spesa` (il campo che legge la web app). Aprendo la Spesa, la web app vede una settimana diversa e sostituisce l'oggetto con `{settimana, presi:{}}`, cancellando spunte ed `extra` della settimana prossima. Conta solo se il punto 2 viene risolto.
- **Correzione:** nella web app lasciare `spesa` com'è se `settimana` è futura, oppure conservare `extra`.

---

## Controllati e senza problemi
- Decodifica tollerante: tutti i modelli della dieta usano `c.valore`, e i campi nuovi (`spesa_prossima`, `reparti_spesa`, `extra`, `promemoria.*`) hanno un valore predefinito. I nomi JSON coincidono con quelli della web app (`olio_tot`, `acqua_tot`, `grasso_kg`, `slot` con chiavi stringa, `acqua` in litri).
- Notifiche: al massimo 26 per l'acqua, più mattino, pasti e pagamento, ben sotto il limite di 64. Prima di programmarle vengono tolte le vecchie (`mattino`, `pasti`, `acqua-*`) e le programmazioni sono messe in coda una dopo l'altra.
- Cancellazioni con le viste aperte: `DettaglioPastoView` e `EditorPianoView`/`EditorPasto` controllano gli indici; `Dosaggio` ha sempre almeno un elemento visibile (`ForEach(1...visibili)` non va in crash con una dose di 0).
- Settimana da lunedì (`firstWeekday = 2` e indice calcolato a mano), anche con il telefono in inglese americano.
- Rimappatura delle spunte quando cambia il piano (per nome e posizione del pasto).
