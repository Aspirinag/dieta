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
        // L'ultimo peso è un valore vero: il campo è compilato e «Salva» è subito attivo
        XCTAssertFalse((campo.value as? String ?? "").isEmpty, "Il campo non è compilato con l'ultimo peso")
        XCTAssertTrue(app.buttons["salva-peso"].isEnabled, "«Salva» è spento con il peso già compilato")
        app.buttons["peso-piu"].tap()
        campo.clearAndTypeText("79,5")
        XCTAssertTrue(app.buttons["salva-peso"].isEnabled, "«Salva» resta spento dopo aver scritto un peso")
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

    // Giorno di riposo: «Allenati lo stesso» apre la scelta della scheda e avvia quella scelta
    func testAllenatiLoStessoApreLaSceltaEAvvia() {
        continueAfterFailure = false
        let app = avvia(["-oggi-riposo"])
        XCTAssertTrue(app.staticTexts["Riposo"].waitForExistence(timeout: 8), "Manca «Riposo»")
        let pulsante = app.buttons["allenati-lo-stesso"]
        XCTAssertTrue(pulsante.exists, "Manca «Allenati lo stesso»")
        pulsante.tap()
        let libero = app.buttons["Allenamento libero"]
        XCTAssertTrue(libero.waitForExistence(timeout: 5), "Non si apre la scelta della scheda")
        XCTAssertFalse(app.tabBars.firstMatch.buttons["Palestra"].isSelected, "Non deve portare alla scheda Palestra")
        libero.tap()
        XCTAssertTrue(app.navigationBars["Allenamento libero"].waitForExistence(timeout: 8), "Non parte l'allenamento scelto")
        XCTAssertTrue(app.buttons["Fine"].exists, "Manca «Fine»: l'allenamento non è in corso")
    }

    func testAltraSchedaDopoAllenamentoFatto() {
        continueAfterFailure = false
        let app = avvia(["-allenato-oggi"])
        XCTAssertTrue(app.buttons["Un'altra scheda"].waitForExistence(timeout: 8), "Manca «Un'altra scheda»")
        app.buttons["Un'altra scheda"].tap()
        XCTAssertTrue(app.tabBars.firstMatch.buttons["Palestra"].isSelected, "Il link non porta a Palestra")
    }
}

private extension XCUIElement {
    func clearAndTypeText(_ testo: String) {
        guard let attuale = value as? String else { typeText(testo); return }
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: attuale.count) + testo)
    }
}
