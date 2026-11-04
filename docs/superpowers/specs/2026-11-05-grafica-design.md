# Forma — nuova grafica

Data: 5 novembre 2026. Branch `grafica`.

Fonti vincolanti: il report `docs/ricerca/interfaccia-e-usabilita.md` (sezioni «Un solo sistema visivo per tutte le schermate» e «Le proposte, schermata per schermata») e i mockup approvati *Sistema visivo*, *Oggi*, *Dieta*, *Spesa* (HTML statici del 5 novembre). Le scelte non scritte in queste fonti sono segnate **[Scelta]**.

## Perché

Il proprietario trova l'interfaccia brutta: troppi riquadri bianchi uguali, verde ovunque, frasi composte in automatico («Oggi cardio»). Le azioni costano già un tocco: il lavoro è **togliere** peso visivo, non aggiungere funzioni. Riferimento: la pulizia di Hevy, senza copiarne la forma.

## Il sistema visivo

Tutto sta in `iOS/Forma/Comune/` (`Tema.swift`, `Stile.swift`, `Riga.swift`, `Scheda.swift`, `CerchioSpunta.swift`). Nessuna schermata scrive a mano colori, raggi o spaziature.

### Lista o riquadro

- **Lista** (`List` con stile raggruppato di sistema) per ogni insieme di cose da spuntare, aprire o scorrere: pasti, prodotti, schede, esercizi, misure, storico, impostazioni. Una riga si costruisce sempre con `Riga`.
- **Riquadro** (`Scheda`) solo in due casi: **un numero con il suo andamento** (peso, volume settimanale) oppure **l'azione principale della schermata** (la scheda di oggi con «Inizia»). Mai un riquadro per una riga di testo.
- Dentro una lista il riquadro è una sezione a sé e prende il raggio di sistema; fuori da una lista usa `Misure.raggio`.

### Misure

- Spaziature a passi di 4: `Spazio.xs` 4, `.s` 8, `.m` 12, `.l` 16, `.xl` 24 (24 tra sezioni fuori dalle liste).
- Un solo raggio: `Misure.raggio` = 22 pt **[Scelta]** (quello del mockup). Pulsanti a capsula.
- Bersagli di tocco: 44 × 44 pt (`Misure.tocco`) per tutto ciò che si tocca; mai sotto 28.
- Margini: quelli di sistema delle liste. Nessun margine destro scritto a mano: le liste rispettano l'area sicura (anche la colonna di sistema a destra del telefono del proprietario) con `sfondoTema()`, che usa i margini del contenuto e non `listRowInsets` **[Scelta]**.

### Testo

Cinque stili di sistema, con Dynamic Type:

| Stile | Uso |
|---|---|
| Large Title | solo il titolo della scheda (barra di sistema) |
| Headline | nomi: pasto, esercizio, scheda |
| Body | contenuti |
| Subheadline, grigio | dettagli (alimenti, «6 esercizi · circa 55 min») |
| Footnote | minimo per i dati |

Numeri importanti (peso, cronometro, kg, ripetizioni): `.numero(_:)`, cioè SF Rounded semibold a cifre fisse. Nomi e grammature vanno a capo con il testo grande; una riga sola solo a testo normale.

### Colori (ognuno con varianti chiaro, scuro e Aumenta contrasto)

| Colore | Valore | Unico uso |
|---|---|---|
| `Colori.accento` | #2F6B4F / scuro #7FB89A | azione principale (pulsante pieno) e stato «fatto» (spunta, serie fatta). Mai titoli, nomi, link |
| `Colori.sulAccento` | bianco / verde scurissimo | testo e segni sopra l'accento |
| `Colori.olio` | #D6A21E | solo cucchiaini pieni |
| `Colori.acqua` | #3D7FA6 | solo gocce piene |
| `Colori.oltre` | arancione di sistema | solo oltre la dose, **sempre con il segno «+N»** |
| `Colori.vuoto` | grigio | cerchi e pittogrammi vuoti: contrasto almeno 3:1 sullo sfondo della riga, anche in scuro |

Testi solo `.primary`, `.secondary`, `.tertiary`; sfondi solo quelli raggruppati di sistema. Niente rosso per gli sgarri. Il contrasto è controllato da un test (`Contrasto.rapporto`).

### Icone

SF Symbols nelle barre e nelle righe, senza cerchio colorato dietro. Disegni propri solo dove portano informazione (cucchiaini, gocce, macchine). Le icone degli esercizi sono grigie, non verdi.

### Vibrazione, conferme, annullamento

- Vibrazione leggera (`.selection`) solo per: pasto spuntato, cucchiaino o goccia, serie fatta; recupero finito con `.success`.
- Nessun «Sei sicuro?» per le azioni comuni: si annullano ritoccando (spunta, dose). Finestra di conferma solo per annullare un allenamento intero o cancellare dati.

### Barra in alto e Impostazioni

