import XCTest

// VoiceOver: una voce spuntata si legge una volta sola (nome del pasto + stato), senza il nome dell'icona
final class SpuntaVoceTests: XCTestCase {
    func testSpuntaNonRipeteFatto() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "oggi"]
        app.launch()

        let voci = app.buttons.matching(NSPredicate(format: "value == 'fatto' OR value == 'da fare'"))
        XCTAssertTrue(voci.firstMatch.waitForExistence(timeout: 8), "Mancano voci da spuntare")
        for i in 0..<min(voci.count, 6) {
            let v = voci.element(boundBy: i)
            XCTAssertFalse(v.label.localizedCaseInsensitiveContains("fatto") || v.label.localizedCaseInsensitiveContains("cerchio")
                           || v.label.localizedCaseInsensitiveContains("circle"),
                           "L'etichetta «\(v.label)» ripete l'icona della spunta")
        }
    }
}
