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
        XCTAssertTrue(app.otherElements["settimana"].exists, "Manca la riga della settimana")

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

    func testConAllenamentoInCorsoMostraRiprendi() {
        continueAfterFailure = false
        let app = avvia()
        XCTAssertTrue(app.staticTexts["Prossima scheda"].waitForExistence(timeout: 8))
        app.buttons["Inizia"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Fine"].waitForExistence(timeout: 5))
        app.buttons["Nascondi"].tap()
        XCTAssertTrue(app.buttons["Riprendi"].waitForExistence(timeout: 5), "Con un allenamento in corso manca «Riprendi»")
        XCTAssertFalse(app.staticTexts["Prossima scheda"].exists, "«Prossima scheda» non va mostrata con un allenamento in corso")
    }
}

// Il recupero resta visibile (e apre l'allenamento) anche con l'allenamento nascosto
final class RecuperoVisibileUITests: XCTestCase {
    func testRecuperoNellaBarraConAllenamentoNascosto() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "inCorso"]
        app.launch()
        let serie = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Serie ' AND value == 'da fare'")).firstMatch
        XCTAssertTrue(serie.waitForExistence(timeout: 8), "Manca una serie da segnare")
        app.swipeUp()   // la serie in fondo resta sotto il bordo dello schermo
        // Se mancano kg o ripetizioni il cursore va nel campo vuoto: si scrive un valore e si ritocca la spunta
        for _ in 0..<3 {
            serie.tap()
            if app.keyboards.firstMatch.waitForExistence(timeout: 1) { app.typeText("10") } else { break }
        }
        app.buttons["Nascondi"].tap()
        let barra = app.buttons["Riapri allenamento"]
        XCTAssertTrue(barra.waitForExistence(timeout: 5), "Con l'allenamento nascosto non si vede il recupero nella barra")
        XCTAssertNotNil((barra.value as? String)?.range(of: #"^\d+:\d\d$"#, options: .regularExpression), "Formato del recupero inatteso: «\(String(describing: barra.value))»")
        // Toccando la barra si torna all'allenamento
        barra.tap()
        XCTAssertTrue(app.buttons["Fine"].waitForExistence(timeout: 5), "Toccando la barra non si riapre l'allenamento")
    }
}

// Palestra compatta: la settimana è una riga sola e le schede si vedono subito
final class PalestraCompattaUITests: XCTestCase {
    func testSettimanaCompattaESchedeInPrimaSchermata() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "allenamento"]
        app.launch()
        let riga = app.otherElements["settimana"]
        XCTAssertTrue(riga.waitForExistence(timeout: 8), "Manca la riga della settimana")
        XCTAssertLessThan(riga.frame.height, 70, "La settimana deve essere una riga compatta")
        XCTAssertNotEqual(riga.label, "", "La riga della settimana deve avere un testo per VoiceOver")
        let schede = app.staticTexts["Schede"]
        XCTAssertTrue(schede.exists)
        XCTAssertLessThan(schede.frame.maxY, app.frame.height * 0.62, "Le schede devono vedersi nella prima schermata")
    }
}
