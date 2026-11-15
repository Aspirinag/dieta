# Revisione Palestra — Forma (main @ f3efa86)

Ambito: `iOS/Forma/Palestra/*`, `iOS/Condiviso/*`, `iOS/RecuperoWidget/*`. Il repo non è stato modificato.
I test temporanei sono in una copia: `/private/tmp/claude-501/-Users-rl/e1beabfc-0da9-4645-bc6c-bf9681184997/scratchpad/audit-palestra/dieta/iOS/FormaTests/AuditPalestraTests.swift`.
Sono 9 test che **passano se il problema c'è**: passano tutti e 9 (`** TEST SUCCEEDED **`, simulatore iPhone 17e; l'iPhone 17 Pro non è installato).
PR aperte non ripetute qui: #19 (editor scheda per posizione, crash eliminando una scheda o un esercizio della scheda) e #20 (importa da PDF).

---

## Confermati

### 1. All'apertura dell'allenamento la serie attiva ignora l'ultima serie salvata — media
- **Dove:** `AllenamentoInCorsoView.swift:20` (`@State riferimento` parte da nil), `:28`, `:82-84` (si allinea a `palestra.ultimaSerie` solo quando *cambia*), `:85-89` (`.task` non lo imposta). Il modello dice il contrario: `ModelliPalestra.swift:201` e `ArchivioPalestra.swift:12-13` («da lei si cerca la serie attiva, anche dopo un riavvio»).
- **Cosa vede l'utente:** fa gli esercizi fuori ordine (per esempio comincia dal 2° perché la macchina del 1° è occupata), poi tocca «Nascondi» o riavvia l'app e riapre. I ± e lo scorrimento automatico vanno alla prima serie da fare dell'**esercizio 1**, mentre la Live Activity (che usa `ultimaSerie`) mostra la serie dopo l'ultima spuntata nell'esercizio 2. App e schermata bloccata indicano due serie diverse.
- **Prova:** test `serieAttivaIgnoraUltimaSerieAllApertura`: `SerieAttiva.trova(riferimento: nil)` dà A1, con l'ultima serie dà B2.
- **Correzione:** in `.task` (o con `@State riferimento = palestra.ultimaSerie` in `init`) partire da `palestra.stato.inCorso?.ultimaSerie`.

### 2. Una sessione del Watch si aggancia a un allenamento rimasto aperto da giorni — media
- **Dove:** `ArchivioPalestra.swift:248` (`registraDalWatch`) con `sovrapposti` a `:263-266`: per l'allenamento in corso `fb = b.fine ?? Date()`, quindi va da quando è iniziato ad *adesso*. Lo stesso calcolo in `termina` (`:180`) assorbe ogni sessione «solo Watch» registrata tra l'inizio vecchio e adesso.
- **Cosa vede l'utente:** lunedì lascia aperto un allenamento, mercoledì registra la palestra con il Watch. La sessione di mercoledì non compare (risulta `.agganciato`, niente notifica «Aggiungi esercizi») e calorie e battito finiscono nell'allenamento di lunedì. Finendo l'allenamento, una sessione «solo Watch» di quei giorni sparisce e viene unita.
- **Prova:** test `watchAgganciatoAUnAllenamentoVecchio`: allenamento in corso da 2 giorni, sessione Watch dell'ultima ora → `.agganciato`, `allenamenti` vuoto.
- **Correzione:** per l'allenamento in corso usare una fine verosimile, per esempio `max(ultima serie spuntata, inizio + 3 h)`, oppure agganciare solo se la sessione del Watch comincia entro N ore da `inizio`.

### 3. «Annullalo e inizia il nuovo» non annulla davvero — media
- **Dove:** `AllenamentoView.swift:55-56` → `avvia(r, forza: true)` → `palestra.inizia(r)` (`ArchivioPalestra.swift:125-131`), che sovrascrive `stato.inCorso`. Non passa da `annulla()` (`:192-202`) e non ferma il timer.
- **Cosa vede l'utente:** (a) se l'allenamento vecchio aveva agganciata una sessione del Watch, la sessione va persa (`annulla()` la terrebbe come «Palestra · dal Watch»). Siccome il suo uuid è già in `importati`, non torna più. (b) Il recupero del vecchio allenamento continua nel nuovo: barra, Live Activity con il nome del vecchio esercizio, notifica. `avviatoDa` resta legato a una serie che non esiste più.
- **Prova:** test `iniziaSopraUnAllenamentoConWatchLoPerde`: con `inizia` → `allenamenti` vuoto; con `annulla` → 1 sessione.
- **Correzione:** nel ramo `forza` chiamare `timer.ferma(); palestra.annulla()` prima di `palestra.inizia(r)`.

