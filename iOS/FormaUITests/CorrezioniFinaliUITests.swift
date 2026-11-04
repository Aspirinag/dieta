import XCTest

// Correzioni dopo la revisione finale
final class CorrezioniFinaliUITests: XCTestCase {
    private func avvia(_ argomenti: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-demo"] + argomenti
        app.launch()
        return app
    }

    // Le note del profilo stanno in fondo a Oggi
    func testNoteInFondoAOggi() {
        continueAfterFailure = false
        let app = avvia(["-tab", "oggi"])
        let note = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Pane e olio puoi distribuirli'")).firstMatch
        for _ in 0..<6 where !note.exists || !note.isHittable { app.swipeUp() }
        XCTAssertTrue(note.exists && note.isHittable, "Le note non si vedono in fondo a Oggi")
    }

    // La pagina dei piani si chiama come la voce di Impostazioni
    func testPaginaPianiSiChiamaPianiAlimentari() {
        continueAfterFailure = false
        let app = avvia(["-tab", "impostazioni"])
        let voce = app.buttons["Piani alimentari"].firstMatch
        XCTAssertTrue(voce.waitForExistence(timeout: 8), "Manca la voce Piani alimentari in Impostazioni")
        voce.tap()
        XCTAssertTrue(app.navigationBars["Piani alimentari"].waitForExistence(timeout: 5), "Il titolo della pagina non è «Piani alimentari»")
    }

    // In inglese i nomi di sistema degli allenamenti sono tradotti anche in Oggi
    func testNomiAllenamentoInInglese() {
        continueAfterFailure = false
        let app = avvia(["-tab", "oggi", "-allenato-oggi", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"])
        XCTAssertTrue(app.staticTexts["Free workout"].waitForExistence(timeout: 8), "Manca «Free workout» in Oggi")
        XCTAssertTrue(app.staticTexts["Gym · from Watch"].exists, "Manca «Gym · from Watch» in Oggi")
        XCTAssertFalse(app.staticTexts["Allenamento libero"].exists, "«Allenamento libero» resta in italiano")
    }

    // Un giorno con il piano ma senza pasti lo dice, in Oggi e in Dieta
    func testGiornoSenzaPastiInOggi() {
        continueAfterFailure = false
        let app = avvia(["-tab", "oggi", "-senza-pasti"])
        XCTAssertTrue(app.staticTexts["Nessun pasto per questo giorno"].waitForExistence(timeout: 8), "Oggi non dice che mancano i pasti")
        XCTAssertFalse(app.staticTexts["0 di 0"].exists, "Resta «0 di 0»")
    }

    func testGiornoSenzaPastiInDieta() {
        continueAfterFailure = false
        let app = avvia(["-tab", "dieta", "-senza-pasti"])
        XCTAssertTrue(app.staticTexts["Nessun pasto per questo giorno"].waitForExistence(timeout: 8), "Dieta non dice che mancano i pasti")
    }
}
