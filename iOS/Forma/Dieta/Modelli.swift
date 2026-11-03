import Foundation

// Dati dell'app. Il formato JSON è lo stesso della web app (index.html),
// così i backup si possono importare ed esportare tra le due versioni.

struct Alimento: Codable, Hashable {
    var nome: String
    var quantita: String

    init(nome: String, quantita: String) {
        self.nome = nome
        self.quantita = quantita
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nome = c.valore(.nome, "")
        quantita = c.valore(.quantita, "")
    }
}

struct Opzione: Codable, Hashable {
    var titolo: String?
    var alimenti: [Alimento]

    init(titolo: String? = nil, alimenti: [Alimento]) {
        self.titolo = titolo
        self.alimenti = alimenti
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        titolo = c.valore(.titolo, nil)
        alimenti = c.valore(.alimenti, [])
    }
}

struct Pasto: Codable, Hashable {
    var nome: String
    var opzioni: [Opzione]

    init(nome: String, opzioni: [Opzione]) {
        self.nome = nome
        self.opzioni = opzioni
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nome = c.valore(.nome, "")
        opzioni = c.valore(.opzioni, [])
    }
}

struct GiornoPiano: Codable, Hashable {
    var nome: String
    var palestra: Bool
    var pasti: [Pasto]

    init(nome: String, palestra: Bool, pasti: [Pasto]) {
        self.nome = nome
        self.palestra = palestra
        self.pasti = pasti
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nome = c.valore(.nome, "")
        palestra = c.valore(.palestra, false)
        pasti = c.valore(.pasti, [])
    }
}

struct Piano: Codable, Hashable, Identifiable {
    var nome: String
    var dal: String       // yyyy-MM-dd
    var al: String        // vuoto = aperto
    var giorni: [GiornoPiano]

    var id: String { nome + "|" + dal }

    init(nome: String, dal: String, al: String, giorni: [GiornoPiano]) {
        self.nome = nome
        self.dal = dal
        self.al = al
        self.giorni = giorni
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nome = c.valore(.nome, "")
        dal = c.valore(.dal, "")
        al = c.valore(.al, "")
        giorni = c.valore(.giorni, [])
    }
}

struct Slot: Codable, Hashable {
    var opt = 0
    var fatto = false

    init(opt: Int = 0, fatto: Bool = false) {
        self.opt = opt
        self.fatto = fatto
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        opt = c.valore(.opt, 0)
        fatto = c.valore(.fatto, false)
    }
}

// Quello che è stato fatto in un giorno: pasti (per indice), olio e acqua
struct Registro: Codable, Hashable {
    var slot: [String: Slot] = [:]
    var olio = 0
    var acqua = 0.0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        slot = c.valore(.slot, [:])
        olio = c.valore(.olio, 0)
        acqua = c.valore(.acqua, 0.0)
    }
}

// Misurazione BIA: i nomi dei campi sono quelli della web app
struct Misura: Codable, Hashable, Identifiable {
    var data: String
    var peso: Double?
    var grassoKg: Double?
    var grassoPct: Double?
    var magraKg: Double?
    var magraPct: Double?
    var acquaL: Double?
    var bmr: Double?
    var vatCm2: Double?
    var vitaCm: Double?
    var addomeCm: Double?
    var fianchiCm: Double?
    var toraceCm: Double?
    var obiettivoPeso: Double?
    var obiettivoGrassoPct: Double?

    var id: String { data }

    enum CodingKeys: String, CodingKey {
        case data, peso, bmr
        case grassoKg = "grasso_kg", grassoPct = "grasso_pct", magraKg = "magra_kg", magraPct = "magra_pct"
        case acquaL = "acqua_l", vatCm2 = "vat_cm2", vitaCm = "vita_cm", addomeCm = "addome_cm"
        case fianchiCm = "fianchi_cm", toraceCm = "torace_cm"
        case obiettivoPeso = "obiettivo_peso", obiettivoGrassoPct = "obiettivo_grasso_pct"
    }