### 4. Una serie di riscaldamento prende i kg della prima serie di lavoro dell'ultima volta — media
- **Dove:** `AllenamentoInCorsoView.swift:546-547` (`numero` conta solo le serie di lavoro precedenti, quindi un riscaldamento in testa ha `numero = 0`), poi `prec = palestra.precedente(esercizio, 0)`. `precedente` (`ArchivioPalestra.swift:269-274`) scarta i riscaldamenti dell'ultima volta. Lo stesso valore va nel segnaposto (`:568, :574`), nella colonna «Precedente» (`:566`), nei ± (`:686-687`) e nella spunta (`:764`). Uguale in `segnaDaLive` (`ArchivioPalestra.swift:143-144`) e nella Live Activity (`LiveAllenamento.swift:40, 48-55`).
- **Cosa vede l'utente:** squat, ultima volta 40×10 di riscaldamento e 100×5 di lavoro. Oggi la riga «R» propone 100 × 5. Spuntandola vuota (o con «Fatta» dalla schermata bloccata) si salva un riscaldamento da 100 kg × 5, e lo storico dell'esercizio lo mostra così.
- **Prova:** test `riscaldamentoPrendeIKgDiLavoro` (kg = 100, rip = 5).
- **Correzione:** per le serie di riscaldamento cercare la serie corrispondente tra i *riscaldamenti* dell'ultima volta (`precedenteRiscaldamento(esercizio, k)`); se non c'è, nessun valore proposto (nella spunta manca → «Scrivi i kg»).

### 5. Allenamento lasciato aperto e chiuso il giorno dopo: durata di 20+ ore — media/bassa
- **Dove:** `ArchivioPalestra.swift:172` (`a.fine = a.fine ?? Date()`). Nessun controllo su un allenamento in corso dei giorni prima (`HomeView.swift:168`, `AllenamentoView.swift:110` mostrano solo «In corso / Riprendi»).
- **Cosa vede l'utente:** il riepilogo dice «Durata 26 h 00 min» con la differenza dall'ultima volta in minuti. «Questa settimana: … · 27 h» in Palestra (`durataSettimana`, `ArchivioPalestra.swift:527-532`) resta gonfiato per tutta la settimana. L'allenamento è contato nel giorno di inizio. Insieme al punto 2 è lo scenario «riaperto il giorno dopo».
- **Prova:** test `allenamentoFinitoIlGiornoDopo` (durata > 24 h).
- **Correzione:** in `termina`, se `Date() - inizio` supera una soglia (es. 4 h), usare come fine l'ora dell'ultima serie spuntata (serve un `fattaIl: Date?` tollerante su `SerieFatta`) o `inizio + durata stimata`. In Oggi/Palestra, un allenamento in corso di un giorno passato dovrebbe chiedere «Finiscilo o annullalo».

### 6. Programma della settimana: crash con un piano di meno di 7 giorni — bassa (solo con dati importati/modificati)
- **Dove:** `SezioniPalestra.swift:125-126` legge e scrive `palestra.stato.piani[w]?[i]` per `i in 0..<7` senza controllo. La decodifica (`ModelliPalestra.swift:324`) accetta qualsiasi lunghezza. `programmato` (`ArchivioPalestra.swift:115-117`) invece controlla gli indici.
- **Cosa vede l'utente:** importa un backup con `"A"` di 5 giorni e apre «Programma della settimana»: l'app si chiude (indice fuori dai limiti). Se manca `"B"`, i picker della settimana B non salvano niente: la scelta torna su «Riposo».
- **Prova:** test `pianoCortoSiDecodifica` (count 5, B nil). Il crash della vista l'ho dedotto leggendo il codice, non l'ho provato nell'interfaccia.
- **Correzione:** in `StatoPalestra.init(from:)` portare ogni piano a 7 giorni (completare con `.riposo`) e aggiungere le chiavi A/B mancanti dal piano base. In alternativa getter/setter con `indices.contains`.

