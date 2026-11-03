import SwiftUI
import UserNotifications

// Dati della palestra, salvati in un file JSON a ogni modifica
@Observable
final class Palestra {
    var stato: StatoPalestra {
        didSet { if !demo { programmaSalvataggio() } }
    }

    let demo: Bool
    // Copia del file dati che all'avvio non si leggeva (l'app è ripartita senza toccarlo)
    @ObservationIgnored private(set) var fileIlleggibile: URL?
    // Il file dati c'è ma non si è potuto leggere: in questa sessione non si salva niente
    @ObservationIgnored private(set) var salvataggioBloccato = false

    init() {
        demo = Avvio.demo
        var illeggibile: URL?
        stato = demo ? StatoPalestra.demo : Self.carica(&illeggibile)
        salvataggioBloccato = illeggibile?.path == "/bloccato"
        fileIlleggibile = salvataggioBloccato ? nil : illeggibile
    }

    // ---------- File ----------

    // Salvataggio raggruppato: più modifiche ravvicinate (es. digitare i kg) scrivono il file una volta sola
    @ObservationIgnored private var salvataggio: Task<Void, Never>?

    private func programmaSalvataggio() {
        salvataggio?.cancel()
        salvataggio = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            salva()
        }
    }

    // Scrive subito (quando l'app va in background)
    func salvaOra() {
        guard salvataggio != nil else { return }
        salvataggio?.cancel()
        salvataggio = nil
        if !demo { salva() }
    }

    private static var fileDati: URL { URL.applicationSupportDirectory.appending(path: "palestra.json") }

    private static func carica(_ illeggibile: inout URL?) -> StatoPalestra {
        switch FileDati.leggi(fileDati, come: StatoPalestra.self) {
        case .ok(let s): return s
        case .bloccato:
            illeggibile = URL(fileURLWithPath: "/bloccato")
            return StatoPalestra()
        case .illeggibile(let copia):
            illeggibile = copia
            return StatoPalestra()
        case .assente: return StatoPalestra()
        }
    }

    private func salva() {
        guard !salvataggioBloccato else { return }
        do {
            try FileManager.default.createDirectory(at: URL.applicationSupportDirectory, withIntermediateDirectories: true)
            try JSONEncoder().encode(stato).write(to: Self.fileDati, options: .atomic)
        } catch {
            print("Salvataggio non riuscito: \(error)")
        }
    }

    // ---------- Libreria ----------

    func esercizio(_ id: String) -> Esercizio {
        stato.esercizi.first { $0.id == id } ?? Esercizio(id: id, nome: id, muscolo: .altro, attrezzo: .altro)
    }

    func nome(_ id: String) -> String { esercizio(id).nome }

    @discardableResult
    func nuovoEsercizio(nome: String, muscolo: Muscolo, attrezzo: Attrezzo) -> Esercizio {
        let e = Esercizio(id: stato.esercizi.contains { $0.id == nome } ? UUID().uuidString : nome,
                          nome: nome, muscolo: muscolo, attrezzo: attrezzo)
        stato.esercizi.append(e)
        return e
    }

    // ---------- Settimane A/B ----------

    // Numero progressivo della settimana dal lunedì 29/12/2025, senza ripartire a gennaio
    static func numeroSettimana(_ iso: String) -> Int {
        let giorni = Giorni.calendario.dateComponents([.day], from: Giorni.data("2025-12-29"), to: Giorni.data(iso)).day ?? 0
        return Int((Double(giorni) / 7).rounded(.down)) + 1
    }

    func settimana(_ iso: String) -> String { stato.settimana(iso) }

    func programmato(_ iso: String) -> TipoGiorno {
        let p = stato.piani[settimana(iso)] ?? []
        let i = Giorni.indice(iso)
        return p.indices.contains(i) ? p[i] : .riposo
    }

    func allenamenti(del iso: String) -> [Allenamento] { stato.allenamenti.filter { $0.giorno == iso } }
    func cardio(del iso: String) -> [SessioneCardio] { stato.cardio.filter { $0.data == iso } }

    // ---------- Allenamento in corso ----------

    func inizia(_ routine: Routine?) {
        var a = Allenamento(nome: routine?.nome ?? "Allenamento libero", routine: routine?.id)
        for v in routine?.voci ?? [] {
            a.esercizi.append(EsercizioFatto(esercizio: v.esercizio, recupero: v.recupero, serie: (0..<v.serie).map { _ in SerieFatta() }))
        }
        stato.inCorso = a
    }

    func aggiungi(esercizi ids: [String]) {
        for id in ids {
            stato.inCorso?.esercizi.append(EsercizioFatto(esercizio: id, serie: (0..<3).map { _ in SerieFatta() }))
        }
    }

    // Chiude l'allenamento: restano solo le serie fatte. Restituisce l'allenamento salvato
    // Un allenamento completato dopo (dal Watch) tiene la sua ora di fine
    @discardableResult
    func termina() -> Allenamento? {
        guard var a = stato.inCorso else { return nil }
        a.fine = a.fine ?? Date()
        a.esercizi = a.esercizi.compactMap { e in
            var e = e
            e.serie = e.serie.filter { $0.fatta && ($0.rip ?? 0) > 0 }
            return e.serie.isEmpty ? nil : e
        }
        stato.inCorso = nil
        // Se il Watch aveva già registrato da solo questa sessione, i suoi dati passano a questa
        if let i = stato.allenamenti.firstIndex(where: { $0.soloWatch && Self.sovrapposti($0, a) }) {
            if a.watch == nil { a.watch = stato.allenamenti[i].watch }
            stato.allenamenti.remove(at: i)
        }
        guard !a.esercizi.isEmpty || a.watch != nil else { return nil }
        stato.allenamenti.append(a)
        stato.allenamenti.sort { $0.inizio < $1.inizio }
        stato.saltati.removeAll { $0 == a.giorno }
        return a
    }

    // Annullando, se il Watch aveva registrato la sessione resta quella (senza esercizi)
    func annulla() {
        if var a = stato.inCorso, a.watch != nil {
            a.esercizi = []
            a.nome = Self.nomeWatch
            a.routine = nil
            a.fine = a.fine ?? Date()
            stato.allenamenti.append(a)
            stato.allenamenti.sort { $0.inizio < $1.inizio }
        }
        stato.inCorso = nil
    }

    // Aggiunge esercizi e pesi a una sessione registrata dal Watch: si apre come allenamento in corso,
    // con le serie della scheda già compilate con i pesi dell'ultima volta (da confermare)
    @discardableResult
    func compila(_ id: UUID, con routine: Routine?) -> Bool {
        guard stato.inCorso == nil, let i = stato.allenamenti.firstIndex(where: { $0.id == id }) else { return false }
        var a = stato.allenamenti.remove(at: i)
        if let routine {
            a.nome = routine.nome
            a.routine = routine.id
            a.esercizi = routine.voci.map { v in
                EsercizioFatto(esercizio: v.esercizio, recupero: v.recupero, serie: (0..<v.serie).map { k in
                    let p = precedente(v.esercizio, k)
                    return SerieFatta(kg: p?.kg, rip: p?.rip)
                })
            }
        } else if a.nome == Self.nomeWatch {
            a.nome = "Allenamento libero"
        }
        stato.inCorso = a
        return true
    }

    static let nomeWatch = "Palestra · dal Watch"

    enum EsitoWatch { case nuovo(Allenamento), agganciato, cardio, ignorato }

    // Registra un allenamento del Watch: cardio come sessione cardio; palestra agganciata
    // all'allenamento di Forma nello stesso orario, oppure salvata come sessione nuova senza esercizi
    func registraDalWatch(_ w: AllenamentoWatch) -> EsitoWatch {
        guard !stato.importati.contains(w.uuid) else { return .ignorato }
        stato.importati.append(w.uuid)
        let giorno = Giorni.iso(w.inizio)
        switch w.genere {
        case .cardio(let tipo):
            guard w.minuti >= Salute.minutiCardio else { return .ignorato }
            stato.cardio.append(SessioneCardio(data: giorno, tipo: tipo, minuti: w.minuti,
                                               km: (w.km * 100).rounded() / 100, watch: w.dati))
            stato.saltati.removeAll { $0 == giorno }
            return .cardio
        case .palestra:
            guard w.minuti >= Salute.minutiPalestra else { return .ignorato }
            var nuovo = Allenamento(nome: Self.nomeWatch, inizio: w.inizio)
            nuovo.fine = w.fine
            nuovo.watch = w.dati
            if let c = stato.inCorso, Self.sovrapposti(nuovo, c) {
                if c.watch == nil { stato.inCorso?.watch = w.dati }
                return .agganciato
            }
            if let i = stato.allenamenti.firstIndex(where: { Self.sovrapposti($0, nuovo) }) {
                if stato.allenamenti[i].watch == nil { stato.allenamenti[i].watch = w.dati }
                return .agganciato
            }
            stato.allenamenti.append(nuovo)
            stato.allenamenti.sort { $0.inizio < $1.inizio }
            stato.saltati.removeAll { $0 == giorno }
            return .nuovo(nuovo)
        }
    }

    static func sovrapposti(_ a: Allenamento, _ b: Allenamento) -> Bool {
        let fa = a.fine ?? a.inizio.addingTimeInterval(3600), fb = b.fine ?? Date()
        return a.inizio < fb && b.inizio < fa
    }

    // Serie corrispondente (stessa posizione tra quelle valide) nell'ultimo allenamento con quell'esercizio
    func precedente(_ esercizio: String, _ indice: Int) -> SerieFatta? {
        guard let ultimo = stato.allenamenti.last(where: { $0.esercizi.contains { $0.esercizio == esercizio } }),
              let e = ultimo.esercizi.first(where: { $0.esercizio == esercizio }) else { return nil }
        let serie = e.serie.filter { !$0.riscaldamento }
        return serie.indices.contains(indice) ? serie[indice] : serie.last
    }

    // ---------- Record e storico ----------

    struct Record {
        var pesoMax = 0.0
        var massimale = 0.0
        var volumeSerie = 0.0
        var ripMax = 0
    }

    func record(_ esercizio: String, prima: Date? = nil) -> Record {
        var r = Record()
        for a in stato.allenamenti where prima == nil || a.inizio < prima! {
            for e in a.esercizi where e.esercizio == esercizio {
                for s in e.serie where s.valida {
                    r.pesoMax = max(r.pesoMax, s.kg ?? 0)
                    r.massimale = max(r.massimale, s.massimale)
                    r.volumeSerie = max(r.volumeSerie, s.volume)
                    r.ripMax = max(r.ripMax, s.rip ?? 0)
                }
            }
        }
        return r
    }

    // Record battuti in un allenamento rispetto a quelli precedenti
    func nuoviRecord(_ a: Allenamento) -> [String] {
        var testi: [String] = []
        for e in a.esercizi {
            let prima = record(e.esercizio, prima: a.inizio)
            let valide = e.serie.filter(\.valida)
            guard !valide.isEmpty, prima.pesoMax > 0 || stato.allenamenti.contains(where: { $0.inizio < a.inizio && $0.esercizi.contains { $0.esercizio == e.esercizio } }) else { continue }
            let peso = valide.compactMap(\.kg).max() ?? 0
            let massimale = valide.map(\.massimale).max() ?? 0
            if peso > prima.pesoMax { testi.append("\(nome(e.esercizio)): peso massimo \(num(peso)) kg") }
            else if massimale > prima.massimale + 0.01 { testi.append("\(nome(e.esercizio)): massimale stimato \(num((massimale * 10).rounded() / 10)) kg") }
        }
        return testi
    }

    struct Punto: Identifiable {
        let data: Date
        let peso: Double
        let massimale: Double
        let volume: Double
        var id: Date { data }
    }

    func andamento(_ esercizio: String) -> [Punto] {
        stato.allenamenti.compactMap { a in
            let serie = a.esercizi.filter { $0.esercizio == esercizio }.flatMap(\.serie).filter(\.valida)
            guard !serie.isEmpty else { return nil }
            return Punto(data: a.inizio, peso: serie.compactMap(\.kg).max() ?? 0,
                         massimale: serie.map(\.massimale).max() ?? 0, volume: serie.reduce(0) { $0 + $1.volume })
        }
    }

    func storico(_ esercizio: String) -> [(allenamento: Allenamento, serie: [SerieFatta])] {
        stato.allenamenti.reversed().compactMap { a in
            let serie = a.esercizi.filter { $0.esercizio == esercizio }.flatMap(\.serie)
            return serie.isEmpty ? nil : (a, serie)
        }
    }

    // ---------- Pagamento ----------

    static func mese(_ iso: String) -> String { String(iso.prefix(7)) }

    // Mese da pagare e testo dell'avviso in Oggi, finché non è segnato pagato
    func promemoriaPagamento() -> (mese: String, testo: String)? {
        guard stato.pagamentoAttivo else { return nil }
        return Self.avvisoPagamento(oggi: Giorni.oggi(), giorno: stato.giornoPagamento, pagamenti: stato.pagamenti)
    }

    // Giorno di pagamento di un mese (yyyy-MM-01), senza superare la fine del mese
    private static func giornoDiPagamento(_ primo: String, _ giorno: Int) -> String {
        let giorni = Giorni.calendario.range(of: .day, in: .month, for: Giorni.data(primo))?.count ?? 28
        return Giorni.aggiungi(primo, min(giorno, giorni) - 1)
    }

    // L'avviso compare una settimana prima del giorno di pagamento e resta fino al giorno dopo
    static func avvisoPagamento(oggi: String, giorno: Int, pagamenti: [String: String]) -> (mese: String, testo: String)? {
        let primo = String(oggi.prefix(8)) + "01"
        // Mese prima (il giorno dopo può cadere nel mese nuovo), mese corrente, mese dopo
        for m in -1..<2 {
            let primoMese = Giorni.iso(Giorni.calendario.date(byAdding: .month, value: m, to: Giorni.data(primo)) ?? Date())
            let paga = giornoDiPagamento(primoMese, giorno)
            guard oggi >= Giorni.aggiungi(paga, -7), oggi <= Giorni.aggiungi(paga, 1) else { continue }
            let mese = Self.mese(primoMese)
            guard pagamenti[mese] == nil else { continue }
            let mancano = Giorni.calendario.dateComponents([.day], from: Giorni.data(oggi), to: Giorni.data(paga)).day ?? 0
            let testo = switch mancano {
            case ..<0: "Ultimo giorno per pagare la palestra."
            case 0: "Oggi si paga la palestra."
            case 1: "Domani si paga la palestra."
            default: "Tra \(mancano) giorni si paga la palestra."
            }
            return (mese, testo)
        }
        return nil
    }

    func segnaPagato(_ mese: String) {
        stato.pagamenti[mese] = Giorni.oggi()
        Task { await programmaPagamento() }
    }

    func annullaPagamento(_ mese: String) {
        stato.pagamenti[mese] = nil
        Task { await programmaPagamento() }
    }

    // Una sola notifica, il primo giorno utile (giorno scelto o il successivo, all'ora scelta) di un mese non pagato
    func programmaPagamento() async {
        guard !demo else { return }
        Notifiche.cancella(["pagamento"])
        guard stato.pagamentoAttivo,
              let p = Self.prossimoPagamento(dopo: Date(), pagamenti: stato.pagamenti, minuti: stato.oraPagamento, giorno: stato.giornoPagamento)
        else { return }
        await Notifiche.una(id: "pagamento", titolo: "Palestra",
                            testo: p.primo ? "Oggi si paga la palestra." : "Ultimo giorno per pagare la palestra.",
                            quando: p.quando)
    }

    static func prossimoPagamento(dopo ora: Date, pagamenti: [String: String], minuti: Int, giorno: Int = 1) -> (quando: DateComponents, primo: Bool)? {
        let questoMese = Giorni.data(String(Giorni.iso(ora).prefix(8)) + "01")
        for m in 0..<3 {
            guard let mese = Giorni.calendario.date(byAdding: .month, value: m, to: questoMese) else { continue }
            let primoMese = Giorni.iso(mese)
            if pagamenti[Self.mese(primoMese)] != nil { continue }
            let paga = giornoDiPagamento(primoMese, giorno)
            for (k, iso) in [paga, Giorni.aggiungi(paga, 1)].enumerated() {
                var dc = Giorni.calendario.dateComponents([.year, .month, .day], from: Giorni.data(iso))
                dc.hour = minuti / 60
                dc.minute = minuti % 60
                guard let quando = Giorni.calendario.date(from: dc), quando > ora else { continue }
                return (dc, k == 0)
            }
        }
        return nil
    }

    // ---------- Backup della vecchia app Palestra ----------

    // Converte il backup della web app o dell'app Palestra: le serie dello stesso giorno diventano un allenamento
    func importaVecchia(_ dati: Data) throws {
        struct Vecchia: Decodable {
            struct S: Decodable { var date: String; var exercise: String; var kg: Double; var reps: Int }
            struct C: Decodable { var date: String; var type: String; var minutes: Int; var km: Double? }
            var plans: [String: [String]]
            var swap: Bool?
            var exercises: [String]?
            var sets: [S]?
            var cardio: [C]?
            var log: [String: String]?
            var payments: [String: String]?
        }
        let v = try JSONDecoder().decode(Vecchia.self, from: dati)
        var s = stato
        for (k, giorni) in v.plans where giorni.count == 7 {
            s.piani[k] = giorni.map { TipoGiorno(rawValue: $0) ?? .riposo }
        }
        s.scambia = v.swap ?? false
        for nome in v.exercises ?? [] where !s.esercizi.contains(where: { $0.id == nome }) {
            s.esercizi.append(Esercizio(nome: nome, muscolo: .altro, attrezzo: .altro))
        }
        let perGiorno = Dictionary(grouping: v.sets ?? [], by: \.date)
        let giaImportati = Set(s.allenamenti.map(\.giorno))
        for (giorno, serie) in perGiorno where !giaImportati.contains(giorno) {
            var a = Allenamento(nome: "Pesi", inizio: Giorni.data(giorno).addingTimeInterval(18 * 3600))
            a.fine = a.inizio.addingTimeInterval(3600)
            var ordine: [String] = []
            for x in serie where !ordine.contains(x.exercise) { ordine.append(x.exercise) }
            a.esercizi = ordine.map { es in
                EsercizioFatto(esercizio: es, serie: serie.filter { $0.exercise == es }.map { SerieFatta(kg: $0.kg, rip: $0.reps, fatta: true) })
            }
            s.allenamenti.append(a)
        }
        s.allenamenti.sort { $0.inizio < $1.inizio }
        for c in v.cardio ?? [] where !s.cardio.contains(where: { $0.data == c.date && $0.tipo == c.type && $0.minuti == c.minutes }) {
            s.cardio.append(SessioneCardio(data: c.date, tipo: c.type, minuti: c.minutes, km: c.km ?? 0))
        }
        s.saltati = Array(Set(s.saltati + (v.log ?? [:]).filter { $0.value == "saltato" }.map(\.key))).sorted()
        s.pagamenti.merge(v.payments ?? [:]) { a, _ in a }
        stato = s
    }
}

