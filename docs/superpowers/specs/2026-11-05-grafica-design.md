# Forma — nuova grafica (BOZZA)

> **BOZZA, da approvare.** Il proprietario non ha ancora scelto la direzione grafica: niente di questo documento va realizzato prima della sua approvazione.

Data: 5 novembre 2026. Branch `grafica`.

Fonti vincolanti, in quest'ordine:
1. `docs/ricerca/checklist-forma.md` — 45 regole con codice (S1…G5). Ogni scelta qui sotto cita la regola che soddisfa.
2. `docs/ricerca/valutazione-forma.md` — i problemi trovati schermata per schermata (codici O1, D1, PA1, IC1…), con gravità e correzione.
3. `docs/ricerca/interfaccia-e-usabilita.md`, `linee-guida-generali.md`, `linee-guida-genere-e-hevy.md` — le ricerche da cui vengono le regole.

Le scelte che non vengono da queste fonti sono segnate **[Scelta]** e vanno confermate dal proprietario.

**Stato del branch.** Su `grafica` c'è solo la correzione del margine destro (`sfondoTema()`, commit `6f1814a`, verificata sul simulatore iPhone Duo). Oggi, Dieta e le altre schermate sono ancora quelle di `main`: la versione precedente di questa bozza diceva per errore che Oggi era già rifatta.

## Perché

Il proprietario trova l'interfaccia brutta. La valutazione conferma che i tocchi vanno bene (quasi tutto a 1 tocco) e che il problema è che **l'app non sembra una sola**: quattro spunte diverse, il verde con sei significati, un riquadro bianco per ogni cosa, frasi composte, tre formati di data, numeri che non crescono con il testo grande. In più due difetti di sostanza: lo stesso totale settimanale ha due valori (8.565 e 17.130 kg) e alcuni moduli mostrano numeri grigi che sembrano dati ma non si salvano. Il lavoro è **togliere e uniformare**, poi correggere quei difetti. Riferimento: la pulizia di Hevy (una riga per serie, un solo pulsante pieno, «Precedente» e spunta), senza copiarne la forma.

## Il sistema visivo

Tutto sta in `iOS/Forma/Comune/`. Nessuna schermata scrive a mano colori, raggi, spaziature, dimensioni di testo o spunte.

| File | Contenuto |
|---|---|
| `Tema.swift` | `Colori` (tabella sotto), `sfondoTema()`, `righeTema()`, `PulsanteAccento` |
| `Stile.swift` (nuovo) | `Spazio`, `Misure`, `.numero(_:)`, `Testi.data(_:)` |
| `Riga.swift` (nuovo) | riga di lista standard: titolo, dettaglio, valore a destra, accessorio |
| `CerchioSpunta.swift` (nuovo) | l'unica spunta dell'app |
| `PulsanteImpostazioni.swift` (nuovo) | ingranaggio da mettere nella barra di ogni scheda |
| `Riquadro.swift` | resta, con raggio da `Misure.raggio` |

### Lista o riquadro (V1)

- **Lista** (`List` raggruppata di sistema) per ogni insieme di cose da spuntare, aprire o scorrere: pasti, prodotti, schede, esercizi, misure, storico, impostazioni. Una riga si costruisce sempre con `Riga`.
- **Riquadro** solo per **un numero con il suo andamento** (peso, volume settimanale) o per **l'azione principale** della schermata (la scheda di oggi con «Inizia»). Mai un riquadro per una riga di testo.
- Dentro una lista il riquadro è una sezione e prende il raggio di sistema.

### Misure (V3, P1, A4)

- Spaziature a passi di 4: `Spazio.xs` 4, `.s` 8, `.m` 12, `.l` 16, `.xl` 24 (24 tra gruppi fuori dalle liste).
- `Misure.raggio` 16 pt per i riquadri fuori dalle liste **[Scelta]** (quello attuale; la bozza precedente proponeva 22, da decidere sui mockup). Pulsanti a capsula.
- `Misure.tocco` 44 pt: ogni cosa toccabile ha almeno 44 × 44 pt; filtri e capsule compresi (PA15).
- Margini: quelli di sistema. Nessun margine destro scritto a mano: `sfondoTema()` aggiunge margini solo oltre 640 pt di larghezza (`MargineLeggibile`), così le liste rispettano la colonna di sistema del Duo.

