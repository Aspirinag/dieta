import Foundation
import HealthKit

// Allenamento del Watch già tradotto per Forma (senza tipi di HealthKit)
struct AllenamentoWatch {
    enum Genere: Equatable {
        case palestra
        case cardio(String)     // tipo di cardio di Forma: Camminata, Corsa, Bici...
    }

    var uuid: String
    var genere: Genere
    var inizio: Date
    var fine: Date
    var calorie: Double?
    var battito: Double?
    var km: Double

    var minuti: Int { Int((fine.timeIntervalSince(inizio) / 60).rounded()) }
    var dati: DatiWatch { DatiWatch(uuid: uuid, calorie: calorie, battito: battito) }
}

// Allenamenti dall'Apple Watch letti dall'app Salute (solo lettura).
// iOS sveglia l'app quando il Watch salva un allenamento nuovo: Forma lo registra da sola
// (palestra, camminate e altro cardio) e per la palestra propone di aggiungere esercizi e pesi.
@MainActor
final class Salute {
    static let shared = Salute()

    static let chiave = "allenamentiWatch"
    // Attivo se non è stato spento in Profilo
    static var attivo: Bool { UserDefaults.standard.object(forKey: chiave) as? Bool ?? true }
    static var disponibile: Bool { HKHealthStore.isHealthDataAvailable() }

    // Minimo per contare: le camminate brevi (andare al bar) non sono allenamento
    static let minutiCardio = 20
    static let minutiPalestra = 10

    // Risvegli in background quando cambia un allenamento: al più uno l'ora
    static let frequenzaRisveglio: HKUpdateFrequency = .hourly

    private let store = HKHealthStore()
    private lazy var lettura = LetturaWatch(fonte: FonteHealthKit(store: store))
    private var osservatore: HKObserverQuery?
    private weak var palestra: Palestra?
    private var importando = false

    // Il permesso si chiede solo se non è già stato chiesto
    func chiediPermesso() async -> Bool {
        guard Self.disponibile else { return false }
        return await lettura.permesso()
    }

    // Da chiamare all'avvio dell'app: anche quando iOS la apre in background per un allenamento nuovo
    func avvia(_ palestra: Palestra) {
        self.palestra = palestra
        guard Self.disponibile, Self.attivo, !palestra.demo, osservatore == nil else { return }
        let q = HKObserverQuery(sampleType: HKObjectType.workoutType(), predicate: nil) { @Sendable _, fatto, errore in
            Task { @MainActor in
                if errore == nil { await Salute.shared.importa() }
                // In background iOS può sospendere l'app subito dopo: si salva prima di dirgli che è finita
                Salute.shared.palestra?.salvaOra()
                fatto()
            }
        }
        store.execute(q)
        osservatore = q
        Task { try? await store.enableBackgroundDelivery(for: HKObjectType.workoutType(), frequency: Self.frequenzaRisveglio) }
    }

    func ferma() {
        if let q = osservatore { store.stop(q) }
        osservatore = nil
        Task { try? await store.disableBackgroundDelivery(for: HKObjectType.workoutType()) }
    }

    // Legge solo gli allenamenti nuovi dall'ultima lettura (al primo avvio: l'ultima settimana)
    func importa() async {
        guard let palestra, Self.attivo, !palestra.demo, !importando else { return }
        importando = true
        defer { importando = false }
        guard let allenamenti = await lettura.leggi() else { return }
        for a in allenamenti {
            if case .nuovo(let salvato) = palestra.registraDalWatch(a), a.fine > Date().addingTimeInterval(-3 * 3600) {
                let kcal = a.calorie.map { " · \(Int($0.rounded())) kcal" } ?? ""
                await Notifiche.sessioneWatch(id: salvato.id, titolo: String(localized: "Sessione palestra registrata ✓"),
                                              testo: String(localized: "Dal Watch: \(a.minuti) min\(kcal). Aggiungi esercizi e pesi?"))
            }
        }
    }
}
