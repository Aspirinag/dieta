import Foundation

// Il recupero tra le serie. Si calcola dall'orario di fine, non contando i secondi:
// con l'app in secondo piano o il telefono bloccato il tempo resta giusto
struct TimerRecupero: Equatable {
    private(set) var fine: Date?

    mutating func avvia(_ secondi: Int, adesso: Date = Date()) {
        fine = adesso.addingTimeInterval(TimeInterval(max(0, secondi)))
    }

    // Solo a recupero avviato: un recupero fermo o finito non riparte con +15
    mutating func aggiungi(_ secondi: Int) {
        guard let f = fine else { return }
        fine = f.addingTimeInterval(TimeInterval(secondi))
    }

    mutating func salta() { fine = nil }

    // Secondi che mancano, arrotondati per eccesso; mai sotto zero
    func rimanenti(adesso: Date = Date()) -> Int {
        guard let fine else { return 0 }
        return max(0, Int((fine.timeIntervalSince(adesso)).rounded(.up)))
    }
}
