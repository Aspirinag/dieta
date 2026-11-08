import Foundation
import HealthKit

// Da dove arrivano gli allenamenti del Watch: l'app Salute, o una finta nei test
@MainActor
protocol FonteSalute: AnyObject {
    func permessoGiaChiesto() async -> Bool
    func chiediPermesso() async -> Bool
    // Allenamenti salvati dopo il punto `ancora` (nil: dalla data `da`), e il nuovo punto raggiunto
    func nuovi(dopo ancora: Data?, da: Date) async throws -> (allenamenti: [AllenamentoWatch], ancora: Data?)
}

// Legge la Salute il meno possibile: solo gli allenamenti nuovi dall'ultima volta,
// al massimo una volta al minuto (all'apertura l'app chiede più volte), permesso chiesto una volta sola
@MainActor
final class LetturaWatch {
    static let chiaveAncora = "salute.ancora"
    static let intervalloMinimo: TimeInterval = 60

    private let fonte: FonteSalute
    private let memoria: UserDefaults
    private var ultima: Date?

    init(fonte: FonteSalute, memoria: UserDefaults = .standard) {
        self.fonte = fonte
        self.memoria = memoria
    }

    func permesso() async -> Bool {
        if await fonte.permessoGiaChiesto() { return true }
        return await fonte.chiediPermesso()
    }

    // nil se ha appena letto: niente lettura nuova
    func leggi(adesso: Date = Date()) async -> [AllenamentoWatch]? {
        if let ultima, adesso.timeIntervalSince(ultima) < Self.intervalloMinimo { return nil }
        ultima = adesso
        let da = Calendar.current.date(byAdding: .day, value: -7, to: adesso) ?? adesso
        guard let r = try? await fonte.nuovi(dopo: memoria.data(forKey: Self.chiaveAncora), da: da) else { return [] }
        if let a = r.ancora { memoria.set(a, forKey: Self.chiaveAncora) }
        return r.allenamenti
    }
}

// La Salute vera
@MainActor
final class FonteHealthKit: FonteSalute {
    let store: HKHealthStore
    init(store: HKHealthStore) { self.store = store }

    static var tipiLettura: Set<HKObjectType> {
        [HKObjectType.workoutType(), HKQuantityType(.activeEnergyBurned), HKQuantityType(.heartRate),
         HKQuantityType(.distanceWalkingRunning), HKQuantityType(.distanceCycling), HKQuantityType(.distanceSwimming)]
    }

    func permessoGiaChiesto() async -> Bool {
        let stato = try? await store.statusForAuthorizationRequest(toShare: [], read: Self.tipiLettura)
        return stato == .unnecessary
    }

    func chiediPermesso() async -> Bool {
        do {
            try await store.requestAuthorization(toShare: [], read: Self.tipiLettura)
            return true
        } catch {
            return false
        }
    }

    func nuovi(dopo ancora: Data?, da: Date) async throws -> (allenamenti: [AllenamentoWatch], ancora: Data?) {
        let punto = ancora.flatMap { try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: $0) }
        let richiesta = HKAnchoredObjectQueryDescriptor(
            predicates: [.workout(HKQuery.predicateForSamples(withStart: da, end: nil))],
            anchor: punto)
        let r = try await richiesta.result(for: store)
        let nuovaAncora = try? NSKeyedArchiver.archivedData(withRootObject: r.newAnchor, requiringSecureCoding: true)
        return (r.addedSamples.compactMap(Self.traduci), nuovaAncora)
    }

    static func traduci(_ w: HKWorkout) -> AllenamentoWatch? {
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
