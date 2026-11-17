# Controllo codice — palestra (10/11/2026)

> Copia letta: `/Users/rl/app-iphone/dieta-controllo` (commit 45bcb35). Sola lettura, niente build né simulatore: ogni punto sotto è verificato leggendo il codice riga per riga.
> Percorsi `Forma/...` = `iOS/Forma/...`.

## 1. In breve
- Il cuore della palestra regge: nessun crash o perdita di dati certi trovati. Timer, Live Activity, salvataggio e calcoli di volume sono coerenti tra loro, e le correzioni delle PR #23–#30 reggono.
- Il difetto più concreto è di **funzione**: la rotella di kg e ripetizioni ha limiti bassi (300 kg, 50 rip) che non bastano per plank in secondi o pesi grandi.
- Ci sono poi un paio di numeri mostrati in modo impreciso (massimale a 1 rip, record a corpo libero) e alcune rifiniture.
- 0 punti di gravità alta, 2 media, 6 bassa. Alcuni sospetti vanno provati su un iPhone o con un test (sezione 3).

## 2. Cosa non va

### 1. La rotella non permette di scrivere plank lunghi né pesi oltre 300 kg
- **Gravità:** media
- **Dove:** `Forma/Palestra/SpuntaSerie.swift:54-56` (`kgMassimo = 300`, `ripMassimo = 50`, passo 0,5), `Forma/Palestra/AllenamentoInCorsoView.swift:913-983` (`RotellaSerie`, unico modo di scrivere kg e rip), `Forma/Palestra/AllenamentoView.swift:319-327` (stepper scheda: serie 1–10, rip 1–50)
- **Cosa succede:** Plank è nella libreria e le schede pronte lo propongono «3 × 30–45 s», con i secondi nel campo ripetizioni. Chi tiene il plank 60 s non può sceglierlo sulla rotella (si ferma a 50): deve premere «+1 rip» 10 volte. Lo stesso vale per leg press o stacco sopra 300 kg (da 300 a 400 kg sono 40 tocchi su «+2,5 kg») e per i dischi da 1,25 kg (il passo della rotella è 0,5 e i ± vanno a 2,5, quindi un carico come 21,25 non si scrive). Nella scheda l'obiettivo non può superare 50 rip/secondi.
- **Prova:** lette le costanti e le opzioni della rotella; non esiste un campo con tastiera per le serie (`cella` apre solo il foglio con la rotella).
- **Correzione proposta:** alzare i massimi (kg 600, rip 200 per gli esercizi a tempo) o aggiungere un campo numerico nella rotella; per Plank usare un passo a 5 s. **Sforzo:** piccolo.

### 2. «Massimale stimato (1 ripetizione)» è sbagliato quando la serie è di 1 ripetizione
- **Gravità:** media (numero sbagliato, ma solo in un caso)
- **Dove:** `Forma/Palestra/ModelliPalestra.swift:182` (`kg * (1 + rip/30)`), usato da `StoricoView.swift:29`, `ArchivioPalestra.swift:351-352` e da `andamento`
- **Cosa succede:** chi fa 100 kg × 1 vede «Massimale stimato 103,3 kg», cioè più del peso davvero sollevato per una ripetizione. Il grafico «Massimale» e il messaggio di record «massimale stimato» partono da questo numero.
- **Prova:** letta la formula (Epley senza il caso `rip == 1`).
- **Correzione proposta:** `rip == 1 ? kg : kg * (1 + rip/30)`. **Sforzo:** piccolo (aggiornare i test che usano 1 rip).

