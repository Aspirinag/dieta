import Testing
@testable import Forma

// Reparto stimato dal nome dell'alimento
@MainActor
struct RepartiTests {
    @Test func reparti() {
        #expect(Reparto.indovina("Petto di pollo") == .carnePesceUova)
        #expect(Reparto.indovina("Mela") == .fruttaVerdura)
        #expect(Reparto.indovina("Yogurt greco") == .latticini)
        #expect(Reparto.indovina("Pasta integrale") == .panePastaCereali)
        #expect(Reparto.indovina("Olio extravergine") == .dispensa)
        #expect(Reparto.indovina("Quinoa soffiata bio") == .altro)
    }

    @Test func singolareEPlurale() {
        #expect(Reparto.indovina("Mele") == .fruttaVerdura)
        #expect(Reparto.indovina("MELA") == .fruttaVerdura)
        #expect(Reparto.indovina("Uova") == .carnePesceUova)
        #expect(Reparto.indovina("Tè verde") == .dispensa)
    }

    @Test func nomiDeiReparti() {
        #expect(Reparto.allCases.map(\.nome) == ["Frutta e verdura", "Carne, pesce, uova", "Latticini", "Pane, pasta, cereali", "Dispensa", "Altro"])
    }
}
