# Forma — checklist di interfaccia

Data: 5 novembre 2026. Branch `grafica`.

Questa lista traduce in regole da spuntare le tre ricerche:
- `docs/ricerca/linee-guida-generali.md` (Nielsen, Laws of UX, Shneiderman, ISO 9241-110, WCAG 2.2, pollice, moduli, fondamenti visivi);
- `docs/ricerca/linee-guida-genere-e-hevy.md` (HIG per allenamento e salute, usabilità mHealth, fatica di registrazione, motivazione, palestra, Hevy);
- `docs/ricerca/interfaccia-e-usabilita.md` (primo esame di Forma).

**Peso delle fonti.** Le regole che vengono da una fonte primaria ([F]/[FONTE]: Apple HIG, W3C, NN/g) o da uno studio ([S]) sono **vincolanti**. Quelle che vengono da un'opinione di settore o da una deduzione ([O]/[OPINIONE]/[NOTA]/[Inferenza]) sono **forti consigli**: si possono cambiare con un motivo scritto. Ogni regola dice di quale tipo è.

**Telefono di riferimento.** Il proprietario usa un iPhone con una colonna di sistema verticale a destra (come il simulatore «iPhone Duo», 466 × 678 pt utili, colonna di circa 60 pt). Le prove si fanno lì e su un iPhone normale.

**Come si usa.** Per ogni schermata: aprirla in chiaro, in scuro e con il testo di accessibilità più grande; per ogni regola segnare *passa*, *non passa* o *non si applica*. Una regola *non passa* diventa una voce nella valutazione (`valutazione-forma.md`) con il suo codice.

---

## S — Struttura e navigazione

| Id | Regola | Come si verifica su una schermata | Fonte |
|---|---|---|---|
| S1 | Una sola azione principale per schermata, con il pulsante pieno; le altre sono secondarie (testo, grigio, menu). | Contare i pulsanti pieni o colorati di pari peso: deve essercene al massimo 1. | Hick + Von Restorff (Laws of UX) [F]; HIG Designing for iOS [F] |
| S2 | Le funzioni che si usano almeno una volta a settimana hanno un'etichetta visibile: non stanno solo dietro un'icona senza testo («+», «…»). | Elencare le funzioni dietro icone senza testo; se una si usa ogni settimana, non passa. | Nielsen H6 riconoscere invece di ricordare [F]; Hevy 5.2 (Nuova scheda/Esplora visibili) [F] |
| S3 | Una cosa compare una volta sola nella schermata; ogni destinazione ha una porta sola nella stessa schermata. | Cercare lo stesso oggetto (scheda, spesa, dato) mostrato due volte. | Nielsen H8 minimalismo [F] |
| S4 | Le funzioni di tutta l'app (Impostazioni) si raggiungono da ogni scheda, sempre nello stesso posto. | Da ognuna delle 4 schede: Impostazioni in ≤ 1 tocco, stessa posizione. | Nielsen H4 coerenza [F]; WCAG 3.2.3 navigazione coerente [NOTA] |
| S5 | Ogni tocco che apre una pagina mostra contenuto (titolo e dati) entro 400 ms; mai una pagina vuota. | Aprire la pagina 5 volte: contenuto visibile subito; se serve più tempo, indicatore. | Soglia di Doherty [F]; Nielsen H1 [F] |

## V — Gerarchia visiva e griglia

| Id | Regola | Come si verifica | Fonte |
|---|---|---|---|
| V1 | Lista per gli insiemi di cose simili; riquadro solo per «un numero con il suo andamento» o per «l'azione principale». Mai un riquadro per una riga di testo. | Contare i riquadri: ognuno deve contenere un numero con andamento o l'azione principale. | HIG Lists and tables [F]; regola lista/riquadro dal report [O] |
| V2 | Il dato o l'azione principale si vede senza scorrere sul telefono del proprietario (466 × 678 pt). | Schermata appena aperta: l'azione principale è visibile per intero. | NN/g mobile UX, «il succo prima dei dettagli» [F] |
| V3 | Spaziature dalla scala 4 · 8 · 12 · 16 · 24 pt; lo spazio tra i gruppi è almeno 1,5 volte quello dentro un gruppo; i bordi sinistri sono allineati. | Misurare 5 distanze e i bordi sinistri sullo screenshot (3 px = 1 pt). | Refactoring UI via riassunti [O]; Gestalt prossimità [F] |
| V4 | Lo stesso componente ha lo stesso aspetto ovunque: spunta, freccia, intestazione di sezione, raggio degli angoli, riga di lista. | Mettere a confronto due schermate con lo stesso elemento. | Nielsen H4 [F]; Shneiderman 1 [F] |

