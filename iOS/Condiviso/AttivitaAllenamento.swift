import ActivityKit
import AppIntents
import Foundation

// Condiviso tra l'app e l'estensione RecuperoWidget: la Live Activity dell'allenamento in corso
// (schermata bloccata e Dynamic Island). La avvia, aggiorna e chiude l'app; l'aspetto sta nell'estensione.

// Tutto quello che la Live Activity mostra
nonisolated struct StatoAllenamentoLive: Codable, Hashable, Sendable {
    var titolo: String                  // nome dell'allenamento, già nella lingua del telefono
    var inizio: Date                    // inizio dell'allenamento (cronometro)
    var esercizio: String?              // esercizio della serie da fare; nil = tutte le serie fatte
    var serie = 0                       // numero della serie da fare (da 1)
    var totaleSerie = 0                 // serie dell'esercizio
    var riscaldamento = false           // la serie da fare è di riscaldamento
    var kg: Double?                     // valori proposti per la serie (quelli che la spunta userebbe)
    var rip: Int?
    var corpoLibero = false
    var idSerie: UUID?                  // la serie che «Fatta» segna
    var prossimo: String?               // prossimo esercizio con serie da fare
    var recupero: StatoRecupero?        // recupero in corso

    // «Fatta» si può toccare solo se ci sono kg e ripetizioni da segnare
    var puoSpuntare: Bool { esercizio != nil && idSerie != nil && kg != nil && (rip ?? 0) > 0 }
}

nonisolated struct AttivitaAllenamento: ActivityAttributes {
    typealias ContentState = StatoAllenamentoLive
}

// Quello che l'intent chiede all'app: impostato dall'app all'avvio, vuoto nell'estensione
enum AzioniLive {
    @MainActor static var segna: ((UUID) async -> Void)?
}

// «Fatta» sulla Live Activity: segna la serie mostrata e fa partire il recupero (gira nel processo dell'app)
struct SegnaSerieIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Segna la serie"
    static let isDiscoverable = false

    @Parameter(title: "Serie")
    var serie: String

    init() {}

    init(serie: UUID) {
        self.serie = serie.uuidString
    }

    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: serie) {
            await AzioniLive.segna?(id)
        }
        return .result()
    }
}
