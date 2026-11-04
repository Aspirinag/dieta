import XCTest

// Progressi → Storico (provvisorio fino al Task 9): toccando un allenamento si apre il dettaglio, e tornando indietro si torna allo Storico
final class StoricoTests: XCTestCase {
    func testAllenamentoApreDettaglioETornaAlloStorico() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "progressi"]
        app.launch()

        app.segmentedControls.buttons["Palestra"].tap()   // la scelta in alto di Progressi: Corpo / Palestra
        let storico = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Storico e record'")).firstMatch
        for _ in 0..<6 where !storico.isHittable { app.swipeUp() }
        XCTAssertTrue(storico.waitForExistence(timeout: 8), "Manca il collegamento allo Storico")
        storico.tap()
        let barraStorico = app.navigationBars["Storico"]
        XCTAssertTrue(barraStorico.waitForExistence(timeout: 5), "Non si apre lo Storico")

        // Prima riga di allenamento: l'elenco dei mesi parte dopo le sezioni dei record
        let allenamento = app.cells.buttons.element(boundBy: app.cells.buttons.count - 1)
        for _ in 0..<6 where !allenamento.isHittable { app.swipeUp() }
        let nome = allenamento.label
        allenamento.tap()
        XCTAssertTrue(barraStorico.waitForNonExistence(timeout: 5), "Toccando «\(nome)» deve aprirsi il dettaglio")

        app.navigationBars.firstMatch.buttons.firstMatch.tap()
        XCTAssertTrue(barraStorico.waitForExistence(timeout: 5), "Tornando indietro si deve rivedere lo Storico")
    }
}
