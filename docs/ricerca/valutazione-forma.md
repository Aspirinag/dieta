# Forma — valutazione euristica di ogni schermata

Data: 5 novembre 2026. Branch `grafica` (commit `6f1814a`, «WIP grafica»: della nuova grafica c'è solo la correzione del margine destro; Oggi, Dieta e le altre schermate sono ancora quelle di `main`, l'allenamento in corso è quello compatto del commit `2504908`).

Metodo: build sul simulatore **iPhone Duo** (`9A22E06F-…`, colonna di sistema a destra, 466 × 678 pt), avvio con `-demo`, prova in chiaro, in scuro e con il testo di accessibilità più grande (`accessibility-extra-extra-extra-large`); le sotto-schermate sono state raggiunte toccando sul simulatore, i dettagli che non si vedono sono stati letti nel codice (`iOS/Forma/…`). Schermate salvate in `/private/tmp/claude-501/forma-eval/` (`L-` chiaro, `D-` scuro, `AX-` testo massimo). Ogni problema rimanda a una regola di `checklist-forma.md`.

**Gravità (Nielsen):** 0 non è un problema · 1 estetico · 2 minore · 3 grave, da correggere presto · 4 catastrofico, da correggere prima di tutto.
**Lavoro:** S poche righe in un file · M una vista o un componente · L più viste o un componente nuovo condiviso.

---

## Sintesi

Forma è veloce (quasi tutto a 1 tocco) ma **sembra un insieme di pezzi**: quattro tipi di spunta diversi (cerchio pieno in Oggi, cerchio in Dieta e Spesa, quadrato nell'allenamento, «Segna come fatto» con cerchio nel dettaglio), il verde usato per sei significati diversi (fatto, pulsante, link, nome dell'esercizio, valore precedente, peso che scende), riquadri bianchi per ogni cosa, frasi composte («Oggi riposo»), tre formati di data. Due problemi sono **di sostanza**, non di gusto: lo stesso totale settimanale vale 8.565 kg in una schermata e 17.130 kg in un'altra, e i moduli mostrano numeri grigi («30» minuti) che sembrano dati ma non si salvano. Con il testo grande i numeri principali **rimpiccioliscono** rispetto alle etichette perché scritti a dimensione fissa.

### I problemi più gravi (gravità 3–4)

| # | Schermata | Problema | Regola | Grav. |
|---|---|---|---|---|
| 1 | Progressi › Palestra / Allenamenti | «Questa settimana» vale 8.565 kg in Progressi e 17.130 kg in Allenamenti (ultimi 7 giorni contro settimana da lunedì) | F3 | 4 |
| 2 | Cardio, Peso veloce | Il numero grigio nel campo («30», ultimo peso) sembra un valore ma non si salva; «✓» resta spento senza spiegazione | I1, E2 | 3 |
| 3 | Tutte | Quattro spunte diverse e il verde con sei significati: l'app non sembra una sola | V4, C1 | 3 |
| 4 | Oggi, Progressi, Palestra | Numeri principali a dimensione fissa (`.system(size: 34)`): con testo grande il peso è più piccolo dell'etichetta «Peso» | T1, A1 | 3 |
| 5 | Oggi | Alimenti troncati («Yogurt greco…») a ogni dimensione grande: si perdono proprio le grammature | A1 | 3 |
| 6 | Palestra | Cinque funzioni (tra cui Registra cardio e Programma) nascoste dietro un «+» senza testo; «Prossima scheda» ripetuta nella lista | S2, S3 | 3 |
| 7 | Allenamento in corso | Con testo grande testata, riscaldamento e primo esercizio occupano tutto lo schermo: la prima serie non si vede | G1, A1 | 3 |
| 8 | Allenamento in corso | Cambiare il peso richiede tastiera (3 tocchi + cifre); nessun ±; nessuna Live Activity per il recupero | G2, G3 | 3 |
| 9 | Oggi, Progressi | Peso che scende scritto in verde (giudizio) e «−3,1 kg» dall'inizio, non da 30 giorni | M1, M3 | 3 |
| 10 | Impostazioni | Raggiungibili solo dall'ingranaggio di Oggi | S4 | 3 |
| 11 | Progressi › Palestra › record | Il dettaglio esercizio una volta è rimasto **bianco senza titolo** per oltre 6 s (alla seconda prova si è aperto subito): da riprodurre | S5 | 3 |
| 12 | Oggi, cucchiaini e gocce | Elementi vuoti a 1,3:1 (chiaro) e 1,6:1 (scuro), cucchiaino pieno giallo a 2,3:1 sul bianco | C3, A3 | 3 |