### 7. Una serie spuntata e poi svuotata resta «fatta» ma sbagliata — bassa
- **Dove:** `AllenamentoInCorsoView.swift:569-577`: i campi di una serie fatta restano modificabili e `modifica { $0.kg = leggiNumero(v) }` scrive nil senza togliere la spunta. `termina` (`ArchivioPalestra.swift:175`) tiene `fatta && rip > 0`.
- **Cosa vede l'utente:** se cancella i kg di una serie fatta, la serie si salva ma non conta (`valida` = false): volume e serie non tornano, e lo storico mostra «0 kg × 8». Se cancella le ripetizioni, la serie sparisce alla fine senza avviso: «Fine» non la conta tra quelle senza spunta.
- **Prova:** test `serieFattaSvuotata` (3 serie fatte → 2 salvate, 1 valida).
- **Correzione:** se un campo di una serie fatta diventa vuoto, togliere la spunta (o non scrivere nil e ripristinare il valore). Contare queste serie nel messaggio di «Fine».

### 8. Solo serie di riscaldamento spuntate → «Nessuna serie spuntata», e chiudendo si perde tutto — bassa
- **Dove:** `AllenamentoInCorsoView.swift:153` usa `a.serieFatte`, che esclude il riscaldamento (`ModelliPalestra.swift:237`). Poi `:106` → `annulla()`.
- **Cosa vede l'utente:** il messaggio è falso (ha spuntato delle serie) e «Chiudi» butta le serie fatte.
- **Prova:** test `soloRiscaldamentoContaZero`.
- **Correzione:** per la conferma contare `filter(\.fatta)`, non `valida`.

### 9. Live Activity: numero della serie diverso dall'app quando c'è il riscaldamento — bassa
- **Dove:** `LiveAllenamento.swift:43-44` (`serie = j + 1`, `totaleSerie = e.serie.count` contano anche i riscaldamenti). `RecuperoWidget.swift:253-257`, Dynamic Island compatta `:78`. Nell'app (`AllenamentoInCorsoView.swift:546, 559`) il riscaldamento è «R» e le serie di lavoro partono da 1.
- **Cosa vede l'utente:** nell'app «Serie 1», sulla schermata bloccata «Serie 2 di 4».
- **Prova:** test `numeroSerieLiveConRiscaldamento` (serie = 2, totale = 4).
- **Correzione:** usare lo stesso conteggio dell'app (serie di lavoro prima di j, più 1; totale = serie di lavoro), lasciando «Riscaldamento» per le serie R. Va scelto in modo coerente con il test esistente `serieDiRiscaldamento`.

### 10. Esercizi a corpo libero: nessun record viene mai festeggiato — bassa
- **Dove:** `ArchivioPalestra.swift:306-310` (`nuoviRecord`) e `:486-489` (`conteggioRecord`) confrontano solo peso massimo e massimale. Con kg = 0 sono sempre 0. «Più ripetizioni» esiste solo nel dettaglio dell'esercizio (`StoricoView.swift:35`).
- **Cosa vede l'utente:** passa da 10 a 15 trazioni o addominali e non compare nessun «Nuovo record», né nel riepilogo né nel conteggio dello storico.
- **Correzione:** se kg = 0 (o attrezzo `corpoLibero`), confrontare `ripMax`.

### 11. «Questa settimana: N allenamenti» dà due numeri diversi — bassa
- **Dove:** `AllenamentoView.swift:98` usa `allenamentiSettimana` (pesi **più cardio**, `ArchivioPalestra.swift:520-524`). `StoricoView.swift:142` usa `riepilogoSettimana.allenamenti` (solo pesi). Entrambi si chiamano «allenamenti».
- **Cosa vede l'utente:** con 2 pesi e 1 corsa, Palestra dice 3 e «Tutti gli allenamenti» dice 2.
- **Correzione:** stessa definizione in entrambi, oppure etichetta «Pesi» nello storico.

---

## Sospetti (letti nel codice, non provati o dipendenti dall'intenzione)