### 3. Esercizi a corpo libero: il record appare come «Peso massimo 0 kg × 12»
- **Gravità:** bassa
- **Dove:** `ArchivioPalestra.swift:619-631` (`recordPerEsercizio`), `ProgressiPalestraView.swift:205-208` (etichetta fissa «Peso massimo»), `StoricoView.swift:27-34`
- **Cosa succede:** per Piegamenti, Trazioni, Plank ecc. (kg = 0) in Progressi → Record si legge «Peso massimo · 0 kg × 12». Il record vero sono le ripetizioni; il calcolo dei record (`contaRipetizioni`) lo sa, ma questa lista no.
- **Prova:** letto il codice: `valida` accetta kg = 0 e la riga mostra sempre kg e etichetta «Peso massimo».
- **Correzione proposta:** se kg = 0 mostrare «Ripetizioni massime · 12 rip». **Sforzo:** piccolo.

### 4. Il recupero non sopravvive se iOS chiude l'app mentre ci si riposa
- **Gravità:** bassa
- **Dove:** `Forma/Palestra/TimerRecupero.swift:10-14` (fine/inizio/esercizio solo in memoria), `LiveAllenamento.swift:88-104`
- **Cosa succede:** durante un riposo l'app va in background e iOS la termina per memoria (succede in allenamento). La notifica di fine recupero arriva comunque, ma riaprendo non c'è più né la barra del recupero né il conto alla rovescia, e la Live Activity perde la riga del recupero al primo aggiornamento.
- **Prova:** il timer non è salvato da nessuna parte; l'allenamento sì (`StatoPalestra.inCorso`), quindi dopo il riavvio resta solo quello.
- **Correzione proposta:** salvare `fine`/`inizio`/`esercizio` in `UserDefaults` e ripristinarli all'avvio se `fine` è futura. **Sforzo:** piccolo-medio.

### 5. «Rimuovi esercizio» non ferma il recupero che quell'esercizio aveva fatto partire
- **Gravità:** bassa
- **Dove:** `AllenamentoInCorsoView.swift:493` (nessuna chiamata a `fermaSeAvviatoDa`), mentre «elimina serie» e togliere la spunta lo fanno (`:757-777`)
- **Cosa succede:** spunti l'ultima serie, ti accorgi che era l'esercizio sbagliato, lo rimuovi: il recupero continua (barra, Live Activity e notifica «Recupero finito») anche se la serie non esiste più.
- **Prova:** letti i tre percorsi; solo la rimozione dell'esercizio intero salta la chiamata.
- **Correzione proposta:** prima di `removeAll` chiamare `timer.fermaSeAvviatoDa` per ogni serie dell'esercizio. **Sforzo:** piccolo.

