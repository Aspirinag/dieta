import XCTest

// Palestra serve a iniziare: prossima scheda, settimana, schede con ▶, sezione «Altro»
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
        XCTAssertTrue(app.staticTexts["settimana"].exists, "Manca il riepilogo della settimana")

        // Le funzioni stanno in una sezione «Altro» con il loro nome, non dietro un «+» senza testo
        XCTAssertTrue(app.buttons["Nuova scheda"].exists, "Manca «Nuova scheda» in barra")
        XCTAssertTrue(app.buttons["Impostazioni"].exists, "Manca l'ingranaggio delle Impostazioni")
        for voce in ["Registra cardio", "Programma della settimana", "Libreria esercizi", "Schede pronte", "Allenamento libero"] {
            for _ in 0..<5 where !app.buttons[voce].exists { app.swipeUp() }
            XCTAssertTrue(app.buttons[voce].exists, "Manca «\(voce)» in «Altro»")
        }
        for _ in 0..<5 where !app.buttons["Libreria esercizi"].isHittable { app.swipeDown() }
        app.buttons["Libreria esercizi"].tap()
        XCTAssertTrue(app.navigationBars["Libreria esercizi"].waitForExistence(timeout: 5), "Non si apre la Libreria")
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        for _ in 0..<4 where !app.buttons["Inizia"].firstMatch.isHittable { app.swipeDown() }

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
            for _ in 0..<4 where !app.buttons[voce].isHittable { app.swipeUp() }
            app.buttons[voce].tap()
            XCTAssertTrue(app.navigationBars[barra].waitForExistence(timeout: 5), "Non si apre \(voce)")
            app.navigationBars.firstMatch.buttons.firstMatch.tap()
        }
    }

    // La prossima scheda compare una volta sola
    func testProssimaSchedaNonRipetuta() {
        continueAfterFailure = false
        let app = avvia()
        XCTAssertTrue(app.staticTexts["Prossima scheda"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Spinta"].exists, "Manca il nome della prossima scheda")
        XCTAssertEqual(app.staticTexts.matching(identifier: "Spinta").count, 1, "«Spinta» compare più di una volta")
        XCTAssertFalse(app.buttons["Inizia Spinta"].exists, "La prossima scheda è anche nella lista")
    }

    // Cardio: i minuti sono un valore vero e il ✓ è acceso
    func testCardioMinutiPrecompilati() {
        continueAfterFailure = false
        let app = avvia()
        XCTAssertTrue(app.staticTexts["Prossima scheda"].waitForExistence(timeout: 8))
        for _ in 0..<4 where !app.buttons["Registra cardio"].isHittable { app.swipeUp() }
        app.buttons["Registra cardio"].tap()
        XCTAssertTrue(app.navigationBars["Cardio"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Salva"].isEnabled, "Il ✓ deve essere acceso: i minuti sono già un valore")
        XCTAssertTrue(app.steppers.firstMatch.exists, "Mancano i ± dei minuti")
    }

    func testNomeApreEditorEPlayAvvia() {
        continueAfterFailure = false
        let app = avvia()
        XCTAssertTrue(app.staticTexts["Prossima scheda"].waitForExistence(timeout: 8))
        let nome = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Tirata' AND NOT label BEGINSWITH 'Inizia'")).firstMatch
        for _ in 0..<4 where !nome.isHittable { app.swipeUp() }
        nome.tap()
        XCTAssertTrue(app.buttons["Inizia"].waitForExistence(timeout: 5), "Toccando il nome deve aprirsi l'editor")
        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        let play = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Inizia ' AND label CONTAINS 'Tirata'")).firstMatch
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

// La settimana è una riga di testo sotto la prossima scheda e le altre schede si vedono subito
final class PalestraCompattaUITests: XCTestCase {
    func testSettimanaCompattaESchedeInPrimaSchermata() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "allenamento"]
        app.launch()
        let riga = app.staticTexts["settimana"]
        XCTAssertTrue(riga.waitForExistence(timeout: 8), "Manca il riepilogo della settimana")
        XCTAssertTrue(riga.label.hasPrefix("Questa settimana"), "Il riepilogo deve dire «Questa settimana»")
        let schede = app.staticTexts["intestazioneSchede"]
        XCTAssertTrue(schede.exists)
        XCTAssertLessThan(schede.frame.maxY, app.frame.height * 0.75, "Le altre schede devono vedersi nella prima schermata")
    }
}

// Eliminare una scheda non deve far chiudere l'app
final class EliminaSchedaUITests: XCTestCase {
    private func avvia() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "allenamento"]
        app.launch()
        return app
    }

    private func apriEditorTirata(_ app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts["Prossima scheda"].waitForExistence(timeout: 8))
        let nome = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Tirata' AND NOT label BEGINSWITH 'Inizia'")).firstMatch
        for _ in 0..<4 where !nome.isHittable { app.swipeUp() }
        nome.tap()
        XCTAssertTrue(app.buttons["Elimina scheda"].waitForExistence(timeout: 5), "Non si apre l'editor")
    }

    // Dall'editor: «Elimina scheda» → conferma → si torna alla lista senza crash
    func testEliminaDallEditor() {
        continueAfterFailure = false
        let app = avvia()
        apriEditorTirata(app)
        app.buttons["Elimina scheda"].tap()
        app.buttons["Elimina Tirata"].tap()
        XCTAssertTrue(app.staticTexts["Prossima scheda"].waitForExistence(timeout: 5), "Dopo l'eliminazione l'app non è tornata alla lista")
        XCTAssertEqual(app.state, .runningForeground, "L'app si è chiusa")
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Tirata'")).firstMatch.exists, "La scheda è ancora in lista")
    }

    // Con un esercizio aperto e la modifica attiva (i campi leggono la scheda mentre sparisce)
    func testEliminaConEsercizioAperto() {
        continueAfterFailure = false
        let app = avvia()
        apriEditorTirata(app)
        app.buttons["Modifica"].tap()
        app.buttons["Fine"].tap()
        let riga = app.buttons.matching(NSPredicate(format: "label CONTAINS 'recupero'")).firstMatch
        if riga.waitForExistence(timeout: 3) { riga.tap() }
        XCTAssertTrue(app.steppers.firstMatch.waitForExistence(timeout: 3), "L'esercizio non si apre")
        for _ in 0..<5 where !app.buttons["Elimina scheda"].isHittable { app.swipeUp() }
        app.buttons["Elimina scheda"].tap()
        app.buttons["Elimina Tirata"].tap()
        XCTAssertTrue(app.staticTexts["Prossima scheda"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.state, .runningForeground, "L'app si è chiusa")
    }

    // Si elimina la scheda dell'allenamento in corso: l'allenamento resta e l'app non si chiude
    func testEliminaLaSchedaDellAllenamentoInCorso() {
        continueAfterFailure = false
        let app = avvia()
        XCTAssertTrue(app.staticTexts["Prossima scheda"].waitForExistence(timeout: 8))
        app.buttons["Inizia"].firstMatch.tap()   // avvia «Spinta»
        XCTAssertTrue(app.buttons["Fine"].waitForExistence(timeout: 5))
        app.buttons["Nascondi"].tap()
        XCTAssertTrue(app.buttons["Riprendi"].waitForExistence(timeout: 5))
        let nome = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Spinta' AND NOT label BEGINSWITH 'Inizia'")).firstMatch
        for _ in 0..<4 where !nome.isHittable { app.swipeUp() }
        nome.tap()
        XCTAssertTrue(app.buttons["Elimina scheda"].waitForExistence(timeout: 5))
        app.buttons["Elimina scheda"].tap()
        app.buttons["Elimina Spinta"].tap()
        XCTAssertTrue(app.buttons["Riprendi"].firstMatch.waitForExistence(timeout: 5), "Dopo l'eliminazione l'app non è tornata alla lista")
        XCTAssertEqual(app.state, .runningForeground, "L'app si è chiusa")
        app.buttons["Riprendi"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Fine"].waitForExistence(timeout: 5), "L'allenamento in corso non si riapre")
    }

    // Scheda appena creata (vuota): «Nuova scheda» → Elimina scheda → conferma
    func testEliminaSchedaAppenaCreata() {
        continueAfterFailure = false
        let app = avvia()
        XCTAssertTrue(app.staticTexts["Prossima scheda"].waitForExistence(timeout: 8))
        app.buttons["Nuova scheda"].tap()
        XCTAssertTrue(app.buttons["Elimina scheda"].waitForExistence(timeout: 5), "Non si apre l'editor")
        app.buttons["Elimina scheda"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Elimina Nuova scheda'")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Prossima scheda"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.state, .runningForeground, "L'app si è chiusa")
    }

    // Dalla lista: tenere premuto → Elimina → conferma
    func testEliminaDallaLista() {
        continueAfterFailure = false
        let app = avvia()
        XCTAssertTrue(app.staticTexts["Prossima scheda"].waitForExistence(timeout: 8))
        let nome = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Tirata' AND NOT label BEGINSWITH 'Inizia'")).firstMatch
        for _ in 0..<4 where !nome.isHittable { app.swipeUp() }
        nome.press(forDuration: 1.2)
        app.buttons["Elimina"].tap()
        app.buttons["Elimina Tirata"].tap()
        XCTAssertTrue(app.staticTexts["Prossima scheda"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.state, .runningForeground, "L'app si è chiusa")
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Tirata'")).firstMatch.exists, "La scheda è ancora in lista")
    }
}