## T — Tipografia

| Id | Regola | Come si verifica | Fonte |
|---|---|---|---|
| T1 | Solo stili di testo di sistema che seguono Dynamic Type; nessuna dimensione fissa (`.system(size:)`) per testi e numeri; al massimo 5 stili per schermata. | Cercare `.system(size:` nel codice della vista; contare gli stili sullo screenshot. | HIG Typography [F]; numero di stili [O] |
| T2 | Ogni frase è scritta a mano per ogni stato, non composta («Riposo», non «Oggi riposo»); un solo formato di data, quello italiano di sistema in minuscolo («giovedì 5 novembre»). | Leggere tutti i testi: niente frasi assemblate, niente «05/11/2026», niente mese maiuscolo. | Nielsen H2 [F]; report sezione Testi [O] |
| T3 | Ogni numero ha la sua unità, metrica e comprensibile (g, kg, s, min, l); niente «porzioni» per cose che si comprano a peso. | Ogni numero sullo schermo ha unità; nessun numero nudo («3 × 30–45»). | Nielsen H2 [F] |

## C — Colore e contrasto

| Id | Regola | Come si verifica | Fonte |
|---|---|---|---|
| C1 | Un solo colore d'accento con un solo significato: azione principale e stato «fatto». Nomi, link, titoli di sezione e valori toccabili non usano l'accento. | Contare gli elementi verdi: ognuno è un pulsante principale o una cosa fatta. | HIG Color «non usare lo stesso colore per significati diversi» [F]; WWDC25 219 [F] |
| C2 | Testo con contrasto almeno 4,5:1 (3:1 se ≥ 18 pt o grassetto) in chiaro e in scuro. | Misurare con Accessibility Inspector o calcolo sui valori esadecimali. | WCAG 1.4.3 [F]; HIG Accessibility [F] |
| C3 | Forme non testuali con significato (cucchiaino vuoto, goccia vuota, bordo del campo, cerchio di spunta) almeno 3:1 rispetto allo sfondo, in chiaro e in scuro. | Calcolare il contrasto del colore «vuoto» e di quelli pieni sullo sfondo della riga. | WCAG 1.4.11 [F] |
| C4 | Nessuna informazione data solo dal colore (stato, legenda, giorno fatto/in programma). | Screenshot in scala di grigi: si capisce ancora tutto. | WCAG 1.4.1 [F]; HIG Accessibility [F] |

## P — Tocco e pollice

| Id | Regola | Come si verifica | Fonte |
|---|---|---|---|
| P1 | Ogni bersaglio è almeno 44 × 44 pt (mai sotto 28); circa 12 pt tra bersagli con bordo. | Leggere i `frame` nel codice o misurare sullo screenshot. | HIG Accessibility [F]; NN/g 1 cm come ideale [F] |
| P2 | Le azioni frequenti stanno nella metà bassa o vicino alla colonna destra (pollice destro); non solo in alto a sinistra. | Il centro dell'azione frequente è sotto il 50 % dell'altezza o a meno di 100 pt dal bordo destro. | HIG «controlli frequenti in basso o al centro» [F]; Hoober 2013 [S] |
| P3 | Le azioni distruttive (Elimina, Annulla allenamento) non sono vicine a quelle frequenti (spunta, Inizia). | Nessuna azione distruttiva a meno di 44 pt da un'azione frequente, né nello stesso menu della prima voce. | Legge di Fitts [F] |
| P4 | Toccare una riga fa la cosa più probabile e tutta la riga è area di tocco; i controlli secondari nella riga hanno un'area propria di 44 pt. | Toccare il bordo della riga: succede qualcosa di prevedibile. | [O] coerente con HIG Lists [F] |

