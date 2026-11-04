import XCTest

// Editor del piano: «Copia su tutti i giorni» sovrascrive gli altri giorni, quindi chiede conferma
final class EditorPianoTests: XCTestCase {
    func testCopiaSuTuttiIGiorniChiedeConferma() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-demo", "-tab", "dieta"]
        app.launch()

        let piani = app.buttons["Piani e misure"]
        for _ in 0..<5 where !piani.isHittable { app.swipeUp() }
        XCTAssertTrue(piani.waitForExistence(timeout: 8))
        piani.tap()

        let piano = app.buttons.matching(NSPredicate(format: "label CONTAINS '→'")).firstMatch
        XCTAssertTrue(piano.waitForExistence(timeout: 5), "Manca un piano da modificare")
        piano.tap()

        let copia = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Copia '")).firstMatch
        XCTAssertTrue(copia.waitForExistence(timeout: 5), "Manca «Copia su tutti i giorni»")
        copia.tap()
        let conferma = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Sostituisci'")).firstMatch
        XCTAssertTrue(conferma.waitForExistence(timeout: 3), "Prima di copiare deve chiedere conferma")
    }
}
