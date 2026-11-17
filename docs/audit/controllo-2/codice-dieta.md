# Controllo codice — dieta e comune (10/11/2026)

Codice letto: `iOS/Forma/Dieta/`, `iOS/Forma/Comune/`, `iOS/Condiviso/`, `FormaApp.swift`, `HomeView.swift`, `ProgressiView.swift`, più i punti di `index.html` che toccano il JSON (modelli, backup, spesa, acqua/olio, PDF BIA). Niente simulatore né build: ogni punto è stato verificato leggendo il codice riga per riga.

## In breve
- L'area è in buono stato: le correzioni delle PR #23–#30 reggono (salvataggio atomico, copia dei file illeggibili, promemoria serializzati, indici protetti).
- Non ho trovato crash certi: niente force unwrap pericolosi, indici dei giorni sempre protetti dal controllo «7 giorni».
- C'è **un punto alto**: modificando o sostituendo un piano, le spunte dei pasti con nome cambiato spariscono per sempre.
- Due punti medi (misure senza controllo dei valori, import che cancella tutto senza rete) e alcune rifiniture basse.
- La compatibilità JSON con la web app è a posto (stessi nomi di campo, nessun campo obbligatorio nuovo).

## Cosa non va

### 1. Le spunte dei pasti si perdono se il nome del pasto cambia — gravità ALTA
- **Dove:** `iOS/Forma/Dieta/Archivio.swift:279-297` (`cambiaPiani`), usato da `aggiungiPiano`, `sostituisciPiano`, `eliminaPiano`.
- **Cosa succede:** le spunte sono salvate per posizione del pasto; quando il piano cambia, l'app le riassegna cercando il pasto con lo stesso nome (`chiaviPasti`). Se il nome non esiste più nel piano nuovo (`firstIndex(of:)` dà nil) la spunta viene scartata (`continue`), insieme alla scelta dell'alternativa (`opt`). Scenario: l'utente corregge un refuso («Spunto» → «Spuntino») in un piano iniziato mesi fa: tutte le spunte di quel pasto, in tutti i giorni da `dal` in poi, spariscono e non c'è modo di recuperarle. Stessa cosa quando arriva il nuovo PDF del nutrizionista con nomi diversi («Spuntino mattina») e inizia oggi o prima: le spunte già messe oggi scompaiono.
- **Prova:** lettura del codice. `slot` nuovo parte vuoto e si riempie solo per i nomi che trovano corrispondenza; `dieta[iso] = r` sovrascrive il registro.
- **Correzione proposta:** quando un nome non trova corrispondenza, tenere la spunta alla stessa posizione se il numero di pasti è uguale (o se il nome è il solo cambiato), oppure, nel dubbio, non toccare i giorni già passati. Test: rinomina di un pasto con giorni già spuntati.
- **Sforzo:** medio.

