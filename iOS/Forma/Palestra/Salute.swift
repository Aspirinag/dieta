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

    private let store = HKHealthStore()
    private var osservatore: HKObserverQuery?
    private weak var palestra: Palestra?
    private var importando = false

    private var tipiLettura: Set<HKObjectType> {
        [HKObjectType.workoutType(), HKQuantityType(.activeEnergyBurned), HKQuantityType(.heartRate),
         HKQuantityType(.distanceWalkingRunning), HKQuantityType(.distanceCycling), HKQuantityType(.distanceSwimming)]
    }

    func chiediPermesso() async -> Bool {
        guard Self.disponibile else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: tipiLettura)
            return true
        } catch {
            return false
        }
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
        Task { try? await store.enableBackgroundDelivery(for: HKObjectType.workoutType(), frequency: .immediate) }
    }

    func ferma() {
        if let q = osservatore { store.stop(q) }
        osservatore = nil
        Task { try? await store.disableBackgroundDelivery(for: HKObjectType.workoutType()) }
    }

    // Legge gli allenamenti dell'ultima settimana non ancora importati
    func importa() async {
        guard let palestra, Self.attivo, !palestra.demo, !importando else { return }
        importando = true
        defer { importando = false }
        let da = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let richiesta = HKSampleQueryDescriptor(
            predicates: [.workout(HKQuery.predicateForSamples(withStart: da, end: nil))],
            sortDescriptors: [SortDescriptor(\.endDate)])
        guard let allenamenti = try? await richiesta.result(for: store) else { return }
        for w in allenamenti where !palestra.stato.importati.contains(w.uuid.uuidString) {
            guard let a = traduci(w) else {
                palestra.stato.importati.append(w.uuid.uuidString)
                continue
            }
            if case .nuovo(let salvato) = palestra.registraDalWatch(a), a.fine > Date().addingTimeInterval(-3 * 3600) {
                let kcal = a.calorie.map { " · \(Int($0.rounded())) kcal" } ?? ""
                await Notifiche.sessioneWatch(id: salvato.id, titolo: String(localized: "Sessione palestra registrata ✓"),
                                              testo: String(localized: "Dal Watch: \(a.minuti) min\(kcal). Aggiungi esercizi e pesi?"))
            }
        }
    }

    private func traduci(_ w: HKWorkout) -> AllenamentoWatch? {
        let genere: AllenamentoWatch.Genere
        switch w.workoutActivityType {
        case .traditionalStrengthTraining, .functionalStrengthTraining, .crossTraining, .coreTraining, .highIntensityIntervalTraining:
            genere = .palestra
        case .walking, .hiking: genere = .cardio("Camminata")
        case .running: genere = .cardio("Corsa")
        case .cycling: genere = .cardio("Bici")
        case .elliptical: genere = .cardio("Ellittica")
        case .rowing: genere = .cardio("Vogatore")
        case .stairClimbing, .stairs, .stepTraining: genere = .cardio("Scale")
        case .mixedCardio: genere = .cardio("Cardio")
        case .swimming: genere = .cardio("Nuoto")
        default: return nil
        }
        let kcal = w.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie())
        let bpm = w.statistics(for: HKQuantityType(.heartRate))?.averageQuantity()?.doubleValue(for: .count().unitDivided(by: .minute()))
        let km = [HKQuantityType(.distanceWalkingRunning), HKQuantityType(.distanceCycling), HKQuantityType(.distanceSwimming)]
            .compactMap { w.statistics(for: $0)?.sumQuantity()?.doubleValue(for: .meterUnit(with: .kilo)) }
            .reduce(0, +)
        return AllenamentoWatch(uuid: w.uuid.uuidString, genere: genere, inizio: w.startDate, fine: w.endDate,
                                calorie: kcal, battito: bpm, km: km)
    }
}
