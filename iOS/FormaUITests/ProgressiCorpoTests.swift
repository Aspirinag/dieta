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

        let tutte = app.buttons["Tutte"]
        for _ in 0..<6 where !tutte.isHittable { app.swipeUp() }
        XCTAssertTrue(tutte.waitForExistence(timeout: 5), "Manca «Tutte» sotto le misurazioni")
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

    func testCorpoMostraPesoGraficoAderenzaEMisurazioni() {
        continueAfterFailure = false
        let app = avvia()
        XCTAssertTrue(app.navigationBars["Progressi"].waitForExistence(timeout: 8))

        XCTAssertTrue(app.staticTexts["valore-grande"].waitForExistence(timeout: 5), "Manca il peso grande")
        XCTAssertTrue(app.buttons["Tutto"].exists && app.buttons["3 mesi"].exists && app.buttons["1 mese"].exists, "Mancano i periodi")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Pasti segnati negli ultimi 7 giorni: '")).firstMatch.exists,
                      "Manca la riga dell'aderenza")

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
        XCTAssertTrue(app.buttons["Carica referto BIA (PDF)"].waitForExistence(timeout: 3), "Manca il caricamento del referto")
        app.buttons["Aggiungi misurazione"].tap()
        XCTAssertTrue(app.navigationBars["Nuova misurazione"].waitForExistence(timeout: 5), "Si apre l'editor")
    }

    func testPalestraRestaRaggiungibile() {
        continueAfterFailure = false
        let app = avvia()
        XCTAssertTrue(app.navigationBars["Progressi"].waitForExistence(timeout: 8))
        app.segmentedControls.buttons["Palestra"].tap()
        XCTAssertTrue(app.staticTexts["Kg sollevati per settimana"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Calendario"].exists)
        XCTAssertFalse(app.navigationBars["Progressi"].buttons["Aggiungi"].exists, "Il + è solo di Corpo")
    }
}
