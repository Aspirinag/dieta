# Linee guida UI/UX per app health, fitness, workout-logging, dieta + Hevy come riferimento

Data ricerca: 2026-11-05. Lingua: italiano. Convenzione: **[F]** = fatto da fonte primaria; **[S]** = studio con limiti dichiarati; **[O]** = opinione/inferenza mia (non supportata direttamente da una fonte). Ogni regola: Regola / Come si verifica / Fonte.

Immagini Hevy scaricate in: `/Users/rl/app-iphone/research_notes/Linee guida UI UX/hevy/` (hevy_3, 5, 6, 8, 9, 10, 13, 17, 18, 19; solo le versioni iPhone, 859x1860; scartate le versioni iPad). Sono immagini di marketing dell'App Store (mockup), non schermate native a piena risoluzione: le misure sono stime.

---

## 1. Guida Apple (HIG) per il genere

### Takeaway
Apple chiede, per il fitness: poche metriche rilevanti e leggibili in movimento, controlli facili da trovare, niente distrazioni durante la sessione, riepilogo a fine sessione, scarto delle sessioni brevissime, richiesta permessi HealthKit solo nel contesto, uso fedele degli Activity ring, Live Activity glanceable, grafici accessibili. Le pagine HIG lette sono quelle correnti (JSON developer.apple.com, scaricato 2026-11-05); la pagina Workouts dice esplicitamente che vale per watchOS/iPhone/iPad ma gli esempi sono Apple Watch.

