import XCTest

// Progressi → Corpo: peso e grafico, misurazioni, menu +, e il giro misurazione → editor → indietro
final class ProgressiCorpoTests: XCTestCase {
    private func avvia() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "progressi"]
        app.launch()
        return app
    }

    func testMisurazioneApreEditorETornaIndietro() {
        continueAfterFailure = false
        let app = avvia()

        XCTAssertTrue(app.navigationBars["Progressi"].waitForExistence(timeout: 8), "Progressi si apre su Corpo")

        let tutte = app.buttons["tutte-le-misurazioni"]
        for _ in 0..<6 where !tutte.isHittable { app.swipeUp() }
        XCTAssertTrue(tutte.waitForExistence(timeout: 5), "Manca «Tutte le misurazioni» sotto le misurazioni")
        tutte.tap()
        XCTAssertTrue(app.navigationBars["Misurazioni"].waitForExistence(timeout: 5), "«Tutte» apre l'elenco completo")

        let misura = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'misura-'")).firstMatch
        XCTAssertTrue(misura.waitForExistence(timeout: 5), "Manca una misurazione nell'elenco")
        misura.tap()
        XCTAssertTrue(app.navigationBars["Modifica misurazione"].waitForExistence(timeout: 5),
                      "Toccando una misurazione deve aprirsi l'editor")

        app.navigationBars["Modifica misurazione"].buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Misurazioni"].waitForExistence(timeout: 5), "Tornando indietro si deve rivedere l'elenco")
        XCTAssertFalse(app.alerts.firstMatch.waitForExistence(timeout: 2), "Tornando indietro non deve comparire un errore")
    }

    func testCorpoMostraPesoGraficoEMisurazioni() {
        continueAfterFailure = false
        let app = avvia()
        XCTAssertTrue(app.navigationBars["Progressi"].waitForExistence(timeout: 8))

        XCTAssertTrue(app.staticTexts["valore-grande"].waitForExistence(timeout: 5), "Manca il peso grande")
        XCTAssertTrue(app.buttons["Tutto"].exists && app.buttons["3 mesi"].exists && app.buttons["1 mese"].exists, "Mancano i periodi")
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Pasti segnati'")).firstMatch.exists,
                       "L'aderenza dei pasti non va nel peso")
        XCTAssertTrue(app.staticTexts["variazione"].exists, "Manca la variazione rispetto a 30 giorni fa")

        // Toccando un riquadro il grafico cambia misura; toccando ancora torna al peso
        let grasso = app.otherElements["metrica-grasso"]
        XCTAssertTrue(grasso.exists, "Manca il riquadro Grasso")
        grasso.tap()
        XCTAssertTrue(app.staticTexts["grafico-titolo"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["grafico-titolo"].label, "Massa grassa")
        app.otherElements["metrica-grasso"].tap()
        XCTAssertEqual(app.staticTexts["grafico-titolo"].label, "Peso")

        XCTAssertGreaterThanOrEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'misura-'")).count, 2,
                                    "Servono le ultime due misurazioni")
    }

    func testMenuPiuAggiungeMisurazione() {
        continueAfterFailure = false
        let app = avvia()
        XCTAssertTrue(app.navigationBars["Progressi"].waitForExistence(timeout: 8))
        app.navigationBars["Progressi"].buttons["Aggiungi"].tap()
        XCTAssertTrue(app.buttons["Carica la BIA (PDF)"].waitForExistence(timeout: 3), "Manca il caricamento della BIA")
        app.buttons["Nuova misura"].tap()
        XCTAssertTrue(app.navigationBars["Nuova misurazione"].waitForExistence(timeout: 5), "Si apre l'editor")
    }

    func testImpostazioniSiApronoDaProgressi() {
        continueAfterFailure = false
        let app = avvia()
        XCTAssertTrue(app.navigationBars["Progressi"].waitForExistence(timeout: 8))
        app.navigationBars["Progressi"].buttons["Impostazioni"].tap()
        XCTAssertTrue(app.navigationBars["Impostazioni"].waitForExistence(timeout: 5), "L'ingranaggio di Progressi apre le Impostazioni")
        XCTAssertTrue(app.buttons["Abbonamento palestra"].exists, "Manca «Abbonamento palestra»")
    }

    func testEditorNuovoSpiegaSalvaSpento() {
        continueAfterFailure = false
        let app = avvia()
        XCTAssertTrue(app.navigationBars["Progressi"].waitForExistence(timeout: 8))
        app.navigationBars["Progressi"].buttons["Aggiungi"].tap()
        app.buttons["Nuova misura"].tap()
        XCTAssertTrue(app.navigationBars["Nuova misurazione"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["Nuova misurazione"].buttons["Salva"].isEnabled, "Senza peso Salva è spento")
        XCTAssertTrue(app.staticTexts["Per salvare scrivi almeno il peso."].exists, "Manca la spiegazione vicino ai campi")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'ultima: '")).firstMatch.exists, "Manca il valore dell'ultima volta")
    }

    func testPalestraRestaRaggiungibile() {
        continueAfterFailure = false
        let app = avvia()
        XCTAssertTrue(app.navigationBars["Progressi"].waitForExistence(timeout: 8))
        app.segmentedControls.buttons["Palestra"].tap()
        XCTAssertTrue(app.staticTexts["Kg totali per settimana"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Calendario"].exists)
        XCTAssertFalse(app.navigationBars["Progressi"].buttons["Aggiungi"].exists, "Il + è solo di Corpo")
    }
}
