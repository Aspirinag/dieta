import XCTest

// Allenamento in corso: esercizio finito chiuso in una riga, «ultima volta» che si tocca
final class AllenamentoScorrevoleUITests: XCTestCase {
    private func avvia() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "inCorso"]
        app.launch()
        return app
    }

    func testEsercizioFinitoSiChiudeESiRiapre() {
        continueAfterFailure = false
        let app = avvia()
        let riga = app.buttons.matching(NSPredicate(format: "label CONTAINS 'serie ✓'")).firstMatch
        XCTAssertTrue(riga.waitForExistence(timeout: 8), "Il primo esercizio, tutto spuntato, non è chiuso in una riga")
        let prima = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Serie 1'")).count
        riga.tap()
        let dopo = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Serie 1'")).count
        XCTAssertGreaterThan(dopo, prima, "Toccando la riga l'esercizio non si riapre")
    }

    func testUltimaVoltaCopiaNeiCampi() {
        continueAfterFailure = false
        let app = avvia()
        let usa = app.buttons["Usa i valori dell'ultima volta"].firstMatch
        XCTAssertTrue(usa.waitForExistence(timeout: 8), "Manca il pulsante «Usa i valori dell'ultima volta»")
        usa.tap()
        let kg = app.textFields.matching(NSPredicate(format: "value != '' AND value != 'kg'")).firstMatch
        XCTAssertTrue(kg.exists, "Dopo il tocco i campi non hanno i valori")
    }
}