### Regole
1. **Regola:** Durante una sessione attiva mostra i dati che interessano di più (tempo, calorie, distanza) e controlli rilevanti (pausa/ripresa/stop, giri/intervalli); non mostrare elenco allenamenti o altre parti dell'app. **Come si verifica:** la schermata sessione ha ≤ ~4 metriche e nessuna navigazione verso sezioni non pertinenti; pausa/stop raggiungibili in 1 tap. **Fonte:** [HIG Workouts](https://developer.apple.com/design/human-interface-guidelines/workouts) [F]
2. **Regola:** La sessione attiva deve essere riconoscibile "a colpo d'occhio" (aspetto distinto, valori che si aggiornano). **Verifica:** test 2 secondi: un osservatore distingue sessione attiva da riposo. **Fonte:** HIG Workouts [F]
3. **Regola:** Controlli di pausa/ripresa/stop facili da trovare e toccare, con feedback chiaro di inizio/fine sessione. **Verifica:** target ≥ 44x44 pt; feedback (aptico/visivo) all'avvio e allo stop. **Fonte:** HIG Workouts; target 44x44 pt da [HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) [F]
4. **Regola:** Testo leggibile in movimento: font grandi, contrasto alto, informazione principale in evidenza. **Verifica:** dato principale ≥ Dynamic Type "large" + contrasto ≥ 4.5:1 (soglia WCAG, mia aggiunta [O]); leggibile a ~50 cm con una mano libera. **Fonte:** HIG Workouts [F]
5. **Regola:** Fornisci un riepilogo a fine sessione che confermi la fine e mostri i dati registrati; valuta di includere gli Activity ring. **Verifica:** esiste schermata riepilogo con durata e dati chiave dopo "Fine". **Fonte:** HIG Workouts [F]
6. **Regola:** Scarta (automaticamente o chiedendo) le sessioni brevissime. **Verifica:** avvia e termina entro pochi secondi: l'app non salva un workout fantasma senza conferma. **Fonte:** HIG Workouts [F]
7. **Regola:** Se mancano dati dei sensori, spiegalo con parole simili a quelle di Workout. **Verifica:** messaggio presente quando il dato è assente. **Fonte:** HIG Workouts [F]
8. **Regola (HealthKit):** Chiedi il permesso solo quando serve, nel contesto (es. peso quando l'utente registra il peso, non al lancio); aggiungi testo descrittivo breve alla schermata di sistema; non costruire schermate proprie che duplicano il permesso; la gestione resta in Impostazioni > Privacy. **Verifica:** nessuna richiesta HealthKit al primo avvio; nessuna schermata custom di "permessi salute". **Fonte:** [HIG HealthKit](https://developer.apple.com/design/human-interface-guidelines/healthkit) [F]
9. **Regola:** Non chiedere accesso a dati salute se l'app non offre funzionalità salute/fitness; esempio Apple: app nutrizione può leggere peso/attività e scrivere le calorie loggate. **Verifica:** ogni tipo HealthKit richiesto ha una funzione visibile che lo usa. **Fonte:** HIG HealthKit [F]
10. **Regola (Activity ring):** Usali solo per Move/Exercise/Stand, per una sola persona (con etichetta/avatar), mai come decorazione o branding, mai ricolorati, su sfondo nero, margine esterno ≥ distanza tra anelli; non replicare lo stile ad anello per altri dati senza separazione visiva. **Verifica:** ogni elemento ad anello dell'app che non è Activity ring è chiaramente diverso; nessun anello nell'icona. **Fonte:** [HIG Activity rings](https://developer.apple.com/design/human-interface-guidelines/activity-rings) [F]. **Implicazione [O]:** per un progresso settimanale personalizzato meglio barra/segmenti, non un finto Activity ring.
11. **Regola:** Non mandare notifiche che ripetono i progressi Move/Exercise/Stand già inviati dal sistema. **Verifica:** nessuna notifica duplicata. **Fonte:** HIG Activity rings [F]
12. **Regola (Live Activity):** Usale per compiti con inizio e fine definiti (≤ 8 ore; un workout è esempio citato: metriche in tempo reale e controlli per pausa/annulla); solo ciò che serve a colpo d'occhio, niente pubblicità, niente dati sensibili in schermata blocco; supporta compact, minimal, expanded, Lock Screen (e StandBy). **Verifica:** la Live Activity mostra 1-2 valori (es. timer riposo/tempo) leggibili in compact; nessuna promo. **Fonte:** [HIG Live Activities](https://developer.apple.com/design/human-interface-guidelines/live-activities) [F]
13. **Regola (Charts):** Scegli il mark per il messaggio: barre per somme per periodo (es. passi al giorno) o confronto categorie, linee per andamento, punti per valori singoli; combinare linea+punti è ok; un grafico efficace evidenzia poche informazioni chiave. **Verifica:** ogni grafico ha un solo messaggio dichiarabile in una frase. **Fonte:** [HIG Charts](https://developer.apple.com/design/human-interface-guidelines/charts) [F]
14. **Regola (Charts, accessibilità):** Ogni grafico accessibile (etichette VoiceOver, Audio Graphs); non affidarti al solo colore per distinguere serie; separa visivamente aree di colore contigue. **Verifica:** VoiceOver legge titolo, serie e valori; il grafico resta leggibile in scala di grigi. **Fonte:** HIG Charts; "Convey information with more than color alone" in HIG Accessibility [F]
15. **Regola (Accessibilità):** Supporta testo ingrandito (Dynamic Type) e target 44x44 pt. **Verifica:** a dimensione testo massima nessun troncamento che nasconde kg/reps; ogni controllo ≥ 44x44 pt. **Fonte:** HIG Accessibility [F]

---

## 2. Usabilità mHealth e fitness: euristiche, MARS, logging burden

### Takeaway
La ricerca mostra che (a) il logging abbandonato è guidato da fatica di inserimento, dimenticanza, valore decrescente e imbarazzo/colpa, (b) chi smette spesso non ha fallito: ha raggiunto l'obiettivo o la routine si è consolidata, (c) gli strumenti di valutazione (MARS, euristiche mHealth) forniscono checklist ma non soglie quantitative.

### Fatti citati
- Epstein et al. (UbiComp 2015) propongono il "lived informatics model": decidere di tracciare/scegliere lo strumento, poi raccolta-integrazione-riflessione-azione, poi **lapsing** (4 tipi: dimenticare, fatica di mantenimento, saltare intenzionalmente, sospendere) e ripresa; survey su 105/99/83 tracker (attività fisica, finanze, posizione) + 22 interviste. Raccomandano di progettare per lapse e ripresa, migrazione tra strumenti, adattamento degli obiettivi. [F] — [Epstein 2015 PDF](https://my.eng.utah.edu/~cs5540/au16/readings/PersonalInformatics-Epstein2015.pdf)
- Dopo una pausa lunga, mostrare lo storico (con i "fallimenti") può demotivare chi riprende; alcuni preferiscono ripartire da zero. [F, discussione degli autori] — stesso PDF
- Il 15%/14%/17% dei tracker di attività/finanze/posizione si dichiara "corrente" pur non usando lo strumento da ≥ 1 mese. [F] — stesso PDF
- Epstein et al. CHI 2016: l'abbandono non è sempre fallimento, alcuni avevano raggiunto l'obiettivo. [F via riassunto] — [Beyond Abandonment (library.selfresearch.org)](https://library.selfresearch.org/research/beyond-abandonment-to-next-steps-understanding-and-designing-for-life-after-personal-informatics-tool-use/). Nota: Consolvo non è autrice del modello lived informatics (verificato dalla ricerca).
- Cordeiro et al. (CHI 2015, DECAF; survey su 141 ex/attuali food journaler, ~270 risposte per le domande sul "mangiare sano"): motivo più citato per non loggare = dimenticare (54% ha saltato una voce per questo); 40% ha scelto di non loggare un cibo troppo difficile da inserire; 40% non sapeva cosa c'era nel pasto; 20% contesti sociali; **13% evita di loggare quando mangia "male" o supera il budget calorico**; alcuni evitano cibi difficili da tracciare e scelgono confezionati ("negative nudge"). Su 141, 94 non loggano più; motivi di stop: valore ridotto nel tempo 37% (abitudine formata o obiettivo raggiunto), troppo sforzo 25%, troppo tempo 16%, perdita di motivazione 10%. Solo 9% (24) cita le calorie come definizione di mangiare sano; la maggior parte cita verdure/frutta/equilibrio. [S, autoriferito] — [Cordeiro CHI 2015](https://homes.cs.washington.edu/~jfogarty/publications/chi2015-decaf.pdf)
- Stoyanov et al. 2015: MARS = 23 voci, 4 scale oggettive (engagement, functionality, aesthetics, information) + 1 soggettiva; alfa .90, ICC .79; correlazione moderata con le stelle iTunes. uMARS è la versione per utenti finali. [F] — [JMIR mHealth 2015;3(1):e27](https://mhealth.jmir.org/2015/1/E27)
- Euristiche mHealth: revisione sistematica (Galavi 2024) 17 studi, 79 euristiche condensate in 20, incluse "Navigation" e "User engagement" come nuove; HE4EH (Khowaja & Al-Thani 2020) copre self-monitoring e cambio di comportamento; EAUHHCAMA propone 14 euristiche per app fitness context-aware. [F, dai riassunti] — [HE4EH, PMC7657716](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7657716/); [revisione Galavi 2024](https://doaj.org/article/55c5a3878965461a9784f2e0f8b9fb76); [EAUHHCAMA](https://unpaywall.org/10.1166%2FJMIHI.2020.3255)

### Regole derivate
1. **Regola:** Ogni inserimento ricorrente deve costare pochi tap: pre-compila, ricorda l'ultimo valore, ammetti preferiti/recenti. **Verifica:** conta i tap per loggare una serie ripetuta (obiettivo ≤ 2) e per un alimento abituale. **Fonte:** Cordeiro 2015 (40% salta cibi difficili da inserire; 25% "troppo sforzo") [S]; formulazione come regola = [O].
2. **Regola:** Non far pagare l'omissione con colpa: permetti di registrare in ritardo, modificare e saltare senza penalità visibile. **Verifica:** nessuna schermata rossa/avviso al salto di un giorno; modifica retroattiva possibile. **Fonte:** Cordeiro 2015 (13% evita di loggare ciò che sente "sbagliato") [S]; Epstein 2015 [F]. Regola = [O].
3. **Regola:** Progetta il rientro dopo una pausa: ripartenza neutra, senza elenco di cosa si è perso; storico disponibile ma non spinto. **Verifica:** dopo 14 giorni di inattività la home mostra "Riprendiamo" e non contatori azzerati/rossi. **Fonte:** Epstein 2015 [F]; formulazione = [O].
4. **Regola:** Non misurare il valore dell'app solo dall'uso continuo: chi ha raggiunto l'obiettivo o ha costruito l'abitudine può smettere legittimamente. **Verifica:** metrica di retention affiancata da "obiettivo raggiunto"; l'app non usa dark pattern per trattenere. **Fonte:** Cordeiro 2015 (37%); Epstein 2016 [S/F]. Regola = [O].
5. **Regola:** Valuta l'app con MARS (engagement/functionality/aesthetics/information) come checklist esterna. **Verifica:** compilare le 23 voci; ogni sottoscala ≥ 4/5 (soglia mia [O]; MARS non prevede soglie). **Fonte:** Stoyanov 2015 [F].
6. **Regola:** Mostra il valore dei dati loggati (grafico/tendenza) subito, perché il "valore ridotto nel tempo" è la prima causa di stop. **Verifica:** dopo il 3° log esiste una vista di progresso. **Fonte:** Cordeiro 2015 (37%) [S]; regola = [O].

### Gaps
- Studi di usabilità peer-reviewed su app di **resistance training** non trovati (solo tesi, capstone, blog). Il dato "66% dei frequentatori di palestra trova il tracking tedioso, 53% UI poco intuitive" viene da un capstone studentesco (UCalgary), da trattare come indicativo: [capstone](https://schulich.ucalgary.ca/sites/default/files/teams/4/2024%20Capstone/2024%20Capstone%20Projects/61905-96%20TrainWise%20AI%20Automated%20Workout%20Logging%20using%20AI.pdf).
- Non ho letto il testo completo di "Barriers and Negative Nudges" (Cordeiro et al. 2015), solo il riassunto e il paper DECAF che ne riporta la survey.

---

## 3. Cambio di comportamento e motivazione senza colpa

### Takeaway
Le serie (streak) motivano finché sono intatte, ma uno streak rotto, soprattutto se evidenziato e attribuito a colpa propria, riduce la persistenza (Silverman & Barasch 2023). Fogg: il comportamento avviene quando motivazione, capacità e prompt convergono; rendere il comportamento più facile è la leva più sostenibile. Obiettivi settimanali vs giornalieri: prove **miste/deboli**, non c'è un verdetto.

### Fatti citati
- Silverman & Barasch, Journal of Consumer Research 2023: dopo uno streak rotto la persistenza cala, in particolare se l'utente si sente responsabile e se la rottura è evidenziata; l'effetto si riduce se si offre la possibilità di "riparare" lo streak. [S, letto via riassunto] — [Psychology Today, riassunto](https://www.psychologytoday.com/us/blog/ulterior-motives/202306/how-broken-streaks-sap-motivation)
- Working paper Northwestern IPR 2026 (WP-26-05, ~60.000 utenti): gli effetti causali maggiori per evidenziare gli streak e per reminder personalizzati; misura engagement, non danni; gli autori dicono che le prove causali sugli streak sono limitate. [S] — [IPR wp-26-05](https://www.ipr.northwestern.edu/documents/working-papers/2026/wp-26-05.pdf)
- Obiettivi giornalieri vs settimanali (step adattivi, Fitbit, singolo caso, tesi): effetto significativo solo con obiettivi giornalieri (p=0.037), 80% li preferiva; campione piccolo. [S debole] — [Univ. Twente](https://essay.utwente.nl/essays/101038)
- CHI 2026 (Gouveia et al., 16 partecipanti, 27 giorni): un obiettivo giornaliero fisso offre una sola occasione di successo/fallimento al giorno; i micro-obiettivi situati sono un complemento; cita l'effetto "what-the-hell" (mancare il target porta ad abbandonare la giornata). [S] — [CHI 2026 microgoals](https://techandpeople.github.io/downloads/2026-chi-mikro.pdf)
- Fogg Behavior Model: B=MAP (Motivation, Ability, Prompt) devono convergere; se manca uno, il comportamento non avviene; tipi di prompt: spark, facilitator, signal; Tiny Habits riduce il comportamento finché l'abilità è altissima. Nota: alcuni blog lo scrivono come somma, il sito ufficiale lo tratta come convergenza. [F per il modello; l'efficacia empirica del modello non l'ho verificata] — [behaviormodel.org](https://behaviormodel.org/)
- Apple HIG: Activity rings sono pensati per mostrare progresso; non descrive streak né colori di fallimento. [F] — HIG Activity rings

### Regole
1. **Regola:** Non basare la motivazione sulla perdita di una serie; se usi serie, offri riparazione/"giorno di grazia" e non evidenziare la rottura. **Verifica:** dopo un giorno saltato non c'è schermata/banner/colore di "perso"; esiste un modo di recuperare. **Fonte:** Silverman & Barasch 2023 [S]; Epstein 2015 su demotivazione del rientro [F].
2. **Regola:** Preferisci misure cumulative o per finestra flessibile (es. "3 allenamenti questa settimana") a un contatore giornaliero che si azzera. **Verifica:** nessun elemento torna a zero a mezzanotte. **Fonte:** CHI 2026 microgoals (limite del target giornaliero fisso) [S]; la superiorità del settimanale **non è dimostrata** (Twente: giornaliero meglio, ma piccolo campione) → raccomandazione = [O].
3. **Regola:** Framing positivo: mostra quanto fatto ("12 serie completate") non quanto manca/mancato. **Verifica:** copy ispezionato: nessun "non hai…", "hai perso…". **Fonte:** [O], coerente con Cordeiro 2015 (13% evita di loggare ciò che sente un fallimento) [S].
4. **Regola:** Evita il rosso come colore di "fallimento" per dati dell'utente (calorie oltre budget, giorni saltati); usa colori neutri/informativi e non solo il colore (vedi HIG Accessibility). **Verifica:** nessun rosso su valori dell'utente non pericolosi; i significati hanno anche testo/icona. **Fonte:** HIG Accessibility (non affidarsi al solo colore) [F]; il divieto del rosso come scelta è [O] (nessuna fonte primaria trovata che misuri l'effetto del rosso nelle app fitness). Nota: Hevy usa rosso/verde per variazioni % nel confronto (hevy_10: freccia rossa -3%).
5. **Regola (Fogg):** Per ogni azione chiave verifica M, A, P: riduci la fatica (A) prima di aggiungere motivazione; metti prompt nel momento giusto (es. a fine serie, non a caso). **Verifica:** per ogni schermata nota il passo più costoso e riducilo; esiste un solo prompt contestuale per azione. **Fonte:** behaviormodel.org [F]; applicazione al gym = [O].
6. **Regola:** Notifiche/reminder personalizzati e rari. **Verifica:** reminder configurabili, mai ripetuti dopo un rifiuto. **Fonte:** IPR WP-26-05 (reminder personalizzati efficaci su engagement) [S]; "rari" = [O].

### Gaps
- Nessuna fonte primaria che confronti colori di feedback (rosso vs neutro) per app fitness/diet.
- Non ho trovato RCT che dimostrino che framing positivo riduca l'abbandono; la regola 3 è un'inferenza.
- Habit loop (cue-routine-reward): non ho cercato/verificato una fonte primaria; non lo uso come regola.

---

## 4. Uso in palestra (gym-specific)

### Takeaway
Non esiste (nei risultati trovati) letteratura peer-reviewed specifica su logging in palestra. Le regole sotto derivano da: HIG (target 44 pt, legibilità in movimento, Live Activity), funzioni documentate di Hevy e da interviste non accademiche. Marcate di conseguenza.

### Fatti citati
- Intervista Wodify (9 interviste): 2/3 degli utenti guarda i risultati passati e logga in palestra subito prima e dopo l'allenamento, con molti start e stop. [Blog/UX case study, non accademico] — [uxdesign.cc Wodify](https://uxdesign.cc/wodify-why-are-we-using-half-this-app-d7100e071b4b)
- Hevy: timer di riposo parte quando segni la serie come completata; default da impostazioni, override per esercizio, step 15 s; valori PREVIOUS mostrati durante il log (configurabile se da qualsiasi routine); Live Activity mostra la prestazione precedente per la serie corrente; superserie con scroll automatico. [F, documentazione Hevy] — [Rest timer](https://www.hevyapp.com/features/workout-rest-timer/), [Settings](https://help.hevyapp.com/hc/en-us/articles/33882110558743), [Live Activity](https://help.hevyapp.com/hc/en-us/articles/35649846517399), [Supersets](https://help.hevyapp.com/hc/en-us/articles/35650286563095)

### Regole
1. **Regola:** Uso a una mano, pollice: azioni primarie (spunta serie, +serie, avvia timer) nella metà inferiore o sul bordo destro dello schermo. **Verifica:** test di raggiungibilità: tutte le azioni primarie del log raggiungibili col pollice destro e sinistro senza spostare la presa. **Fonte:** [O]; coerente con HIG sui controlli facili da trovare/toccare (HIG Workouts) [F].
2. **Regola:** Target tattili ben oltre il minimo per mani sudate/guanti: minimo Apple 44x44 pt, preferibile ≥ 48-56 pt per la spunta serie con spazio tra le righe. **Verifica:** misura in pt delle aree di tocco; test con dita umide. **Fonte:** 44 pt = HIG Accessibility [F]; "≥ 48-56" = [O].
3. **Regola:** Valori precedenti già visibili e pre-compilati: l'utente conferma invece di digitare. **Verifica:** per una serie uguale all'ultima volta bastano 1 tap (spunta). **Fonte:** funzione Hevy (PREVIOUS + prefill) [F]; razionale: riduce logging burden [Cordeiro 2015, S].
4. **Regola:** Nessun modale mentre si allena; usa sheet non bloccanti, azioni inline, annulla invece di conferma. **Verifica:** dal log nessuna azione frequente (spunta, aggiungi serie, modifica peso) apre un dialogo; conferma solo per azioni distruttive. **Fonte:** HIG Workouts "evita di distrarre" [F]; "no modali" = [O].
5. **Regola:** Timer di riposo automatico alla spunta, visibile in Live Activity/Dynamic Island, con +/-15 s; non richiede di tornare all'app. **Verifica:** spunta → timer parte senza altri tap; timer visibile da schermata blocco. **Fonte:** Hevy docs [F] + HIG Live Activities [F].
6. **Regola:** Glanceability: stato sessione (tempo, volume, serie) in testata fissa leggibile da 1 m con numeri grandi; dati secondari più piccoli. **Verifica:** test 2 secondi: l'utente legge tempo e serie completate. **Fonte:** HIG Workouts (leggibilità in movimento) [F]; distanza = [O].
7. **Regola:** Stato completato non solo cromatico: spunta + variazione di sfondo/peso del testo. **Verifica:** distinguibile in scala di grigi. **Fonte:** HIG Accessibility (più del solo colore) [F].
8. **Regola:** Funzionamento offline e salvataggio continuo (se l'app crasha o la palestra non ha segnale non si perde la sessione). **Verifica:** modalità aereo: log completo senza errori; kill dell'app: sessione recuperata. **Fonte:** Hevy dichiara uso offline (App Store) [F]; criterio = [O].

---

## 5. Hevy come riferimento: descrizione precisa dalle schermate reali

Fonte: App Store [Hevy](https://apps.apple.com/us/app/hevy-workout-tracker-gym-log/id1458862350), v3.2.4 (ott 2026), rating 4.9 da ~102K, developer Hevy Studios S.L., gratis con Hevy Pro (IAP). Descrizione ufficiale: log di peso/ripetizioni/durata/RPE, valori della sessione precedente per ogni esercizio, timer di riposo automatici, superserie/drop set/warm-up/failure, grafici di forza e PR, social, foto progresso e misure, offline e sync, Apple Watch. Immagini: `hevy/hevy_3.jpg` ... `hevy_19.jpg`.

Convenzione misure: nelle immagini lo schermo interno è largo ~693 px (da x≈86 a x≈779) per un iPhone da ~393 pt, quindi ≈ 1,76 px/pt; altezza utile ~1.860 px totali immagine non lo schermo intero. Valori in pt = stime ±15% dai mockup.

### 5.1 Workout in corso (hevy_8.jpg, mockup inclinato)
- **Testata:** a sinistra chevron "v" (riduce/minimizza la sessione) + titolo "Log Workout" (centrato nel mockup); a destra icona sveglia (timer) e pulsante **"Finish"** blu pieno, angoli arrotondati, testo bianco (≈ 100x45 pt stima).
- **Riga statistiche sotto la testata** (3 colonne, etichetta piccola grigia + valore più grande): **Time** (valore in blu, es. "1h 15min"), **Volume** (es. "6 800 kg"), **Sets** (es. "18"). Solo il tempo è colorato (blu = dato "vivo").
- **Blocco esercizio:** miniatura circolare ~50 pt dell'esercizio (illustrazione), nome in **blu** "Bench Press (Barbell)" (tappabile, apre la scheda esercizio), menu "⋮" a destra; sotto una **nota** libera in nero (testo dell'utente); sotto un link blu con icona cronometro **"Rest Timer: 1min 30s"** (timer di riposo per esercizio, modificabile).
- **Tabella serie:** colonne con intestazione in maiuscolo piccolo grigio: **SET** (numero/W per warm-up in giallo arancio, visibile in hevy_5 come "W"), **PREVIOUS** (es. "40kg × 7", grigio chiaro), **KG** (icona manubrio + valore), **REPS**, e colonna spunta "✓". Valori correnti in **grassetto nero grande** (es. "40", "65", "8"), valori PREVIOUS in grigio chiaro più piccolo (gerarchia: ciò che inserisci > ciò che hai fatto).
- **Righe:** altezza della riga serie stimata ≈ 60-65 pt (circa 3,4% dell'altezza schermo 852 pt; rapporto rispetto alle ~12 righe visibili in uno schermo: ≈ 8-10 righe serie visibili con una testata e un blocco esercizio). Stima alta incertezza, essendo il mockup inclinato.
- **Stato completato:** l'intera riga diventa **verde chiaro/lime pieno** (≈ #C6FB9A, stima a occhio), con spunta bianca su **cerchio/squircle verde più scuro** (≈ #4DB32D). Righe non completate: sfondo bianco, spunta grigia in squircle grigio chiaro. Cambio di stato è doppio: sfondo + spunta (non solo colore).
- **Pulsante "+ Add Set":** barra grigio chiaro larga quanto il contenuto, testo nero con "+", sotto l'ultima serie; è un'azione secondaria (non blu).
- **Seguito:** il blocco dell'esercizio successivo ("Overhead Press (Barbell)") ha la stessa struttura; la tabella è ripetuta con colonne PREVIOUS / KG / REPS / ✓. Nessun modale visibile nel flusso di spunta.
- **Principi (da non copiare l'aspetto):** (1) tre numeri di sessione sempre in testata; (2) prefill + PREVIOUS = confermare piuttosto che digitare; (3) stato completato con colore pieno su tutta la riga (bersaglio visivo enorme e glanceable); (4) un solo CTA primario (Finish) in alto; (5) timer di riposo legato all'esercizio, non a una schermata separata.

### 5.2 Allenamento: Quick Start e routine (hevy_6.jpg, tab "Workout")
- Barra di navigazione: solo titolo "Workout" (centrato, piccolo, nero), senza grandi titoli.
- **Quick Start:** sottotitolo in grassetto + pulsante grigio chiaro largo quanto la colonna **"+ Start Empty Workout"** (altezza ≈ 50 pt, angoli ≈ 10 pt di raggio).
- **Routines:** titolo con icona cartella-più; due pulsanti affiancati grigio chiaro **"New Routine"** e **"Explore"** (≈ 50 pt); intestazione comprimibile "⌄ My Routines (6)" in grigio.
- **Card routine:** bordo grigio chiaro sottile, angoli ≈ 12 pt, sfondo bianco; titolo in grassetto ("Chest & Triceps day") + menu "···"; riga di descrizione grigia con i nomi degli esercizi tagliati con "…" (2 righe); pulsante pieno blu **"Start Routine"** largo tutta la card (≈ 42 pt di altezza, angoli ≈ 10 pt, testo bianco). Una card ≈ 165 pt di altezza, quindi ~3,5 card per schermo.
- **Tab bar** (3 voci): **Home, Workout, Profile**, icone outline con etichetta, la voce attiva in blu; nessun quarto tab.
- **Principi:** una sola azione primaria per card (Start); creazione/esplorazione sono secondarie (grigie); partenza da routine in 1 tap + eventuale conferma.

### 5.3 Esercizio: Summary e andamento (hevy_13.jpg)
- Barra: freccia indietro + titolo "Squat (Barbell)"; sotto **tab testuali scorrevoli**: Summary (attivo, blu con sottolineatura), History, How to, Leaderboard (tagliato a destra, indica scroll).
- Hero: animazione/immagine dell'esercizio con muscoli primari evidenziati in rosso (rosso usato per anatomia, non per errore), pulsante pausa in cerchio grigio in alto a destra; sotto "Primary: Quadriceps".
- **Grafico a linea con punti** (blu pieno, linea sottile): asse y 40/60/80 kg con griglia orizzontale molto leggera, asse x con 5 etichette di data (Oct 31 ... Feb 27); valore selezionato in alto a sinistra in grassetto ("80 kg") con data blu; selettore periodo a destra "All time ⌄" (blu). Nessuna legenda.
- **Chip di metrica sotto il grafico:** "Heaviest Weight" (selezionato: pieno blu, testo bianco), "One Rep Max", "Best S…" (scroll orizzontale); chip non selezionati grigio chiaro. Sotto: "Personal Records" con medaglia gialla e icona "?".
- **Principi:** una sola metrica per grafico, cambiata con chip; profilo aggiornato ai dati; il colore giallo = PR/medaglia.

### 5.4 Profilo/storico (hevy_9.jpg) e misure (hevy_17.jpg)
- **Profilo:** barra con "Edit Profile" (blu, sinistra), username centrale, icone condividi e ingranaggio; blocco con avatar tondo (~90 pt), tre contatori (Workouts / Followers / Following) con etichetta grigia + numero; bio; pulsante pieno blu "Follow" a tutta larghezza (~42 pt).
- **Grafico a barre settimanale:** titolo "3 hours this week" ("3 hours" in grassetto nero, "this week" in grigio), barre blu uguali (11 barre, ~10 settimane + una) con asse y 0/2/4 hrs e asse x con date; nessuna barra rossa o vuota evidenziata: il "vuoto" è solo una barra bassa. Sotto: griglia 2x2 di card routine con bordo grigio, numerate.
- **Misure:** "Progress Pictures" (miniature con data, "See All" blu), grafico a linea blu per Body Weight (kg) con punti, chip "Bodyweight / Bodyfat % / Chest / Bi…", sotto "History" in righe con data a sinistra e valore a destra con icona fotocamera; "+" in alto a destra per aggiungere.
- **Principi:** unità di tempo settimanale nel titolo del grafico; confronti numerici sempre nello stesso grafico; aggiunta dato con un "+" nella barra.

### 5.5 Confronto e social (hevy_10.jpg, hevy_3.jpg, hevy_18.jpg)
- **Confronto:** due avatar (selezionato con bordo blu, badge giallo "STRONGER"); metriche (One Rep Max, Heaviest Weight, Best Set) con barre orizzontali blu vs grigio chiaro, variazione % in **verde con freccia su** (+16%, +5%) e **rosso con freccia giù** (-3%). Questo è l'unico uso evidente di rosso come "peggioramento" nelle schermate viste (affiancato da freccia e segno).
- **Home/feed:** selettore "Home ⌄" in capsula grigia, icone ricerca e notifiche; card di allenamento di altri utenti con titolo, Time/Volume, elenco esercizi con miniature e "N sets", like/commenti/condividi; "Suggested Athletes" con "Invite a friend" blu.
- **Dark mode** (hevy_3): sfondo nero puro per i contenuti, barra superiore grigio scuro (#2A2A2C stimato), testo bianco, accenti blu per azioni (like blu).
- **Principi (inferenza [O]):** il confronto sociale è opzionale e fuori dal flusso di allenamento; in un'app personale senza social non è da copiare.

### 5.6 Libreria esercizi (hevy_19.jpg)
- Modale/sheet con "Cancel" (blu) a sinistra, titolo "Add Exercise", "Create" (blu) a destra; **campo di ricerca** grigio chiaro (placeholder "Search Exercise", altezza ≈ 42 pt); due filtri in capsule: "All Equipment" (grigio), "Chest" (pieno blu = attivo) con "✕" per resettare; lista righe con miniatura circolare ~58 pt, nome + gruppo muscolare grigio, chevron; altezza riga ≈ 75-80 pt, separatore sottile.
- **Principi:** ricerca + filtri a capsule con stato attivo pieno; riga ≥ 75 pt facile da toccare.

### 5.7 Palette e tipografia osservate
- Primario: blu saturo (≈ #2780E8, stima) per CTA pieni, link, titoli esercizio, tab attivo, grafici; sfondo chiaro #F5F5F5-bianco per le card; testo nero/grigio medio/grigio chiaro (3 livelli); verde per completato e variazione positiva; giallo per warm-up "W", PR, badge; rosso solo per variazione negativa e anatomia. Font sans neo-grotesca (aspetto Inter-like), pesi regular/semibold/bold; i numeri chiave in grassetto.
- Angoli: pulsanti ~10 pt, card ~12 pt, avatar e miniature tonde.
- Nota: le immagini sono promo, non garantiscono pixel-esattezza né l'aspetto attuale della v3.2.4.

### 5.8 Cosa NON ho potuto verificare da schermate
- Schermata riepilogo a fine workout, finestra modifica timer di riposo, tastiera numerica custom, Live Activity e Watch (screenshot watch4/watch5 presenti nell'App Store ma non scaricati/guardati), i dettagli di empty/error state. Non descrivo ciò che non ho visto.

---

## 6. Checklist sintetica (verificabile)

| # | Regola | Verifica rapida | Fonte |
|---|---|---|---|
| 1 | Target ≥ 44x44 pt (spunta serie ≥ 48-56 pt) | Misura in Xcode view debugger | HIG Accessibility [F] / soglia 48-56 [O] |
| 2 | Testo ok a Dynamic Type max | Test AX5 su schermata log | HIG Accessibility [F] |
| 3 | Mai solo colore per stato | Screenshot in scala di grigi | HIG Accessibility/Charts [F] |
| 4 | Log di serie ripetuta in ≤ 2 tap | Conteggio tap | Cordeiro 2015 [S] + [O] |
| 5 | Nessun modale su azioni frequenti | Walkthrough del log | HIG Workouts [F] / [O] |
| 6 | Timer automatico alla spunta | Prova su device | Hevy docs [F] |
| 7 | Nessuna richiesta HealthKit al primo avvio | Test installazione pulita | HIG HealthKit [F] |
| 8 | Sessioni di pochi secondi non salvate | Avvia/termina subito | HIG Workouts [F] |
| 9 | Riepilogo a fine sessione | Flusso Fine | HIG Workouts [F] |
| 10 | Nessun elemento rosso/penalità per giorno saltato | Revisione copy e colori | Silverman 2023 [S] + [O] |
| 11 | Rientro dopo 14 giorni neutro | Simula inattività | Epstein 2015 [F] + [O] |
| 12 | Grafico = 1 messaggio, accessibile, no solo colore | Audit VoiceOver | HIG Charts [F] |
| 13 | Live Activity: 1-2 valori, no promo/sensibili | Review su schermata blocco | HIG Live Activities [F] |
| 14 | Offline completo | Modalità aereo | Hevy [F] / [O] |
| 15 | Valutazione MARS | 23 voci | Stoyanov 2015 [F] |

## Conflitti e limiti da tenere presenti
- Obiettivi giornalieri vs settimanali: Twente (piccolo, singolo caso) favorisce i giornalieri; CHI 2026 critica i target giornalieri fissi: nessun consenso.
- Fogg: la formula B=MAP è presentata come somma da alcuni blog e come convergenza dal sito ufficiale; ho usato la lettura ufficiale.
- Riassunti secondari (Psychology Today per Silverman; riassunti search per Epstein 2016, MARS e HE4EH) non confermati a pieno testo.
