import Foundation

// Condiviso tra l'app e l'estensione RecuperoWidget (Live Activity dell'allenamento)

// Il recupero in corso, tutto quello che serve per mostrarlo anche fuori dall'app (Live Activity):
// quando è partito, quando finisce (cambia con ±15 s) e per quale esercizio
nonisolated struct StatoRecupero: Codable, Hashable, Sendable {
    var inizio: Date
    var fine: Date
    var esercizio: String?

    // Quanto del recupero è passato, da 0 a 1
    func trascorso(il momento: Date) -> Double {
        let totale = fine.timeIntervalSince(inizio)
        guard totale > 0 else { return 1 }
        return min(1, max(0, momento.timeIntervalSince(inizio) / totale))
    }
}
