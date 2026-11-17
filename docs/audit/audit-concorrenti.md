# Forma contro i concorrenti (novembre 2026)

Note sul metodo: ho letto README e codice di `iOS/Forma` (circa 9.500 righe) e fatto ricerche web. Quasi tutte le fonti trovate sono blog di app concorrenti (Fitia, Jefit, Boostcamp, Nutrola...), quindi di parte: i confronti sono indicativi. Su Dietosystem e MioDietista non ho trovato niente di verificabile; ho guardato Nutrium, Segui-Mi (Medimatica), DietoPro, Nutriplan. Prezzi: da controllare negli store. Alcune funzioni di Forma (sostituzioni, riscaldamento, superset, widget recupero) le ho viste solo cercando nel codice, non provandole.

## Cosa fa Forma oggi (in breve)
- Dati solo sul telefono, niente account. Piano dieta letto dal PDF o scritto a mano, pasti da spuntare, Spesa per reparto, acqua, peso, misure, BIA, promemoria.
- Palestra: schede A/B, allenamento in corso con spunta serie e recupero, Live Activity e widget, record e 1RM stimato, calendario, grafici, allenamenti dell'Apple Watch letti da Salute.
- Italiano, interfaccia semplice, backup file; esiste anche una web app.

## Dieta

### MyFitnessPal
- Meglio di Forma: database enorme di cibi e ristoranti, scansione codice a barre, diario libero di calorie e macro, tanti collegamenti con altre app.
- Meglio Forma: nessun abbonamento, nessun account, nessuna pubblicità, segue il piano del nutrizionista invece di farti contare tutto. Le recensioni 2026 lamentano un redesign lento e molte funzioni a pagamento.
- Gli utenti si aspettano e Forma non ha: ricerca alimenti con valori nutrizionali, barcode, totale calorie/macro del giorno.

### Yazio
- Meglio: diario pulito, digiuno intermittente, ricette, database europeo con buona copertura italiana, prezzo basso.
- Meglio Forma: piano reale del professionista, import PDF, lista spesa, misure e BIA.
- Mancano a Forma: ricette, totali nutrizionali, grafico peso con obiettivo.

### Lifesum
- Meglio: interfaccia curata, piani a tema, abitudini, valutazione dei pasti.
- Meglio Forma: segue il piano vero, non uno generico; privacy.
- Mancano: promemoria "intelligenti" sulle abitudini, ricette.

### Cronometer
- Meglio: oltre 80 nutrienti (vitamine, minerali), dati accurati, importa dati dai dispositivi.
- Meglio Forma: molto più semplice, gratuita, in italiano.
- Mancano: valori nutrizionali per pasto (anche solo kcal e macro), se il PDF li contiene.

