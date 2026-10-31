import Foundation

// Dati dell'allenamento. Come in Modelli.swift la lettura è tollerante:
// un campo mancante o non valido prende il valore predefinito, mai un errore.

enum TipoSerie: String, Codable, Hashable, CaseIterable {
    case riscaldamento, normale, cedimento

    init(from decoder: Decoder) throws {
        let testo = (try? decoder.singleValueContainer().decode(String.self)) ?? ""
        self = TipoSerie(rawValue: testo) ?? .normale
    }
}

struct SerieFatta: Codable, Hashable {
    var tipo: TipoSerie
    var kg: Double
    var ripetizioni: Int
    var fatta: Bool

    init(tipo: TipoSerie = .normale, kg: Double = 0, ripetizioni: Int = 0, fatta: Bool = true) {
        self.tipo = tipo
        self.kg = kg
        self.ripetizioni = ripetizioni
        self.fatta = fatta
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tipo = c.valore(.tipo, .normale)
        kg = c.valore(.kg, 0.0)
        ripetizioni = c.valore(.ripetizioni, 0)
        fatta = c.valore(.fatta, true)
    }

    // Conta per record e precedenti: fatta e non di riscaldamento
    var vale: Bool { fatta && tipo != .riscaldamento }
}

struct EsercizioFatto: Codable, Hashable {
    var nome: String
    var serie: [SerieFatta]

    init(nome: String, serie: [SerieFatta] = []) {
        self.nome = nome
        self.serie = serie
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nome = c.valore(.nome, "")
        serie = c.valore(.serie, [])
    }
}

struct Allenamento: Codable, Hashable, Identifiable {
    var id: String
    var inizio: String      // yyyy-MM-dd'T'HH:mm:ss: si ordina come testo
    var fine: String        // vuoto finché l'allenamento è in corso
    var routine: String?
    var esercizi: [EsercizioFatto]

    init(id: String = UUID().uuidString, inizio: String, fine: String = "", routine: String? = nil, esercizi: [EsercizioFatto] = []) {
        self.id = id
        self.inizio = inizio
        self.fine = fine
        self.routine = routine
        self.esercizi = esercizi
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.valore(.id, UUID().uuidString)
        inizio = c.valore(.inizio, "")
        fine = c.valore(.fine, "")
        routine = c.valore(.routine, nil)
        esercizi = c.valore(.esercizi, [])
    }
}

struct EsercizioPrevisto: Codable, Hashable {
    var nome: String
    var serie: Int
    var recupero: Int       // secondi

    init(nome: String, serie: Int = 3, recupero: Int = 90) {
        self.nome = nome
        self.serie = serie
        self.recupero = recupero
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nome = c.valore(.nome, "")
        serie = c.valore(.serie, 3)
        recupero = c.valore(.recupero, 90)
    }
}

struct Routine: Codable, Hashable, Identifiable {
    var nome: String
    var esercizi: [EsercizioPrevisto]
    var giorni: [Int]       // giorni previsti: 1 = lunedì … 7 = domenica

    var id: String { nome }

    init(nome: String, esercizi: [EsercizioPrevisto] = [], giorni: [Int] = []) {
        self.nome = nome
        self.esercizi = esercizi
        self.giorni = giorni
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        nome = c.valore(.nome, "")
        esercizi = c.valore(.esercizi, [])
        giorni = c.valore(.giorni, [])
    }
}

struct SessioneCardio: Codable, Hashable {
    var data: String        // yyyy-MM-dd
    var tipo: String
    var minuti: Int
    var km: Double

    init(data: String, tipo: String, minuti: Int = 0, km: Double = 0) {
        self.data = data
        self.tipo = tipo
        self.minuti = minuti
        self.km = km
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        data = c.valore(.data, "")
        tipo = c.valore(.tipo, "")
        minuti = c.valore(.minuti, 0)
        km = c.valore(.km, 0.0)
    }
}

extension Profilo {
    // Allenamenti conclusi: quello in corso non conta per precedenti e record
    private var conclusi: [Allenamento] {
        allenamenti.filter { $0.id != allenamentoInCorso?.id }
    }

    // Le serie valide dell'ultima volta che l'esercizio è stato fatto
    func precedente(_ esercizio: String) -> [SerieFatta] {
        for a in conclusi.sorted(by: { $0.inizio > $1.inizio }) {
            let serie = a.esercizi.filter { $0.nome == esercizio }.flatMap(\.serie).filter(\.vale)
            if !serie.isEmpty { return serie }
        }
        return []
    }

    // Il carico più alto mai sollevato, senza riscaldamento
    func massimo(_ esercizio: String) -> Double? {
        conclusi.flatMap(\.esercizi).filter { $0.nome == esercizio }
            .flatMap(\.serie).filter(\.vale).map(\.kg).max()
    }

    // Tutti i nomi in uso, senza doppioni, in ordine alfabetico
    func eserciziUsati() -> [String] {
        var nomi = routine.flatMap(\.esercizi).map(\.nome)
        nomi += allenamenti.flatMap(\.esercizi).map(\.nome)
        nomi += allenamentoInCorso?.esercizi.map(\.nome) ?? []
        nomi += noteEsercizi.keys
        let puliti = nomi.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return Set(puliti).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    // Rinomina un esercizio ovunque. Se il nuovo nome esiste già i due esercizi si uniscono:
    // nello stesso allenamento le serie si sommano, la nota già presente vince.
    mutating func rinomina(esercizio: String, in nuovo: String) {
        let nuovo = nuovo.trimmingCharacters(in: .whitespaces)
        guard !nuovo.isEmpty, nuovo != esercizio else { return }

        for r in routine.indices {
            for e in routine[r].esercizi.indices where routine[r].esercizi[e].nome == esercizio {
                routine[r].esercizi[e].nome = nuovo
            }
        }
        for i in allenamenti.indices { allenamenti[i].esercizi = Self.unisci(allenamenti[i].esercizi, esercizio, nuovo) }
        if var inCorso = allenamentoInCorso {
            inCorso.esercizi = Self.unisci(inCorso.esercizi, esercizio, nuovo)
            allenamentoInCorso = inCorso
        }
        if let vecchia = noteEsercizi.removeValue(forKey: esercizio) {
            if (noteEsercizi[nuovo] ?? "").isEmpty { noteEsercizi[nuovo] = vecchia }
        }
    }

    private static func unisci(_ esercizi: [EsercizioFatto], _ vecchio: String, _ nuovo: String) -> [EsercizioFatto] {
        guard esercizi.contains(where: { $0.nome == vecchio }) else { return esercizi }
        var risultato: [EsercizioFatto] = []
        for var e in esercizi {
            if e.nome == vecchio { e.nome = nuovo }
            if e.nome == nuovo, let k = risultato.firstIndex(where: { $0.nome == nuovo }) {
                risultato[k].serie += e.serie
            } else {
                risultato.append(e)
            }
        }
        return risultato
    }
}