- **S1. Live Activity bloccata sul riscaldamento — media se non è voluto.** `LiveAllenamento.swift:19-31`: finché non c'è nessuna serie spuntata e manca un movimento, la Live mostra solo i 6 movimenti. Chi non fa il riscaldamento non può spuntare serie dalla schermata bloccata finché non segna 6 volte «Fatta» o una serie nell'app. Succede anche dopo `compila` (sessione del Watch già finita). Proposta: passare alle serie quando l'utente tocca una serie nell'app, oppure aggiungere «Salta riscaldamento».
- **S2. La Live Activity chiusa con uno swipe torna a ogni modifica.** `LiveAllenamento.swift:195-208`: se l'attività non è più `viva`, `avvia` ne chiede una nuova a ogni cambio di stato. Va bene se è voluto («può essere sparita»), ma l'utente non riesce a toglierla durante l'allenamento.
- **S3. Cardio doppio, manuale + Watch.** `ArchivioPalestra.swift:237-242` aggiunge il cardio del Watch senza confrontarlo con un cardio scritto a mano lo stesso giorno e dello stesso tipo. I conteggi della settimana raddoppiano.
- **S4. Fuso orario fisso fino al riavvio.** `Utilita.swift:48-53`: `Giorni.calendario` è creato una volta con il fuso di quel momento. Se l'utente viaggia senza chiudere l'app, `giorno` degli allenamenti, calendario e settimana usano il fuso vecchio. Vicino a mezzanotte l'allenamento finisce nel giorno sbagliato. Proposta: `c.timeZone = .autoupdatingCurrent` o un calendario calcolato ogni volta.
- **S5. Import dal Watch rimandato.** `LetturaWatch.swift:36` (al massimo una lettura al minuto) e `Salute.swift:79` (`importando`): se l'osservatore scatta entro 60 s da una lettura fatta all'apertura, la sessione nuova entra solo alla prossima apertura dopo 60 s o al prossimo risveglio (orario). Non si perde nulla grazie all'ancora, arriva solo in ritardo, e la notifica arriva solo se la sessione è finita da meno di 3 h (`Salute.swift:84`).
- **S6. Notifica del recupero con durata vecchia.** `TimerRecupero.swift:87-97` poi `avvia`: `ferma()` azzera `compitoNotifica`, quindi il nuovo `programma` non aspetta l'aggiunta precedente ancora in corso. Se quella finisce dopo, la notifica «recupero» (stesso id) ha la durata vecchia. Succede solo con «Salta» e una nuova spunta entro pochi millisecondi.
- **S7. Indice catturato nel menu dell'esercizio.** `AllenamentoInCorsoView.swift:488-499, 429`: setter del Picker del recupero, «Sposta su/giù» e «Aggiungi serie» usano la `i` di quando è stata disegnata la vista (lo stesso schema corretto da #19 per l'editor). Oggi nessun percorso cambia l'elenco con il menu aperto (la Live Activity non toglie esercizi), quindi è solo fragilità.
- **S8. «Aggiungi serie» copia i valori di un riscaldamento.** `AllenamentoInCorsoView.swift:428-429`: se l'ultima serie è di riscaldamento (o non è ancora fatta), la nuova serie di lavoro parte con quei kg già scritti, che nascondono il segnaposto dell'ultima volta.

## Verificati senza problemi
- HealthKit: solo lettura (`toShare: []`), quindi niente scritture doppie. Con il permesso negato si leggono 0 allenamenti, senza errori. I duplicati sono evitati con `importati`.
- Intent «Fatta» con l'allenamento finito o la serie eliminata: `segnaDaLive` non fa niente e `aggiornaEAttendi` chiude l'attività (`applica(nil)` con `haAttivita`). Il doppio tocco è innocuo (serie già fatta).
- Recupero in background: niente vibrazione in ritardo (`TimerRecupero.swift:70`), la notifica ha un minimo di 1 s (`Notifiche.swift:28`), ±15 s sotto zero ferma il timer, un recupero scaduto viene tolto dalla Live (`LiveAllenamento.swift:88`) e `staleDate` copre l'app sospesa.
- Intervalli di date nel widget protetti (`RecuperoWidget.swift:241`). Decodifica tollerante su tutti i modelli della palestra, compreso `ultimaSerie`.
- Settimana A/B con date prima del 29/12/2025 e attraverso l'ora legale: corretta (`rounded(.down)` e differenza in giorni di calendario).
