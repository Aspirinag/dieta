import XCTest

// Palestra serve a iniziare: prossima scheda, settimana, schede con ▶, menu +
final class PalestraUITests: XCTestCase {
    private func avvia() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "allenamento"]
        app.launch()
        return app
    }

    func testInizia() {
        continueAfterFailure = false
        let app = avvia()
        XCTAssertTrue(app.staticTexts["Prossima scheda"].waitForExistence(timeout: 8), "Manca il riquadro Prossima scheda")
        XCTAssertTrue(app.staticTexts["Questa settimana"].exists, "Manca il riquadro Questa settimana")

        // Il menu + contiene le quattro voci
        app.buttons["Aggiungi"].tap()
        for voce in ["Nuova scheda", "Schede pronte", "Libreria esercizi", "Programma della settimana"] {
            XCTAssertTrue(app.buttons[voce].waitForExistence(timeout: 3), "Manca «\(voce)» nel menu +")
        }
        app.buttons["Libreria esercizi"].tap()
        XCTAssertTrue(app.navigationBars["Libreria esercizi"].waitForExistence(timeout: 5), "Non si apre la Libreria")
        app.navigationBars.firstMatch.buttons.firstMatch.tap()

        // Inizia apre l'allenamento in corso
        let inizia = app.buttons["Inizia"].firstMatch
        XCTAssertTrue(inizia.waitForExistence(timeout: 5), "Manca il pulsante Inizia")
        inizia.tap()
        XCTAssertTrue(app.buttons["Fine"].waitForExistence(timeout: 5), "Non si apre l'allenamento in corso")
    }

    func testSchedaERaggiungibilita() {
        continueAfterFailure = false
        let app = avvia()
        XCTAssertTrue(app.staticTexts["Prossima scheda"].waitForExistence(timeout: 8))
        let play = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Inizia '")).firstMatch
        for _ in 0..<4 where !play.exists { app.swipeUp() }
        XCTAssertTrue(play.exists, "Manca il ▶ di una scheda")
        XCTAssertTrue(app.buttons["Allenamento libero"].exists || { app.swipeUp(); return app.buttons["Allenamento libero"].exists }(), "Manca Allenamento libero")
        for (voce, barra) in [("Schede pronte", "Schede pronte"), ("Programma della settimana", "Programma della settimana")] {
            app.swipeDown(); app.swipeDown()
            app.buttons["Aggiungi"].tap()
            app.buttons[voce].tap()
            XCTAssertTrue(app.navigationBars[barra].waitForExistence(timeout: 5), "Non si apre \(voce)")
            app.navigationBars.firstMatch.buttons.firstMatch.tap()
        }
    }

    func testNomeApreEditorEPlayAvvia() {
        continueAfterFailure = false
        let app = avvia()
        XCTAssertTrue(app.staticTexts["Prossima scheda"].waitForExistence(timeout: 8))
        let nome = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Pull'")).firstMatch
        for _ in 0..<4 where !nome.isHittable { app.swipeUp() }
        nome.tap()
        XCTAssertTrue(app.textFields["Nome della scheda"].waitForExistence(timeout: 5), "Toccando il nome deve aprirsi l'editor")
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        let play = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Inizia ' AND label CONTAINS 'Pull'")).firstMatch
        for _ in 0..<4 where !play.isHittable { app.swipeUp() }
        play.tap()
        XCTAssertTrue(app.buttons["Fine"].waitForExistence(timeout: 5), "Il ▶ deve avviare la scheda")
    }
}
