import XCTest

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

        XCTAssertTrue(app.staticTexts["1 di 4"].waitForExistence(timeout: 8), "Il contatore dei pasti parte da 1 di 4")
        let pranzo = app.buttons["Segna Pranzo"]
        XCTAssertTrue(pranzo.exists, "Manca il cerchio di Pranzo")
        pranzo.tap()
        XCTAssertTrue(app.staticTexts["2 di 4"].waitForExistence(timeout: 3), "Dopo il tocco i pasti segnati sono 2 di 4")
        XCTAssertTrue(app.buttons.matching(identifier: "riga-pasto").count >= 4, "Manca una riga per pasto")
    }

    func testOlioSiSegnaConUnTocco() {
        continueAfterFailure = false
        let app = avvia()

        let olio = app.descendants(matching: .any)["Olio"].firstMatch
        XCTAssertTrue(olio.waitForExistence(timeout: 8), "Manca l'elemento Olio")
        XCTAssertEqual(olio.value as? String, "2 di 6 cucchiaini")
        // Si tocca il terzo cucchiaino: ogni cucchiaino occupa 24 punti, allineati al bordo destro
        let terzo = olio.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: olio.frame.width - 3.5 * 24, dy: olio.frame.height / 2))
        terzo.tap()
        XCTAssertEqual(olio.value as? String, "3 di 6 cucchiaini")
    }

    func testPesoApreProgressi() {
        continueAfterFailure = false
        let app = avvia()

        let peso = app.buttons["Peso"]
        XCTAssertTrue(peso.waitForExistence(timeout: 8), "Manca il riquadro Peso")
        peso.tap()
        XCTAssertTrue(app.tabBars.firstMatch.buttons["Progressi"].isSelected, "Il peso porta a Progressi")
    }
}
