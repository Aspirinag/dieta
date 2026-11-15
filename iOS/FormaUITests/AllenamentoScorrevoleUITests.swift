import XCTest

// Allenamento in corso: esercizio finito chiuso in una riga, «ultima volta» che si tocca, ± e rotella senza tastiera,
// prossima serie visibile a testo grande, conferma di «Fine» con il numero di serie che si perdono
final class AllenamentoScorrevoleUITests: XCTestCase {
    private func avvia(_ altri: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "inCorso"] + altri
        app.launch()
        return app
    }

    // La casella dei kg della riga che sta sopra un elemento (i ± stanno sotto la serie attiva): un pulsante «Kg, serie N»
    private func campoKgSopra(_ elemento: XCUIElement, in app: XCUIApplication) -> XCUIElement? {
        let sopra = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Kg, serie'")).allElementsBoundByIndex
            .filter { $0.frame.maxY <= elemento.frame.minY + 1 }
        return sopra.max { $0.frame.midY < $1.frame.midY }
    }

    private func numero(_ elemento: XCUIElement) -> Double? {
        Double((elemento.value as? String ?? "").replacingOccurrences(of: ",", with: "."))
    }

    func testEsercizioFinitoSiChiudeESiRiapre() {
        continueAfterFailure = false
        let app = avvia()
        let riga = app.buttons.matching(NSPredicate(format: "label CONTAINS 'serie fatte'")).firstMatch
        XCTAssertTrue(riga.waitForExistence(timeout: 8), "Il primo esercizio, tutto spuntato, non è chiuso in una riga")
        let prima = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Segna la serie 1 di'")).count
        riga.tap()
        let dopo = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Segna la serie 1 di'")).count
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
        // La casella kg della stessa riga
        let riga = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Kg, serie'")).allElementsBoundByIndex
            .filter { abs($0.frame.midY - usa.frame.midY) < 20 }
        guard let kg = riga.first else { return XCTFail("Non trovo la casella kg della riga") }
        // Un valore diverso scelto con i ±: se il tocco non copia, resta quello
        let piu = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Aggiungi 2'")).firstMatch
        XCTAssertTrue(piu.waitForExistence(timeout: 3))
        piu.tap()
        XCTAssertNotEqual(numero(kg), Double(precedente.replacingOccurrences(of: ",", with: ".")), "Il + non cambia il valore")
        usa.tap()
        XCTAssertEqual(numero(kg), Double(precedente.replacingOccurrences(of: ",", with: ".")), "Il tocco su «ultima volta» non copia i kg nella casella")
    }

    // +2,5 kg in un tocco, senza aprire la tastiera; poi la spunta segna la serie con quel peso (2 tocchi in tutto)
    func testPiuDueEMezzoSenzaTastiera() {
        continueAfterFailure = false
        let app = avvia()
        let piu = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Aggiungi 2'")).firstMatch
        XCTAssertTrue(piu.waitForExistence(timeout: 8), "Manca «+2,5 kg» sotto la prossima serie")
        guard let kg = campoKgSopra(piu, in: app) else { return XCTFail("Non trovo il campo kg della serie attiva") }
        guard let valore = numero(kg) else { return XCTFail("La casella kg non ha un valore di partenza: «\(String(describing: kg.value))»") }
        XCTAssertGreaterThanOrEqual(piu.frame.height, 44, "Il pulsante + è più basso di 44 punti")
        piu.tap()
        XCTAssertFalse(app.keyboards.firstMatch.exists, "«+2,5 kg» non deve aprire la tastiera")
        XCTAssertEqual(numero(kg), valore + 2.5, "«+2,5 kg» non aggiunge 2,5 kg alla casella")
        // La spunta della stessa riga: è la prima serie «da fare»
        let daFare = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Segna la serie ' AND value == 'da fare'"))
        let spunta = daFare.firstMatch
        let quante = daFare.count
        XCTAssertLessThan(abs(spunta.frame.midY - kg.frame.midY), 30, "La prima serie da fare non è quella con i ±")
        spunta.tap()
        XCTAssertEqual(daFare.count, quante - 1, "La spunta non segna la serie")
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Recupero'")).firstMatch.waitForExistence(timeout: 3), "La spunta non fa partire il recupero")
    }

    // Toccando la casella dei kg si apre la rotella, non la tastiera: girandola il valore cambia, «Fine» la chiude
    func testRotellaDeiKgSenzaTastiera() {
        continueAfterFailure = false
        let app = avvia()
        let piu = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Aggiungi 2'")).firstMatch
        XCTAssertTrue(piu.waitForExistence(timeout: 8))
        guard let kg = campoKgSopra(piu, in: app) else { return XCTFail("Non trovo la casella kg") }
        guard let prima = numero(kg) else { return XCTFail("La casella kg non ha un valore") }
        kg.tap()
        let rotella = app.pickerWheels.firstMatch
        XCTAssertTrue(rotella.waitForExistence(timeout: 3), "Toccando i kg non si apre la rotella")
        XCTAssertFalse(app.keyboards.firstMatch.exists, "I kg non devono aprire la tastiera")
        rotella.adjust(toPickerWheelValue: String(format: "%g", prima + 10).replacingOccurrences(of: ".", with: ","))
        let fine = app.buttons["Fine"].firstMatch
        XCTAssertTrue(app.buttons["Svuota"].exists, "Manca «Svuota» nel foglio")
        fine.tap()
        XCTAssertFalse(rotella.waitForExistence(timeout: 1), "«Fine» non chiude la rotella")
        XCTAssertEqual(numero(kg), prima + 10, "La rotella non cambia i kg")
    }

    // «Svuota» toglie il valore scelto: la casella torna a quello proposto (l'ultima volta)
    func testSvuotaTogliIlValore() {
        continueAfterFailure = false
        let app = avvia()
        let piu = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Aggiungi 2'")).firstMatch
        XCTAssertTrue(piu.waitForExistence(timeout: 8))
        guard let kg = campoKgSopra(piu, in: app), let proposto = numero(kg) else { return XCTFail("Non trovo la casella kg") }
        piu.tap()
        XCTAssertEqual(numero(kg), proposto + 2.5)
        kg.tap()
        let svuota = app.buttons["Svuota"]
        XCTAssertTrue(svuota.waitForExistence(timeout: 3))
        svuota.tap()
        XCTAssertEqual(numero(kg), proposto, "«Svuota» non toglie il valore scelto")
    }

    // Testo di accessibilità più grande: la prossima serie da fare e i suoi ± si vedono senza scorrere a mano
    func testProssimaSerieVisibileATestoGrande() {
        continueAfterFailure = false
        let app = avvia(["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let serie = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Segna la serie ' AND value == 'da fare'")).firstMatch
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
        XCTAssertTrue(app.buttons["Finisci e salva"].exists, "Nella conferma manca «Finisci e salva»")
        XCTAssertTrue(app.buttons["Annulla"].exists, "Nella conferma manca «Annulla»")
    }
}
