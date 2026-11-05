# Linee guida UI/UX generali per app mobile: regole verificabili schermata per schermata (iPhone)

Formato: ogni regola = **Regola** / **Verifica** (pass/fail su una schermata) / fonte. Etichette: [FONTE] = letto sulla fonte primaria in questa ricerca; [NOTA] = conoscenza mia non riverificata in questa sessione (da controllare); [OPINIONE] = convenzione di settore, non standard.
Convenzione unità: 1 pt iOS ≈ 1 CSS px WCAG (equivalenza usata comunemente, non dichiarata da W3C per iOS) [NOTA].

## 1. Euristiche di Nielsen e guida NN/g mobile

### Takeaway
Le 10 euristiche sono principi generali (non numerici); su mobile diventano checkable se tradotte in: stato visibile, uscita/annulla sempre presente, etichette riconoscibili, minimalismo, errori in linguaggio semplice. NN/g mobile aggiunge: contenuto prima del chrome, target grandi (>= 1 cm), meno digitazione, salvataggio dello stato.

### Cited Findings
Le 10 euristiche [FONTE: https://www.nngroup.com/articles/ten-usability-heuristics/]:
- H1 Visibilità dello stato del sistema. Regola: ogni azione ha feedback tempestivo. Verifica: dopo un tap compare entro ~1 s un cambiamento visibile (spinner, toast, stato del bottone); nessuna azione "muta". — [NN/g](https://www.nngroup.com/articles/ten-usability-heuristics/)
- H2 Corrispondenza col mondo reale. Regola: linguaggio dell'utente, ordine naturale. Verifica: nessun termine tecnico/interno nelle label; elenco di campi nell'ordine in cui l'utente li conosce. — [NN/g](https://www.nngroup.com/articles/ten-usability-heuristics/)
- H3 Controllo e libertà. Regola: via d'uscita chiara + undo/redo. Verifica: ogni schermata modale/flusso ha Annulla/Chiudi/Indietro visibile; azioni distruttive hanno Annulla (vedi sez. 8). — [NN/g](https://www.nngroup.com/articles/ten-usability-heuristics/)
- H4 Coerenza e standard. Regola: stesso significato = stesso aspetto/azione; seguire convenzioni di piattaforma. Verifica: stesso elemento (es. "Salva") ha stessa etichetta, posizione, stile in tutte le schermate; controlli iOS nativi dove esiste l'equivalente. — [NN/g](https://www.nngroup.com/articles/ten-usability-heuristics/)
- H5 Prevenzione errori. Regola: eliminare condizioni a rischio o chiedere conferma. Verifica: input vincolati (stepper, picker, tastiera numerica) invece di testo libero; bottoni disabilitati quando l'azione non è valida. — [NN/g](https://www.nngroup.com/articles/ten-usability-heuristics/)
- H6 Riconoscere invece di ricordare. Regola: opzioni visibili. Verifica: nessuna informazione necessaria in schermata N che sia stata mostrata solo in N-1; valori precedenti/suggerimenti visibili. — [NN/g](https://www.nngroup.com/articles/ten-usability-heuristics/)
- H7 Flessibilità ed efficienza. Regola: scorciatoie per esperti senza complicare i novizi. Verifica: azioni frequenti raggiungibili in <= 1-2 tap; esistono default/ricorrenti/azioni rapide. — [NN/g](https://www.nngroup.com/articles/ten-usability-heuristics/)
- H8 Design estetico e minimalista. Regola: rimuovere contenuto irrilevante o raro. Verifica: ogni elemento in schermata serve il compito primario; elementi rari spostati in secondo livello. — [NN/g](https://www.nngroup.com/articles/ten-usability-heuristics/)
- H9 Riconoscere, diagnosticare, recuperare dagli errori. Regola: messaggi in linguaggio semplice, che dicono il problema e propongono la correzione. Verifica: ogni messaggio d'errore contiene (a) cosa è andato storto (b) cosa fare; nessun codice grezzo. — [NN/g](https://www.nngroup.com/articles/ten-usability-heuristics/)
- H10 Aiuto e documentazione. Regola: progettare per non averne bisogno; aiuto breve e contestuale. Verifica: nessuna schermata richiede un manuale; spiegazioni inline brevi dove serve.

NN/g mobile UX [FONTE: https://www.nngroup.com/articles/mobile-ux/]:
- Contenuto prima ("the gist before the minutiae"); alto rapporto contenuto/chrome. Verifica: il dato/azione principale è visibile above-the-fold senza scroll; barre/header non occupano più di una frazione ridotta dello schermo [soglia numerica non data dalla fonte]. — [NN/g mobile UX](https://www.nngroup.com/articles/mobile-ux/)
- Target touch molto più grandi che per mouse; prevedere tocchi accidentali e supportare undo. — [NN/g mobile UX](https://www.nngroup.com/articles/mobile-ux/)
- Digitare è il punto dolente: ridurre la digitazione (camera per codici, GPS per CAP, biometria), minimizzare passi/caricamenti, salvare lo stato per riprendere un form interrotto. Verifica: conta i campi di testo libero; ognuno ha un'alternativa (picker, stepper, scelta) se il valore è prevedibile. — [NN/g mobile UX](https://www.nngroup.com/articles/mobile-ux/)
- Dati: sessione mobile media 72 s (desktop 150 s); contenuto di un fold da 30" richiede ~5 schermate su 4". — [NN/g mobile UX](https://www.nngroup.com/articles/mobile-ux/)
- Dimensione minima target: 1 cm x 1 cm (0,4 in), da studio Parhi, Karlson, Bederson; è un minimo, più grande se l'uso è in movimento (es. 2 cm x 2 cm per bottoni chiave). Verifica: ogni controllo >= 1 cm fisico. Nota di conversione [NOTA, calcolo mio]: iPhone ha ~163 pt per pollice, quindi 1 cm ≈ 64 pt, mentre 44 pt ≈ 6,9 mm: il default Apple (44 pt) è SOTTO il minimo NN/g di 1 cm; i due standard divergono (NN/g è più severo). Soglia pratica: 44 pt come pass, 1 cm come 'ideale' per azioni primarie. — [NN/g touch target](https://www.nngroup.com/articles/touch-target-size/) (letto solo via snippet di ricerca)
- Spaziatura 2 mm tra target: attribuita a NN/g da siti secondari, NON verificata. [NOTA]

### Inferences
- 44 pt Apple (~6,9 mm) è più piccolo di 1 cm NN/g: segnalare come warning, non fail, i target tra 44 e ~64 pt.

### Gaps
- NN/g su form mobile e input numerico: l'articolo mobile-ux non dà indicazioni specifiche (lo dice esplicitamente); non ho letto gli articoli NN/g dedicati ai form/checklist input. Cercare "mobile input checklist" NN/g.
- Il pezzo NN/g touch-target è stato letto solo come snippet.

## 2. Laws of UX

### Takeaway
Le leggi sono euristiche psicologiche; solo poche hanno numeri (Doherty 400 ms; Miller 7±2, che è comunque ampiamente criticata come regola di design). Tradotte in test: n. di scelte, distanza/dimensione target, tempi di risposta, raggruppamento visivo.

### Cited Findings
Tutte da [Laws of UX](https://lawsofux.com/) [FONTE]:
- Fitts: tempo per raggiungere un target dipende da distanza e dimensione. Regola: azioni primarie grandi e vicine al pollice; distruttive piccole/lontane o separate. Verifica: bottone primario >= 44 pt, nella metà bassa; target critici non adiacenti a quelli distruttivi.
- Hick: il tempo di decisione cresce con numero/complessità delle scelte. Regola: una sola azione primaria evidente per schermata. Verifica: conta le azioni di pari peso; > ~5-7 opzioni non raggruppate = segnala [soglia = OPINIONE].
- Jakob: gli utenti si aspettano che la tua app funzioni come le altre che usano. Verifica: pattern standard iOS (tab bar in basso, swipe-back, sheet, toggle) senza reinvenzioni.
- Miller (7±2 elementi in memoria di lavoro): Regola: non richiedere di ricordare; chunking (altra legge: Chunking). Verifica: liste lunghe raggruppate in sezioni; numeri lunghi a gruppi.
- Tesler: la complessità minima non si elimina, si sposta. Regola: il sistema assorbe complessità (default, calcoli automatici) invece dell'utente. Verifica: ci sono campi che l'app potrebbe calcolare/precompilare e non lo fa?
- Doherty threshold (< 400 ms): produttività sale con risposte entro 400 ms. Regola: feedback visibile < 400 ms; oltre, mostrare progresso. Verifica: tap -> cambio visibile in < 0,4 s (misurabile con registrazione schermo a 60 fps ≈ 24 frame); operazioni lunghe hanno indicatore.
- Aesthetic-usability: design attraente percepito più usabile. Verifica: coerenza visiva (sez. 9); NB può nascondere problemi reali nei test.
- Peak-End: l'esperienza è giudicata da picco e finale. Regola: curare il momento di successo/completamento. Verifica: la schermata finale di un flusso conferma l'esito e propone il passo successivo, non un vicolo cieco.
- Serial position: si ricordano primo e ultimo elemento. Regola: voci/azioni più importanti agli estremi di liste e tab bar. Verifica: nella tab bar le sezioni chiave sono prima/ultima.
- Von Restorff: l'elemento diverso si ricorda. Regola: UN solo elemento enfatizzato per area. Verifica: nella schermata c'è un solo elemento con colore/peso "pieno" (CTA primaria); se tutto è enfatizzato = fail.
- Prossimità: oggetti vicini = gruppo. Verifica: spazio tra gruppi > spazio entro i gruppi (regola pratica >= 1,5-2x, vedi sez. 9 [OPINIONE]).
- Common region: elementi in un'area delimitata = gruppo. Verifica: card/sezioni raggruppate hanno bordo/sfondo coerente.
- Similarità: elementi simili = gruppo/funzione. Verifica: elementi con stessa funzione hanno stesso stile; stili diversi solo per funzioni diverse.
- Altre utili: Postel (accetta input liberale: formati data/numero tolleranti), Zeigarnik, Goal-gradient (barre di progresso nei flussi lunghi), Chunking.

### Inferences
- Von Restorff + Hick insieme danno il test "una sola CTA primaria".

### Gaps
- Miller 7±2 è citata dal sito ma è discussa in letteratura (Cowan ~4 chunk); non verificato in questa sessione. [NOTA]

## 3. Golden rules di Shneiderman e ISO 9241-110:2020

### Takeaway
Shneiderman: 8 regole stabili (Designing the User Interface). ISO 9241-110:2020 ha sette principi di interazione (sostituisce la versione 2006); non sono riuscito a leggere il testo ufficiale (a pagamento), l'elenco sotto è da conoscenza mia.

### Cited Findings
Shneiderman [FONTE: https://www.cs.umd.edu/~ben/goldenrules.html]:
1. Coerenza — sequenze/terminologia/layout uniformi. Verifica: stesse azioni, stesse etichette tra schermate.
2. Usabilità universale — esperti e novizi, disabilità, età. Verifica: scorciatoie + Dynamic Type/VoiceOver supportati.
3. Feedback informativo — ogni azione ha risposta proporzionata. Verifica: tap sempre seguito da risposta.
4. Dialoghi con chiusura — sequenze con inizio, centro, fine. Verifica: flussi multi-passo mostrano progresso e una conferma finale.
5. Prevenzione e gestione errori — es. grigio le voci non valide, niente lettere in campi numerici. Verifica: campi numerici accettano solo numeri; azioni non valide disabilitate.
6. Reversibilità — azioni annullabili. Verifica: modifica/eliminazione ha undo.
7. Controllo dell'utente (locus of control) — l'utente avvia, non risponde. Verifica: nessuna azione automatica sorprendente; nessun blocco forzato.
8. Ridurre il carico di memoria a breve termine. Verifica: nessun dato da ricordare tra schermate.
(Date d'origine discordanti: 1985 vs 1986 tra fonti.)

ISO 9241-110:2020 [pubblicata 2020-05-27, sostituisce 2006; ISO 9241-112 per la presentazione]: [Catalogo](https://genorma.com/en/standards/iso-9241-110-2020) [FONTE per data/ambito]. Sette principi [NOTA, da memoria, non verificato su fonte aperta; 2 su 7 confermati dai risultati di ricerca: suitability for the user's tasks e self-descriptiveness]:
- Idoneità al compito (suitability for the user's tasks): Verifica: la schermata offre solo ciò che serve al compito.
- Auto-descrittività: Verifica: l'utente capisce dove è e cosa fare senza istruzioni esterne.
- Conformità alle aspettative: Verifica: come H4/Jakob.
- Apprendibilità (learnability): Verifica: primo uso senza tutorial.
- Controllabilità: Verifica: ritmo e direzione controllabili, annulla/interrompi.
- Robustezza agli errori d'uso (use error robustness): Verifica: errori evitabili/recuperabili (corrisponde a H5/H9).
- Coinvolgimento dell'utente (user engagement): Verifica: [OPINIONE] motivazione/feedback positivo, non dark pattern.

### Inferences
- Shneiderman 3/4/6/7 coprono feedback, chiusura, undo, controllo; nel checklist sono dedupe con Nielsen H1/H3/H5.

### Gaps
- Testo ufficiale ISO 9241-110:2020 non accessibile (paywall); elenco dei sette principi da verificare.

## 4. Thumb zone e uso a una mano

### Takeaway
La mappa "thumb zone" è molto citata ma basata su osservazione 2013 (non scientifica) e la fonte stessa è stata in parte ritrattata. Regola pratica ancora supportata da Apple: controlli frequenti in basso/centro.

### Cited Findings
- Hoober (UXmatters, 2013): 1.333 osservazioni in pubblico, 780 con schermo toccato; 49% una mano, 36% "cradling" (una mano regge, l'altra tocca), 15% due mani; pollice in uso nel 67% dei casi a una mano. Osservazionale, non esperimento controllato; studio senza tablet. — [UXmatters](https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php)
- Secondo una fonte secondaria Hoober stesso avrebbe definito errata nel 2022 la heat map della thumb zone; NON confermato da fonte primaria. [Secondario, incerto]
- Apple HIG: "Place frequently used controls in the middle or bottom area, which is easier to reach"; supportare swipe per tornare indietro e azioni su righe. — [Apple HIG Designing for iOS (via sosumi)](https://sosumi.ai/design/human-interface-guidelines/designing-for-ios)
- Regola: azione primaria e navigazione principale nella metà inferiore. Verifica: il CTA primario ha il centro sotto circa il 50-60% dell'altezza; elementi di scrittura/cancellazione critici non negli angoli superiori [soglia % = OPINIONE derivata dalla heat map].

### Inferences
- Non usare la mappa colorata come criterio pass/fail rigido; usare "azioni frequenti nel terzo/metà inferiore" come euristica.

### Gaps
- Nessuna fonte primaria recente (2022+) di Hoober letta.

## 5. WCAG 2.2 per mobile nativo

### Takeaway
I criteri WCAG sono web ma W3C li applica per analogia al mobile (WCAG2Mobile); i numeri sono usabili come soglie. Apple adotta lo stesso AA per contrasto.

### Cited Findings
- 1.4.3 Contrasto minimo (AA): testo >= 4.5:1; testo grande (>= 18 pt, o >= 14 pt grassetto) >= 3:1; soglie non arrotondabili (4,499 = fail); eccezioni: testo inattivo/decorativo, loghi. Verifica: misura con Accessibility Inspector/colorimetro su ogni testo. — [W3C Understanding 1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)
- 1.4.11 Contrasto non testuale (AA): 3:1 per componenti UI e grafici. Verifica: bordi di campi, icone, stato selezionato >= 3:1 col fondo. — [W3C quickref](https://www.w3.org/WAI/WCAG22/quickref/?versions=2.2&levels=aa); valore 3:1 confermato dal titolo del criterio.
- 2.5.8 Dimensione target minima (AA): >= 24x24 CSS px, eccezioni: spaziatura (cerchio di 24 px non interseca altri target), equivalente, inline, controllo del user agent, essenziale. Verifica: ogni target >= 24 pt oppure spaziato; per iOS usare 44 pt. — [W3C Understanding 2.5.8](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html)
- 1.4.4 Ridimensionamento testo (AA) e 1.4.10 Reflow (AA, 320 CSS px senza scroll bidirezionale), 1.4.12 Spaziatura testo (AA): Verifica su iOS: con Dynamic Type al massimo (incl. Accessibility sizes) nessun testo troncato/sovrapposto e nessuno scroll orizzontale. — [W3C quickref](https://www.w3.org/WAI/WCAG22/quickref/?versions=2.2&levels=aa) (livelli AA confermati)
- 1.3.4 Orientamento (AA); 1.4.1 Uso del colore (A): Verifica: nessuna informazione veicolata solo dal colore (aggiungere icona/testo). — W3C quickref (stessa fonte)
- Livelli non confermati dalla fonte letta ma noti [NOTA]: 3.2.3 Navigazione coerente (AA), 3.2.4 Identificazione coerente (AA), 3.3.1 Identificazione errori (A: l'errore è descritto in testo), 3.3.2 Etichette o istruzioni (A), 3.3.3 Suggerimento errori (AA), 3.3.4 Prevenzione errori legali/finanziari/dati (AA: reversibile, verificato o confermato), 3.3.7 Voce ridondante (A, nuovo in 2.2: non richiedere di reinserire dati già forniti), 3.3.8 Autenticazione accessibile (AA, nuovo 2.2), 2.5.1 Gesti del puntatore (A: alternativa a gesti multi-punto/percorso), 2.5.2 Annullamento puntatore (A: azione all'up, non al down), 2.5.4 Attuazione tramite movimento (A: shake ha alternativa), 2.3.3 Animazione da interazioni (AAA: poter disattivare), 2.2.2 Pausa/Stop/Nascondi (A). Verifiche: errore con testo (non solo rosso); nessun dato richiesto due volte nello stesso flusso; shake/gesti complessi hanno bottone alternativo; animazioni non essenziali rispettano "Riduci movimento". Fonte: [WCAG 2.2 quickref](https://www.w3.org/WAI/WCAG22/quickref/?versions=2.2&levels=aa).

### Inferences
- Per iPhone usare la soglia più severa di Apple (44 pt; testo >= 11 pt) anziché 24 px WCAG.

### Gaps
- Livelli di conformità dei criteri 3.x/2.5.x/2.3.3 non estratti dalla pagina (troncata): da verificare.

## 6. Apple HIG (solo principi generici)

### Takeaway
L'HIG conferma regole generiche e dà numeri accessibili utili.

### Cited Findings
- Gerarchia: limitare i controlli a schermo per concentrarsi sul compito primario; azioni secondarie raggiungibili con interazione minima. Verifica: una azione primaria evidente; secondarie in menu/dettaglio. — [HIG Designing for iOS](https://sosumi.ai/design/human-interface-guidelines/designing-for-ios)
- Coerenza/adattabilità: adattarsi a orientamento, Dark Mode, Dynamic Type; usare funzioni di sistema. Verifica: la schermata funziona in dark mode e con testo grande. — stessa fonte
- Evitare di chiedere di digitare ciò che il dispositivo può fornire. — stessa fonte
- Controlli: dimensione default 44x44 pt, minimo 28x28 pt su iOS/iPadOS. — [HIG Accessibility](https://sosumi.ai/design/human-interface-guidelines/accessibility)
- Spaziatura tra tocchi: ~12 pt attorno a elementi con bezel, ~24 pt attorno a elementi senza bezel. — stessa fonte
- Testo custom: default 17 pt, minimo 11 pt su iOS. Dynamic Type: consentire ingrandimento di almeno 200%. — stessa fonte
- Contrasto (AA): testo fino a 17 pt 4.5:1; 18 pt 3:1; grassetto qualsiasi dimensione 3:1. — stessa fonte
- Feedback e modalità: il testo della pagina letta non li copre; [Gap].

### Gaps
- Feedback/modality/harmony: sosumi ha restituito solo "designing-for-ios" e "accessibility"; coperti dall'altro ricercatore.

## 7. Form e inserimento dati su mobile

### Takeaway
Ridurre campi e digitazione, usare tastiere/controlli adatti, validazione inline non prematura, preferire undo a conferma per azioni reversibili.

### Cited Findings
- Baymard validazione inline (studio gen. 2024): 31% dei siti non la ha, 4% la sbaglia; tre dettagli: non validare prematuramente (prima che l'utente finisca), rimuovere l'errore appena corretto, usare validazione positiva su tutti i campi. Verifica: errore mostrato a blur/invio, non al primo carattere; scompare appena corretto. — [Baymard inline validation](https://baymard.com/research-articles/inline-form-validation)
- Baymard: evitare label inline (placeholder come label) su mobile: dopo un errore gli utenti cancellano tutto per rivedere la label. Verifica: ogni campo ha label persistente visibile, non solo placeholder. — [Baymard](https://baymard.com/blog/mobile-forms-avoid-inline-labels)
- Baymard: disattivare l'autocorrect su nomi, indirizzi, email. Verifica: per campi nome/email/indirizzo autocorrezione e maiuscole automatiche disattivate. — [Baymard guideline 948](https://baymard.com/guidelines/948-where-to-disable-mobile-keyboard-auto-correct)
- Tastiera adatta al tipo (email, telefono, numerica): da fonti secondarie, non verificate su Baymard; Apple: `keyboardType` nativo [NOTA]. Verifica: campi numerici aprono tastiera numerica; campi email con tastiera email. — [Secondaria](https://babich.biz/blog/mobile-form-usability/)
- NN/g: ridurre digitazione, salvare stato del form. — [NN/g](https://www.nngroup.com/articles/mobile-ux/)
- Undo vs conferma: consenso di esperti, non studi controllati: undo preferibile perché si clicca senza leggere le conferme; conferma quando undo è impossibile; la conferma previene prima dell'azione, undo riduce il danno dopo. Verifica: azioni reversibili -> toast "Annulla"; irreversibili -> dialogo che nomina l'azione con bottone distruttivo esplicito. — [GNOME HIG (consenso di settore)](https://developer.gnome.org/hig/patterns/feedback/dialogs.html); [Matuschak note](https://notes.andymatuschak.org/zXH4ASvHNz488hCNgrBjQJK) [OPINIONE]
- Default/prefill/stepper: Tesler, Shneiderman 5, WCAG 3.3.7 (non chiedere due volte). Regola: valori numerici piccoli a step con stepper/picker; campi con valore tipico precompilato. Verifica: nessun campo vuoto per cui esiste un default sensato. [Derivata/OPINIONE]

### Inferences
- Controllare per ogni campo: label persistente, tastiera giusta, default, errore a blur, alternativa a digitazione.

### Gaps
- Nessuna fonte primaria su steppers/prefill/numero-input da NN/g o Wroblewski (Web Form Design non letto). Mancano numeri su n. di campi ottimale.

## 8. Design visivo "professionale"

### Takeaway
La fonte principale (Refactoring UI) è letta solo tramite riassunti di terzi: trattare come [OPINIONE] di settore, non standard.

### Cited Findings
- Scala di spaziature limitata (es. 4, 8, 16, 24, 32, 48, 64) invece di valori arbitrari; spazio tra gruppi > spazio interno ai gruppi. Verifica: tutti i padding/margini appartengono a una scala (multipli di 4/8); misurare 5 distanze a caso. — riassunti di Refactoring UI: [playbooks.com](https://playbooks.com/skills/wondelai/skills/refactoring-ui) [Secondario, OPINIONE]
- Partire con più whitespace e ridurre. — stessa fonte [OPINIONE]
- Scala tipografica con poche dimensioni (es. rapporto 1,25), max due famiglie di carattere. Verifica: contare i corpi di testo distinti nella schermata (> ~5-6 = sospetto); una sola famiglia (SF) è ok. — stessa fonte [OPINIONE]
- Gerarchia con spazio, contrasto, peso prima del colore (progettare in scala di grigi); tre livelli di colore testo (scuro, medio, chiaro). Verifica: convertire lo screenshot in grigio: la gerarchia resta leggibile? — stessa fonte [OPINIONE]
- Palette limitata: 1 colore primario + neutri + colori semantici (successo/avviso/errore). Verifica: contare i colori di accento distinti (> 1 accento + semantici = sospetto). [OPINIONE]
- Allineamento/griglia: margini laterali costanti, bordi sinistri allineati. Verifica: tracciare la linea dei bordi sinistri; elementi disallineati di 1-2 pt = fail. [OPINIONE; HIG layout margins non letto]
- Densità e coerenza: componenti identici ovunque (raggio angoli, altezza righe, icone stessa famiglia/peso). Verifica: confrontare 2 schermate. Fondamenti: Nielsen H4, Gestalt (sez. 2).

### Gaps
- Non ho letto Refactoring UI né le pagine HIG layout/typography/spacing né Material; i valori numerici sopra sono secondari. Da rimandare all'altro ricercatore (Apple) per margini 16/20 pt, SF e Dynamic Type.

## Checklist rapida (pass/fail per schermata)
1. Una sola azione primaria evidente, nella metà bassa (Hick, Fitts, Von Restorff, HIG).
2. Tutti i controlli >= 44x44 pt, spaziati ~12 pt (HIG, NN/g 1 cm, WCAG 24 px).
3. Testo >= 4.5:1 (>= 3:1 se grande/grassetto); componenti UI >= 3:1; testo >= 11 pt.
4. Feedback < 400 ms; operazioni lunghe con progresso.
5. Con Dynamic Type massimo nessun troncamento/sovrapposizione.
6. Nessuna info solo con colore; errori in testo con soluzione.
7. Campi: label persistente, tastiera giusta, default/prefill, validazione a blur, stepper/picker dove possibile.
8. Azioni reversibili = undo; irreversibili = conferma esplicita.
9. Spaziature da scala; gruppi separati più dei contenuti interni; bordi allineati.
10. Poche dimensioni di testo e un solo colore accento; coerenza tra schermate.