Ingranaggio delle Impostazioni (`PulsanteImpostazioni`) in alto a destra in **tutte e quattro le schede**. Al massimo un'azione piena per barra. Vetro solo quello dei componenti di sistema, mai su righe o riquadri.

### Testi

Ogni frase scritta a mano per ogni stato, mai composta. Date dal sistema in minuscolo («giovedì 5 novembre»). Ogni stringa nuova con `en` e `en-GB`.

## Schermata per schermata (P1 del report)

### Oggi (pilota, fatta in questo branch)

Una sola lista raggruppata, nell'ordine della giornata. Titolo «Oggi», sotto la data di sistema.

1. **Pagamento** — riga in cima solo quando il pagamento è vicino, con «Segna come pagato».
2. **Pasti** — intestazione «Pasti · 1 di 4»; la barra a segmenti sparisce. Una riga per pasto: nome (Headline), alimenti (Subheadline grigio, vanno a capo), cerchio di spunta a destra. Tocco sulla riga: dettaglio. **Tocco lungo: menu per cambiare l'alternativa** (stessi nomi del dettaglio).
3. **Allenamento** — una riga: nome della scheda, «6 esercizi · circa 55 min», pulsante pieno «Inizia». Varianti scritte a mano: in corso «In corso» + «Riprendi»; cardio «Cardio» + «Registra»; riposo «Riposo» + «Allenati lo stesso» (secondario, non pieno); fatto: nome, durata, spunta. Niente «Oggi cardio».
4. **Olio e acqua** — i contatori a pittogrammi (un elemento VoiceOver regolabile ciascuno, vibrazione leggera), vuoti più contrastati, oltre la dose arancione con «+N».
5. **Peso** — riquadro numero: «Peso · ieri», valore grande in cifre arrotondate, a destra la variazione **rispetto a 30 giorni fa**. Tocco: foglio del peso veloce.
6. Le note del profilo restano come piè di pagina dell'ultima sezione **[Scelta]** (il report le sposta in Dieta: P2, da fare con Dieta).

### Dieta

Striscia dei giorni fissa sotto il titolo, non in un riquadro. Sotto, una lista con una riga per pasto: nome, alimenti con grammature (a capo), alternativa scelta in chiaro («Alternativa 2 di 3»), `CerchioSpunta`, freccia per il dettaglio. Stesso nome dell'alternativa ovunque. Carrello in alto con il conteggio come unica porta per la Spesa (P2).

### Dettaglio pasto

In alto il selettore delle alternative con gli stessi nomi della lista; sotto gli alimenti con i grammi allineati a destra in cifre fisse; «Fatto» come unica azione piena nella barra in alto al posto del riquadro «Segna come fatto». Il giorno nel sottotitolo.

### Spesa

Reparti come sezioni, `CerchioSpunta` a sinistra, quantità a destra in cifre fisse; quantità in g o kg, gli alimenti liberi «a piacere» invece di «7 porzioni». Sottotitolo «Settimana 2 – 8 novembre · 3 di 11 presi».

### Palestra

Un solo `Scheda` in alto per la scheda di oggi (nome, «6 esercizi · circa 55 min», «Inizia»); sotto la lista «Schede» senza ripeterla, righe con nome, esercizi in grigio e ▶ semplice senza cerchio. Intestazione della lista «Questa settimana: 2 allenamenti · 1 h 25 min» al posto dei pallini. Il «+» solo per «Nuova scheda»; le altre funzioni (Registra cardio, Allenamento libero, Libreria esercizi, Programma, Schede pronte) in una sezione visibile in fondo, come righe con icona e freccia.

### Allenamento in corso (già rifatto, si allinea)

Nome dell'esercizio in Headline **nero**; icone grigie senza cerchio. Il verde resta solo per le serie fatte, per «Fine» e per l'esercizio completato. Cronometro e recupero in `.numero`, colore primario. «Precedente» e «Aggiungi serie» in grigio/primario, non verdi.

### Progressi › Corpo

Grafico basso (circa un quarto dello schermo), pesate come punti chiari e tendenza in linea piena d'accento, asse dinamico; sopra valore attuale e variazione a 30 giorni in un `Scheda`. Periodo «1 mese / 3 mesi / Tutto» sotto il grafico. Via la percentuale dei pasti segnati.

### Progressi › Palestra

Istogramma del volume settimanale da zero, in accento pieno, titolo con il messaggio («17.130 kg questa settimana»). «Storico» e «Calendario» come righe con freccia in testa alla sezione Allenamenti.

### Impostazioni

Ingranaggio in tutte le schede. `Form` raggruppato di sistema con le tre sezioni; i paragrafi lunghi diventano piè di sezione. Margine destro corretto dal sistema (vedi «Misure»), non a mano.

## Prove

Simulatore iPhone Duo (colonna di sistema a destra) e iPhone 17; chiaro, scuro, testo di accessibilità massimo, Aumenta contrasto. Test di unità per contrasto e formattazione dei numeri; test dell'interfaccia di Oggi aggiornati agli identificativi nuovi senza indebolirli.
