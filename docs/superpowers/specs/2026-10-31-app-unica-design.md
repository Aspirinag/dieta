# èffort: app unica Dieta + Palestra

Il nome si pronuncia come «è forte» in napoletano. Sul telefono e dentro l'app si scrive sempre **èffort**, tutto minuscolo con l'accento; nei nomi tecnici e nei file si usa `Effort`.

Stato: bozza da approvare. Disegni di riferimento: <https://claude.ai/artifact/EgifRgb69bfWhvT98WAJTq>

## Perché

Dieta e Palestra diventano una sola app per iPhone, perché:

- con l'Apple ID gratuito SideStore consente 3 app, SideStore compreso, e un solo rinnovo ogni 7 giorni è più semplice di due;
- dieta, peso e allenamenti appartengono alla stessa giornata;
- date, salvataggio e backup oggi sono duplicati;
- l'interfaccia attuale non convince: icone anonime, stili diversi tra le due app, Palestra lenta da usare durante l'allenamento.

Riferimento per l'allenamento: Hevy, soprattutto la velocità con cui si registra una serie. La dieta resta funzionale: bella, chiara, precisa, senza elementi decorativi.

## Obiettivi

1. Registrare una serie in pochi secondi, con il valore precedente davanti agli occhi.
2. Vedere in una schermata cosa fare oggi: pasti, acqua, allenamento.
3. Conservare tutti i dati esistenti di Dieta e Palestra.
4. Dare all'app un'identità unica con temi curati.

## Fuori dalla prima versione

Feed social, account e sincronizzazione online, Apple Watch, Live Activity, HealthKit, libreria esercizi con animazioni, Claude Artifacts dentro l'app, ArtCraft (da provare solo quando servirà l'icona definitiva).

## Cosa sarebbe un fallimento

- Perdere anche un solo dato durante il passaggio.
- Cinque tocchi per registrare una serie.
- Calorie, pagamenti o altri elementi estranei sullo schermo durante l'allenamento.
- Un bel tema con numeri poco leggibili.

## Vincoli

- App nativa SwiftUI, iOS 18 o successivo, solo iPhone, come oggi.
- Nessun server: i dati restano sul telefono, con backup manuale.
- Distribuzione via SideStore e script di installazione, firma gratuita di 7 giorni.
- I lavori sul branch `fix/protezione-dati-e-piani` di entrambe le app (protezione dei dati, piano più recente, avviso di scadenza, test) sono il punto di partenza.
- Nessuna dipendenza esterna, come oggi.

## Prima apertura

Su una nuova installazione non ci sono profili predefiniti: Raffaele e Alessandra escono dai valori iniziali del codice. La prima schermata offre due scelte:

- **Carica il tuo profilo:** importa un backup di èffort, Dieta o Palestra;
- **Crea un profilo:** chiede il nome, poi propone di caricare il piano alimentare in PDF, saltabile.

Se sul telefono ci sono già dati, questa schermata non compare e nulla viene cancellato: chi aggiorna da Dieta ritrova i profili che ha, compresa Alessandra, e può eliminarla da Profilo. L'app continua a gestire più profili.

## Struttura

Cinque schede: **Oggi, Dieta, Allenamento, Progressi, Profilo**.

- **Oggi:** tre anelli (calorie, pasti, acqua), prossimo pasto con «Mangiato» e «Altro», allenamento del giorno con «Inizia allenamento». Nei giorni di riposo mostra il riposo e un accesso all'allenamento libero. Il promemoria del pagamento compare sotto, mai sopra.
- **Dieta:** settimana in alto; ogni pasto su una riga con alimenti, calorie e spunta; un tocco apre alternative e «Ho mangiato altro». Dopo «Mangiato» compare per pochi secondi «Annulla», anche in Oggi. Acqua e olio aumentano con un tasto e possono superare l'obiettivo. Lista della spesa da un tasto in alto.
- **Allenamento:** routine, allenamento libero, storico, cardio.
- **Progressi:** peso, misurazioni, costanza e record degli esercizi. Per ogni esercizio un grafico del carico e il massimale stimato.
- **Profilo:** profili, piani alimentari, tema, promemoria, backup con la data dell'ultimo, pagamento palestra, elenco esercizi con rinomina e unione, versione dell'app.

### Allenamento in corso

Schermata a tutto schermo, senza schede.

- In alto durata e «Termina».
- Per ogni esercizio una tabella: serie, valore precedente, kg, ripetizioni, spunta. I campi partono dai valori precedenti.
- La spunta salva la serie e avvia il recupero. Il recupero ha una durata per esercizio, tasti −15, +15 e «Salta», e una notifica se l'app è in secondo piano. Il tempo si calcola dall'orario di fine, così resta giusto dopo il secondo piano.
- Dopo una spunta compare per pochi secondi «Annulla».
- Ogni esercizio può avere una nota, riproposta la volta successiva.
- Gli esercizi si scelgono dall'elenco di quelli già usati; un nome nuovo entra nell'elenco.
- Tipi di serie: riscaldamento, normale, cedimento.
- Si possono aggiungere e togliere serie ed esercizi.
- Avviso discreto quando si supera il carico massimo.
- «Termina» mostra durata, serie, volume e record.
- Ogni serie viene salvata subito: se l'app si chiude, l'allenamento riprende da dove era.

