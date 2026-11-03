import XCTest

// Il selettore dei file deve aprirsi da ogni pulsante di caricamento
final class CaricamentoPDFTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "dieta"]
        app.launch()
    }

    // Il selettore di iOS ha la barra di ricerca e le schede Recenti/Sfoglia
    private var selettoreAperto: Bool {
        let barra = app.searchFields.firstMatch
        return barra.waitForExistence(timeout: 6)
    }

    private func apriPianiEReferti() {
        let link = app.buttons["Piani e referti (PDF)"]
        for _ in 0..<6 where !link.isHittable { app.swipeUp() }
        link.tap()
    }

    func testCaricaBiaApreIlSelettore() {
        apriPianiEReferti()
        app.buttons["Carica referto BIA (PDF)"].tap()
        XCTAssertTrue(selettoreAperto, "Il selettore dei file non si è aperto:\n\(app.debugDescription)")
    }

    func testCaricaSchemaDaPianiApreIlSelettore() {
        apriPianiEReferti()
        app.buttons["Carica schema dietetico (PDF)"].tap()
        XCTAssertTrue(selettoreAperto, "Il selettore dei file non si è aperto")
    }
}
