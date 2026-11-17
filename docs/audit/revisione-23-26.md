# Revisione finale PR #23–#27 (Forma)

Data: 10/11/2026. Repo `/Users/rl/app-iphone/dieta` solo letto: niente modifiche, commit o unioni.

## Prova di unione
Copia: `/private/tmp/claude-501/-Users-rl/e1beabfc-0da9-4645-bc6c-bf9681184997/scratchpad/rev-merge` (ramo locale `rev`, da `origin/main` f3efa86).
Rami uniti in ordine: `dati-sicuri`, `sessioni-watch`, `logica-allenamento`, `spesa-e-backup`, `piani-e-date`.
**Nessun conflitto di testo** (Git unisce da solo ArchivioPalestra, AllenamentoInCorsoView, ModelliPalestra, Archivio, Utilita).
FormaTests sull'unione: **244 test in 32 gruppi, tutti verdi** (`** TEST SUCCEEDED **`, iPhone 17e, al primo tentativo).
Log: `/private/tmp/claude-501/-Users-rl/e1beabfc-0da9-4645-bc6c-bf9681184997/scratchpad/rev-test.log`.

Le righe citate sotto sono quelle dell'albero unito.

---

## Critici
Nessuno.

## Importanti

### I1. #25: correggere i kg di una serie appena spuntata toglie la spunta e ferma il recupero
- `Palestra/AllenamentoInCorsoView.swift:569-578` (`onChange(of: kg/rip)` → `togliSpuntaSeSvuotata()`), `:750`; `Palestra/ModelliPalestra.swift` `togliSpuntaSeIncompleta`.
- **Scenario:** spunto la serie 3 con 100 kg proposti, il recupero parte. Mi accorgo che erano 97,5: tocco il campo e cancello «100». Al primo momento in cui il campo è vuoto (succede sempre cancellando un carattere alla volta) la serie perde la spunta e il recupero si ferma (`timer.fermaSeAvviatoDa`). Scrivo «97,5»: la serie resta **non spuntata**. Per rimetterla devo spuntarla di nuovo, e così il recupero riparte da capo e cambia l'orario della serie. Lo stesso con le ripetizioni. Se non me ne accorgo, a «Fine» la serie risulta «senza spunta» e si perde chiudendo.
- Il controllo scatta a ogni tasto, non quando il campo resta vuoto davvero. Il caso tipico, correggere un numero subito dopo la spunta, è proprio quello in cui il recupero è appena partito.
- **Correzione proposta:** togliere la spunta solo quando il campo **perde il focus** ed è ancora vuoto (o non è valido); durante la scrittura non toccare né spunta né timer. In alternativa, quando il campo si svuota lasciare il valore salvato e riscriverlo se si esce dal campo vuoto. Va aggiunto un test che simuli «svuota e riscrivi» e verifichi che spunta e recupero restano.

## Minori