## Dati

Un solo file, `dieta.json` come oggi, con la protezione già realizzata per i file illeggibili. `Stato` mantiene i campi attuali e aggiunge per ogni profilo:

- `routine`: nome, esercizi con serie previste e recupero, giorni previsti;
- `allenamenti`: inizio, fine, routine di partenza, esercizi con le serie (tipo, kg, ripetizioni);
- `cardio`, `pagamenti`, spunte di riscaldamento e defaticamento;
- `note` per esercizio e data dell'ultimo backup.

L'esercizio è identificato dal nome. Rinominare o unire due esercizi aggiorna routine, allenamenti e note, quindi precedenti e record restano uniti.

Il formato cresce solo aggiungendo campi, con decodifica tollerante come oggi.

### Passaggio dei dati

- L'app unica mantiene il bundle ID `io.github.aspirinag.dieta`: si aggiorna sopra Dieta e ne conserva i dati.
- I dati di Palestra sono in un'altra app e iOS non li rende accessibili. Prima di aggiornare si esporta il backup da Palestra, poi lo si importa con «Importa backup di Palestra».
- Gli allenamenti importati vanno nel profilo attivo.
- L'importazione converte: serie raggruppate per giorno in un allenamento ciascuna, sessioni cardio, calendario, pagamenti e piano A/B in routine.
- Importare due volte lo stesso file non deve duplicare nulla.
- Palestra si elimina solo dopo aver verificato i dati nell'app nuova.
- Prima dell'importazione viene conservata una copia del file dati.

## Rinnovo e backup

L'avviso di scadenza dei 7 giorni offre anche «Esporta backup», perché i dati stanno solo sul telefono.

## Versioni

- Numero `maggiore.minore.correzione`, una sola fonte in `MARKETING_VERSION`.
- Ogni tappa del piano è una versione minore, con le sue voci in `CHANGELOG.md`. Dieta era 2.0; la prima versione completa di èffort è la 3.0.0.
- Una release si pubblica solo quando su `main` arriva un numero nuovo, con le note prese dal changelog.

## Aspetto

- Temi: **Halloween** (predefinito), **Giorno** (la sua versione chiara), **Notte** (viola), **Ossidiana** (quasi nero). Tutti con gradienti su fondo e schede.
- Il tema si sceglie in Profilo e viene salvato. Il tema predefinito resta scuro anche con iPhone in modalità chiara.
- Sul tema chiaro il verde neon compare solo su tasti e spunte; testi, anelli e timer usano il verde scuro.
- Font: Georgia in tutta l'app, numeri compresi, per scelta del proprietario. Fanno eccezione solo gli elementi di sistema che iOS non lascia cambiare, come avvisi e selettori file. Le cifre di Georgia hanno altezze e larghezze diverse: nel timer e nelle colonne di kg e ripetizioni ogni cifra sta in una casella di larghezza fissa. La lettura va controllata sul telefono.
- Viola come terzo colore anche nel tema Halloween.
- Testo grande di iOS supportato in tutte le schermate, contrasto minimo 4.5:1, tasti di almeno 44 punti.

## Nomi

BIA diventa Misurazioni, Andamento diventa Progressi, Scheda pesi e Pesi diventano Allenamento, Schema diventa Piano alimentare, Scambia A e B diventa Inverti le settimane.

## Ordine dei lavori

1. Portare su `main` il lavoro esistente di Dieta e le correzioni, dopo la tua approvazione.
2. Temi, font e componenti condivisi.
3. Nuova struttura a cinque schede con Oggi e Dieta.
4. Modello dati dell'allenamento e importazione da Palestra, con test.
5. Allenamento in corso, routine e storico.
6. Progressi.
7. Icona, nome definitivo e script di installazione.
8. Prova su iPhone vero con i dati reali.

Ogni passo lascia l'app funzionante. L'importazione si prova con una copia del tuo backup.

## Test

Unit test per conversione, record, recupero dell'allenamento interrotto e formato dei dati. Controllo nel simulatore di ogni schermata in tutti i temi e con il testo più grande. Prova finale su iPhone, compreso l'avviso di scadenza.

## Decisioni prese

- Nome: **èffort**, sempre minuscolo con l'accento.
- Icona: **Anello**, con varianti per i temi.
- Allenamento: nessun profilo condiviso, solo Raffaele lo usa oggi.

## Dopo la prima versione

Superserie, calcolo dei dischi, widget.

## Da decidere più avanti

- Web app: dopo la prima versione. Fino ad allora restano come sono.
- Apple Watch: dopo la prima versione, solo per l'allenamento, previa prova dell'installazione su dispositivi veri.

## Scelte lasciate a chi costruisce

Struttura interna dei file, animazioni, testi secondari e colori esatti entro i temi approvati.