extension StatoPalestra {
    // Scheda da proporre: quella dopo l'ultima fatta (a giro); senza storico la prima
    func prossimaRoutine() -> Routine? {
        guard let ultima = allenamenti.sorted(by: { $0.inizio < $1.inizio }).last(where: { a in routine.contains { $0.id == a.routine } }),
              let i = routine.firstIndex(where: { $0.id == ultima.routine }) else { return routine.first }
        return routine[(i + 1) % routine.count]
    }

    // Record battuti da ogni allenamento (come Palestra.nuoviRecord), in una sola passata
    func conteggioRecord() -> [UUID: Int] {
        var pesoMax: [String: Double] = [:], massimale: [String: Double] = [:]
        var visti: Set<String> = []          // esercizi già comparsi, anche senza serie valide
        var risultato: [UUID: Int] = [:]
        for a in allenamenti.sorted(by: { $0.inizio < $1.inizio }) {
            var n = 0
            // Ogni voce si confronta con i record di prima dell'allenamento, poi si aggiornano
            for e in a.esercizi {
                let valide = e.serie.filter(\.valida)
                guard !valide.isEmpty, visti.contains(e.esercizio) || (pesoMax[e.esercizio] ?? 0) > 0 else { continue }
                let peso = valide.compactMap(\.kg).max() ?? 0
                let mass = valide.map(\.massimale).max() ?? 0
                if peso > pesoMax[e.esercizio] ?? 0 || mass > (massimale[e.esercizio] ?? 0) + 0.01 { n += 1 }
            }
            for e in a.esercizi {
                let valide = e.serie.filter(\.valida)
                visti.insert(e.esercizio)
                pesoMax[e.esercizio] = max(pesoMax[e.esercizio] ?? 0, valide.compactMap(\.kg).max() ?? 0)
                massimale[e.esercizio] = max(massimale[e.esercizio] ?? 0, valide.map(\.massimale).max() ?? 0)
            }
            risultato[a.id] = n
        }
        return risultato
    }
}

extension StatoPalestra {
    // Settimana A o B di una data (sempre A se il piano A/B è spento)
    func settimana(_ iso: String) -> String {
        guard usaAB else { return "A" }
        return (Palestra.numeroSettimana(iso) + (scambia ? 1 : 0)) % 2 == 0 ? "A" : "B"
    }
}