---

## Conteggio dei tocchi per le azioni di ogni giorno

Da app aperta sulla scheda Oggi (dove si apre). Hevy dove c'è un equivalente (da documentazione e schermate promozionali, `linee-guida-genere-e-hevy.md` §5).

| Azione | Forma oggi | Obiettivo | Hevy | Nota |
|---|---|---|---|---|
| Spuntare un pasto | 1 | 1 | — | ok |
| Cambiare l'alternativa di un pasto | 2 (riga → segmento) + indietro | 2, anche da Oggi con tocco lungo | — | il nome cambia tra lista («oppure pasta integrale») e segmento («Pasta») |
| Un cucchiaino d'olio / una goccia | 1 | 1 | — | ok, ma bersagli vuoti poco visibili |
| Pesarsi (stesso peso di ieri) | 1 + cifre + Salva = 2 tocchi + 4 cifre | 2 (± o «Uguale a ieri») | 2–3 («+», valore, Salva) | l'ultimo peso è solo grigio, non si salva |
| Iniziare la scheda del giorno | 1 («Inizia» in Oggi) nei giorni di pesi; 3 nei giorni di riposo («Allenati lo stesso» porta solo alla scheda Palestra, poi Inizia) | 1 | 2 (Workout → Start Routine) | |
| Serie uguale all'ultima volta | 1 | 1 | 1 | ok, il recupero parte da solo |
| Serie con 2,5 kg in più | 3 tocchi + cifre (campo, cancella, scrivi, spunta) | 2 (+2,5, spunta) | 2 + cifre | manca il ± |
| Finire l'allenamento | 3 (Fine → Finisci e salva → Fine del riepilogo) | 2 | 2–3 (Finish → Save) | la conferma non dice quante serie non spuntate si perdono |
| Registrare un cardio non previsto | 4 + cifre (Palestra → + → Registra cardio → minuti → ✓) | 3 | — | i «30» minuti grigi non valgono |
| Spuntare un prodotto della spesa | 3 la prima volta (Dieta → carrello → prodotto), poi 1 | 2 | — | |
| Aprire le Impostazioni da Palestra | 2 (Oggi → ingranaggio) | 1 | 1 (Profilo → ingranaggio è 2) | |

**Conclusione:** il numero di tocchi va bene; vanno corretti cardio, peso, peso della serie e il «riposo» di Oggi. Il resto del lavoro è visivo.

---

## Oggi

Schermate: `L-oggi.png`, `L-oggi-sotto.png`, `D-oggi.png`, `AX-oggi.png`. Codice: `iOS/Forma/HomeView.swift`.