### 6. Sessione completata dal Watch: il cronometro continua a correre in barra e Live Activity
- **Gravità:** bassa
- **Dove:** `ArchivioPalestra.swift:225-242` (`compila` tiene `a.fine`), `AllenamentoInCorsoView.swift:~182` (testata: durata fissa se `fine != nil`), `TimerRecupero.swift:146` (barra: `timerInterval: a.inizio...distantFuture`), `StatoAllenamentoLive.inizio` (solo `inizio`)
- **Cosa succede:** dopo «Aggiungi esercizi e pesi» a una sessione del Watch, la schermata mostra 45:00 fisso, mentre la barra in basso e la schermata bloccata mostrano un cronometro che sale (ore dopo l'allenamento).
- **Prova:** letti i tre punti; la barra non guarda `fine`.
- **Correzione proposta:** usare lo stesso criterio (durata fissa se `fine` c'è) nella barra e nella Live Activity. **Sforzo:** piccolo.

### 7. Importazione della vecchia app: i giorni che hanno già un allenamento si perdono in silenzio
- **Gravità:** bassa
- **Dove:** `ArchivioPalestra.swift:490-491` (`giaImportati` = tutti i giorni con un allenamento qualsiasi)
- **Cosa succede:** chi importa il backup della vecchia app Palestra dopo aver già registrato un allenamento in Forma (anche oggi, o dal Watch) non ritrova le serie di quel giorno: il giorno è saltato per intero, senza avviso.
- **Prova:** il filtro è per data, non per allenamento importato.
- **Correzione proposta:** saltare solo i giorni già importati da backup (o confrontare le serie) e dire quanti giorni sono stati saltati. **Sforzo:** piccolo.

### 8. Lettura Watch: una lettura entro 60 s dalla precedente salta l'importazione
- **Gravità:** bassa
- **Dove:** `LetturaWatch.swift:36`, `Salute.swift:58-65,78-82`
- **Cosa succede:** se l'app ha appena letto la Salute (apertura) e il Watch salva un allenamento subito dopo, il risveglio in background non importa niente (`leggi` ritorna nil) e la notifica «Sessione palestra registrata» non arriva. L'allenamento si recupera solo alla successiva lettura (non si perde: l'ancora non avanza).
- **Prova:** letta la guardia sull'intervallo minimo, che vale anche per i risvegli in background.
- **Correzione proposta:** non applicare il limite quando la chiamata viene dall'osservatore. **Sforzo:** piccolo.

## 3. Da verificare
- **Possibile crash eliminando una voce nell'editor scheda:** `AllenamentoView.swift:259-266` crea un `Binding` con indici `i`/`j` catturati; se SwiftUI rivaluta la riga appena eliminata, `routine[i].voci[j]` può uscire dall'indice. Da provare eliminando l'ultima voce (e con «Elimina» a scorrimento) su iPhone o con un test UI.
- **Ancora di Salute salvata prima dell'importazione:** `LetturaWatch.swift:40` scrive l'ancora, `Salute.swift:83-89` registra gli allenamenti e `salvaOra` arriva dopo. Se iOS termina l'app nel mezzo, l'allenamento del Watch non viene più riletto. Finestra molto piccola, solo su iPhone vero.
- **Live Activity dopo lo swipe:** `AttivitaDiSistema.avvia` (`LiveAllenamento.swift:198-213`) ne chiede una nuova a ogni aggiornamento, non solo al rientro dell'app (oltre al caso già noto e voluto). Da vedere su iPhone se dà fastidio durante una serie.
- **Codice morto:** `StatoPalestra.giorniAllenati` (`ArchivioPalestra.swift:559`) è usato solo dai test, nessuna schermata. Da togliere o da usare (es. nel calendario).
- **Precedente a più esercizi uguali:** `Palestra.precedente` (`ArchivioPalestra.swift:299-312`) guarda solo la prima occorrenza dell'esercizio nell'ultimo allenamento; se lo stesso esercizio compare due volte (es. squat prima e dopo) il «precedente» della seconda occorrenza è quello della prima.

## 4. Cosa funziona bene
- Timer di recupero: notifica ricreata a ogni ±15 s con le aggiunte messe in coda, notifica tolta se il recupero viene fermato mentre si aggiunge, niente vibrazione in ritardo dal background, `traSecondi` con minimo 1 s (nessun crash a 0).
- Live Activity: stato costruito da un'unica funzione condivisa con la spunta nell'app (stessa numerazione R/lavoro e stesso «precedente»), recupero scaduto tolto in `applica`, intervallo del widget mai rovesciato, aggiornamenti in coda ordinata, `perform` che aspetta update e notifica prima di ritornare.
- Salvataggio: scrittura atomica, mai dati vuoti, file illeggibile copiato e salvataggio bloccato con avviso, salvataggio forzato quando l'app non è attiva e dopo ogni azione dalla Live Activity.
- Fine allenamento: restano solo le serie spuntate con ripetizioni, durata limitata a 30 min dopo l'ultima serie (niente allenamenti da 14 ore se ci si dimentica), unione con la sessione del Watch senza doppioni; annullare un allenamento con dati Watch lo conserva come sessione Watch.
- Record e conteggi: `nuoviRecord` e `conteggioRecord` danno lo stesso risultato; volume e serie contano solo serie valide e non di riscaldamento.

## 5. Cosa si può verificare solo su un iPhone vero
- Tutto il comportamento Live Activity con app sospesa o terminata (punti 4 e sospetti su `avvia`).
- Risveglio in background da HealthKit con un allenamento reale del Watch (punto 8 e ancora di Salute).
- Notifica di fine recupero con telefono bloccato e pulsante «Ancora 30 s».