### M1. Unione #24 + #25: la spunta tolta per campo vuoto non azzera `fattaIl`
- `ModelliPalestra.swift` `togliSpuntaSeIncompleta` (da #25) mette `fatta = false` ma lascia `fattaIl` (da #24). Il tocco sulla spunta invece lo azzera (`AllenamentoInCorsoView.swift:769`).
- `Allenamento.fineVerosimile` (#24) prende il `fattaIl` più recente di **tutte** le serie, anche di quelle non più spuntate. **Scenario:** l'ultima serie spuntata alle 19:00 viene poi svuotata e resta non fatta. Il giorno dopo chiudo: fine = 19:30 invece di ultima serie vera + 30 min. Pochi minuti di differenza.
- **Correzione:** in `togliSpuntaSeIncompleta` aggiungere `fattaIl = nil`, oppure in `fineVerosimile` filtrare `.filter(\.fatta)` prima di `compactMap(\.fattaIl)`. Si fa in #25 dopo aver unito #24, o in una PR piccola dopo.

### M2. #23: le callback del lettore PDF non controllano quale pagina le manda
- `Dieta/LettorePDF.swift:54-63`: `didFinish`, `didFail`, `webContentProcessDidTerminate` agiscono senza `webView === web`. Se arrivasse una callback dalla pagina vecchia dopo il tempo massimo (`:40`), potrebbe buttare via la pagina nuova, oppure mettere `pronto = true` con `web == nil`. In quel caso tornerebbe l'errore «file non leggibile» fisso fino al riavvio. Di solito una WKWebView rilasciata non chiama più il delegato, quindi è improbabile.
- **Correzione:** `guard webView === web else { return }` nelle quattro callback.

### M3. #23: `Backup.esporta` può ancora dare un file vuoto
- `Comune/Backup.swift:15` (`(try? …) ?? Data()`). Con #23 non risultano più vie per salvare NaN o infinito (misure, kg, km del cardio passano tutti da `leggiNumero`), quindi oggi non succede. Resta però un errore silenzioso: meglio che lanci l'errore e che l'interfaccia dica «backup non riuscito».

### M4. #26: quantità con forme non previste nella spesa
- `Dieta/Archivio.swift:408` (nuova regex). Il numero all'inizio viene preso con la **prima parola** dopo:
  - «2 x 50 g» diventa «2 x» invece di 100 g (prima era «a piacere»);
  - «100 grammi» o «1 litro» finiscono tra i pezzi: «100 g + 100 grammi»;
  - singolare e plurale restano separati: «1 fetta + 2 fette».
- La regola delle migliaia (`1.500 kg` = 1500 kg) è documentata e va bene per PDF italiani.
- Nei dati d'esempio ci sono solo «N g», «libera» e vuoto, quindi l'impatto dipende dai PDF reali. **Correzione eventuale:** riconoscere `grammi|grammo|litri|litro` come g/ml, e non prendere come parola `x` o `×`.

### M5. #26: importando un backup della web app si perdono le sue scelte acqua/pasti
- `Comune/Backup.swift:20-24`: vengono tenuti **tutti** i promemoria attuali di Forma, compresi acqua e pasti, anche se il backup web li aveva accesi. È voluto, e il test lo fissa (`acqua == false`). Lo segnalo solo perché chi passa dalla web app a Forma deve riaccenderli a mano.
- Alternativa: prendere `acqua` e `pasti` dal backup e tenere da Forma solo mattino e orari.

### M6. #27: altri percorsi che lasciano chiuso il piano precedente
- `Dieta/Archivio.swift:231` `sostituisciPiano`: se **modifico** un piano aperto (che aveva chiuso il precedente) e gli metto una data di fine, il precedente resta chiuso. Finito quello modificato torna «Nessun piano», cioè il difetto #3 dell'audit per un'altra strada. Lo stesso succede spostando in avanti la data di inizio: resta un buco.
- `:239` `eliminaPiano` riapre qualsiasi piano che finisce il giorno prima, anche se la fine l'aveva scelta l'utente. È raro.
- I piani già accorciati prima di #27 non vengono riparati.
- **Correzione eventuale:** in `sostituisciPiano`, se l'originale aveva chiuso dei piani (fine = suo inizio − 1) e il nuovo ha una fine o inizia dopo, riaprirli come fa `eliminaPiano`.

### M7. #27: calendario ricreato a ogni chiamata
- `Comune/Utilita.swift:48` `Giorni.calendario` ora è calcolato: ogni `Giorni.iso` crea un `Calendar`. Va bene per i volumi attuali (centinaia di allenamenti). Se in futuro lo storico rallenta, basta una cache invalidata da `NSSystemTimeZoneDidChange`/`NSCurrentLocaleDidChange`.

---

## Per PR

### #23 dati-sicuri: ok da unire
- `leggiNumero` rifiuta nan, inf, 1e999, esponenti ed esadecimali, e accetta ancora le cifre arabe e la virgola. `salva()` di dieta e palestra non scrive mai dati vuoti, `backup()` lancia l'errore. Il file vuoto viene trattato come «assente», senza copia vuota. Promemoria e pagamento non vengono toccati con i dati bloccati. Il lettore PDF si ricrea dopo un errore o la chiusura da parte di iOS e ha un tempo massimo di 20 s.
- Isolamento: il progetto ha `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, quindi il `Task` del tempo massimo gira sul MainActor.
- I test provano il comportamento giusto: NaN produce un errore e non dati vuoti, il file resta com'è, la pagina si ricrea. Solo M2 e M3, minori.

### #24 sessioni-watch: ok da unire
- L'aggancio usa una fine verosimile: un allenamento lasciato aperto da due giorni non prende più la sessione Watch di oggi, e `termina` non assorbe sessioni di altri giorni. «Annullalo e inizia» passa da `annulla()` e ferma il timer. Gli altri punti da cui si inizia un allenamento (HomeView, dettaglio scheda) partono solo senza un allenamento in corso. La durata alla chiusura ha un limite.
- `fattaIl` è decodificato in modo tollerante (testato), e la parte palestra viene ignorata dalla web app, quindi non c'è problema di compatibilità con index.html. Una sessione compilata dal Watch tiene la sua `fine`.
- Solo M1, che nasce dall'unione con #25.

### #25 logica-allenamento: da correggere I1 prima di unire
- Gli altri punti sono corretti e testati: serie attiva da `ultimaSerie`, riscaldamento con il suo «precedente» (anche in Live e `segnaDaLive`), «Fine» con solo riscaldamento, numerazione della Live, record a corpo libero (stringa tradotta e coerente: `%@`/`%lld`), settimana unica pesi + cardio (usata anche in Palestra e Storico; in Progressi viene letto solo `kg`), piani portati a 7 giorni alla lettura e indici controllati nella vista.
- Da sistemare: I1, e già che c'è M1 (`fattaIl = nil`).

### #26 spesa-e-backup: ok da unire
- Pezzi, unità miste e migliaia funzionano. `numeroQuantita` passa da `leggiNumero` di #23: dopo l'unione «1.250,5» dà ancora 1250,5 (test verdi).
- Web app: `datiDaBackup` prende la parte `dieta` di Forma. Il formato dei promemoria è compatibile (`acqua` e `pasti` booleani, le altre chiavi vengono ignorate). `spuntaSpesa` tiene le due settimane più recenti; ho controllato i casi «solo prossima», «due vecchie» e «questa + prossima».
- Solo M4 e M5.

### #27 piani-e-date: ok da unire
- Un piano a termine non chiude il precedente, eliminare un piano riapre quello che aveva chiuso, a parità di data vince il primo (come `planFor` della web app), il calendario segue il fuso attuale. Oggi si aggiorna al ritorno in primo piano e a mezzanotte, e tutte le sezioni (pasti, allenamento, olio/acqua, peso, misura veloce) usano `ultimoOggi`.
- Mancano test per la schermata Oggi, come dichiarato. Solo M6 e M7.

---

## Ordine di unione consigliato
1. **#23** dati-sicuri: base di sicurezza; cambia `leggiNumero`, usato da #26.
2. **#27** piani-e-date: Utilita e Archivio, piccola.
3. **#26** spesa-e-backup: Archivio (spesa) e index.html.
4. **#24** sessioni-watch.
5. **#25** logica-allenamento, dopo la correzione di I1 (e M1), così si integra sopra `fineVerosimile` di #24.

Le cinque si uniscono senza conflitti in qualsiasi ordine. Dopo l'ultima conviene rilanciare i FormaTests su main.