### MacroFactor
- Meglio: obiettivi che si aggiornano da soli in base all'andamento del peso (media mobile), registrazione molto veloce, nessuna pubblicità.
- Meglio Forma: segue il nutrizionista (che di solito non vuole che l'app cambi la dieta), gratuita.
- Mancano: tendenza del peso con media mobile e proiezione verso l'obiettivo. Questa si può fare senza toccare la dieta.

### App dei nutrizionisti: Nutrium, Segui-Mi, DietoPro, Nutriplan
- Meglio: il nutrizionista invia il piano direttamente (nessun PDF), lo aggiorna e il paziente lo vede subito; notifiche agli orari dei pasti; il paziente scrive diario e foto, il professionista vede i dati; chat; appuntamenti. Nutrium costa al professionista da circa 15 a 50 euro al mese (fonte non recente), l'app paziente è gratuita ma funziona solo con un professionista che usa Nutrium.
- Meglio Forma: funziona con qualsiasi PDF, senza che il nutrizionista installi niente o paghi niente; palestra e misure nello stesso posto; privacy totale.
- Mancano a Forma: un modo semplice per il paziente di mandare i dati al nutrizionista (peso, misure, aderenza) prima della visita; un riepilogo stampabile o in PDF; un modo per il nutrizionista di dare un piano senza PDF (per esempio un file o un link che Forma apre). Questo conta molto per l'idea di diffusione.

## Palestra

### Strong
- Meglio: registrazione velocissima, tastiera e note per serie, superserie, timer, grafici, Watch app, esporta CSV, libreria di esercizi, calcolatore dei dischi.
- Meglio Forma: collegata alla dieta, calendario, Live Activity, gratuita.
- Mancano: app per Apple Watch propria (Forma legge solo gli allenamenti da Salute), esporta CSV, dischi.

### Hevy
- Meglio: feed e amici (non adatto a Forma), ma anche routine condivisibili, libreria con animazioni, grafici per muscolo, misure, note, serie di riscaldamento, cartelle di schede, AI per programmare.
- Meglio Forma: privacy, italiano, dieta.
- Mancano: immagini o animazioni degli esercizi, grafico per gruppo muscolare, duplica e condividi una scheda come file.

### Fitbod
- Meglio: genera l'allenamento da solo in base al recupero muscolare e all'attrezzatura. Costoso e senza versione gratuita.
- Meglio Forma: l'utente ha già una scheda del preparatore; non serve generarla.
- Manca: suggerimento del peso e delle ripetizioni successive (progressione) in base all'ultimo allenamento. Questa è piccola e utile anche in Forma.

### JEFIT
- Meglio: libreria enorme (oltre mille esercizi con video), piani pronti, analisi dettagliata, misure.
- Meglio Forma: semplice, niente pubblicità né account.
- Mancano: video o immagini, un modo rapido di creare esercizi propri con foto, piani pronti (non necessario).

## Le 10 cose che mancano o vanno migliorate

Ordinate per valore diviso sforzo.

| # | Cosa | Perché | Valore | Sforzo |
|---|------|--------|--------|--------|
| 1 | **Riepilogo per il nutrizionista**: foglio condivisibile (PDF o testo) con peso, misure, BIA e aderenza ai pasti dell'ultimo periodo | Chiude il giro con il nutrizionista; è l'argomento di vendita per proporla ai professionisti. Le app dei nutrizionisti lo fanno | Alto | Medio |
| 2 | **Tendenza del peso** (media mobile a 7 giorni, linea verso l'obiettivo) nei grafici del Corpo | Il peso quotidiano oscilla e scoraggia; MacroFactor ne ha fatto il punto di forza. Non cambia la dieta | Alto | Piccolo |
| 3 | **Peso e ripetizioni suggeriti** nell'allenamento in base all'ultima volta (con "ripeti" in un tocco) | Strong, Hevy e Fitbod lo fanno: è il motivo per cui si apre l'app in palestra | Alto | Piccolo |
| 4 | **Importazione più affidabile del PDF**, con schermata di controllo prima di salvare e correzione facile di alimenti e grammi | È la prima impressione; i PDF dei nutrizionisti italiani sono molto diversi. Se fallisce, l'app non si usa | Alto | Medio |
| 5 | **Kcal e macro del giorno** (e dello spuntato) se il piano li indica o li ricavi da un piccolo database italiano | MyFitnessPal, Yazio, Cronometer lo danno; molti pazienti lo chiedono. Solo informativo, senza obiettivi che cambiano il piano | Medio | Grande |
| 6 | **Sostituzioni e pasti fuori piano**: scegliere un'alternativa indicata dal nutrizionista e segnare "ho mangiato altro" con una nota | Succede ogni settimana; senza, l'utente smette di spuntare. Il codice ha già qualche base per le alternative | Medio | Medio |
| 7 | **Immagini o brevi animazioni degli esercizi** e note per esercizio | JEFIT e Hevy; aiuta i principianti. Si possono usare foto proprie per non pesare sull'app | Medio | Grande |
| 8 | **Apple Watch**: app minima per spuntare le serie e vedere il recupero | Strong e Hevy ce l'hanno; oggi Forma legge solo da Salute | Medio | Grande |
| 9 | **Backup automatico su iCloud** (oltre al file) | Niente account ma i dati non si perdono col telefono nuovo o con la firma di 7 giorni scaduta; paura n.1 di chi usa un'app personale | Medio | Medio |
| 10 | **Esportazione dati** (CSV allenamenti e misure) e **widget** Oggi con prossimo pasto | Strong esporta CSV; i widget tengono l'app davanti agli occhi. Piccole rifiniture | Basso | Piccolo |

## Consigli
- Per la diffusione tra i nutrizionisti: fare prima 1 e 4. Con quelli, il nutrizionista vede un vantaggio senza dover cambiare software.
- Da evitare: feed, amici, classifiche, calorie obbligatorie, obiettivi automatici che cambiano la dieta: sono il punto debole delle app generiche e un conflitto con il nutrizionista.
- Da fare presto, a basso costo: 2 e 3.

## Fonti
- https://www.welling.ai/articles/best-calorie-tracker-apps-expert-reviews-rankings
- https://fitia.app/learn/article/best-myfitnesspal-alternatives-2026/
- https://www.jefit.com/blog/fitbod-vs-strong-vs-jefit-vs-hevy
- https://www.sensai.fit/blog/hevy-vs-strong-vs-fitbod-vs-jefit
- https://help.nutrium.com/en/articles/3372169-what-are-the-features-of-the-nutrium-mobile-app-for-nutrition-clients
- https://www.capterra.it/software/173803/nutrium
- https://coachway.io/it/migliori-app-per-nutrizionisti/
