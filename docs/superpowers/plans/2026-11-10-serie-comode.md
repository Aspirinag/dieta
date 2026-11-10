# Piano: serie comode

1. Test (FormaTests/SerieComodeTests.swift): elenco rotella kg (0-300 passi 0,5, valore non multiplo incluso, fuori scala incluso), elenco rotella ripetizioni, arrotondamento al passo, ± che non scende sotto 0. Vederli fallire.
2. `PassoSerie` in SpuntaSerie.swift: `opzioniKg`, `opzioniRip`. Vederli passare.
3. AllenamentoInCorsoView: caselle al posto dei TextField; `RotellaSerie` (foglio con Picker .wheel, «Fine», «Svuota»); tolti barra tastiera e `RichiestaPasso`; `campo` diventa lo stato della rotella aperta; spunta con campo mancante apre la rotella; − / + a 44 pt.
4. VoiceOver: etichette in spunta, dialogo «Fine» con «Annulla», − / +, Oggi nascosta sotto l'allenamento (FormaApp), Dosaggio (olio/acqua).
5. Localizable.xcstrings a mano (en, en-GB).
6. UI test: aggiornare AllenamentoScorrevoleUITests (campi di testo -> caselle, niente tastiera) e provarli.
7. Schermate (chiaro, scuro, testo grande), FormaTests verdi, commit, push, PR con `--base logica-allenamento`.