| # | Regola | Grav. | Cosa vede o fa l'utente | Correzione | Lavoro |
|---|---|---|---|---|---|
| O1 | A1 | 3 | A testo grande gli alimenti di tutti i pasti diventano «Yogurt greco…», «Riso basmati…»: non si vedono le grammature. Anche a testo normale la cena è tagliata («pane in…»). | Togliere `.lineLimit(1)` (HomeView ~r.155): alimenti su più righe, con `lineLimit(dimensione.isAccessibilitySize ? nil : 2)`. | S |
| O2 | V1, S3 | 2 | Sei riquadri bianchi impilati; «Oggi riposo» occupa un riquadro intero per una riga; le note stanno in un riquadro a sé in fondo. | Una sola `List` raggruppata con sezioni Pasti · Allenamento · Olio e acqua · Peso; le note come piè della sezione Olio e acqua (o in Dieta). Vedi spec, pacchetto P2. | L |
| O3 | T2 | 2 | «Oggi riposo», «Oggi cardio»: frasi composte; la data è «Giovedì 5 Novembre» con il mese maiuscolo. | Riga allenamento: titolo «Riposo» / «Cardio · 30 min» / nome scheda; data con `.formatted(.dateTime.weekday(.wide).day().month(.wide))` **senza** `.capitalized` (r.20). | S |
| O4 | I5, S1 | 3 | Nei giorni di riposo «Allenati lo stesso» porta solo alla scheda Palestra: servono altri 2 tocchi. | «Allenati lo stesso» apre un menu con le schede (come `SceltaSchedaView`) e avvia direttamente quella scelta. | M |
| O5 | V3 | 1 | Barra a segmenti «1 di 4» ripete l'informazione delle spunte. | Togliere `BarraSegmenti`; «1 di 4» nell'intestazione della sezione. | S |
| O6 | C3, A3 | 3 | Cucchiaini e gocce vuoti quasi invisibili (`systemFill`: circa 1,3:1 sul bianco, 1,6:1 sul grigio scuro); il giallo dell'olio pieno è 2,3:1 sul bianco. | Colore `Colori.vuoto` con ≥ 3:1 (es. contorno `.secondary` 1,5 pt + riempimento leggero); olio pieno più scuro in chiaro (#B07F0C, ≈ 3,4:1) o con contorno. Test di contrasto. | M |
| O7 | M1, M3 | 3 | Peso «−3,1 kg» in verde: confronto con la prima pesata e verde = «bravo». | Variazione rispetto a 30 giorni fa, colore `.secondary`, testo «−0,8 kg in 30 giorni». | S |
| O8 | T1, A1 | 3 | Il peso «81,1» è a 34 pt fissi: a testo grande diventa più piccolo dell'etichetta. | `.font(.largeTitle.weight(.bold))` con `.monospacedDigit()` (o `.numero(.largeTitle)` del sistema visivo). | S |
| O9 | I5 | 2 | Pesarsi: tocco sul riquadro, cifre, Salva; l'ultimo peso è solo grigio. | Nel foglio peso: valore precompilato con l'ultimo peso e due pulsanti −0,1 / +0,1, «Salva» attivo subito. | M |
| O10 | P2 | 1 | Ingranaggio e profilo in alto (colonna destra: raggiungibile, ok sul Duo; su iPhone normale in alto a destra). | Nessuna modifica di posto; l'ingranaggio va però in tutte le schede (vedi Impostazioni). | — |
| O11 | V4 | 2 | La spunta del pasto è un cerchio pieno verde con segno bianco (24 pt) diverso da quella di Dieta e dell'allenamento. | Un solo componente `CerchioSpunta` ovunque. | M (pacchetto P1) |

## Dieta

Schermate: `L-dieta.png`, `AX-dieta.png`. Codice: `iOS/Forma/Dieta/DietaView.swift`.

| # | Regola | Grav. | Cosa vede o fa l'utente | Correzione | Lavoro |
|---|---|---|---|---|---|
| D1 | V1 | 2 | Ogni pasto è un riquadro separato (4 riquadri + spesa + striscia giorni = 6 riquadri). | `List` raggruppata, una sezione «Pasti · 1 di 4» con una riga per pasto. | M |
| D2 | S3 | 2 | La spesa ha due porte: il carrello nella barra e il riquadro «Spesa della settimana» in fondo. | Tenere solo il carrello nella barra, con conteggio nell'etichetta di accessibilità; togliere il riquadro. | S |
| D3 | C1, T2 | 2 | «oppure pasta integrale» in verde sotto il pranzo: sembra un link, e nel dettaglio la stessa alternativa si chiama «Pasta». | Riga grigia «Alternativa: riso (1 di 2)»; stesso nome nel segmento del dettaglio. | S |
| D4 | P4 | 2 | Nella riga ci sono due frecce di significato diverso: «›» (apre) e il cerchio (spunta), vicini; la freccia sta in alto, non centrata. | Freccia a destra centrata come accessorio di riga; cerchio a sinistra (come Spesa) così la spunta è sempre nello stesso posto. | S |
| D5 | C4 | 1 | I puntini sotto i giorni (fatto/non fatto) sono distinti solo dal colore. | Tenere i puntini ma con forma piena/vuota (cerchio pieno = fatto, contorno = da fare). | S |
| D6 | S4 | 2 | Nessun ingranaggio: per cambiare il piano bisogna tornare a Oggi. | `PulsanteImpostazioni` in barra. | S (pacchetto P1) |

