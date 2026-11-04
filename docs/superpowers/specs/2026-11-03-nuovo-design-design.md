# Forma — nuovo design

Data: 3 novembre 2026. Le bozze discusse sono in `.superpowers/brainstorm/85159-1793700809/content/`; vincolanti sono `oggi-v3.html`, `dieta-spesa-v3.html`, `palestra-progressi-v2.html`, più le Impostazioni di `schermate.html`.

## Perché

L'app oggi è «confusionaria e fuorviante»: ogni schermata mostra troppe cose insieme. Forma serve a una persona sola (il proprietario), e ogni giorno ne usa cinque cose: **segnare i pasti, tracciare l'allenamento, vedere il peso, seguire l'andamento, sapere cosa comprare**. Il nuovo design mette queste cinque in primo piano e sposta il resto a un tocco di distanza.

Riferimento dichiarato: Hevy (e app simili: Strong, MacroFactor, Happy Scale, AnyList). Funzionale e chiara, **non deve sembrare fatta da un'AI**, né nell'aspetto né nei testi.

## Obiettivi

- Ogni schermata fa una cosa; i dettagli si aprono con un tocco.
- Quattro schede: **Oggi, Dieta, Palestra, Progressi**. Le Impostazioni non sono più una scheda.
- Un solo aspetto: verde salvia, chiaro e scuro che seguono il telefono.
- Icone disegnate (SF Symbols o pittogrammi), mai emoji.
- Testi brevi, concreti, in italiano corretto (vedi «Testi»).

## Non obiettivi

