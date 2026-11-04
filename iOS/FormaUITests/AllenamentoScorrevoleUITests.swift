import XCTest

// Allenamento in corso: esercizio finito chiuso in una riga, «ultima volta» che si tocca
final class AllenamentoScorrevoleUITests: XCTestCase {
    private func avvia() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "inCorso"]
        app.launch()
        return app
    }

    func testEsercizioFinitoSiChiudeESiRiapre() {
        continueAfterFailure = false
        let app = avvia()
        let riga = app.buttons.matching(NSPredicate(format: "label CONTAINS 'serie ✓'")).firstMatch
        XCTAssertTrue(riga.waitForExistence(timeout: 8), "Il primo esercizio, tutto spuntato, non è chiuso in una riga")
        let prima = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Serie 1'")).count
        riga.tap()
        let dopo = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Serie 1'")).count
        XCTAssertGreaterThan(dopo, prima, "Toccando la riga l'esercizio non si riapre")
    }

    func testUltimaVoltaCopiaNeiCampi() {
        continueAfterFailure = false
        let app = avvia()
        let usa = app.buttons["Usa i valori dell'ultima volta"].firstMatch
        XCTAssertTrue(usa.waitForExistence(timeout: 8), "Manca il pulsante «Usa i valori dell'ultima volta»")
        // «62,5 kg × 8»: i kg della serie precedente
        let precedente = (usa.value as? String ?? "").components(separatedBy: " kg").first ?? ""
        XCTAssertFalse(precedente.isEmpty, "Il pulsante non dice i kg dell'ultima volta: \(String(describing: usa.value))")
        // Il campo kg della stessa riga (il più a sinistra tra i campi alla stessa altezza)
        let riga = app.textFields.allElementsBoundByIndex
            .filter { abs($0.frame.midY - usa.frame.midY) < 20 }
            .sorted { $0.frame.minX < $1.frame.minX }
        guard let kg = riga.first else { return XCTFail("Non trovo il campo kg della riga") }
        // Un valore diverso scritto a mano: se il tocco non copia, resta quello (il segnaposto non basta a farlo passare)
        kg.tap()
        kg.typeText("1")
        XCTAssertEqual(kg.value as? String, "1", "Il valore scritto non compare nel campo")
        usa.tap()
        XCTAssertEqual(kg.value as? String, precedente, "Il tocco su «ultima volta» non copia i kg nel campo")
    }
}
