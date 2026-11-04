import Testing
@testable import Forma

// Controlla che il target di test si colleghi all'app
@MainActor
struct AvvioTests {
    @Test func oggiHaFormatoISO() {
        #expect(Giorni.oggi().count == 10)
    }
}

// Il benvenuto compare solo a chi parte davvero da zero: chi ha già dati della palestra non lo vede
@MainActor
struct BenvenutoTests {
    @Test func soloSenzaDatiDiNessunTipo() {
        #expect(BenvenutoView.daMostrare(dietaNuova: true, datiPalestra: false, visto: false))
        #expect(!BenvenutoView.daMostrare(dietaNuova: true, datiPalestra: true, visto: false))
        #expect(!BenvenutoView.daMostrare(dietaNuova: false, datiPalestra: false, visto: false))
        #expect(!BenvenutoView.daMostrare(dietaNuova: true, datiPalestra: false, visto: true))
    }
}
