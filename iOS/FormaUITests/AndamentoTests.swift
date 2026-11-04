import XCTest

// Progressi → Andamento: toccando una misurazione si apre l'editor, e tornando indietro si torna all'Andamento
final class AndamentoTests: XCTestCase {
    func testMisurazioneApreEditorETornaIndietro() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "progressi"]
        app.launch()

        XCTAssertTrue(app.navigationBars["Andamento"].waitForExistence(timeout: 8), "Progressi apre l'Andamento")

        let misura = app.buttons.matching(NSPredicate(format: "label CONTAINS ' · grasso '")).firstMatch
        for _ in 0..<6 where !misura.isHittable { app.swipeUp() }
        XCTAssertTrue(misura.waitForExistence(timeout: 5), "Manca una misurazione nello storico")
        misura.tap()
        XCTAssertTrue(app.navigationBars["Modifica misurazione"].waitForExistence(timeout: 5),
                      "Toccando una misurazione deve aprirsi l'editor")

        app.navigationBars["Modifica misurazione"].buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Andamento"].waitForExistence(timeout: 5), "Tornando indietro si deve rivedere l'Andamento")
        XCTAssertFalse(app.alerts.firstMatch.waitForExistence(timeout: 2), "Tornando indietro non deve comparire un errore")
    }
}