### Testo (T1, T2, T3, A1)

Solo stili di sistema con Dynamic Type; **vietato** `.font(.system(size:))` (oggi in Oggi, Progressi e Palestra: O8, C-1).

| Stile | Uso |
|---|---|
| Large Title | titolo della scheda (barra di sistema) |
| Headline | nomi: pasto, esercizio, scheda |
| Body | contenuti |
| Subheadline `.secondary` | dettagli (alimenti, «6 esercizi · circa 55 min») |
| Footnote | minimo per i dati |

- `.numero(_ stile: Font.TextStyle)`: SF Rounded semibold a cifre fisse, **sullo stile di sistema** (es. `.numero(.largeTitle)` per il peso, `.numero(.title2)` per il cronometro), così cresce con il testo.
- Nomi e grammature vanno a capo: nessun `lineLimit(1)` su nomi o alimenti (O1); a testo di accessibilità le righe con controlli a destra si impilano.
- Testi scritti per ogni stato, mai composti («Riposo», non «Oggi riposo»).
- Date solo con `Testi.data(_:)`: formato di sistema in minuscolo, «giovedì 5 novembre»; mai «05/11/2026» né mese maiuscolo (O3, PP6, C-7).
- Ogni numero con unità metrica: «a piacere» invece di «7 porzioni» (SP1), «30–45 s» (PA12).

### Colori (C1–C4, M1), ognuno con varianti chiaro, scuro e Aumenta contrasto

| Colore | Valore | Unico uso |
|---|---|---|
| `Colori.accento` | #2F6B4F / scuro #7FB89A | pulsante principale pieno e stato «fatto» (spunta, serie fatta). **Mai** nomi di esercizi, link, titoli di sezione, valori «Precedente», icone di riga, variazioni di peso |
| `Colori.sulAccento` | bianco / verde scurissimo #0F2218 | testo e segni sopra l'accento |
| `Colori.olio` | #D6A21E in scuro, #B07F0C in chiaro **[Scelta]** (≥ 3:1 sul bianco; oggi 2,3:1) | solo cucchiaini pieni |
| `Colori.acqua` | #3D7FA6 | solo gocce piene |
| `Colori.oltre` | arancione di sistema | solo oltre la dose, sempre con «+N» |
| `Colori.vuoto` | contorno `.secondary` 1,5 pt su riempimento leggero **[Scelta]** | cerchi, cucchiaini e gocce vuoti: ≥ 3:1 sullo sfondo della riga, anche in scuro (oggi 1,3:1 e 1,6:1) |

- Testi solo `.primary`, `.secondary`, `.tertiary`; sfondi solo quelli raggruppati di sistema.
- **Variazioni del corpo neutre**: peso, grasso, vita in `.secondary` con segno («−0,8 kg in 30 giorni»), mai verde quando scendono (M1, O7, C-2).
- Niente rosso per gli sgarri, niente «saltato» (M2, PP5).
- Un test di unità controlla i contrasti (`Contrasto.rapporto`) di accento, olio, acqua e vuoto in chiaro e in scuro.

### Spunta unica (V4, F2)

`CerchioSpunta(fatta:)`: cerchio da 26 pt dentro un'area di 44 × 44; vuoto = contorno `Colori.vuoto`; fatto = cerchio pieno accento con segno `Colori.sulAccento`. Si usa in Oggi, Dieta, dettaglio pasto, Spesa e **nella riga della serie** (al posto di `checkmark.square`). Lo stato «fatto» è sempre doppio: cerchio pieno + nome grigio (pasti, spesa) o sfondo della riga (serie).

### Icone