- Nessuna funzione nuova oltre a quelle elencate qui (reparti della spesa, «Aggiungi qualcos'altro», striscia dei giorni, grafico del volume).
- Nessun cambio al formato dei dati salvo i due campi nuovi della spesa (vedi «Dati»).
- Non si rifà la schermata dell'allenamento in corso: va già bene; cambia solo nei colori e nei testi.

## Anti-obiettivi (sarebbe un fallimento anche se funziona)

- Schermate che tornano a riempirsi di sezioni, paragrafi di spiegazione o righe di contorno (settimana A/B, date ripetute, «Dettagli e quantità»).
- Le Impostazioni che diventano un elenco lunghissimo: restano **sette voci al massimo in tre gruppi**, i dettagli dentro.
- Emoji, etichette tutte maiuscole, testi enfatici o «da marketing», sfumature e decorazioni.
- Perdere dati esistenti o rompere la compatibilità con la web app.

## Aspetto

- **Colore**: un solo accento, verde salvia `#2F6B4F` (in scuro una variante più chiara che resti leggibile). Verde = fatto / azione principale.
  - Altri colori solo con significato: **giallo olio** `#D6A21E` (cucchiaini), **azzurro acqua** `#3D7FA6` (gocce), **arancione** per «oltre la dose».
- **Sfondo**: grigio di sistema raggruppato; contenuti in riquadri bianchi arrotondati (in scuro, i colori di sistema equivalenti).
- **Tipografia**: quella di sistema (SF Pro). Titoli grandi di iOS; numeri importanti (peso, kg, minuti) grandi e con cifre a larghezza fissa.
- **Temi**: si tolgono i sette temi e la voce «Aspetto». (Scelta del costruttore di questo documento, approvata dal proprietario.)
- Liquid Glass di iOS 26 resta dove lo dà il sistema (tab bar, barre).

## Le schermate

### Oggi
Dall'alto:
1. Titolo «Oggi», sotto la data. In alto a destra l'**ingranaggio** che apre le Impostazioni.
2. **Pasti**: «1 di 4» con una barra a segmenti; una riga per pasto con solo il nome e un cerchio da toccare per segnarlo fatto. Niente cibi o quantità (stanno in Dieta).
3. **Allenamento**: una riga con la prossima scheda della rotazione («Push · 6 esercizi · circa 50 min») e il pulsante «Inizia». Nei giorni senza scheda il riquadro dice che è giorno di riposo, in una riga.
4. **Olio e acqua**, riquadro compatto:
   - Olio: un cucchiaino giallo per ogni cucchiaino della dose, «2 di 6 cucchiaini». Toccare l'n-esimo segna n; ritoccare l'ultimo segnato lo toglie.
   - Acqua: una goccia azzurra ogni 0,25 L fino alla dose, «0,75 di 2 L». Stesso tocco.
   - Oltre la dose: compare un elemento in più, arancione. Nessun messaggio.
5. **Peso**: ultimo peso grande, variazione dall'inizio a destra, mini-linea della tendenza. Toccando si va a Progressi.

Tolti: pagamento palestra in alto (diventa notifica e voce nelle Impostazioni), settimana A/B, paragrafo delle regole della dieta, «Apri Palestra».

### Dieta
È la **settimana del piano**, non il giorno (i pasti di oggi si segnano in Oggi).
1. Titolo «Dieta», sotto il nome del piano («Schema ottobre · dal 1 ottobre»).
2. **Striscia dei 7 giorni** (lun…dom con il numero). Oggi ha il numero in verde; il giorno scelto è pieno verde. Sotto ogni giorno, un puntino per pasto: pieno se segnato.
3. I **pasti del giorno scelto**, uno per riquadro: nome, e sotto i cibi scritti di seguito con le quantità. Se ci sono alternative, una riga verde piccola «oppure riso basmati». Toccando un pasto si apre il dettaglio (quantità riga per riga, scelta dell'alternativa, spunta).
4. In fondo, riga **«Spesa della settimana · 14 prodotti · 5 presi»** che apre la Spesa.

Tolti: frecce del giorno, olio e acqua (vanno in Oggi), selettore «Giorno / Spesa».

### Spesa
Pagina a sé, aperta da Dieta.
- In alto la settimana («per la settimana 2 – 8 novembre · 5 di 14») con frecce per cambiarla e una barra di avanzamento. Dal venerdì si apre già sulla settimana successiva (come oggi).
- Prodotti **raggruppati per reparto** nell'ordine del negozio: Frutta e verdura; Carne, pesce, uova; Latticini; Pane, pasta, cereali; Dispensa; Altro.
- **Quantità a peso**, totale della settimana dal piano: grammi, e kg da 1000 g in su («1,05 kg»). Solo per i cibi senza grammi nel piano: «7 porzioni».
- Toccando il cerchio il prodotto è preso: resta al suo posto nel reparto ma sbiadisce e viene barrato.
- Toccando il nome si apre, piccolo e grigio, in quali giorni serve («lun 150 g · mer 150 g…»). Chiuso di base.
- Ultima riga: **«Aggiungi qualcos'altro»** per prodotti fuori dal piano (caffè, detersivo).
- In alto a destra: condividi la lista.

### Palestra
Serve a **iniziare**; tutto ciò che guarda indietro va in Progressi.
1. Titolo «Palestra». In alto a destra **+**: Nuova scheda, Schede pronte, Libreria esercizi, Programma della settimana (quali giorni riposo / pesi / cardio, settimane A/B). *(Posizione del programma: scelta mia, per non allungare le Impostazioni.)*
2. Riquadro **Prossima scheda**: nome grande, elenco esercizi in una frase, pulsante largo «Inizia».
3. Riquadro **Questa settimana**: sette pallini (pieni nei giorni con allenamento) e «2 allenamenti · 1 h 27 min».
4. **Schede**: una riga per scheda con nome, primi esercizi in grigio e un tasto ▶ per partire. Toccare il nome apre la scheda per modificarla. Ultima riga «Allenamento libero».

Tolti da qui: storico, calendario, «Piano, pagamento e Watch», «Oggi: riposo · settimana B», pulsanti «Inizia» ripetuti.

### Progressi (nuova scheda)
Scelta in alto **Corpo / Palestra**. In alto a destra **+** (in Corpo): Aggiungi misurazione, Carica referto BIA (PDF).
- **Corpo**: peso grande con variazione; grafico con periodo (1 mese / 3 mesi / Tutto); tre riquadri BIA (Grasso, Magra, Vita) con valore e variazione; toccandone uno il grafico mostra quella misura. Sotto, «Misurazioni» con le ultime due e «Tutte» per l'elenco completo (modifica / elimina come oggi).
- **Palestra**: grafico a barre del volume (kg sollevati) per settimana, ultime 7 settimane, l'ultima in verde pieno; «Record recenti» (2, con «Tutti»); «Allenamenti» (ultimi, compresi quelli dal Watch, con «Calendario»). Toccando un esercizio si apre il suo grafico; toccando un allenamento il dettaglio.

Assorbe: Andamento della dieta (BIA e grafico), Storico e record, Calendario. L'aderenza alla dieta (percentuale di pasti segnati) va sotto il grafico in Corpo, in una riga.

### Impostazioni
Foglio aperto dall'ingranaggio di Oggi, titolo «Impostazioni», pulsante «Fine». Sei voci in tre gruppi, più «Profili» (sotto):
- **Dieta**: Piani alimentari (elenco, carica PDF, nuovo a mano, modifica), Olio e acqua (dosi giornaliere).
- **Palestra**: Pagamento (giorno e avviso), Apple Watch.
- **Generali**: Promemoria, Backup (esporta, importa, copie dei dati non letti).

**Profili** (deciso dal proprietario): il selettore del profilo compare **solo se esistono almeno due profili**, e solo in Oggi, accanto all'ingranaggio. Con un profilo solo non si vede da nessuna parte. Si aggiungono, rinominano ed eliminano da una settima voce in Generali, «Profili». *(Posizione della voce: scelta mia.)*

## Testi

Tutti i testi dell'app vanno rivisti con queste regole:
- Frasi brevi, verbi semplici, maiuscola solo all'inizio. Niente paragrafi di spiegazione nelle schermate principali.
- Un'azione ha lo stesso nome dappertutto («Inizia», «Segna», «Aggiungi misurazione»).
- Numeri con unità sempre («2 di 6 cucchiaini», «0,75 di 2 L», «81,1 kg»).
- Errori: dicono cosa è successo e cosa fare, senza scuse.
- Niente etichette tecniche («schema», «A/B», «volume») dove esiste una parola comune; dove servono, spiegate una volta.

## Lingua

*(Aggiunta del 4 novembre, decisa dal proprietario.)*
- L'app segue la lingua del telefono **solo se è inglese** (Regno Unito o Stati Uniti): allora è in inglese. Con qualunque altra lingua resta in **italiano**, che è la lingua di base.
- Inglese britannico e americano condividono lo stesso testo; la variante britannica cambia solo dove l'ortografia è diversa (es. «programme», «colour»).
- Date e numeri seguono il formato del telefono (niente formato italiano fisso nel codice).
- **Unità sempre metriche**, anche negli Stati Uniti: kg, g, L, cm (deciso dal proprietario).
- Restano in italiano: la lettura dei PDF del nutrizionista; i nomi scritti dall'utente (cibi, pasti, schede, esercizi creati a mano). I nomi degli esercizi della libreria e delle schede pronte si traducono.
- I testi inglesi seguono le stesse regole della sezione «Testi».

## Dati

- Il formato di `dieta.json` resta compatibile con la web app. Aggiunte permesse, solo come campi nuovi con valore predefinito:
  - reparto scelto a mano per un prodotto della spesa (mappa nome → reparto);
  - prodotti aggiunti a mano alla spesa, per settimana.
- Il reparto si deduce da un elenco di parole chiave in italiano (es. «pollo» → Carne, pesce, uova); se non si riconosce: «Altro».
- Nessun altro cambio a `dieta.json` o `palestra.json`.

## Cosa resta al costruttore

- Componenti SwiftUI, struttura dei file e come condividere i riquadri.
- Variante scura esatta del verde, purché leggibile (contrasto AA).
- Comportamento esatto del tocco su cucchiaini e gocce con VoiceOver (deve restare utilizzabile: valore letto e regolabile).
- Elenco delle parole chiave per i reparti.
- Forma esatta dei pittogrammi (cucchiaino, goccia), purché semplici e coerenti con SF Symbols.
- Con testo molto grande, come andare a capo nelle righe e nella striscia dei giorni (deve restare tutto leggibile).

## Comportamenti che restano come oggi

- **Cosa si fa in palestra oggi**: resta il programma settimanale attuale (riposo / pesi / cardio per giorno, con le settimane A/B se attive): la logica e `palestra.json` non cambiano, sparisce solo la scritta «settimana A/B».
  - Giorno di pesi: Oggi e Palestra propongono la prossima scheda della rotazione (`prossimaRoutine()`), come oggi.
  - Giorno di riposo: in Oggi una riga «Oggi riposo» con un link piccolo «Allenati lo stesso» che apre Palestra.
  - Giorno di cardio: una riga «Oggi cardio»; il cardio arriva dal Watch, nessun pulsante. *(Scelta mia.)*
- **Pasto segnato** = spunta del pasto intero, come oggi (`slot[indice].fatto`). Il cerchio in Oggi e la spunta nel dettaglio di Dieta sono la stessa cosa. «1 di 4», i puntini della striscia e l'aderenza contano i pasti segnati. Toccando il cerchio in Oggi vale l'alternativa già scelta per quel giorno (altrimenti la prima).
- **Totali della spesa**: come oggi (`vociSpesa`): per ogni giorno si usa il piano valido quel giorno e l'alternativa scelta (altrimenti la prima); i giorni senza piano non contano; i nomi si uniscono ignorando maiuscole e prefissi «Contorno:» / «Secondo:». Il reparto scelto a mano vale per quel nome, senza maiuscole.

## Stati vuoti *(scelte mie)*

- **Nessun piano attivo**: in Oggi il riquadro Pasti è una riga «Nessun piano per oggi» con «Carica piano»; Dieta mostra la striscia dei giorni e al posto dei pasti «Nessun piano per questo giorno» con «Carica il PDF» e «Scrivilo a mano». La riga della Spesa non compare se la settimana non ha nessun piano.
- **Nessuna misurazione**: il riquadro Peso in Oggi dice «Aggiungi il primo peso» e apre la misurazione; Progressi → Corpo mostra lo stesso invito.
- **Nessuna scheda**: Palestra mostra «Crea la prima scheda» e «Scegli tra le schede pronte».

## Olio e acqua: dosi *(scelte mie)*

- Olio: si segna a cucchiaini interi (come oggi); un cucchiaino disegnato per cucchiaino di dose.
- Acqua: si segna a bicchieri da 0,25 L (come oggi); il numero di gocce è la dose divisa per 0,25 arrotondata per eccesso (1,9 L → 8 gocce).
- Oltre la dose: un elemento arancione in più per ogni unità oltre la dose, fino al massimo che l'app già consente (doppio della dose); il valore salvato è sempre il numero reale.
- VoiceOver: ogni riga si legge come «Olio, 2 di 6 cucchiaini» ed è regolabile con su/giù.

## Domande aperte

Nessuna.
