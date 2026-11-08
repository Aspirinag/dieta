import XCTest

// Il selettore dei file deve aprirsi da ogni pulsante di caricamento
final class CaricamentoPDFTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "oggi"]
        app.launch()
    }

    // Il selettore di iOS ha la barra di ricerca e le schede Recenti/Sfoglia
    private var selettoreAperto: Bool {
        let barra = app.searchFields.firstMatch
        return barra.waitForExistence(timeout: 15)
    }

    private func apriPianiEReferti() {
        app.buttons["Impostazioni"].tap()
        let link = app.buttons["Piani alimentari"]
        XCTAssertTrue(link.waitForExistence(timeout: 8))
        link.tap()
    }

    func testCaricaBiaApreIlSelettore() {
        apriPianiEReferti()
        app.buttons["Carica la BIA (PDF)"].tap()
        XCTAssertTrue(selettoreAperto, "Il selettore dei file non si è aperto:\n\(app.debugDescription)")
    }

    func testCaricaSchemaDaPianiApreIlSelettore() {
        apriPianiEReferti()
        app.buttons["Carica il piano alimentare (PDF)"].tap()
        XCTAssertTrue(selettoreAperto, "Il selettore dei file non si è aperto")
    }
}
