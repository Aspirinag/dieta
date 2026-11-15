# Controllo design di Forma

## 1. In breve
Il design è già curato: nessun colore fisso (nessun `.white`/`.black`/`Color(red:)` fuori da `Colori.swift`, che ha varianti chiaro/scuro e «Aumenta contrasto»), un solo font a misura fissa (`AllenamentoInCorsoView.swift:901`, scalato con `@ScaledMetric`), bottoni solo-icona quasi tutti con etichetta. Provato su iPhone 17 (Oggi, Palestra, Impostazioni, chiaro/scuro, testo `accessibility-extra-extra-large`): nessun testo sovrapposto, nessun contrasto illeggibile.
I difetti sono pochi e piccoli. Il più concreto: su iOS 18–25 la data (sottotitolo) sparisce da Oggi, Dieta e dal dettaglio pasto.
Punti: 0 alta, 1 media, 4 bassa.

## 2. Cosa non va

### 1. Su iOS 18–25 la data sparisce da Oggi, Dieta e dettaglio pasto — gravità media
- **Dove**: `iOS/Forma/HomeView.swift:42` e `:419-421`; `Dieta/DietaView.swift:50`; `Dieta/DettaglioPastoView.swift:23`.
- **Cosa succede**: `navigationSubtitleSePossibile` fa `navigationSubtitle` solo da iOS 26; sotto restituisce la vista senza nulla. Il target minimo è iOS 18.0 (`project.pbxproj`, `IPHONEOS_DEPLOYMENT_TARGET`). Chi ha iOS 18–25 vede «Oggi» senza il giorno, «Dieta» senza il sottotitolo e il dettaglio pasto (con titolo inline) senza dire di che giorno è: aprendo un pasto da un'altra data non sa quale giorno sta guardando.
- **Prova**: lettura del codice (le schermate fatte sono su iOS 26, dove la data si vede). Non provato su un simulatore iOS 18.
- **Correzione**: sotto iOS 26 mettere la data in una riga di testo `.secondary` in cima alla lista (o nel titolo del dettaglio). **Sforzo**: piccolo.

### 2. Filtri della libreria alti solo 28 pt — gravità bassa
- **Dove**: `Palestra/LibreriaView.swift:111-125` (`.frame(minHeight: Misure.tocco - 16)`, padding verticale 8).
- **Cosa succede**: le «pillole» dei filtri (muscolo, attrezzo…) hanno area di tocco circa 28–32 pt invece dei 44 che l'app stessa dichiara in `Stile.swift` («.tocco 44, area minima di ogni cosa toccabile»). Si sbaglia facilmente il tocco con una mano sola.
- **Prova**: lettura del codice.
- **Correzione**: `.frame(minHeight: Misure.tocco)` con `.contentShape(.capsule)` e un po' più di spazio tra le pillole. **Sforzo**: piccolo.

### 3. Numero della serie (menu) senza etichetta per VoiceOver — gravità bassa
- **Dove**: `Palestra/AllenamentoInCorsoView.swift:534-545`.
- **Cosa succede**: il bottone è solo il numero «1», «2», o «R». VoiceOver legge «1, menu» senza dire che è la serie né che apre riscaldamento/elimina. Gli altri menu solo-icona hanno invece l'etichetta (`:149`, `:490`, `ProgressiView.swift:50`).
- **Prova**: letto il codice: nessun `accessibilityLabel` sul `Menu`.
- **Correzione**: `.accessibilityLabel("Serie \(numero + 1)")` (o «Serie di riscaldamento») e un hint. **Sforzo**: piccolo.

### 4. Avvio scheda: due stili diversi per la stessa azione — gravità bassa
- **Dove**: `Palestra/AllenamentoView.swift:174-180` (play grigio `.secondary` nelle «Altre schede») contro il pulsante pieno «Inizia» della scheda in evidenza (`PulsanteAccento`, `Comune/Tema.swift:68`).
- **Cosa succede**: nella schermata Palestra l'azione principale compare come bottone verde pieno in alto e come triangolino grigio nelle righe sotto, che si confonde con le icone decorative e con la freccia `>` accanto. Visto nelle schermate (chiaro e scuro).
- **Correzione**: triangolo con l'accento (`Colori.accento`) o in capsula più piccola. **Sforzo**: piccolo.

### 5. Riga della spesa toccabile senza essere un bottone — gravità bassa
- **Dove**: `Dieta/SpesaView.swift:156-159`.
- **Cosa succede**: il nome del prodotto apre i giorni con `onTapGesture`. VoiceOver non lo annuncia come azionabile; c'è l'azione «Mostra i giorni» (rotore azioni), ma senza il tratto «bottone» chi usa VoiceOver non sa che ci si può toccare; con Controllo con interruttori non è raggiungibile come elemento normale.
- **Prova**: lettura del codice.
- **Correzione**: `Button` con `.buttonStyle(.plain)` o `.accessibilityAddTraits(.isButton)`. **Sforzo**: piccolo.

## 3. Da verificare
- Etichette del grafico in `Palestra/ProgressiPalestraView.swift:76-89` e `StoricoView`: `.caption2` (11 pt) con colore `.secondary`; non provate con testo grande (scalano, ma il grafico ha altezze fisse 150/200 pt, `ProgressiPalestraView.swift:92`, `StoricoView.swift:61`, e `CorpoView.swift:158` 130 pt).
- Schermate Dieta, Spesa, Progressi, Allenamento in corso non guardate nel simulatore (solo codice); `AllenamentoInCorsoView.swift:394-397` usa `.caption2` con `minimumScaleFactor(0.7)` per le intestazioni Kg/rip: a testo molto grande potrebbe tagliare.
- Widget e Live Activity (`RecuperoWidget.swift`, parecchi `lineLimit(1)`): non provati con testo grande né con nomi di esercizio lunghi.
- Colore «done» delle righe (riga «Colazione» spuntata, grigio più spento): contrasto stimato buono (testo `.secondary` su fondo scuro) ma non misurato.

## 4. Cosa funziona bene
- Sistema visivo unico (`Comune/Stile.swift`, `Tema.swift`): spaziature, raggio, area di tocco 44, numeri su stile di sistema che crescono col testo; `Contrasto.rapporto` per misurare i colori.
- Colori tutti dinamici con variante «Aumenta contrasto» (`Condiviso/Colori.swift`); testo sull'accento scuro in tema scuro, non bianco.
- Con testo gigante (AX-XXL) le schermate Oggi e Palestra si riorganizzano in colonna senza sovrapposizioni; i bottoni solo-icona hanno quasi tutti `accessibilityLabel`; schede su schermi larghi con larghezza leggibile.