## I — Inserimento dati

| Id | Regola | Come si verifica | Fonte |
|---|---|---|---|
| I1 | Un valore grigio nel campo o è un **valore vero** (si salva) o non c'è: un segnaposto non deve sembrare un dato. Dove esiste un valore tipico, è già compilato. | Aprire il modulo e premere Salva senza scrivere: se si vede un numero ma Salva è spento, non passa. | Tesler [F]; Nielsen H5 [F]; HIG Entering data [F] |
| I2 | Numeri: tastiera numerica; per valori che cambiano poco (kg, minuti, peso) anche ± a passi fissi senza tastiera. | Cambiare un valore di un passo: si fa senza aprire la tastiera. | HIG Steppers [F]; HIG Entering data [F] |
| I3 | Accanto a ogni campo da riempire si vede il valore dell'ultima volta. | Il modulo mostra il valore precedente di ogni campo. | Nielsen H6 [F]; Hevy «Precedente» [F] |
| I4 | Ogni campo ha un'etichetta che resta visibile e la sua unità; nessun campo vuoto con un solo «–». | Leggere il modulo vuoto: ogni riga dice cosa e in che unità; le unità sono allineate. | Baymard etichette persistenti [F] |
| I5 | Le registrazioni di ogni giorno costano al massimo 2 tocchi: pasto, olio, acqua, serie uguale all'ultima, peso uguale a ieri. | Contare i tocchi da app aperta. | Cordeiro 2015 (40 % salta ciò che è difficile da inserire) [S]; soglia [O] |

## F — Risposta e stato

| Id | Regola | Come si verifica | Fonte |
|---|---|---|---|
| F1 | Ogni tocco ha una risposta visiva immediata; la vibrazione solo per: pasto, cucchiaino/goccia, serie fatta, recupero finito. | Toccare: cambio entro 400 ms; nessuna vibrazione su azioni banali. | Nielsen H1 [F]; HIG Playing haptics [F] |
| F2 | Lo stato «fatto» è segnato da due cose insieme: forma (spunta piena) e sfondo o peso del testo. | In scala di grigi «fatto» e «da fare» si distinguono. | HIG Accessibility [F]; Hevy riga verde + spunta [F] |
| F3 | Lo stesso dato ha lo stesso valore e la stessa etichetta in tutte le schermate (es. «questa settimana» vuol dire sempre da lunedì). | Confrontare lo stesso totale in due schermate. | Nielsen H4 [F]; Shneiderman 1 [F] |
| F4 | Alla fine di un flusso c'è un riepilogo che conferma ciò che è stato salvato e confronta con la volta prima. | Finire il flusso: compare il riepilogo con almeno un confronto. | HIG Workouts «riepilogo a fine sessione» [F]; Peak-End [F] |

## E — Errori e annullamento

| Id | Regola | Come si verifica | Fonte |
|---|---|---|---|
| E1 | Le azioni comuni e reversibili non chiedono conferma e si annullano (ritocco, «Annulla»). La conferma è solo per cancellare dati o chiudere/annullare un allenamento, e dice cosa si perde, con numeri. | Elencare le finestre di conferma: ognuna riguarda dati che si perdono e ne dice la quantità. | HIG Alerts [F]; HIG Undo and redo [F]; Nielsen H3 [F] |
| E2 | Ogni foglio ha «Annulla» e un'azione di conferma con un nome; un pulsante spento spiega vicino perché lo è. | Aprire il foglio vuoto: si capisce cosa manca per salvare. | Nielsen H3, H9 [F] |
| E3 | Un errore si dice a parole, vicino al campo: cosa manca e come rimediare. | Provocare l'errore (spunta senza kg): compare un testo, non solo una vibrazione. | Nielsen H9 [F]; WCAG 3.3.1 [NOTA] |