SF Symbols nelle barre e nelle righe, senza cerchio colorato dietro, colore `.secondary`. Disegni propri solo dove portano informazione (cucchiaini, gocce, macchine): se un esercizio non ha il disegno della sua macchina, **nessuna icona** invece dell'omino generico (PA10). Frecce delle righe: solo l'accessorio di sistema (PA8).

### Vibrazione, conferme, annullamento (F1, E1–E3)

- Vibrazione leggera (`.selection`) solo per: pasto spuntato, cucchiaino o goccia, serie fatta; recupero finito con `.success`.
- Nessuna conferma per azioni comuni: si annullano ritoccando. Conferma solo per cancellare dati o chiudere/annullare un allenamento, **con il numero** di ciò che si perde (IC7).
- Errori a parole vicino al campo (IC10). Un pulsante spento ha accanto il motivo (PA14).

### Moduli (I1–I4)

- Mai un segnaposto che sembra un dato: o il campo è **precompilato con un valore vero** (ultimo peso, ultimo cardio dello stesso tipo, 30 min) o è vuoto con etichetta (PA14, O9).
- Valori che cambiano poco hanno ± a passi fissi: peso ±0,1 kg, minuti ±5, kg della serie ±2,5 **[Scelta]** (passo da confermare), ripetizioni ±1.
- Ogni campo dell'editor delle misure mostra l'ultimo valore sotto l'etichetta; unità in colonna fissa (C-6).

### Barra in alto e Impostazioni (S1, S4)

- `PulsanteImpostazioni` in alto a destra in **tutte e quattro le schede** (apre `navigazione.impostazioniAperte`).
- Al massimo un'azione piena per barra. Vetro solo quello dei componenti di sistema.
- Le funzioni usate ogni settimana non stanno solo dietro un «+» o un «…» senza testo (S2).

### Numeri coerenti (F3, M3)

- «Questa settimana» vuol dire sempre **da lunedì a oggi**, calcolato da una sola funzione di `StatoPalestra`, usata da Palestra, Progressi e Allenamenti (PP1).
- La settimana in corso nei grafici si distingue con un segno e la parola «finora», non solo con il colore (PP2).
- Il peso si confronta con 30 giorni fa, non con la prima misura (O7, C-2).

## Schermata per schermata

Ogni voce rimanda ai codici di `valutazione-forma.md`.

### Oggi (O1–O11)
Una sola lista raggruppata, nell'ordine della giornata; titolo «Oggi», sotto la data di `Testi.data`.
1. **Abbonamento** — riga in cima solo vicino alla scadenza, con «Segna come pagato».
2. **Pasti** — intestazione «Pasti · 1 di 4» (via la barra a segmenti). Riga: nome (Headline), alimenti (Subheadline grigio, fino a 2 righe, tutte a testo grande), `CerchioSpunta` a destra. Tocco: dettaglio. Tocco lungo: menu per cambiare l'alternativa (stessi nomi del dettaglio).
3. **Allenamento** — una riga: nome scheda, «6 esercizi · circa 55 min», «Inizia» pieno. In corso: «In corso» + «Riprendi». Cardio: «Cardio · 30 min» + «Registra». Riposo: «Riposo» + «Allenati lo stesso» (secondario) che **apre il menu delle schede e avvia** quella scelta (O4). Fatto: nome, durata, spunta.
4. **Olio e acqua** — contatori a pittogrammi con i nuovi colori vuoto e olio.
5. **Peso** — riquadro numero: «Peso · ieri», valore in `.numero(.largeTitle)`, a destra «−0,8 kg in 30 giorni» grigio. Tocco: foglio con il peso precompilato, ±0,1 e «Salva» attivo.
6. Note del nutrizionista come piè della sezione Olio e acqua **[Scelta]**.

### Dieta (D1–D6)
Striscia dei giorni fissa sotto il titolo (puntini pieno = fatto, contorno = da fare). Sotto una lista «Pasti · 1 di 4»: `CerchioSpunta` a sinistra (come Spesa), nome, alimenti a capo, «Alternativa: riso (1 di 2)» grigio, freccia di sistema. Carrello nella barra come unica porta alla Spesa; via il riquadro in fondo. Ingranaggio.

