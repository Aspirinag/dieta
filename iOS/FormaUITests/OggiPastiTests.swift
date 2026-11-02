import XCTest

// In Oggi la sezione dei pasti si apre e si chiude toccando "Pasti segnati"
final class OggiPastiTests: XCTestCase {
    func testPastiSegnatiSiApreESiChiude() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "oggi"]
        app.launch()

        let intestazione = app.buttons["pasti-segnati"]
        XCTAssertTrue(intestazione.waitForExistence(timeout: 8), "Manca l'intestazione Pasti segnati")
        let riga = app.descendants(matching: .any)["riga-pasto"].firstMatch

        // Parte chiusa, qualunque fosse lo stato salvato
        if riga.waitForExistence(timeout: 2) { intestazione.tap() }
        XCTAssertFalse(riga.waitForExistence(timeout: 2), "Da chiusa non deve mostrare i pasti")

        intestazione.tap()
        XCTAssertTrue(riga.waitForExistence(timeout: 3), "Da aperta deve mostrare i pasti")

        intestazione.tap()
        XCTAssertFalse(riga.waitForExistence(timeout: 2), "Richiusa non deve mostrare i pasti")
    }
}
