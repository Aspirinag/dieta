import XCTest

// Allenamento in corso: esercizio finito chiuso in una riga, «ultima volta» che si tocca, ± senza tastiera,
// prossima serie visibile a testo grande, conferma di «Fine» con il numero di serie che si perdono
final class AllenamentoScorrevoleUITests: XCTestCase {
    private func avvia(_ altri: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "inCorso"] + altri
        app.launch()
        return app
    }

    // Il campo kg della riga che sta sopra un elemento (i ± stanno sotto la serie attiva)
    private func campoKgSopra(_ elemento: XCUIElement, in app: XCUIApplication) -> XCUIElement? {
        let sopra = app.textFields.allElementsBoundByIndex.filter { $0.frame.maxY <= elemento.frame.minY + 1 }
        guard let y = sopra.map(\.frame.midY).max() else { return nil }
        return sopra.filter { abs($0.frame.midY - y) < 4 }.min { $0.frame.minX < $1.frame.minX }
    }

    func testEsercizioFinitoSiChiudeESiRiapre() {
        continueAfterFailure = false
        let app = avvia()
        let riga = app.buttons.matching(NSPredicate(format: "label CONTAINS 'serie fatte'")).firstMatch
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

    // +2,5 kg in un tocco, senza aprire la tastiera; poi la spunta segna la serie con quel peso (2 tocchi in tutto)
    func testPiuDueEMezzoSenzaTastiera() {
        continueAfterFailure = false
        let app = avvia()
        let piu = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Aggiungi 2'")).firstMatch
        XCTAssertTrue(piu.waitForExistence(timeout: 8), "Manca «+2,5 kg» sotto la prossima serie")
        guard let kg = campoKgSopra(piu, in: app) else { return XCTFail("Non trovo il campo kg della serie attiva") }
        let prima = (kg.value as? String ?? "").replacingOccurrences(of: ",", with: ".")
        guard let valore = Double(prima) else { return XCTFail("Il campo kg non ha un valore di partenza: «\(prima)»") }
        piu.tap()
        XCTAssertFalse(app.keyboards.firstMatch.exists, "«+2,5 kg» non deve aprire la tastiera")
        let dopo = Double((kg.value as? String ?? "").replacingOccurrences(of: ",", with: "."))
        XCTAssertEqual(dopo, valore + 2.5, "«+2,5 kg» non aggiunge 2,5 kg al campo")
        // La spunta della stessa riga: è la prima serie «da fare»
        let daFare = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Serie ' AND value == 'da fare'"))
        let spunta = daFare.firstMatch
        let quante = daFare.count
        XCTAssertLessThan(abs(spunta.frame.midY - kg.frame.midY), 30, "La prima serie da fare non è quella con i ±")
        spunta.tap()
        XCTAssertEqual(daFare.count, quante - 1, "La spunta non segna la serie")
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Recupero'")).firstMatch.waitForExistence(timeout: 3), "La spunta non fa partire il recupero")
    }

    // Sopra la tastiera: i ± del campo e «Chiudi» (un solo «Fine» nella schermata, quello che chiude l'allenamento)
    func testBarraSopraLaTastiera() {
        continueAfterFailure = false
        let app = avvia()
        let piu = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Aggiungi 2'")).firstMatch
        XCTAssertTrue(piu.waitForExistence(timeout: 8))
        guard let kg = campoKgSopra(piu, in: app) else { return XCTFail("Non trovo il campo kg") }
        kg.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
        let chiudi = app.buttons["Chiudi"]
        XCTAssertTrue(chiudi.exists, "Sopra la tastiera manca «Chiudi»")
        XCTAssertEqual(app.buttons.matching(identifier: "Fine").count, 1, "«Fine» compare due volte")
        XCTAssertGreaterThanOrEqual(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Togli 2'")).count, 1)
        chiudi.tap()
        XCTAssertFalse(app.keyboards.firstMatch.waitForExistence(timeout: 1), "«Chiudi» non chiude la tastiera")
    }

    // Testo di accessibilità più grande: la prossima serie da fare e i suoi ± si vedono senza scorrere a mano
    func testProssimaSerieVisibileATestoGrande() {
        continueAfterFailure = false
        let app = avvia(["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let serie = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Serie ' AND value == 'da fare'")).firstMatch
        XCTAssertTrue(serie.waitForExistence(timeout: 8))
        let piu = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Aggiungi 2'")).firstMatch
        // Lo scorrimento automatico parte poco dopo l'apertura
        let visibile = NSPredicate(format: "isHittable == true")
        expectation(for: visibile, evaluatedWith: serie)
        expectation(for: visibile, evaluatedWith: piu)
        waitForExpectations(timeout: 5)
        XCTAssertLessThan(piu.frame.maxY, app.windows.firstMatch.frame.maxY, "I ± della prossima serie sono fuori schermo")
    }

    // «Fine» con serie non spuntate: la conferma dice quante se ne perdono
    func testFineDiceQuanteSerieSiPerdono() {
        continueAfterFailure = false
        let app = avvia()
        let fine = app.buttons["Fine"]
        XCTAssertTrue(fine.waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["Annulla allenamento"].exists, "«Annulla allenamento» sta solo nel menu «…», non in fondo alla lista")
        fine.tap()
        let testo = app.staticTexts.matching(NSPredicate(format: "label MATCHES '^[0-9]+ serie senza spunta non verr.*'")).firstMatch
        XCTAssertTrue(testo.waitForExistence(timeout: 3), "La conferma non dice quante serie senza spunta si perdono")
    }
}
