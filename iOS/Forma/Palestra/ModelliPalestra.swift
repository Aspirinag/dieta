import Foundation

// Dati della parte palestra (stile Hevy): libreria esercizi, routine, allenamenti con le serie,
// cardio, piano settimanale A/B e pagamenti della palestra

enum Muscolo: String, Codable, CaseIterable, Identifiable {
    case petto, schiena, lombari, trapezi, spalle, bicipiti, tricipiti, avambracci
    case quadricipiti, femorali, glutei, adduttori, abduttori, polpacci, addominali, corpoIntero, cardio, altro
    var id: String { rawValue }
    var nome: String {
        switch self {
        case .corpoIntero: "Corpo intero"
        default: rawValue.capitalized
        }
    }
    var simbolo: String {
        switch self {
        case .petto, .spalle, .trapezi: "figure.arms.open"
        case .schiena, .lombari: "figure.rower"
        case .bicipiti, .tricipiti, .avambracci: "dumbbell"
        case .quadricipiti, .femorali, .glutei, .adduttori, .abduttori, .polpacci: "figure.strengthtraining.functional"
        case .addominali: "figure.core.training"
        case .corpoIntero: "figure.cross.training"
        case .cardio: "figure.run"
        case .altro: "figure.mixed.cardio"
        }
    }
}

enum Attrezzo: String, Codable, CaseIterable, Identifiable {
    case macchina, bilanciere, manubri, cavi, corpoLibero, kettlebell, smith, elastico, bilancierePesato = "zavorra", altro
    var id: String { rawValue }
    var nome: String {
        switch self {
        case .macchina: "Macchina"
        case .bilanciere: "Bilanciere"
        case .manubri: "Manubri"
        case .cavi: "Cavi"
        case .corpoLibero: "Corpo libero"
        case .kettlebell: "Kettlebell"
        case .smith: "Multipower"
        case .elastico: "Elastico"
        case .bilancierePesato: "Zavorra"
        case .altro: "Altro"
        }
    }
}

struct Esercizio: Codable, Hashable, Identifiable {
    var id: String          // per quelli predefiniti è il nome; per quelli nuovi un identificativo univoco
    var nome: String
    var muscolo: Muscolo
    var attrezzo: Attrezzo

    init(id: String? = nil, nome: String, muscolo: Muscolo, attrezzo: Attrezzo) {
        self.id = id ?? nome
        self.nome = nome
        self.muscolo = muscolo
        self.attrezzo = attrezzo
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nome = c.valore(.nome, "")
        id = c.valore(.id, nome)
        muscolo = c.valore(.muscolo, .altro)
        attrezzo = c.valore(.attrezzo, .altro)
    }
}

// Esercizio dentro una routine: serie previste, ripetizioni e recupero
struct VoceRoutine: Codable, Hashable, Identifiable {
    var id = UUID()
    var esercizio: String   // id dell'esercizio
    var serie = 3
    var ripMin = 10
    var ripMax = 12
    var recupero = 90       // secondi

    init(esercizio: String, serie: Int = 3, ripMin: Int = 10, ripMax: Int = 12, recupero: Int = 90) {
        self.esercizio = esercizio
        self.serie = serie
        self.ripMin = ripMin
        self.ripMax = ripMax
        self.recupero = recupero
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.valore(.id, UUID())
        esercizio = c.valore(.esercizio, "")
        serie = c.valore(.serie, 3)
        ripMin = c.valore(.ripMin, 10)
        ripMax = c.valore(.ripMax, 12)
        recupero = c.valore(.recupero, 90)
    }

    var obiettivo: String { ripMin == ripMax ? "\(serie) × \(ripMin)" : "\(serie) × \(ripMin)–\(ripMax)" }
}

struct Routine: Codable, Hashable, Identifiable {
    var id = UUID()
    var nome: String
    var voci: [VoceRoutine] = []

    init(nome: String, voci: [VoceRoutine] = []) {
        self.nome = nome
        self.voci = voci
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.valore(.id, UUID())
        nome = c.valore(.nome, "Routine")
        voci = c.valore(.voci, [])
    }
}

struct SerieFatta: Codable, Hashable, Identifiable {
    var id = UUID()
    var kg: Double?
    var rip: Int?
    var fatta = false
    var riscaldamento = false

    init(kg: Double? = nil, rip: Int? = nil, fatta: Bool = false, riscaldamento: Bool = false) {
        self.kg = kg
        self.rip = rip
        self.fatta = fatta
        self.riscaldamento = riscaldamento
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.valore(.id, UUID())
        kg = c.valore(.kg, nil)
        rip = c.valore(.rip, nil)
        fatta = c.valore(.fatta, false)
        riscaldamento = c.valore(.riscaldamento, false)
    }

    // Serie che conta per volume e record: fatta, non di riscaldamento, con kg e ripetizioni
    var valida: Bool { fatta && !riscaldamento && (kg ?? -1) >= 0 && (rip ?? 0) > 0 }
    var volume: Double { valida ? (kg ?? 0) * Double(rip ?? 0) : 0 }
    // Massimale stimato (formula di Epley)
    var massimale: Double { valida ? (kg ?? 0) * (1 + Double(rip ?? 0) / 30) : 0 }
}