## Dettaglio pasto

Schermata: `L-dettaglio-pasto.png`. Codice: `iOS/Forma/Dieta/DettaglioPastoView.swift`.

| # | Regola | Grav. | Cosa vede o fa l'utente | Correzione | Lavoro |
|---|---|---|---|---|---|
| DP1 | V4, S1 | 2 | «Segna come fatto» è un riquadro con un cerchio: una terza forma di spunta. | Pulsante «Fatto» pieno in barra a destra (`.confirmationAction`), che diventa «Fatto ✓» e si annulla ritoccando. | S |
| DP2 | V2 | 1 | Metà schermo vuota; «Giovedì 5» è una riga grigia dentro il riquadro. | Giorno nel sottotitolo della barra; sotto gli alimenti le note del nutrizionista per quel pasto, se ci sono. | S |
| DP3 | T2 | 2 | Segmento «Pasta / Riso» ma lista «oppure pasta integrale»: nomi diversi per la stessa cosa. | Una funzione unica `Pasto.nomeAlternativa` usata da lista e segmento. | S |

## Spesa

Schermata: `L-spesa.png`. Codice: `iOS/Forma/Dieta/SpesaView.swift`, `Dieta/Archivio.swift` (~r.355).

| # | Regola | Grav. | Cosa vede o fa l'utente | Correzione | Lavoro |
|---|---|---|---|---|---|
| SP1 | T3 | 2 | «Insalata · 7 porzioni»: non si compra a porzioni. | Alimenti senza grammi «a piacere» (testo in `testoQuantita`). | S |
| SP2 | S3 | 1 | Barra di avanzamento grigia sotto «0 di 11 presi»: ripete il numero. | Togliere la `ProgressView` (r.105). | S |
| SP3 | F2 | 2 | I prodotti presi restano al loro posto: con la lista lunga quello che manca si perde. | Presi in fondo alla sezione, barrati e grigi, con animazione. | S |
| SP4 | P2 | 1 | «Indietro», «Condividi» e «…» sono in colonna a destra; le frecce della settimana in alto, lontane. | Ok sul Duo; nessuna modifica. | — |

## Palestra

Schermate: `L-allenamento.png`, `L-palestra-piu.png`, `AX-allenamento.png`, `D-allenamento.png`. Codice: `iOS/Forma/Palestra/AllenamentoView.swift`, `SezioniPalestra.swift`.

| # | Regola | Grav. | Cosa vede o fa l'utente | Correzione | Lavoro |
|---|---|---|---|---|---|
| PA1 | S2 | 3 | Il «+» senza testo contiene Nuova scheda, Schede pronte, Libreria esercizi, Programma della settimana, Registra cardio: cinque funzioni, due usate ogni settimana. | «+» solo per «Nuova scheda». In fondo una sezione «Altro» con righe: Registra cardio, Programma della settimana, Libreria esercizi, Schede pronte. | M |
| PA2 | S3 | 2 | «Push (spinta)» è sia nel riquadro «Prossima scheda» sia nella lista. | Lista «Altre schede» senza quella già in alto. | S |
| PA3 | V1, M2 | 2 | Un riquadro intero per sette pallini L-M-M-G-V-S-D; a testo grande diventano «LMMGVSD» attaccati e il riepilogo si taglia. | Intestazione della lista: «Questa settimana: 3 allenamenti · 2 h 22 min» (testo, va a capo). Niente pallini. | S |
| PA4 | C1, V4 | 2 | ▶ verde in un cerchio grigio-verde per ogni scheda; «Allenamento libero» è una riga di testo verde in fondo alla lista. | ▶ semplice (`play.fill`, `.secondary`) come accessorio; «Allenamento libero» nella sezione «Altro». | S |
| PA5 | T2 | 1 | Nomi demo misti: «Push (spinta)», «Legs (gambe)». | Demo in italiano: «Spinta», «Tirata», «Gambe». | S |
| PA6 | S4 | 2 | Nessun ingranaggio. | `PulsanteImpostazioni` in barra. | S (P1) |

