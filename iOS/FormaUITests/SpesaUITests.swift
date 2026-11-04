import XCTest

// Spesa: prodotti per reparto, cerchio che li segna come presi, voci aggiunte a mano
final class SpesaUITests: XCTestCase {
    private func avvia() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "dieta", "-vista", "spesa"]
        app.launch()
        return app
    }

    private func conteggio(_ app: XCUIApplication) -> Int? {
        let testo = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label MATCHES %@", ".*[0-9]+ di [0-9]+ presi")).firstMatch
        guard testo.waitForExistence(timeout: 8) else { return nil }
        let parti = testo.label.components(separatedBy: " di ")
        return parti.first.flatMap { Int($0.split(separator: " ").last ?? "") }
    }

    func testSpesaPerRepartoEAggiunta() {
        continueAfterFailure = false
        let app = avvia()

        XCTAssertTrue(app.staticTexts["Frutta e verdura"].waitForExistence(timeout: 8), "Manca il reparto Frutta e verdura")
        XCTAssertTrue(app.staticTexts["Carne, pesce, uova"].exists, "Manca il reparto Carne, pesce, uova")
        XCTAssertEqual(conteggio(app), 0, "All'inizio non c'è nulla di preso")

        let cerchio = app.buttons["spunta.petto di pollo"]
        XCTAssertTrue(cerchio.exists, "Manca il cerchio di Petto di pollo")
        XCTAssertGreaterThanOrEqual(cerchio.frame.height, 44, "Il cerchio è troppo piccolo")
        cerchio.tap()
        XCTAssertEqual(conteggio(app), 1, "Dopo il tocco «1 di N» aumenta")
        XCTAssertEqual(app.buttons["spunta.petto di pollo"].value as? String, "preso")

        let campo = app.textFields["Aggiungi qualcos'altro"]
        for _ in 0..<5 where !campo.isHittable { app.swipeUp() }
        campo.tap()
        campo.typeText("Caffè\n")

        let altro = app.staticTexts["reparto.altro"]
        let caffe = app.buttons["Caffè"]
        XCTAssertTrue(caffe.waitForExistence(timeout: 5), "«Caffè» non compare")
        XCTAssertTrue(altro.exists, "Manca il reparto Altro")
        // La riga nuova entra con un'animazione: si aspetta che sia al suo posto
        let sotto = NSPredicate { _, _ in altro.frame.minY < caffe.frame.minY }
        let attesa = XCTNSPredicateExpectation(predicate: sotto, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [attesa], timeout: 3), .completed,
                       "«Caffè» deve stare sotto «Altro» (Altro \(altro.frame.minY), Caffè \(caffe.frame.minY))")
    }

    func testExtraGiaNellaListaDaFeedback() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "dieta", "-vista", "spesa"]
        app.launch()
        XCTAssertTrue(app.buttons["spunta.petto di pollo"].waitForExistence(timeout: 8))
        let campo = app.textFields["Aggiungi qualcos'altro"]
        for _ in 0..<5 where !campo.isHittable { app.swipeUp() }
        campo.tap()
        campo.typeText("Petto di pollo\n")
        XCTAssertTrue(app.staticTexts["È già nella lista"].waitForExistence(timeout: 3), "Manca l'avviso «È già nella lista»")
    }
}