## M — Motivazione senza colpa

| Id | Regola | Come si verifica | Fonte |
|---|---|---|---|
| M1 | Nessun giudizio a colori sui dati del corpo: la variazione di peso e di misure è neutra (segno + numero), non verde quando scende. | Peso in salita e in discesa hanno lo stesso colore. | Silverman & Barasch 2023 [S]; HIG non solo colore [F]; scelta del neutro [O] |
| M2 | Nessun segno di «saltato», nessun contatore che torna a zero; la costanza si mostra come somma della settimana. | Cercare «saltato», ✕, rosso, contatori giornalieri. | Silverman & Barasch 2023 [S]; CHI 2026 microgoals [S] |
| M3 | I confronti sono onesti: la settimana in corso si dice «finora» e non si confronta a colpo d'occhio con settimane intere; il peso si confronta con 30 giorni fa. | Il grafico settimanale distingue la settimana in corso con testo, non solo con colore. | [O] da Cordeiro 2015 (valore percepito) [S]; Happy Scale [F] |
| M4 | Dopo una pausa (14 giorni) l'app riparte neutra: niente elenco di ciò che è mancato. | Simulare 14 giorni senza dati: Oggi non mostra mancanze. | Epstein 2015 [F]; formulazione [O] |

## A — Accessibilità

| Id | Regola | Come si verifica | Fonte |
|---|---|---|---|
| A1 | Al testo di accessibilità più grande nessun nome, grammatura, kg o ripetizione viene troncato; le righe con controlli a destra si impilano; la gerarchia resta (il numero principale resta il più grande). | `xcrun simctl ui … content_size accessibility-extra-extra-extra-large` e screenshot. | HIG Typography [F]; WCAG 1.4.4 [F] |
| A2 | Ogni controllo ha un'etichetta per VoiceOver; i contatori sono regolabili; ogni grafico ha una descrizione con i valori. | Accessibility Inspector. | HIG Accessibility, HIG Charts [F] |
| A3 | Ogni schermata funziona in scuro: elementi vuoti, campi e grafici visibili. | Screenshot in scuro. | HIG Designing for iOS [F] |
| A4 | Il contenuto rispetta l'area sicura anche con la colonna di sistema a destra; nessun margine scritto a mano per un solo telefono. | Screenshot sul simulatore iPhone Duo e su iPhone 17: margine destro uguale al sinistro. | HIG Layout [F]; caso Duo [NOTA] |

## G — Palestra, durante l'allenamento

| Id | Regola | Come si verifica | Fonte |
|---|---|---|---|
| G1 | La testata della sessione mostra tempo, kg e serie leggibili in 2 secondi; sopra la prima serie da fare non c'è altro (al testo normale la prima serie da fare si vede senza scorrere). | Aprire la sessione: la prima serie non fatta è visibile. | HIG Workouts [F] |
| G2 | Serie uguale all'ultima volta: 1 tocco. Peso diverso di un passo: ± senza tastiera (passo da confermare, 2,5 kg). | Contare i tocchi. | Hevy prefill [F]; Cordeiro 2015 [S]; HIG Steppers [F] |
| G3 | Il recupero parte da solo alla spunta, si regola di ±15 s e si vede fuori dall'app (Live Activity / Dynamic Island). | Spuntare e bloccare il telefono. | Hevy rest timer e Live Activity [F]; HIG Live Activities [F] |
| G4 | Nessuna finestra modale per le azioni frequenti della sessione (spunta, aggiungi serie, cambia peso). | Percorrere una sessione completa. | HIG Workouts «non distrarre» [F]; divieto [O] |
| G5 | La sessione si salva a ogni modifica e si riprende dopo la chiusura dell'app; una sessione di pochi secondi non si salva senza chiedere. | Chiudere l'app a metà; avviare e finire subito. | HIG Workouts [F]; Hevy offline [F] |

---

45 regole. Le regole marcate [O] si possono cambiare dopo averne parlato con il proprietario; le altre no.
