# Live Activity dell'allenamento — piano

**Spec:** `docs/superpowers/specs/2026-11-09-live-allenamento-design.md`
**Interfaccia condivisa (già scritta):** `iOS/Condiviso/AttivitaAllenamento.swift` — non cambiarne i nomi.

Due parti indipendenti, ciascuna con il suo branch/worktree, poi unite in `live-allenamento`.

## Parte A — logica dell'app (test prima del codice)
File: `Forma/Palestra/LiveRecupero.swift` (diventa la Live Activity dell'allenamento), `ArchivioPalestra.swift`,
`AllenamentoInCorsoView.swift`, `FormaApp.swift`, test in `FormaTests/LiveRecuperoTests.swift` (+ nuovi).
1. `StatoAllenamentoLive.da(allenamento:, ultimaSerie:, recupero:, libreria:)` (funzione pura nell'app):
   serie attiva con `SerieAttiva.trova`, numero/totale, kg×rip con `EsitoSpunta.valuta`, prossimo con
   `PercorsoAllenamento.prossimoAperto`, titoli localizzati. Test: serie con valori, valori dalla precedente,
   corpo libero, mancano le ripetizioni (niente spunta), tutte fatte, riscaldamento, prossimo/ultimo.
2. Il gestore (ex `LiveRecupero`) lavora su `StatoAllenamentoLive?`: avvia/aggiorna/chiude, niente invii uguali;
   `staleDate` = fine del recupero se c'è. Test con il sistema finto.
3. `Palestra.ultimaSerie: UUID?` (non salvata) e `Palestra.segnaDaLive(_ id:, timer:)` che fa ciò che fa la spunta
   nell'app (valori da `EsitoSpunta`, `fatta = true`, recupero con `timer.avvia(recupero, serie:, esercizio:)`),
   poi `salvaOra()`. La spunta della vista aggiorna anche `ultimaSerie`. Test.
4. Collegamento: osservazione con Observation fuori dalle viste (vale anche in background), `AzioniLive.segna`
   impostato in `FormaApp.init`, `chiudiRimaste` per `AttivitaAllenamento`. Rimuovere `AttivitaRecupero`.

## Parte B — aspetto (estensione RecuperoWidget)
File: `RecuperoWidget/RecuperoWidget.swift`, `RecuperoWidget/Localizable.xcstrings`.
1. `ActivityConfiguration(for: AttivitaAllenamento.self)`: schermata bloccata, Dynamic Island (espansa,
   compatta, minima) come da spec, pulsante `Button(intent: SegnaSerieIntent(serie:))` solo se `puoSpuntare`.
2. Testi con traduzione inglese; `#Preview(as: .content, using: AttivitaAllenamento())` con stati di esempio.

## Fine
Unione delle due parti, test completi, `ui-checker` dove possibile, PR, CI verde.
