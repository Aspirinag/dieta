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
        let testo = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'per la settimana'")).firstMatch
        guard testo.waitForExistence(timeout: 8) else { return nil }
        let parti = testo.label.components(separatedBy: " · ")
        guard let ultima = parti.last, let primo = ultima.split(separator: " ").first else { return nil }
        return Int(primo)
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

        let altro = app.staticTexts["Altro"]
        let caffe = app.buttons["Caffè"].firstMatch
        XCTAssertTrue(caffe.waitForExistence(timeout: 5), "«Caffè» non compare")
        XCTAssertTrue(altro.exists, "Manca il reparto Altro")
        XCTAssertLessThan(altro.frame.minY, caffe.frame.minY, "«Caffè» sta sotto «Altro»")
    }
}