### Dettaglio pasto (DP1–DP3)
Giorno nel sottotitolo della barra; selettore delle alternative con i nomi della lista; alimenti con grammi a destra in cifre fisse; «Fatto» pieno nella barra; sotto, le note del nutrizionista per quel pasto se ci sono.

### Spesa (SP1–SP3)
Reparti come sezioni, `CerchioSpunta` a sinistra, quantità a destra (g, kg, «a piacere»); presi in fondo alla sezione, barrati e grigi; via la barra di avanzamento; sottotitolo «2–8 novembre · 3 di 11 presi».

### Palestra (PA1–PA15)
- Un riquadro in alto: la scheda di oggi (nome, «6 esercizi · circa 55 min», «Inizia» pieno).
- Lista «Altre schede» senza quella in alto, intestazione «Questa settimana: 3 allenamenti · 2 h 22 min»; righe con nome, esercizi in grigio, ▶ semplice grigio. Via i pallini.
- «+» solo per «Nuova scheda». In fondo sezione «Altro»: Allenamento libero, Registra cardio, Programma della settimana, Libreria esercizi, Schede pronte (righe con icona e freccia).
- Editor: nome nel titolo (rinominabile), niente riga ripetuta; «Inizia» pieno con testo in fondo.
- Libreria: ricerca sempre visibile; filtri alti 44 pt; nessun omino generico.
- Programma: «Questa settimana: B» con pulsante «Scambia», non un interruttore.
- Cardio: minuti precompilati come valore vero, ±5; km facoltativi.
- Nomi demo in italiano: «Spinta», «Tirata», «Gambe».

### Allenamento in corso (IC1–IC10)
Struttura attuale tenuta (è la più vicina a Hevy). Cambia:
- Testata in **una riga** anche a testo grande: cronometro `.numero(.title2)` `.primary`, «4 serie» a destra; i kg solo a testo normale. Riscaldamento e esercizi completati compressi in righe di 44 pt (IC3).
- Nomi degli esercizi `.primary`, «Precedente» `.secondary` ma toccabile, «Aggiungi serie» `.primary`: verde solo per serie fatta e «Fine» (IC1).
- `CerchioSpunta` nella riga; riga fatta con sfondo accento più deciso in scuro (IC2).
- Barra sopra la tastiera: «−2,5» «+2,5» per i kg, «−1» «+1» per le ripetizioni, «Chiudi» (non «Fine») (IC4, IC6).
- «Fine»: se ci sono serie non spuntate, la conferma dice quante; se nessuna serie è fatta, chiede se chiudere senza salvare (IC7, IC9). «Annulla allenamento» solo nel menu «…» (IC8).
- Serie senza kg: contorno arancione e «Scrivi i kg» sotto il campo (IC10).
- Live Activity del recupero: pacchetto a parte (IC5).

### Riepilogo di fine allenamento (R1–R2)
Titolo = nome della scheda; tre numeri grandi in riga (Durata · Kg · Serie) con la differenza rispetto all'ultima volta della stessa scheda; poi i nuovi record; niente medaglia né «!»; niente riga Data.

### Progressi › Corpo (C-1–C-8)
Riquadro peso: valore `.numero(.largeTitle)`, «−0,8 kg in 30 giorni» grigio; grafico alto circa un quarto dello schermo, pesate come punti e linea di tendenza piena, asse dinamico; periodo con `Picker` segmentato sotto il grafico. Via la percentuale dei pasti. Misure BIA in tabella «ultima (data) · precedente · differenza». Misurazioni: lista con «Tutte le misurazioni ›» in fondo. «+» con «Nuova misura» e «Carica la BIA (PDF)». Editor con ultimo valore sotto ogni campo e unità in colonna.

