import Testing
@testable import Forma

// Controlla che il target di test si colleghi all'app
@MainActor
struct AvvioTests {
    @Test func oggiHaFormatoISO() {
        #expect(Giorni.oggi().count == 10)
    }
}