### Menu «+», editor della scheda, libreria, schede pronte, programma, cardio

Schermate: `L-palestra-piu.png`, `L-editor-scheda.png`, `L-libreria.png`, `L-esercizio-libreria.png`, `L-schede-pronte.png`, `L-programma.png`, `L-cardio.png`.

| # | Regola | Grav. | Cosa vede o fa l'utente | Correzione | Lavoro |
|---|---|---|---|---|---|
| PA7 | S3 | 2 | Editor: il nome «Scheda pesi» è sia nel titolo sia nella prima riga (campo). | Il nome si cambia toccando il titolo (`navigationTitle($nome)` rinominabile) o con «Rinomina» nel menu; togliere la riga. | S |
| PA8 | V4 | 1 | Editor: frecce «›» nere e spesse; altrove grigie e sottili. | Accessorio di riga di sistema (`NavigationLink` normale), mai `chevron.right` disegnato a mano. | S |
| PA9 | S1, S2 | 2 | Editor: l'azione «Inizia» è un ▶ verde senza testo nella colonna; «Modifica» è un pulsante a capsula in alto. | «Inizia» pulsante pieno con testo in fondo alla lista (o barra in basso); «Modifica» testo semplice. | S |
| PA10 | V4 | 2 | Libreria ed editor: 5 esercizi su 6 hanno lo stesso omino generico, in un cerchio verde chiaro. | Omino solo se c'è il disegno della macchina; altrimenti nessuna icona, oppure un simbolo per gruppo muscolare in grigio. | M |
| PA11 | S2 | 2 | Libreria: 198 esercizi e la ricerca non si vede finché non si scorre verso il basso. | `.searchable(..., placement: .navigationBarDrawer(displayMode: .always))`. | S |
| PA12 | T3 | 2 | Schede pronte: «Plank 3 × 30–45» senza unità. | «3 × 30–45 s». | S |
| PA13 | E1, T2 | 2 | Programma: «Scambia A e B» è un interruttore, ma è un'azione una tantum; «Questa settimana B» è una riga in sola lettura. | Riga «Questa settimana: B» con pulsante «Scambia» (azione, si annulla ritoccando); togliere l'interruttore. | S |
| PA14 | I1, E2 | 3 | Cardio: «Minuti 30» e «Km 0» sono segnaposto grigi; il ✓ resta spento senza spiegazione. | Minuti precompilati con l'ultimo cardio dello stesso tipo (o 30) **come valore**, Km vuoto con etichetta «facoltativo»; Stepper ±5 min. | S |
| PA15 | P1 | 1 | Libreria: filtri «Muscolo» e «Attrezzo» a capsula da circa 34 pt di altezza. | `controlSize(.large)` o `minHeight: 44`. | S |
| PA16 | T2 | 1 | Dettaglio esercizio: «Serie migliore (kg × ripetizioni) 450 kg»: un prodotto chiamato kg; «Massimale stimato» senza spiegazione. | «Serie migliore: 37,5 kg × 12»; «Massimale stimato (1 ripetizione)» con nota a piè. | S |
| PA17 | M3 | 1 | Dettaglio esercizio: la linea del grafico è curva (`.monotone`) e inventa valori tra i punti. | `.interpolationMethod(.linear)` o solo punti con linea a gradini. | S |