### Progressi › Palestra (PP1–PP10, PA16, PA17)
Istogramma del volume da lunedì, settimane intere in accento pieno, settimana in corso con contorno e «finora», asse y con due valori; titolo «8.565 kg questa settimana (finora)». «Tutti gli allenamenti ›» e «Calendario ›» come righe. Dettaglio allenamento: una riga per esercizio. Calendario: pieno = fatto, contorno = in programma, niente «saltato». Cardio con dettaglio. Dettaglio esercizio: senza nome ripetuto, «Serie migliore: 37,5 kg × 12», linea del grafico non curva; nessuna pagina vuota all'apertura (PP3).

### Impostazioni (IM1–IM4)
Ingranaggio in tutte le schede; `Form` raggruppato di sistema; icone grigie; «Abbonamento palestra» al posto di «Pagamento».

## Prove

Simulatore iPhone Duo (`9A22E06F-6DE7-4B43-92FA-244B7B917DB0`, colonna di sistema a destra) e iPhone 17; chiaro, scuro, testo `accessibility-extra-extra-extra-large`, Aumenta contrasto; inglese (`-AppleLanguages "(en)"`). Per ogni schermata: la checklist intera, poi i codici della valutazione che il pacchetto doveva chiudere. Test di unità per contrasto, formato delle date, settimana da lunedì; test dell'interfaccia aggiornati agli identificativi nuovi senza indebolirli.

---

## Pacchetti di lavoro (dopo l'approvazione)

Ordine: **P1 da solo per primo**; poi P2–P7 **in parallelo**, un worktree e un agente ciascuno, da `grafica` dopo P1; poi P8 e P9. Ogni pacchetto tocca solo i suoi file: se gli serve altro dal sistema visivo, lo chiede invece di modificarlo. Ognuno finisce con build, test (`cd iOS && xcodebuild test -project Forma.xcodeproj -scheme Forma -destination 'platform=iOS Simulator,name=iPhone 17' -quiet`) e screenshot sul Duo in chiaro, scuro e testo massimo, con la checklist compilata per le sue schermate.

