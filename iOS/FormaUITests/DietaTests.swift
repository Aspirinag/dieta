import XCTest

// Dieta: la settimana del piano, un riquadro per pasto, il dettaglio con le quantità, la riga della spesa
final class DietaTests: XCTestCase {
    private func avvia(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "dieta"] + extra
        app.launch()
        return app
    }

    private func giorni(_ app: XCUIApplication) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "label MATCHES %@", "(Lunedì|Martedì|Mercoledì|Giovedì|Venerdì|Sabato|Domenica) [0-9]+"))
    }

    func testSettimanaEPasto() {
        continueAfterFailure = false
        let app = avvia()

        XCTAssertTrue(giorni(app).firstMatch.waitForExistence(timeout: 8), "Manca la striscia dei giorni")
        XCTAssertEqual(giorni(app).count, 7, "La striscia ha sette giorni")

        let mercoledi = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Mercoledì '")).firstMatch
        mercoledi.tap()
        let colazione = app.buttons["Colazione"]
        XCTAssertTrue(colazione.waitForExistence(timeout: 3), "Manca il riquadro Colazione")
        colazione.tap()

        XCTAssertTrue(app.staticTexts["Yogurt greco"].waitForExistence(timeout: 5), "Il dettaglio mostra lo yogurt")
        XCTAssertTrue(app.staticTexts["150 g"].exists, "Il dettaglio mostra la quantità")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["Colazione"].waitForExistence(timeout: 5), "Indietro torna a Dieta")
        XCTAssertEqual(giorni(app).count, 7)
    }

    func testPastoSegnatoNelDettaglioCompareInOggi() {
        continueAfterFailure = false
        let app = avvia()

        app.buttons["Pranzo"].tap()
        // Nel demo oggi il pranzo ha già l'alternativa «Riso»; lo segniamo dal dettaglio
        let segna = app.buttons["Pranzo"]
        XCTAssertTrue(segna.waitForExistence(timeout: 5), "Manca la spunta del pasto")
        XCTAssertEqual(segna.value as? String, "da fare")
        segna.tap()
        XCTAssertEqual(app.buttons["Pranzo"].value as? String, "fatto")
        app.navigationBars.buttons.firstMatch.tap()
        app.tabBars.firstMatch.buttons["Oggi"].tap()
        XCTAssertTrue(app.staticTexts["2 di 4"].waitForExistence(timeout: 5), "Il pasto segnato in Dieta conta in Oggi")
    }

    func testRigaSpesaApreLaSpesa() {
        continueAfterFailure = false
        let app = avvia()

        let riga = app.buttons["Spesa della settimana"]
        for _ in 0..<4 where !riga.isHittable { app.swipeUp() }
        XCTAssertTrue(riga.waitForExistence(timeout: 8), "Manca la riga della spesa")
        let valore = riga.value as? String ?? ""
        XCTAssertTrue(valore.contains("prodotti") && valore.contains("presi"), "La riga dice quanti prodotti e quanti presi: \(valore)")
        riga.tap()
        XCTAssertTrue(app.navigationBars["Spesa"].waitForExistence(timeout: 5), "Non si apre la spesa")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(giorni(app).firstMatch.waitForExistence(timeout: 5), "Indietro torna a Dieta")
    }

    func testVistaSpesaApreLaSpesa() {
        continueAfterFailure = false
        let app = avvia(["-vista", "spesa"])
        XCTAssertTrue(app.navigationBars["Spesa"].waitForExistence(timeout: 8), "-vista spesa apre la spesa")
    }

    func testSenzaPianoNonCompareLaSpesa() {
        continueAfterFailure = false
        let app = avvia()
        // Il secondo profilo di prova non ha nessun piano
        app.tabBars.firstMatch.buttons["Oggi"].tap()
        app.buttons["Esempio"].tap()
        app.buttons["Secondo esempio"].tap()
        app.tabBars.firstMatch.buttons["Dieta"].tap()

        XCTAssertTrue(app.staticTexts["Nessun piano per questo giorno"].waitForExistence(timeout: 5), "Manca lo stato vuoto")
        XCTAssertTrue(app.buttons["Carica il PDF"].exists)
        XCTAssertTrue(app.buttons["Scrivilo a mano"].exists)
        XCTAssertEqual(giorni(app).count, 7, "La striscia resta")
        XCTAssertFalse(app.buttons["Spesa della settimana"].exists, "Senza piano la spesa non compare")
    }
}