## Allenamento in corso

Schermate: `L-inCorso.png`, `D-inCorso.png`, `AX-inCorso.png`, `L-fine.png`. Codice: `iOS/Forma/Palestra/AllenamentoInCorsoView.swift`, `TimerRecupero.swift`.

Questa schermata è già la più vicina a Hevy (valore precedente, prefill, spunta che avvia il recupero, ±15 s). I problemi sono di coerenza e di dettaglio.

| # | Regola | Grav. | Cosa vede o fa l'utente | Correzione | Lavoro |
|---|---|---|---|---|---|
| IC1 | C1 | 2 | Nomi degli esercizi in verde (`.tint`), numeri delle serie verdi, valori «Precedente» verdi, «Aggiungi serie» verde, cronometro verde, spunta verde: il verde non vuol più dire «fatto». | Nomi e cronometro `.primary`; «Precedente» `.secondary` (resta toccabile, con sottolineatura leggera o icona ↺ al tocco lungo); verde solo per serie fatta e «Fine». | S |
| IC2 | V4, F2 | 2 | Spunta quadrata (`checkmark.square`) diversa dal cerchio di tutte le altre schermate; la riga fatta ha un velo verde al 20 %, poco distinguibile in scuro. | `CerchioSpunta` da 28 pt in area 44; riga fatta con sfondo accento al 25 % in chiaro e 35 % in scuro, cifre in semibold. | S |
| IC3 | G1, A1 | 3 | A testo grande cronometro, «2.800 kg · 4 serie» su due righe, «Riscaldamen-to · 3/6» spezzato, «Leg press · 3 serie ✓»: la prima serie da fare è fuori schermo. | Testata in una riga sola anche a testo grande (cronometro a sinistra, «4 serie» a destra, kg nascosti in accessibilità); riscaldamento compresso in un'icona con conteggio nella stessa riga; esercizio completato ridotto a una riga di 44 pt. | M |
| IC4 | G2, I2 | 3 | Per cambiare il peso: tocco sul campo, cancellare, scrivere, spunta. | Barra sopra la tastiera con «−2,5» «+2,5» (e «−1» «+1» per le ripetizioni); oppure tocco lungo sul campo = +2,5. | M |
| IC5 | G3 | 3 | Il recupero si vede solo dentro l'app: bloccando il telefono non c'è Live Activity. | Live Activity con nome esercizio, recupero e ±15 (ActivityKit, nuovo target). | L |
| IC6 | T2, V4 | 2 | Due pulsanti «Fine» diversi: chiudere l'allenamento (barra) e chiudere la tastiera (barra sopra la tastiera). | Sopra la tastiera: «Chiudi» o freccia giù, non «Fine». | S |
| IC7 | E1 | 2 | «Finire l'allenamento? Le serie senza spunta non vengono salvate»: non dice quante. | «8 serie senza spunta non verranno salvate.» con il numero; se sono 0, nessuna conferma. | S |
| IC8 | P3 | 2 | «Annulla allenamento» è sia nel menu «…» sia in fondo alla lista, rosso, subito sotto «Aggiungi esercizio». | Solo nel menu «…» (con conferma). | S |
| IC9 | F1, G5 | 2 | Finire senza nessuna serie spuntata scarta l'allenamento (`ArchivioPalestra.termina`) e chiude la schermata **senza dirlo**: nessun riepilogo, nessun messaggio. | Con 0 serie fatte, «Fine» chiede «Nessuna serie spuntata: chiudere senza salvare?» con «Chiudi» e «Continua». | S |
| IC10 | E3 | 2 | Spuntare una serie senza kg dà solo una vibrazione di errore e sposta il cursore. | Il campo vuoto si colora con contorno arancione e sotto compare «Scrivi i kg». | S |

## Riepilogo di fine allenamento

Schermata: `L-riepilogo.png`. Codice: `iOS/Forma/Palestra/StoricoView.swift` (`RiepilogoView`).

