import Testing
@testable import Forma

// Gocce di olio o acqua per una dose in litri
@MainActor
struct DosiTests {
    @Test func gocceArrotondaPerEccesso() {
        #expect(Dosi.gocce(dose: 2) == 8)
        #expect(Dosi.gocce(dose: 1.9) == 8)
    }

    @Test func almenoUnaGoccia() {
        #expect(Dosi.gocce(dose: 0.1) == 1)
        #expect(Dosi.gocce(dose: 0) == 1)
    }
}
