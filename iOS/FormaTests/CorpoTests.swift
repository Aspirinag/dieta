import Testing
@testable import Forma

// Progressi → Corpo: l'invito «Aggiungi il primo peso» solo senza alcuna misurazione
@MainActor
struct CorpoTests {
    @Test func vuotoSoloSenzaMisurazioni() {
        #expect(CorpoView.senzaMisurazioni([]))
        var soloVita = Misura(data: "2026-10-01")
        soloVita.vitaCm = 90
        #expect(!CorpoView.senzaMisurazioni([soloVita]))
        var conPeso = Misura(data: "2026-10-02")
        conPeso.peso = 80
        #expect(!CorpoView.senzaMisurazioni([soloVita, conPeso]))
    }
}
