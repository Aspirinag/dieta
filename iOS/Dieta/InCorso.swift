import Foundation

// Logica dell'allenamento in corso. Ogni modifica si salva subito: se l'app si chiude si riprende da dove era.

struct Riepilogo: Equatable {
    var durata: TimeInterval
    var serie: Int
    var volume: Double
    var record: [String]
}

enum TipoAnnulla { case spunta, pasto }

// Il tasto «Annulla» che resta qualche secondo dopo una spunta o dopo «Mangiato»
struct RichiestaAnnulla: Equatable {
    let id = UUID()
    let tipo: TipoAnnulla
    let testo: String
}

struct SpuntaPrecedente {
    let profilo: String
    let allenamento: String
    let esercizio: Int
    let serie: Int
    let prima: SerieFatta
}

struct PastoPrecedente {
    let profilo: String
    let giorno: String
    let indice: Int
    let prima: Slot?        // nil: il pasto non aveva ancora nessun dato
    let registroEsisteva: Bool
}

extension Allenamento {
    private static let formato: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Giorni.calendario
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }()

    static func testo(_ data: Date) -> String { formato.string(from: data) }
    static func data(_ testo: String) -> Date? { formato.date(from: testo) }

    // Il giorno in cui è iniziato, anche se finisce dopo la mezzanotte
    var giorno: String { String(inizio.prefix(10)) }
    var dataInizio: Date? { Self.data(inizio) }
}

extension Archivio {
    static let recuperoPredefinito = 90
    static let secondiAnnulla: Double = 5
    private static let massimoValore = 1000.0

    // ---------- Valori ----------

