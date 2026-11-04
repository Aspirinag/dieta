import XCTest

// Quattro schede; le Impostazioni si aprono dall'ingranaggio di Oggi
final class NavigazioneTests: XCTestCase {
    func testQuattroSchedeEImpostazioniDalIngranaggio() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "oggi"]
        app.launch()

        let barra = app.tabBars.firstMatch
        XCTAssertTrue(barra.waitForExistence(timeout: 8), "Manca la tab bar")
        for nome in ["Oggi", "Dieta", "Palestra", "Progressi"] {
            XCTAssertTrue(barra.buttons[nome].exists, "Manca la scheda \(nome)")
        }
        XCTAssertFalse(barra.buttons["Impostazioni"].exists, "Impostazioni non è più una scheda")

        let ingranaggio = app.buttons["Impostazioni"]
        XCTAssertTrue(ingranaggio.waitForExistence(timeout: 5), "Manca l'ingranaggio in Oggi")
        ingranaggio.tap()

        for voce in ["Piani alimentari", "Promemoria", "Backup"] {
            XCTAssertTrue(app.buttons[voce].waitForExistence(timeout: 5), "Manca la voce \(voce)")
        }
        let fine = app.buttons["Fine"]
        XCTAssertTrue(fine.exists, "Manca Fine")
        fine.tap()
        XCTAssertFalse(app.buttons["Backup"].waitForExistence(timeout: 2), "Il foglio non si è chiuso")
        XCTAssertTrue(app.buttons["Impostazioni"].exists)
    }
}
