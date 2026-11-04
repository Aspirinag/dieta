import Foundation
import Testing
@testable import Forma

// Il recupero nella barra sopra la tab bar si legge come un conto alla rovescia m:ss
@MainActor
struct RecuperoVisibileTests {
    @Test func formatoMinutiESecondi() {
        #expect(testoRecupero(90) == "1:30")
        #expect(testoRecupero(5) == "0:05")
        #expect(testoRecupero(600) == "10:00")
    }

    @Test func arrotondaPerEccessoENonVaSottoZero() {
        #expect(testoRecupero(89.2) == "1:30")
        #expect(testoRecupero(0.4) == "0:01")
        #expect(testoRecupero(-3) == "0:00")
    }
}