    init(data: String) {
        self.data = data
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        data = c.valore(.data, "")
        peso = c.valore(.peso, nil)
        grassoKg = c.valore(.grassoKg, nil)
        grassoPct = c.valore(.grassoPct, nil)
        magraKg = c.valore(.magraKg, nil)
        magraPct = c.valore(.magraPct, nil)
        acquaL = c.valore(.acquaL, nil)
        bmr = c.valore(.bmr, nil)
        vatCm2 = c.valore(.vatCm2, nil)
        vitaCm = c.valore(.vitaCm, nil)
        addomeCm = c.valore(.addomeCm, nil)
        fianchiCm = c.valore(.fianchiCm, nil)
        toraceCm = c.valore(.toraceCm, nil)
        obiettivoPeso = c.valore(.obiettivoPeso, nil)
        obiettivoGrassoPct = c.valore(.obiettivoGrassoPct, nil)
    }

    subscript(campo: CampoMisura) -> Double? {
        get { self[keyPath: campo.percorso] }
        set { self[keyPath: campo.percorso] = newValue }
    }
}

// Campi modificabili a mano, nell'ordine del modulo
enum CampoMisura: String, CaseIterable, Identifiable {
    case peso, grasso, magra, acqua, bmr, vat, vita, addome, fianchi, torace

    var id: String { rawValue }

    var percorso: WritableKeyPath<Misura, Double?> {
        switch self {
        case .peso: \.peso
        case .grasso: \.grassoKg
        case .magra: \.magraKg
        case .acqua: \.acquaL
        case .bmr: \.bmr
        case .vat: \.vatCm2
        case .vita: \.vitaCm
        case .addome: \.addomeCm
        case .fianchi: \.fianchiCm
        case .torace: \.toraceCm
        }
    }

    var nome: String {
        switch self {
        case .peso: "Peso"
        case .grasso: "Massa grassa"
        case .magra: "Massa magra"
        case .acqua: "Acqua"
        case .bmr: "Metabolismo"
        case .vat: "Grasso viscerale"
        case .vita: "Vita"
        case .addome: "Addome"
        case .fianchi: "Fianchi"
        case .torace: "Torace"
        }
    }

    var unita: String {
        switch self {
        case .peso, .grasso, .magra: "kg"
        case .acqua: "l"
        case .bmr: "kcal"
        case .vat: "cm²"
        case .vita, .addome, .fianchi, .torace: "cm"
        }
    }
}

struct Spesa: Codable, Hashable {
    var settimana: String   // lunedì della settimana a cui valgono le spunte
    var presi: [String: Bool]

    init(settimana: String, presi: [String: Bool] = [:]) {
        self.settimana = settimana
        self.presi = presi
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        settimana = c.valore(.settimana, "")
        presi = c.valore(.presi, [:])
    }
}

struct Profilo: Codable, Hashable {
    var nome: String
    var piani: [Piano] = []
    var bia: [Misura] = []
    var dieta: [String: Registro] = [:]
    var olioTot: Int?
    var acquaTot: Double?
    var note: String?
    var spesa: Spesa?               // settimana più vecchia: è quella che legge anche la web app
    var spesaProssima: Spesa?       // seconda settimana (solo app), così spuntare la prossima non azzera questa

    enum CodingKeys: String, CodingKey {
        case nome, piani, bia, dieta, note, spesa
        case spesaProssima = "spesa_prossima"
        case olioTot = "olio_tot", acquaTot = "acqua_tot"
    }

    // I profili nuovi partono senza note; quelli salvati senza il campo tengono il testo predefinito
    init(nome: String, note: String? = nil) {
        self.nome = nome
        self.note = note
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nome = c.valore(.nome, "")
        piani = c.valore(.piani, [])
        bia = c.valore(.bia, [])
        dieta = c.valore(.dieta, [:])
        olioTot = c.valore(.olioTot, nil)
        acquaTot = c.valore(.acquaTot, nil)
        note = c.valore(.note, nil)
        spesa = c.valore(.spesa, nil)
        spesaProssima = c.valore(.spesaProssima, nil)
    }
}

