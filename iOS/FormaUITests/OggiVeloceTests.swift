import XCTest

// Oggi: peso con un solo foglio, alimenti sotto i pasti, link «Un'altra scheda»
final class OggiVeloceTests: XCTestCase {
    private func avvia(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "oggi"] + extra
        app.launch()
        return app
    }

    func testPesoSiSalvaDalFoglioVeloce() {
        continueAfterFailure = false
        let app = avvia()
        let peso = app.buttons["Peso"]
        XCTAssertTrue(peso.waitForExistence(timeout: 8), "Manca il riquadro Peso")
        peso.tap()
        let campo = app.textFields["campo-peso"]
        XCTAssertTrue(campo.waitForExistence(timeout: 5), "Il peso non apre il foglio veloce")
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3), "La tastiera non è aperta")
        XCTAssertFalse((campo.value as? String ?? "").isEmpty, "Il campo non ha l'ultimo peso")
        campo.typeText("79,5")
        app.buttons["salva-peso"].tap()
        let chiuso = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: campo)
        XCTAssertEqual(XCTWaiter().wait(for: [chiuso], timeout: 5), .completed, "Il foglio non si chiude")
        XCTAssertTrue((app.buttons["Peso"].value as? String ?? "").contains("79,5"), "Il peso nuovo non compare in Oggi")
        XCTAssertTrue(app.tabBars.firstMatch.buttons["Oggi"].isSelected, "Si resta su Oggi")
    }

    func testAltriDatiApreEditorCompleto() {
        continueAfterFailure = false
        let app = avvia()
        app.buttons["Peso"].tap()
        let altri = app.buttons["Altri dati"]
        XCTAssertTrue(altri.waitForExistence(timeout: 5), "Manca «Altri dati»")
        altri.tap()
        XCTAssertTrue(app.navigationBars["Nuova misurazione"].waitForExistence(timeout: 5), "Non si apre l'editor completo")
    }

    func testPastoMostraAlimentiEApreIlDettaglio() {
        continueAfterFailure = false
        let app = avvia()
        let riga = app.buttons["pasto-Colazione"]
        XCTAssertTrue(riga.waitForExistence(timeout: 8), "Manca la riga degli alimenti sotto Colazione")
        riga.tap()
        XCTAssertTrue(app.navigationBars["Colazione"].waitForExistence(timeout: 5), "Non si apre il dettaglio del pasto")
    }

    func testAltraSchedaDopoAllenamentoFatto() {
        continueAfterFailure = false
        let app = avvia(["-allenato-oggi"])
        XCTAssertTrue(app.buttons["Un'altra scheda"].waitForExistence(timeout: 8), "Manca «Un'altra scheda»")
        app.buttons["Un'altra scheda"].tap()
        XCTAssertTrue(app.tabBars.firstMatch.buttons["Palestra"].isSelected, "Il link non porta a Palestra")
    }
}
