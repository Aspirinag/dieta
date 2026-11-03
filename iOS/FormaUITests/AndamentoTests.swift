import XCTest

// Dieta → Andamento: toccando una misurazione si apre l'editor, e tornando indietro si torna all'Andamento
final class AndamentoTests: XCTestCase {
    func testMisurazioneApreEditorETornaIndietro() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "dieta"]
        app.launch()

        let andamento = app.buttons["Andamento e misure BIA"]
        for _ in 0..<5 where !andamento.isHittable { app.swipeUp() }
        XCTAssertTrue(andamento.waitForExistence(timeout: 8), "Manca il collegamento all'Andamento")
        andamento.tap()
        XCTAssertTrue(app.navigationBars["Andamento"].waitForExistence(timeout: 5), "Non si apre l'Andamento")

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
