import XCTest

// Importa una scheda da PDF: menu «+», anteprima, «Importa». Il file arriva con l'argomento di prova,
// perché il selettore dei file di iOS non si può guidare da qui
final class ImportaSchedaUITests: XCTestCase {
    private var pdf: String {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("FormaTests/SchedaAllenamentoForma.pdf").path
    }

    func testImportaDaPDF() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "allenamento", "-importaPDFProva", pdf]
        app.launch()

        let piu = app.buttons["Nuova scheda"]
        XCTAssertTrue(piu.waitForExistence(timeout: 8), "Manca il «+» in barra")
        piu.tap()
        app.buttons["Importa da PDF"].firstMatch.tap()

        XCTAssertTrue(app.navigationBars["Importa da PDF"].waitForExistence(timeout: 8), "Non si apre l'anteprima:\n\(app.debugDescription)")
        XCTAssertTrue(app.staticTexts["Scheda A"].exists, "Manca la Scheda A nell'anteprima")
        XCTAssertTrue(app.staticTexts["Leg press"].exists, "Manca Leg press nell'anteprima")
        XCTAssertFalse(app.staticTexts["nuovo"].exists, "Nessun esercizio del PDF di esempio è nuovo")

        app.buttons["Importa"].tap()
        XCTAssertTrue(app.navigationBars["Palestra"].waitForExistence(timeout: 5))
        for _ in 0..<6 where !app.buttons["Scheda B"].exists { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["Scheda B"].exists || app.buttons["Scheda B"].exists, "La scheda importata non compare in Palestra")
    }
}
