import XCTest

extension XCUIElement {
    // Oggi è una lista: le righe fuori schermo esistono solo dopo aver scorso
    func esisteScorrendo(in app: XCUIApplication, timeout: TimeInterval = 8) -> Bool {
        _ = app.tabBars.firstMatch.waitForExistence(timeout: timeout)
        let barra = app.tabBars.firstMatch.frame.minY
        for _ in 0..<8 {
            if exists && isHittable && frame.maxY < barra { return true }
            app.swipeUp()
        }
        return exists && isHittable
    }
}

// Oggi: i pasti si segnano con un tocco; olio e acqua si segnano toccando i cucchiaini e le gocce
final class OggiPastiTests: XCTestCase {
    private func avvia() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "oggi"]
        app.launch()
        return app
    }

    func testSegnareUnPastoDaOggi() {
        continueAfterFailure = false
        let app = avvia()

        XCTAssertTrue(app.staticTexts["Pasti · 1 di 4"].waitForExistence(timeout: 8), "Il contatore dei pasti parte da 1 di 4")
        let pranzo = app.buttons["Segna Pranzo"]
        XCTAssertTrue(pranzo.exists, "Manca il cerchio di Pranzo")
        pranzo.tap()
        XCTAssertTrue(app.staticTexts["Pasti · 2 di 4"].waitForExistence(timeout: 3), "Dopo il tocco i pasti segnati sono 2 di 4")
        XCTAssertTrue(app.buttons.matching(identifier: "riga-pasto").count >= 4, "Manca una riga per pasto")
    }

    func testOlioSiSegnaConUnTocco() {
        continueAfterFailure = false
        let app = avvia()

        let olio = app.descendants(matching: .any)["Olio"].firstMatch
        XCTAssertTrue(olio.esisteScorrendo(in: app), "Manca l'elemento Olio")
        XCTAssertEqual(olio.value as? String, "2 di 6 cucchiaini")
        // Si tocca il terzo cucchiaino: ogni cucchiaino occupa 44 punti, in una riga sotto il testo, dal bordo sinistro
        let terzo = olio.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: 2.5 * 44, dy: olio.frame.height - 22))
        terzo.tap()
        // La riga può essere ricreata dalla lista: si cerca di nuovo
        let dopo = app.descendants(matching: .any)["Olio"].firstMatch
        XCTAssertTrue(dopo.esisteScorrendo(in: app, timeout: 3), "L'elemento Olio sparisce dopo il tocco")
        XCTAssertEqual(dopo.value as? String, "3 di 6 cucchiaini")
    }

    func testPesoApreIlFoglioVeloce() {
        continueAfterFailure = false
        let app = avvia()

        let peso = app.buttons["Peso"]
        XCTAssertTrue(peso.esisteScorrendo(in: app), "Manca il riquadro Peso")
        peso.tap()
        XCTAssertTrue(app.textFields["campo-peso"].waitForExistence(timeout: 5), "Il peso apre il foglio veloce")
    }

    func testRiquadroPagamentoSoloNellaFinestra() {
        continueAfterFailure = false
        let dentro = XCUIApplication()
        dentro.launchArguments = ["-demo", "-tab", "oggi", "-pagamento-tra", "3"]
        dentro.launch()
        XCTAssertTrue(dentro.descendants(matching: .any)["riquadro-pagamento"].waitForExistence(timeout: 8), "Il riquadro manca nella settimana del pagamento")
        XCTAssertEqual(dentro.staticTexts["Tra 3 giorni si paga la palestra."].exists, true)
        dentro.buttons["Segna come pagato"].tap()
        XCTAssertFalse(dentro.descendants(matching: .any)["riquadro-pagamento"].waitForExistence(timeout: 2), "Segnato pagato, il riquadro sparisce")
        dentro.terminate()

        let fuori = XCUIApplication()
        fuori.launchArguments = ["-demo", "-tab", "oggi", "-pagamento-tra", "15"]
        fuori.launch()
        XCTAssertTrue(fuori.staticTexts["Pasti · 1 di 4"].waitForExistence(timeout: 8))
        XCTAssertFalse(fuori.descendants(matching: .any)["riquadro-pagamento"].exists, "Fuori dalla finestra il riquadro non compare")
    }

    // Giorno di cardio senza cardio fatto: titolo e pulsante per registrarlo
    func testOggiCardioHaIlPulsante() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "oggi", "-oggi-cardio"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Cardio"].waitForExistence(timeout: 8), "Manca «Cardio»")
        let registra = app.buttons["Registra cardio"]
        XCTAssertTrue(registra.exists, "Manca il pulsante «Registra cardio»")
        registra.tap()
        XCTAssertTrue(app.navigationBars["Cardio"].waitForExistence(timeout: 5), "Non si apre il foglio del cardio")
    }
}