| # | Regola | Grav. | Cosa vede o fa l'utente | Correzione | Lavoro |
|---|---|---|---|---|---|
| R1 | F4 | 2 | Medaglia verde con «Allenamento finito!» e nome: tono generico; i dati sono una lista Data/Durata/Kg/Serie senza confronto. | Titolo con il nome della scheda; tre numeri grandi in riga (Durata · Kg · Serie) con la differenza rispetto all'ultima volta della stessa scheda («+120 kg»), poi i record. Niente punto esclamativo né medaglia. | M |
| R2 | T2 | 1 | «mercoledì 4 novembre alle ore 23:58» come riga «Data»: informazione inutile appena finito. | Togliere la riga Data dal riepilogo (resta nel dettaglio storico). | S |

## Progressi › Corpo

Schermate: `L-progressi.png`, `D-progressi.png`, `AX-progressi.png`, `L-corpo-piu.png`, `L-editor-misura.png`, `L-misura-esistente.png`. Codice: `iOS/Forma/Dieta/CorpoView.swift`, `Dieta/EditorMisura.swift`.

| # | Regola | Grav. | Cosa vede o fa l'utente | Correzione | Lavoro |
|---|---|---|---|---|---|
| C-1 | T1, A1 | 3 | A testo grande «81,1» resta piccolo mentre «Peso» e «−3,1 kg» diventano enormi; i tre pulsanti periodo vanno uno sotto l'altro. | Numero con stile di sistema; periodo con `Picker(.segmented)` sotto il grafico. | S |
| C-2 | M1, M3 | 3 | «−3,1 kg» verde, rispetto alla prima misura; Grasso «−2,6 kg» verde, Magra «−0,5 kg» grigio: il colore giudica. | Variazioni tutte `.secondary` con segno, rispetto a 30 giorni fa, con l'etichetta «in 30 giorni». | S |
| C-3 | S3, V1 | 2 | «Pasti segnati negli ultimi 7 giorni: 64 %» nel riquadro del peso: dato della dieta nel posto sbagliato. | Togliere (eventualmente in Dieta). | S |
| C-4 | V1 | 2 | Grafico alto un terzo dello schermo con una sola linea dritta; tre riquadri BIA senza data. | Grafico alto ~25 % con pesate come punti e linea di tendenza; misure BIA in una tabella «ultima (3 nov) · precedente · differenza». | M |
| C-5 | S2 | 1 | Menu «+»: «Aggiungi misurazio-ne» va a capo con il trattino a testo normale. | Testo «Nuova misura». | S |
| C-6 | I3, I4 | 2 | Editor BIA nuovo: 13 righe vuote con «–», nessun valore precedente; le unità non sono in colonna (kcal, cm² sporgono). | Valore precedente in grigio sotto ogni etichetta («ultima: 81,1 kg»); colonna delle unità a larghezza fissa. | M |
| C-7 | T2 | 1 | Data «5 nov 2026» nel nuovo, «03/11/2026» nella modifica. | Stesso `DatePicker` compatto in entrambi. | S |
| C-8 | C1 | 1 | «Tutte» delle misurazioni in verde come i pulsanti. | Riga «Tutte le misurazioni ›» in fondo alla sezione. | S |

## Progressi › Palestra (+ storico, calendario, dettaglio esercizio)

Schermate: `L-prog-palestra.png`, `L-storico.png`, `L-storico-dettaglio.png`, `L-calendario.png`, `L-esercizio.png` (vuota), `L-record-esercizio.png`. Codice: `Palestra/ProgressiPalestraView.swift`, `StoricoView.swift`, `CalendarioView.swift`.