    // Solo cifre con una virgola o un punto: niente vuoti, zero, esponenti, nan o inf
    static func kgValidi(_ testo: String) -> Double? {
        let t = testo.trimmingCharacters(in: .whitespaces)
        guard t.wholeMatch(of: #/\d+([.,]\d+)?/#) != nil, let v = leggiNumero(t), v.isFinite, v > 0, v <= massimoValore else { return nil }
        return v
    }

    static func ripetizioniValide(_ testo: String) -> Int? {
        let t = testo.trimmingCharacters(in: .whitespaces)
        guard t.wholeMatch(of: #/\d+/#) != nil, let v = Int(t), v > 0, v <= Int(massimoValore) else { return nil }
        return v
    }

    // ---------- Inizio ----------

    // Con un allenamento già in corso non fa niente: non va mai sovrascritto
    func iniziaAllenamento(_ r: Routine?, adesso: Date = Date()) {
        guard profilo.allenamentoInCorso == nil else { return }
        var a = Allenamento(inizio: Allenamento.testo(adesso), routine: r?.nome)
        for e in r?.esercizi ?? [] {
            a.esercizi.append(EsercizioFatto(nome: e.nome, serie: serieIniziali(e.nome, quante: e.serie)))
        }
        profilo.allenamentoInCorso = a
        recupero.salta()
        salvaSubito()
    }

    // Le serie partono dai valori dell'ultima volta (l'ultima serie ripete l'ultimo valore)
    private func serieIniziali(_ nome: String, quante: Int) -> [SerieFatta] {
        let prima = profilo.precedente(nome)
        return (0..<max(1, quante)).map { i in
            let p = prima.indices.contains(i) ? prima[i] : prima.last
            return SerieFatta(tipo: .normale, kg: p?.kg ?? 0, ripetizioni: p?.ripetizioni ?? 0, fatta: false)
        }
    }

    func recuperoPrevisto(_ nome: String) -> Int {
        guard let r = profilo.allenamentoInCorso?.routine else { return Self.recuperoPredefinito }
        return profilo.routine.first { $0.nome == r }?.esercizi.first { $0.nome == nome }?.recupero ?? Self.recuperoPredefinito
    }

    // ---------- Serie ----------

    @discardableResult
    func spuntaSerie(esercizio e: Int, serie s: Int, kg: String, ripetizioni: String, adesso: Date = Date()) -> Bool {
        guard var a = profilo.allenamentoInCorso, a.esercizi.indices.contains(e), a.esercizi[e].serie.indices.contains(s),
              !a.esercizi[e].serie[s].fatta,
              let k = Self.kgValidi(kg), let r = Self.ripetizioniValide(ripetizioni) else { return false }
        let prima = a.esercizi[e].serie[s]
        a.esercizi[e].serie[s].kg = k
        a.esercizi[e].serie[s].ripetizioni = r
        a.esercizi[e].serie[s].fatta = true
        profilo.allenamentoInCorso = a
        spuntaPrecedente = SpuntaPrecedente(profilo: stato.attivo, allenamento: a.id, esercizio: e, serie: s, prima: prima)
        recupero.avvia(recuperoPrevisto(a.esercizi[e].nome), adesso: adesso)
        salvaSubito()
        offriAnnulla(.spunta, "Serie segnata")
        return true
    }

    // Riapre una serie già segnata, senza annulla: serve a correggerla
    func riapriSerie(esercizio e: Int, serie s: Int) {
        modifica { a in
            guard a.esercizi.indices.contains(e), a.esercizi[e].serie.indices.contains(s) else { return false }
            a.esercizi[e].serie[s].fatta = false
            return true
        }
    }

    @discardableResult
    func annullaSpunta() -> Bool {
        guard let p = spuntaPrecedente else { return false }
        spuntaPrecedente = nil
        chiudiAnnulla(.spunta)
        guard stato.attivo == p.profilo, var a = profilo.allenamentoInCorso, a.id == p.allenamento,
              a.esercizi.indices.contains(p.esercizio), a.esercizi[p.esercizio].serie.indices.contains(p.serie) else { return false }
        a.esercizi[p.esercizio].serie[p.serie] = p.prima
        profilo.allenamentoInCorso = a
        recupero.salta()
        salvaSubito()
        return true
    }

    func aggiungiSerie(esercizio e: Int) {
        modifica { a in
            guard a.esercizi.indices.contains(e) else { return false }
            let ultima = a.esercizi[e].serie.last
            a.esercizi[e].serie.append(SerieFatta(tipo: .normale, kg: ultima?.kg ?? 0, ripetizioni: ultima?.ripetizioni ?? 0, fatta: false))
            return true
        }
    }

    func togliSerie(esercizio e: Int, serie s: Int) {
        modifica { a in
            guard a.esercizi.indices.contains(e), a.esercizi[e].serie.indices.contains(s) else { return false }
            a.esercizi[e].serie.remove(at: s)
            return true
        }
    }

    func cambiaTipo(esercizio e: Int, serie s: Int, _ tipo: TipoSerie) {
        modifica { a in
            guard a.esercizi.indices.contains(e), a.esercizi[e].serie.indices.contains(s) else { return false }
            a.esercizi[e].serie[s].tipo = tipo
            return true
        }
    }

    // ---------- Esercizi ----------

    func aggiungiEsercizio(_ nome: String) {
        let pulito = nome.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pulito.isEmpty else { return }
        modifica { a in
            a.esercizi.append(EsercizioFatto(nome: pulito, serie: serieIniziali(pulito, quante: 3)))
            return true
        }
    }

    func togliEsercizio(_ i: Int) {
        modifica { a in
            guard a.esercizi.indices.contains(i) else { return false }
            a.esercizi.remove(at: i)
            return true
        }
    }

    // Vero se il carico supera il massimo di sempre per quell'esercizio, compreso quanto già segnato oggi.
    // Senza un massimo precedente non c'è niente da battere
    func superaIlMassimo(esercizio e: Int, kg: String) -> Bool {
        guard let a = profilo.allenamentoInCorso, a.esercizi.indices.contains(e),
              let valore = Self.kgValidi(kg) else { return false }
        let nome = a.esercizi[e].nome
        guard let storico = profilo.massimo(nome) else { return false }
        let oggi = a.esercizi.filter { $0.nome == nome }.flatMap(\.serie).filter(\.vale).map(\.kg).max() ?? 0
        return valore > max(storico, oggi)
    }

    // ---------- Fine ----------

    @discardableResult
    func terminaAllenamento(adesso: Date = Date()) -> Riepilogo {
        guard var a = profilo.allenamentoInCorso else { return Riepilogo(durata: 0, serie: 0, volume: 0, record: []) }
        // Resta solo ciò che è stato segnato
        for i in a.esercizi.indices { a.esercizi[i].serie.removeAll { !$0.fatta } }
        a.esercizi.removeAll { $0.serie.isEmpty }
        a.fine = Allenamento.testo(adesso)

        let valide = a.esercizi.flatMap(\.serie).filter(\.vale)
        // Record sul nome unico: due voci dello stesso esercizio contano insieme
        var record: [String] = []
        var visti = Set<String>()
        for e in a.esercizi where visti.insert(e.nome).inserted {
            let migliore = a.esercizi.filter { $0.nome == e.nome }.flatMap(\.serie).filter(\.vale).map(\.kg).max() ?? 0
            if let storico = profilo.massimo(e.nome), migliore > storico { record.append("\(e.nome): \(num(migliore)) kg") }
        }
        let riepilogo = Riepilogo(durata: max(0, adesso.timeIntervalSince(a.dataInizio ?? adesso)), serie: valide.count,
                                  volume: valide.reduce(0) { $0 + $1.kg * Double($1.ripetizioni) }, record: record)

        if !a.esercizi.isEmpty { profilo.allenamenti.append(a) }
        profilo.allenamentoInCorso = nil
        recupero.salta()
        spuntaPrecedente = nil
        chiudiAnnulla(.spunta)
        salvaSubito()
        return riepilogo
    }

    // ---------- Mangiato, con annulla ----------

    func segnaMangiato(_ iso: String, _ i: Int, azzeraAltro: Bool = false) {
        let registroPrima = profilo.dieta[iso]
        pastoPrecedente = PastoPrecedente(profilo: stato.attivo, giorno: iso, indice: i,
                                          prima: registroPrima?.slot[String(i)], registroEsisteva: registroPrima != nil)
        cambiaSlot(iso, i) { $0.fatto = true; if azzeraAltro { $0.altro = nil } }
        salvaSubito()
        offriAnnulla(.pasto, "Pasto segnato")
    }

    // Rimette il pasto com'era e lascia stare il resto del giorno (acqua, olio, altri pasti)
    @discardableResult
    func annullaUltimoPasto() -> Bool {
        guard let p = pastoPrecedente else { return false }
        pastoPrecedente = nil
        chiudiAnnulla(.pasto)
        guard stato.attivo == p.profilo, var r = profilo.dieta[p.giorno] else { return false }
        r.slot[String(p.indice)] = p.prima
        profilo.dieta[p.giorno] = (!p.registroEsisteva && r == Registro()) ? nil : r
        salvaSubito()
        return true
    }

    // ---------- Annulla ----------

    private func offriAnnulla(_ tipo: TipoAnnulla, _ testo: String) {
        scadenzaAnnulla?.cancel()
        // Un solo annulla alla volta: il precedente non è più disponibile
        if tipo == .spunta { pastoPrecedente = nil } else { spuntaPrecedente = nil }
        let richiesta = RichiestaAnnulla(tipo: tipo, testo: testo)
        richiestaAnnulla = richiesta
        scadenzaAnnulla = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.secondiAnnulla))
            guard !Task.isCancelled, let self, self.richiestaAnnulla == richiesta else { return }
            self.spuntaPrecedente = nil
            self.pastoPrecedente = nil
            self.richiestaAnnulla = nil
        }
    }

    private func chiudiAnnulla(_ tipo: TipoAnnulla) {
        guard richiestaAnnulla?.tipo == tipo else { return }
        scadenzaAnnulla?.cancel()
        richiestaAnnulla = nil
    }

    // Applica una modifica all'allenamento in corso e salva subito
    private func modifica(_ f: (inout Allenamento) -> Bool) {
        guard var a = profilo.allenamentoInCorso, f(&a) else { return }
        profilo.allenamentoInCorso = a
        salvaSubito()
    }
}
