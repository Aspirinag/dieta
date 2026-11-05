import XCTest

// Progressi → Palestra: grafico, record, allenamenti; dettaglio e ritorno; eliminazione del cardio
final class ProgressiPalestraTests: XCTestCase {
    private func avvia() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "progressi"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Progressi"].waitForExistence(timeout: 8))
        app.segmentedControls.buttons["Palestra"].tap()
        return app
    }

    private func porta(_ el: XCUIElement, _ app: XCUIApplication) {
        for _ in 0..<8 where !el.isHittable { app.swipeUp() }
    }

    func testDettaglioETorna() {
        continueAfterFailure = false
        let app = avvia()
        let riga = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'allenamento-'")).firstMatch
        XCTAssertTrue(riga.waitForExistence(timeout: 5), "Manca un allenamento nell'elenco")
        porta(riga, app)
        riga.tap()
        XCTAssertTrue(app.navigationBars["Progressi"].waitForNonExistence(timeout: 5), "Toccando un allenamento deve aprirsi il dettaglio")
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Progressi"].waitForExistence(timeout: 5), "Tornando indietro si deve rivedere Progressi")
    }

    func testRecordApreEsercizioETorna() {
        continueAfterFailure = false
        let app = avvia()
        let record = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'record-'")).firstMatch
        XCTAssertTrue(record.waitForExistence(timeout: 5), "Manca un record")
        porta(record, app)
        record.tap()
        XCTAssertTrue(app.navigationBars["Progressi"].waitForNonExistence(timeout: 5), "Toccando un record si apre l'esercizio")
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Progressi"].waitForExistence(timeout: 5))
    }

    func testCalendarioETuttiSiAprono() {
        continueAfterFailure = false
        let app = avvia()
        XCTAssertTrue(app.staticTexts["Kg totali per settimana"].waitForExistence(timeout: 5), "Manca il grafico")
        let calendario = app.buttons["Calendario"]
        porta(calendario, app)
        calendario.tap()
        XCTAssertTrue(app.navigationBars["Calendario"].waitForExistence(timeout: 5))
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Progressi"].waitForExistence(timeout: 5))
        let tutti = app.buttons["Tutti gli allenamenti"]
        porta(tutti, app)
        tutti.tap()
        XCTAssertTrue(app.navigationBars["Allenamenti"].waitForExistence(timeout: 5))
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Progressi"].waitForExistence(timeout: 5))
        let tuttiRecord = app.buttons["Tutti i record"]
        porta(tuttiRecord, app)
        tuttiRecord.tap()
        XCTAssertTrue(app.navigationBars["Record"].waitForExistence(timeout: 5))
    }

    func testCardioSiElimina() {
        continueAfterFailure = false
        let app = avvia()
        let cardio = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'cardio-'"))
        XCTAssertTrue(cardio.firstMatch.waitForExistence(timeout: 5), "Nei dati di prova ci sono cardio tra gli ultimi allenamenti")
        let riga = cardio.firstMatch
        let id = riga.identifier
        porta(riga, app)
        riga.tap()
        let elimina = app.buttons["Elimina cardio"]
        XCTAssertTrue(elimina.waitForExistence(timeout: 3), "Toccando un cardio si apre il dettaglio, dove si elimina")
        elimina.tap()
        let conferma = app.sheets.buttons["Elimina"].firstMatch
        XCTAssertTrue(conferma.waitForExistence(timeout: 3), "Prima di eliminare serve una conferma")
        conferma.tap()
        XCTAssertTrue(app.navigationBars["Progressi"].waitForExistence(timeout: 5), "Dopo l'eliminazione si torna a Progressi")
        XCTAssertTrue(app.descendants(matching: .any)[id].waitForNonExistence(timeout: 3), "Il cardio eliminato non deve più comparire")
    }

    private func tocca(_ prefisso: String, _ app: XCUIApplication) {
        let riga = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", prefisso)).firstMatch
        XCTAssertTrue(riga.waitForExistence(timeout: 5), "Manca una riga «\(prefisso)»")
        porta(riga, app)
        riga.tap()
    }

    // Tutti → allenamento → dettaglio → indietro: si rivede «Allenamenti», non la radice di Progressi
    func testTuttiApreDettaglioETornaAllElenco() {
        continueAfterFailure = false
        let app = avvia()
        let tutti = app.buttons["Tutti gli allenamenti"]
        porta(tutti, app)
        tutti.tap()
        let barra = app.navigationBars["Allenamenti"]
        XCTAssertTrue(barra.waitForExistence(timeout: 5))
        tocca("allenamento-", app)
        XCTAssertTrue(barra.waitForNonExistence(timeout: 5), "Toccando un allenamento deve aprirsi il dettaglio")
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        XCTAssertTrue(barra.waitForExistence(timeout: 5), "Tornando indietro si deve rivedere «Allenamenti»")
        XCTAssertFalse(app.navigationBars["Progressi"].exists)
    }

    // Calendario → giorno con i pesi → allenamento → dettaglio → indietro: si rivede il calendario
    func testCalendarioApreDettaglioETornaAlCalendario() {
        continueAfterFailure = false
        let app = avvia()
        let calendario = app.buttons["Calendario"]
        porta(calendario, app)
        calendario.tap()
        let barra = app.navigationBars["Calendario"]
        XCTAssertTrue(barra.waitForExistence(timeout: 5))
        let giorno = app.buttons.matching(NSPredicate(format: "label CONTAINS 'pesi fatti'")).firstMatch
        XCTAssertTrue(giorno.waitForExistence(timeout: 5), "Nel mese ci sono giorni con i pesi")
        giorno.tap()
        tocca("allenamento-", app)
        XCTAssertTrue(barra.waitForNonExistence(timeout: 5), "Toccando un allenamento deve aprirsi il dettaglio")
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        XCTAssertTrue(barra.waitForExistence(timeout: 5), "Tornando indietro si deve rivedere il calendario")
        XCTAssertFalse(app.navigationBars["Progressi"].exists)
    }

    // Tutti i record → esercizio → indietro: si rivede «Record»
    func testTuttiIRecordApreEsercizioETornaAllElenco() {
        continueAfterFailure = false
        let app = avvia()
        let tutti = app.buttons["Tutti i record"]
        porta(tutti, app)
        tutti.tap()
        let barra = app.navigationBars["Record"]
        XCTAssertTrue(barra.waitForExistence(timeout: 5))
        tocca("record-", app)
        XCTAssertTrue(barra.waitForNonExistence(timeout: 5), "Toccando un record si apre l'esercizio")
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        XCTAssertTrue(barra.waitForExistence(timeout: 5), "Tornando indietro si deve rivedere «Record»")
        XCTAssertFalse(app.navigationBars["Progressi"].exists)
    }
}