| # | Regola | Grav. | Cosa vede o fa l'utente | Correzione | Lavoro |
|---|---|---|---|---|---|
| PP1 | F3 | 4 | Progressi: «8.565 kg questa settimana». Allenamenti: «Questa settimana 3 · Kg totali 17.130 kg». Il primo conta da lunedì, il secondo gli ultimi 7 giorni (`StoricoAllenamenti.statistiche`, `Date() - 7×86400`). | Una sola funzione `StatoPalestra.settimana(corrente)` da lunedì usata ovunque; etichetta «Questa settimana» solo per quella. | S |
| PP2 | M3, C4 | 2 | Istogramma: settimana in corso in verde pieno, più bassa delle altre (verde sbiadito); nessun asse y; sembra un calo. | Settimane intere in accento pieno, la settimana in corso con riempimento a righe o contorno e scritta «finora»; asse y con 2 valori. | S |
| PP3 | S5 | 3 | Toccando un record la pagina dell'esercizio è rimasta vuota (nessun titolo, nessun contenuto) per oltre 6 s; alla seconda prova si è aperta subito. Possibile doppia registrazione di `navigationDestination(for: Esercizio.self)` nella stessa pila (`ProgressiView` + `destinazioniArchivioPalestra`). | Riprodurre; tenere una sola registrazione per tipo per pila; se il calcolo di `andamento`/`storico` è lento, farlo una volta in `task`. | M |
| PP4 | C1 | 1 | «Tutti» e «Calendario» link verdi affiancati nell'intestazione. | Righe «Tutti gli allenamenti ›» e «Calendario ›» in cima alla sezione. | S |
| PP5 | M2, C4 | 2 | Calendario: legenda «Pallino pieno: pesi o cardio fatti. Grigio: in programma. ✕: saltato.» — il segno «saltato» è colpa; pieno/chiaro/grigio solo colore. | Togliere «saltato»; fatto = pallino pieno, in programma = contorno; legenda come aiuto VoiceOver. | S |
| PP6 | T2 | 1 | Calendario: «Giovedì 05/11/2026». | «giovedì 5 novembre». | S |
| PP7 | V1 | 2 | Dettaglio di un allenamento: una riga per serie (21 righe per la Scheda pesi). | Una riga per esercizio: «Leg press  77,5 × 12 · 11 · 10». | M |
| PP8 | C1 | 1 | Dettaglio: nomi degli esercizi (intestazioni) in verde. | Intestazioni `.primary` con freccia. | S |
| PP9 | S3 | 1 | Dettaglio esercizio: il nome è nel titolo e di nuovo nel riquadro («Addominali / Corpo libero»). | Nel riquadro solo muscolo e attrezzo. | S |
| PP10 | — | 2 | Righe Corsa e Camminata senza freccia e non si aprono; Watch e Scheda pesi sì: stesso aspetto, comportamento diverso. | Cardio con dettaglio (anche solo durata, km, kcal, Elimina) e freccia. | M |

## Impostazioni

Schermata: `L-impostazioni.png`. Codice: `iOS/Forma/Dieta/ImpostazioniView.swift`, `ImpostazioniSezioni.swift`.

| # | Regola | Grav. | Cosa vede o fa l'utente | Correzione | Lavoro |
|---|---|---|---|---|---|
| IM1 | S4 | 3 | Si aprono solo dall'ingranaggio di Oggi. | `PulsanteImpostazioni` in barra in tutte le schede. | S |
| IM2 | C1 | 1 | Icone delle righe verdi. | Icone `.secondary` o colori di sistema. | S |
| IM3 | T2 | 1 | «Pagamento» sotto «Palestra»: non dice di cosa. | «Abbonamento palestra». | S |
| IM4 | A4 | 0 | Il margine destro ora è giusto sul Duo (correzione WIP `sfondoTema`). | Tenerla e verificarla su iPhone 17. | — |

---

## Verifiche trasversali

- **Scuro (A3):** ok in generale; problemi solo negli elementi vuoti (O6) e nelle righe fatte dell'allenamento (IC2).
- **Testo massimo (A1):** problemi in Oggi (O1, O8), Palestra (PA3), Allenamento in corso (IC3), Progressi (C-1). Il titolo grande diventa piccolo in linea: è il comportamento di sistema, va bene.
- **Colonna destra (A4):** il WIP `MargineLeggibile` funziona: in tutte le schermate viste il contenuto finisce prima della colonna.
- **Lingua inglese:** non verificata.