struct EsercizioFatto: Codable, Hashable, Identifiable {
    var id = UUID()
    var esercizio: String
    var recupero = 90
    var serie: [SerieFatta] = []

    init(esercizio: String, recupero: Int = 90, serie: [SerieFatta] = []) {
        self.esercizio = esercizio
        self.recupero = recupero
        self.serie = serie
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.valore(.id, UUID())
        esercizio = c.valore(.esercizio, "")
        recupero = c.valore(.recupero, 90)
        serie = c.valore(.serie, [])
    }
}

struct Allenamento: Codable, Hashable, Identifiable {
    var id = UUID()
    var nome: String
    var inizio: Date
    var fine: Date?
    var esercizi: [EsercizioFatto] = []
    var routine: UUID?
    var riscaldamento: [String: Bool] = [:]
    var watch: DatiWatch?                       // dati dell'allenamento registrato sull'Apple Watch

    init(nome: String, inizio: Date = Date(), esercizi: [EsercizioFatto] = [], routine: UUID? = nil) {
        self.nome = nome
        self.inizio = inizio
        self.esercizi = esercizi
        self.routine = routine
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.valore(.id, UUID())
        nome = c.valore(.nome, "Allenamento")
        inizio = c.valore(.inizio, Date())
        fine = c.valore(.fine, nil)
        esercizi = c.valore(.esercizi, [])
        routine = c.valore(.routine, nil)
        riscaldamento = c.valore(.riscaldamento, [:])
        watch = c.valore(.watch, nil)
    }

    var giorno: String { Giorni.iso(inizio) }
    var soloWatch: Bool { esercizi.isEmpty && watch != nil }
    var volume: Double { esercizi.flatMap(\.serie).reduce(0) { $0 + $1.volume } }
    var serieFatte: Int { esercizi.flatMap(\.serie).filter(\.valida).count }
    var durata: TimeInterval { (fine ?? Date()).timeIntervalSince(inizio) }
}

struct SessioneCardio: Codable, Hashable, Identifiable {
    var id = UUID()
    var data: String
    var tipo: String
    var minuti: Int
    var km: Double
    var watch: DatiWatch?

    init(data: String, tipo: String, minuti: Int, km: Double, watch: DatiWatch? = nil) {
        self.data = data
        self.tipo = tipo
        self.minuti = minuti
        self.km = km
        self.watch = watch
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.valore(.id, UUID())
        data = c.valore(.data, "")
        tipo = c.valore(.tipo, "Corsa")
        minuti = c.valore(.minuti, 0)
        km = c.valore(.km, 0.0)
        watch = c.valore(.watch, nil)
    }
}

// Allenamento letto dall'app Salute (registrato sull'Apple Watch)
struct DatiWatch: Codable, Hashable {
    var uuid: String
    var calorie: Double?        // kcal attive
    var battito: Double?        // battiti al minuto, media
}

enum TipoGiorno: String, CaseIterable, Identifiable, Codable {
    case riposo, pesi, cardio
    var id: String { rawValue }
    var nome: String {
        switch self {
        case .riposo: "Riposo"
        case .pesi: "Pesi"
        case .cardio: "Cardio"
        }
    }
    var simbolo: String {
        switch self {
        case .riposo: "moon.zzz"
        case .pesi: "dumbbell"
        case .cardio: "figure.run"
        }
    }
}

struct StatoPalestra: Codable, Hashable {
    var esercizi: [Esercizio] = Libreria.predefiniti
    var routine: [Routine] = Libreria.routineIniziali
    var allenamenti: [Allenamento] = []
    var inCorso: Allenamento?
    var cardio: [SessioneCardio] = []
    // Settimana A: 2 cardio + 1 pesi. Settimana B: 2 pesi + 1 cardio. Lunedì = 0
    var piani: [String: [TipoGiorno]] = [
        "A": [.cardio, .riposo, .pesi, .riposo, .cardio, .riposo, .riposo],
        "B": [.pesi, .riposo, .cardio, .riposo, .pesi, .riposo, .riposo],
    ]
    var scambia = false
    var saltati: [String] = []                  // giorni segnati "non sono andato"
    var pagamenti: [String: String] = [:]       // yyyy-MM → data del pagamento
    var importati: [String] = []                // allenamenti di Salute già letti (anche se poi eliminati)
    var oraPagamento = 9 * 60                   // ora del promemoria del pagamento, minuti dalla mezzanotte

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let base = StatoPalestra()
        esercizi = c.valore(.esercizi, base.esercizi)
        routine = c.valore(.routine, base.routine)
        allenamenti = c.valore(.allenamenti, [])
        inCorso = c.valore(.inCorso, nil)
        cardio = c.valore(.cardio, [])
        piani = c.valore(.piani, base.piani)
        scambia = c.valore(.scambia, false)
        saltati = c.valore(.saltati, [])
        pagamenti = c.valore(.pagamenti, [:])
        importati = c.valore(.importati, [])
        oraPagamento = c.valore(.oraPagamento, base.oraPagamento)
        // Aggiunge alla libreria gli esercizi predefiniti nuovi
        for e in Libreria.predefiniti where !esercizi.contains(where: { $0.id == e.id }) { esercizi.append(e) }
    }
}