| Pacchetto | File (solo questi) | Voci della valutazione | Dipende da | Modello consigliato |
|---|---|---|---|---|
| **P1 Sistema visivo** | `Comune/Tema.swift`, `Comune/Riquadro.swift`, nuovi `Comune/Stile.swift`, `Comune/Riga.swift`, `Comune/CerchioSpunta.swift`, `Comune/PulsanteImpostazioni.swift`, `Comune/Dosaggio.swift`, `Comune/Utilita.swift` (date), test nuovi `FormaTests/SistemaVisivoTests.swift` | O6, O11 (componente), C3, T1 (`.numero`), T2 (`Testi.data`), colori olio e vuoto | — | il più capace (decide le basi) |
| **P2 Oggi** | `HomeView.swift`, `Dieta/PesoVeloce.swift`, test UI di Oggi | O1–O5, O7–O10; ingranaggio | P1 | intermedio |
| **P3 Dieta, dettaglio pasto, Spesa** | `Dieta/DietaView.swift`, `Dieta/DettaglioPastoView.swift`, `Dieta/SpesaView.swift`, `Dieta/Archivio.swift` (solo `testoQuantita` e nome dell'alternativa), `FormaUITests/DietaTests.swift` | D1–D6, DP1–DP3, SP1–SP3 | P1 | intermedio |
| **P4 Palestra e sotto-schermate** | `Palestra/AllenamentoView.swift`, `Palestra/SezioniPalestra.swift`, `Palestra/LibreriaView.swift`, `Palestra/Libreria.swift` (solo testi delle schede pronte), `Palestra/DemoPalestra.swift`, `Palestra/SceltaSchedaView.swift` | PA1–PA15; ingranaggio. Espone `SceltaSchedaView` come menu riusabile per O4 | P1 | intermedio |
| **P5 Allenamento in corso** | `Palestra/AllenamentoInCorsoView.swift`, `Palestra/TimerRecupero.swift`, `Palestra/SpuntaSerie.swift`, test `AllenamentoScorrevole*`, `SpuntaSerieTests` | IC1–IC4, IC6–IC10 | P1 | il più capace (schermata più usata, testi e logica di spunta) |
| **P6 Progressi › Palestra e riepilogo** | `Palestra/ProgressiPalestraView.swift`, `Palestra/StoricoView.swift`, `Palestra/CalendarioView.swift`, `Palestra/ModelliPalestra.swift` (solo funzione settimana), `PalestraTests` | PP1–PP10, PA16, PA17, R1, R2 | P1 | intermedio; PP1 e PP3 con test prima del codice |
| **P7 Progressi › Corpo e Impostazioni** | `ProgressiView.swift`, `Dieta/CorpoView.swift`, `Dieta/EditorMisura.swift`, `Dieta/ImpostazioniView.swift`, `Dieta/ImpostazioniSezioni.swift`, `CorpoTests` | C-1–C-8, IM2, IM3; ingranaggio in Progressi | P1 | intermedio |
| **P8 Live Activity del recupero** | nuovo target widget, `Palestra/TimerRecupero.swift` (dopo P5), `Info.plist` | IC5, G3 | P5 | il più capace |
| **P9 Verifica finale** | nessun codice; `docs/ricerca/valutazione-forma.md` aggiornata | tutte: checklist completa su ogni schermata, Duo e iPhone 17, chiaro/scuro/testo massimo/Aumenta contrasto/inglese | P2–P8 | intermedio (subagent `ui-checker`) |

Note sui confini:
- O4 («Allenati lo stesso» avvia una scheda) è in P2 ma usa `SceltaSchedaView` di P4: P2 la usa così com'è oggi; se P4 ne cambia la firma, l'adeguamento si fa al momento dell'unione.
- PP1 (settimana da lunedì) tocca il modello: solo P6 modifica `ModelliPalestra.swift`; P4 legge il riepilogo settimanale attuale, che già conta da lunedì.
- Le stringhe nuove vanno nel catalogo con `en` e `en-GB` da chi le introduce; P9 controlla l'inglese.

---

## API di P1

Fatto nel pacchetto P1 (branch `grafica`). Tutto in `iOS/Forma/Comune/`; ogni file spiega in testa come si usa. I pacchetti P2–P7 usano solo queste API e non modificano questi file: se serve altro, lo chiedono.

### Stile.swift — misure, numeri, date

```swift
enum Spazio { static let xs = 4, s = 8, m = 12, l = 16, xl = 24 }      // CGFloat
enum Misure {
    static let raggio: CGFloat = 16    // riquadri fuori dalle liste (pulsanti a capsula)
    static let tocco: CGFloat = 44     // area minima di tocco
    static let riga: CGFloat = 52      // altezza minima di Riga
    static let spunta: CGFloat = 26    // cerchio di CerchioSpunta
    static let contorno: CGFloat = 1.5 // contorno degli elementi vuoti
}
extension Font { static func numero(_ stile: Font.TextStyle = .body) -> Font }   // SF Rounded semibold, cifre fisse
extension View { func numero(_ stile: Font.TextStyle = .body) -> some View }
enum Testi {
    static func data(_ data: Date, anno: Bool = false, locale: Locale = .current) -> String   // «giovedì 5 novembre»
    static func data(iso: String, anno: Bool = false, locale: Locale = .current) -> String   // da "2026-11-05"
    static func periodo(da: Date, a: Date, locale: Locale = .current) -> String              // «2–8 novembre»
    static func conSegno(_ valore: Double, unita: String, locale: Locale = .current) -> String // «−0,8 kg», «+0,3 kg», «0 kg»
}
```

```swift
Text(num(kg)).numero(.largeTitle)                       // peso in Oggi e Progressi (O8, C-1)
Text(cronometro).numero(.title2)                         // allenamento in corso
Text(Testi.data(Date()))                                 // sottotitolo di Oggi (O3)
Text(Testi.conSegno(-0.8, unita: "kg")).foregroundStyle(.secondary)   // variazione neutra (M1)
.padding(.horizontal, Spazio.l)
.frame(minHeight: Misure.tocco)
```

### Tema.swift — colori

| Token | Chiaro / scuro | Uso |
|---|---|---|
| `Colori.accento` | #2F6B4F / #7FB89A (contrasto alto #245A40 / #9FD0B5) | solo pulsante principale pieno e «fatto» |
| `Colori.sulAccento` | bianco / #0F2218 | segni e testo sopra l'accento |
| `Colori.sfondoFatto` | accento al 25 % / 35 % | sfondo della riga fatta (serie) |
| `Colori.olio` | #B07F0C / #D6A21E (alto #8C6508 / #E8BC4A) | solo cucchiaini pieni |
| `Colori.acqua` | #3D7FA6 / #5A9CC4 (alto #2C6688 / #7DB4D6) | solo gocce piene |
| `Colori.oltre` | #C4610A / #FF9F0A (alto #A34F06 / #FFB340) | solo oltre la dose, con «+N» |
| `Colori.vuoto` | grigio secondario di sistema | contorno di cerchi, cucchiaini, gocce vuoti |
| `Colori.riempimentoVuoto` | riempimento quaternario di sistema | interno degli elementi vuoti |

Tutti ≥ 3:1 sugli sfondi raggruppati (riga, schermata, foglio) in chiaro, scuro e Aumenta contrasto: lo controlla `SistemaVisivoTests`. Scelte rispetto alla bozza: acqua più chiara in scuro (#5A9CC4, perché #3D7FA6 sul grigio dei fogli è 3,2:1) e «oltre» più scuro in chiaro (l'arancione di sistema è 2,2:1 sul bianco).

```swift
Color(chiaro: 0x…, scuro: 0x…, chiaroContrasto: 0x…, scuroContrasto: 0x…)   // per eventuali token nuovi, solo qui
Contrasto.rapporto(_ colore: Color, su sfondo: Color, stile: UIUserInterfaceStyle, contrastoAlto: Bool = false) -> Double
.applicaTema()   .sfondoTema()   .righeTema()
Button("Inizia") { … }.buttonStyle(PulsanteAccento())   // capsula piena, alta almeno 44 pt; uno per schermata
```

Nota: `.applicaTema()` mette ancora l'accento come `tint` di tutta l'app (interruttori, link, icone della barra). Ogni pacchetto, nelle sue schermate, toglie il verde da ciò che non è azione principale o «fatto» (es. `.tint(.primary)` sulla barra, `.foregroundStyle(.primary)` sui nomi).

### CerchioSpunta.swift — la spunta unica

```swift
CerchioSpunta(fatta: Bool)                                  // solo disegno, dentro un pulsante più grande (nascosto a VoiceOver)
CerchioSpunta(fatta: Bool, etichetta: Text,
              stati: (fatta: LocalizedStringResource, daFare: LocalizedStringResource) = ("fatto", "da fare"),
              vibra: Bool = true, azione: @escaping () -> Void)   // pulsante a sé, area 44 × 44
```

```swift
CerchioSpunta(fatta: s.fatto, etichetta: Text("Segna \(pasto.nome)")) { archivio.cambiaSlot(giorno, i) { $0.fatto.toggle() } }
    .disabled(giorno > Giorni.oggi())                       // spenta e schiarita
CerchioSpunta(fatta: preso, etichetta: Text("Segna \(v.nome)"), stati: ("preso", "da prendere")) { … }
CerchioSpunta(fatta: s.fatta, etichetta: Text("Serie \(n)"), vibra: false) { segna(…) }   // la vibrazione la fa la riga
```

Il cerchio cresce con il testo grande (fino a 1,6 volte). Già sostituite in modo meccanico le spunte di Oggi (pasti, allenamento e cardio fatti), Dieta, Spesa, dettaglio pasto e riscaldamento (via `RigaSpunta`) e serie dell'allenamento (con `Colori.sfondoFatto`); il resto delle loro schermate non è cambiato.

### Riga.swift — riga di lista standard

```swift
Riga(_ titolo: Text, dettaglio: Text? = nil, valore: Text? = nil, evidente: Bool = false, fatta: Bool = false,
     righeDettaglio: Int? = nil, @ViewBuilder inizio: () -> Inizio, @ViewBuilder fine: () -> Fine)   // tutte e due
Riga(_ titolo: Text, …, @ViewBuilder fine: () -> Fine)   // solo a destra: `Riga(…) { … }`
Riga(_ titolo: Text, …, inizio: Inizio)                  // solo a sinistra: la vista come valore, non closure
Riga(_ titolo: Text, …)                                  // nessuna vista ai lati
Riga(_ titolo: LocalizedStringKey, dettaglio: LocalizedStringKey? = nil, valore: LocalizedStringKey? = nil,
     evidente: Bool = false, fatta: Bool = false)        // testi del catalogo
```

Alta almeno 52 pt; titolo `.body` (`.headline` con `evidente`), dettaglio `.subheadline` grigio che va a capo (`righeDettaglio` limita solo a testo normale), valore a destra a cifre fisse mai troncato; a testo di accessibilità valore e `fine` vanno sotto. `fatta: true` rende grigi titolo e dettaglio. La freccia la mette il `NavigationLink`, non la riga.

```swift
Riga("Olio", dettaglio: "2 di 3 cucchiaini")
NavigationLink(value: scheda.id) { Riga(Text(scheda.nome), dettaglio: Text("6 esercizi · circa 55 min"), evidente: true) }
Riga(Text(pasto.nome), dettaglio: Text(opzione.riassunto), evidente: true, fatta: s.fatto, righeDettaglio: 2,
     inizio: CerchioSpunta(fatta: s.fatto, etichetta: Text("Segna \(pasto.nome)")) { … })      // spunta a sinistra (Dieta, Spesa)
Riga(Text(scheda.nome), dettaglio: Text("6 esercizi · circa 55 min"), evidente: true) {
    Button("Inizia") { … }.buttonStyle(PulsanteAccento())                                    // a destra
}
```

### Altri

```swift
PulsanteImpostazioni()   // ingranaggio: .toolbar { ToolbarItem(placement: .topBarTrailing) { PulsanteImpostazioni() } }
Riquadro { … }           // solo numero con andamento o azione principale; Spazio.l / Spazio.m, Misure.raggio
Dosaggio(…)              // stessa firma; vuoti con Colori.vuoto, oltre con Colori.oltre
RigaSpunta(fatto:azione:etichetta:)   // riga intera toccabile con CerchioSpunta a sinistra e testo grigio se fatta
RigaAlimento(nome:quantita:)          // nome che va a capo, quantità intera a destra a cifre fisse
```

### Cosa resta ai pacchetti

- **P2 Oggi:** usare `Riga`, `.numero(.largeTitle)` per il peso (oggi ancora `.system(size: 34)`), `Testi.data`, `Testi.conSegno` in `.secondary`; togliere `lineLimit(1)` dagli alimenti.
- **P3 Dieta/Spesa:** `PulsanteImpostazioni` in barra; `Riga` con `CerchioSpunta` a sinistra; date con `Testi.periodo`.
- **P4 Palestra:** `PulsanteImpostazioni`; via `.font(.system(size: 14))`.
- **P5 Allenamento in corso:** etichette della spunta della serie se si passa al pulsante `CerchioSpunta(…, vibra: false)`; cronometro con `.numero(.title2)`; via `.system(size:)` del recupero.
- **P6/P7 Progressi:** `.numero(.largeTitle)` al posto di `.system(size: 34)`; `Testi.data` al posto di `Giorni.breve` dove si mostra una data; `PulsanteImpostazioni` in Progressi; medaglia del riepilogo e `xmark` del calendario sono da togliere (R1, PP5).