### 2. Il modulo delle misure accetta qualsiasi numero — gravità MEDIA
- **Dove:** `iOS/Forma/Dieta/EditorMisura.swift:60-64` (✓ attivo se c'è un numero) e `:106-116` (`salva`).
- **Cosa succede:** il peso può essere 0, negativo o 800 (virgola dimenticata): il foglio veloce di Oggi invece lo blocca fuori da 0–500 (`PesoVeloce.swift`, `kg`). Un 800 distorce il grafico, la carta «Peso» di Oggi e la variazione a 30 giorni. Inoltre, in `salva`, ogni campo che non si legge (es. «80,5kg», «ottanta») diventa nil senza avviso: se era un valore già presente (vita, BMR…) viene cancellato in silenzio.
- **Prova:** lettura: `leggiNumero` accetta qualsiasi numero finito, `m[c] = leggiNumero(...)` per tutti i campi.
- **Correzione proposta:** stesso controllo del foglio veloce per il peso (0–500) e limiti ragionevoli per gli altri; se un campo ha testo non leggibile, segnalarlo invece di svuotarlo.
- **Sforzo:** piccolo.

### 3. «Importa backup» sostituisce tutto senza una copia di sicurezza — gravità MEDIA
- **Dove:** `iOS/Forma/Comune/Backup.swift:26-39`, usato da `ImpostazioniSezioni.swift` (alert «Importa»).
- **Cosa succede:** `archivio.stato = ...` (e `palestra.stato`) rimpiazza i dati attuali; il salvataggio dopo 400 ms sovrascrive `dieta.json`. Se l'utente sceglie il file sbagliato (un vecchio backup della web app, un backup di un altro profilo) mesi di dati sono persi: l'alert avvisa ma non c'è modo di tornare indietro.
- **Prova:** lettura; nessuna copia del file prima dell'import (a differenza del caso «file illeggibile», che la fa).
- **Correzione proposta:** prima di sostituire, salvare una copia dei dati attuali nella cartella delle copie (stessa lista «Copie dei dati non letti», con un nome come `dieta-prima-import-…`).
- **Sforzo:** piccolo.

### 4. Un elemento sbagliato in un elenco fa perdere tutto l'elenco — gravità BASSA
- **Dove:** `iOS/Forma/Dieta/Modelli.swift:402-406` (`valore`), usato per `piani`, `bia`, `dieta`, `giorni`, `pasti`, `alimenti`.
- **Cosa succede:** `valore` fa `try? decodeIfPresent` sull'intero array. I campi dei singoli oggetti sono tolleranti, ma se un elemento non è un oggetto (es. `null` o una stringa dentro `bia` o `piani`, per un backup modificato a mano) l'array intero diventa `[]`, e al salvataggio successivo il file viene sovrascritto senza alcun avviso.
- **Prova:** lettura. Non è raggiungibile dall'app o dalla web app normale, solo da file rovinati o modificati.
- **Correzione proposta:** per gli array decodificare elemento per elemento e scartare solo quelli non validi.
- **Sforzo:** piccolo.

### 5. Date non valide diventano «oggi» in silenzio — gravità BASSA
- **Dove:** `iOS/Forma/Comune/Utilita.swift:63-67` (`Giorni.data`: `?? Date()` e `guard p.count == 3 else { return Date() }`).
- **Cosa succede:** una misura senza data (decodifica con `data = ""`) viene disegnata nel grafico e nelle liste con la data di oggi; un piano senza `dal` (`""`) vale per tutte le date passate; `Giorni.aggiungi("", -1)` dà «ieri», quindi chiuderebbe altri piani a una data sbagliata.
- **Prova:** lettura (`CorpoView.grafico` usa `Giorni.data(m.data)`; `piano(per:)` confronta `p.dal <= iso`).
- **Correzione proposta:** scartare in decodifica misure con `data` non valida e piani con `dal` non valida.
- **Sforzo:** piccolo.

### 6. Dieta e Spesa non seguono la mezzanotte con l'app aperta — gravità BASSA
- **Dove:** `iOS/Forma/Dieta/DietaView.swift:57-69` e `SpesaView.swift:57-63` (aggiornano `ultimoOggi` solo quando cambia `scenePhase`); `HomeView.swift` invece ascolta anche `significantTimeChangeNotification`.
- **Cosa succede:** se l'app resta aperta in primo piano da domenica a lunedì, la striscia dei giorni resta sulla settimana vecchia e il carrello della spesa propone ancora la settimana vecchia finché l'app non va in background e torna.
- **Prova:** lettura.
- **Correzione proposta:** aggiungere lo stesso `onReceive(significantTimeChangeNotification)` di Oggi.
- **Sforzo:** piccolo.

### 7. Quantità come «2-3 fette» o «1/2» nella spesa — gravità BASSA
- **Dove:** `iOS/Forma/Dieta/Archivio.swift`, regex in `vociSpesa` (riga ~423) e `numeroQuantita`.
- **Cosa succede:** «2-3 fette» viene letto come «2» senza unità (finisce come numero nudo nella somma dei pezzi); «1/2 melone» non conta niente («a piacere»). Non sono i casi minori già noti (plurali, «grammi/g»).
- **Prova:** lettura della regex: `(?![\d\/])` blocca la frazione, il trattino ferma il numero.
- **Correzione proposta:** trattare gli intervalli «a-b» prendendo il valore più alto (o il primo con segnalazione) e le frazioni «a/b» come decimale.
- **Sforzo:** piccolo.

### 8. L'editor del piano non toglie i pasti vuoti, contrariamente al commento — gravità BASSA
- **Dove:** `iOS/Forma/Dieta/EditorPianoView.swift:148-158` (`salva`).
- **Cosa succede:** il commento dice «Pasti senza nome o senza alimenti non servono» ma si tolgono solo i pasti senza nome e gli alimenti senza nome. Un pasto con nome e zero alimenti (o un'alternativa vuota) resta: Oggi mostra una riga di pasto da spuntare senza nessun alimento.
- **Prova:** lettura.
- **Correzione proposta:** togliere anche le alternative senza alimenti e i pasti rimasti senza alternative.
- **Sforzo:** piccolo.

### 9. `aderenza()` è codice morto — gravità BASSA
- **Dove:** `iOS/Forma/Dieta/Archivio.swift:301`.
- **Cosa succede:** nessuna vista la chiama (grep su tutto `iOS/Forma`). Non fa danni, ma calcola con una regola (7 giorni, oggi escluso) che nessuno ha verificato.
- **Correzione proposta:** toglierla o usarla (per esempio in Progressi).
- **Sforzo:** piccolo.

## Da verificare (sospetti senza prova)
- **Promemoria del mattino acceso senza scelta.** `Promemoria.mattino` vale `true` per default e `eseguiProgrammazione` usa `stato.promemoria ?? Promemoria()`: con il permesso notifiche già dato (per la palestra) e `promemoria` nil, parte la notifica «Ecco la dieta di oggi» alle 9:00 senza che l'utente l'abbia attivata. Succede anche dopo aver importato un backup Forma vecchio senza il campo `promemoria`. Va chiarito se è voluto (il benvenuto potrebbe spiegarlo).
- **Spesa con giorni già passati.** La lista della settimana corrente comprende anche i pasti di lunedì-mercoledì già consumati, se oggi è giovedì. Può essere una scelta di prodotto: da decidere con l'utente.
- **Importa quando il salvataggio è bloccato** (`salvataggioBloccato`): l'import sembra riuscito ma non viene salvato; i dati importati si perdono alla chiusura. L'avviso «Dati non disponibili» compare solo all'avvio.
- **Ordine di corrispondenza dei reparti** (`Reparti.swift`): si ferma alla prima parola del nome che combacia; nomi come «Insalata di tonno» finiscono in frutta e verdura. Da provare con i piani veri del nutrizionista.

## Cosa funziona bene
- Decodifica tollerante campo per campo (`valore`), con default sensati; `Stato` rifiuta solo l'assenza totale di profili e poi tiene la copia del file.
- Nessun force unwrap pericoloso nell'area: ogni `[0]` o `!` è dietro un controllo (profili non vuoti, `scelto != nil`, `visti[n]!` appena scritto); `piano(per:)` richiede 7 giorni, quindi `giorni[indice]` non va mai fuori limite.
- Scrittura atomica, mai dati vuoti (`FileDati.scrivi`), copia unica per contenuto uguale, nessun salvataggio se il file non si legge.
- Promemoria: una programmazione alla volta, pulizia degli id vecchi, orari riportati nei limiti in decodifica, 26 notifiche al massimo (sotto il tetto di 64 di iOS).
- Spesa: tenute solo le due settimane più recenti e le sole due raggiungibili dall'interfaccia, quindi `salvaSettimane` non scarta mai una settimana appena spuntata.
- Compatibilità web: nomi dei campi invariati, `spesa` resta la settimana più vecchia, `reparti_spesa` e `spesa_prossima` ignorati dalla web senza danni; il formato `{forma, dieta, palestra}` è già gestito dalla web (`datiDaBackup`).
- Calcolo settimana/lunedì e variazione a 30 giorni (finestra 23–37 giorni) coerenti tra Oggi, Progressi e Corpo.
