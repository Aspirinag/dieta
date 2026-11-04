import XCTest

// L'app segue il telefono solo in inglese; con le altre lingue resta in italiano
final class LinguaTests: XCTestCase {
    private func schede(lingua: String, area: String, attese: [String]) {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "oggi", "-AppleLanguages", lingua, "-AppleLocale", area]
        app.launch()
        let barra = app.tabBars.firstMatch
        XCTAssertTrue(barra.waitForExistence(timeout: 8), "Manca la tab bar")
        for nome in attese {
            XCTAssertTrue(barra.buttons[nome].exists, "Manca la scheda \(nome) con \(lingua)")
        }
    }

    func testInglesAmericano() {
        schede(lingua: "(en)", area: "en_US", attese: ["Today", "Diet", "Gym", "Progress"])
    }

    func testInglesBritannico() {
        schede(lingua: "(en-GB)", area: "en_GB", attese: ["Today", "Diet", "Gym", "Progress"])
    }

    func testAltraLinguaRestaInItaliano() {
        schede(lingua: "(fr)", area: "fr_FR", attese: ["Oggi", "Dieta", "Palestra", "Progressi"])
    }
}