// Promemoria della dieta; gli orari sono minuti dalla mezzanotte e li sceglie l'utente
struct Promemoria: Codable, Hashable {
    var acqua = false
    var pasti = false
    var mattino = true
    var oraMattino = 9 * 60
    var oraPasti = 21 * 60
    var acquaDalle = 10 * 60
    var acquaAlle = 20 * 60
    var acquaOgni = 2           // ore tra un promemoria dell'acqua e il successivo

    struct Notifica: Equatable {
        let id: String
        let minuti: Int
        let titolo: String
        let testo: String
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let base = Promemoria()
        acqua = c.valore(.acqua, false)
        pasti = c.valore(.pasti, false)
        mattino = c.valore(.mattino, true)
        oraMattino = c.valore(.oraMattino, base.oraMattino)
        oraPasti = c.valore(.oraPasti, base.oraPasti)
        acquaDalle = c.valore(.acquaDalle, base.acquaDalle)
        acquaAlle = c.valore(.acquaAlle, base.acquaAlle)
        acquaOgni = c.valore(.acquaOgni, base.acquaOgni)
        // Valori da un backup modificato o rovinato: riportati nei limiti
        oraMattino = minutiValidi(oraMattino)
        oraPasti = minutiValidi(oraPasti)
        acquaDalle = minutiValidi(acquaDalle)
        acquaAlle = max(minutiValidi(acquaAlle), acquaDalle)
        acquaOgni = min(max(acquaOgni, 1), 6)
    }

    // Dalle `acquaDalle` alle `acquaAlle`, ogni `acquaOgni` ore (almeno il primo)
    var orariAcqua: [Int] {
        let passo = max(acquaOgni, 1) * 60
        return Array(stride(from: acquaDalle, through: max(acquaAlle, acquaDalle), by: passo))
    }

    // Le notifiche giornaliere da programmare con le scelte attuali
    var notifiche: [Notifica] {
        var n: [Notifica] = []
        if mattino { n.append(Notifica(id: "mattino", minuti: oraMattino, titolo: "Dieta", testo: "Controlla la dieta odierna 🥗")) }
        if pasti { n.append(Notifica(id: "pasti", minuti: oraPasti, titolo: "Dieta", testo: "Hai segnato i pasti di oggi?")) }
        if acqua {
            n += orariAcqua.map { Notifica(id: "acqua-\($0)", minuti: $0, titolo: "Acqua 💧", testo: "È il momento di un bicchiere d'acqua.") }
        }
        return n
    }
}

struct Stato: Codable, Hashable {
    var profili: [String: Profilo]
    var attivo: String
    var preferito: String?
    var promemoria: Promemoria?

    // Prima installazione: un solo profilo, senza note (si rinomina in Impostazioni)
    static let iniziale = Stato(profili: ["io": Profilo(nome: "Io", note: "")], attivo: "io")

    init(profili: [String: Profilo], attivo: String, preferito: String? = nil, promemoria: Promemoria? = nil) {
        self.profili = profili
        self.attivo = attivo
        self.preferito = preferito
        self.promemoria = promemoria
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        guard let profili = try c.decodeIfPresent([String: Profilo].self, forKey: .profili), !profili.isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: .profili, in: c, debugDescription: "Nessun profilo")
        }
        self.profili = profili
        attivo = c.valore(.attivo, profili.keys.sorted()[0])
        preferito = c.valore(.preferito, nil)
        promemoria = c.valore(.promemoria, nil)
        if profili[attivo] == nil { attivo = profili.keys.sorted()[0] }
    }
}

// Minuti dalla mezzanotte tra 0:00 e 23:59
func minutiValidi(_ m: Int) -> Int { min(max(m, 0), 24 * 60 - 1) }

extension KeyedDecodingContainer {
    // Legge un campo se c'è ed è valido, altrimenti usa il valore predefinito
    func valore<T: Decodable>(_ chiave: Key, _ predefinito: T) -> T {
        ((try? decodeIfPresent(T.self, forKey: chiave)) ?? nil) ?? predefinito
    }
}
