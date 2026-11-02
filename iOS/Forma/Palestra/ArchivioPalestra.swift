import SwiftUI
import UserNotifications

// Dati della palestra, salvati in un file JSON a ogni modifica
@Observable
final class Palestra {
    var stato: StatoPalestra {
        didSet { if !demo { salva() } }
    }

    let demo: Bool

    init() {
        demo = Avvio.demo
        stato = demo ? StatoPalestra.demo : Self.carica()
    }

    // ---------- File ----------

    private static var fileDati: URL { URL.applicationSupportDirectory.appending(path: "palestra.json") }

    private static func carica() -> StatoPalestra {
        if let d = try? Data(contentsOf: fileDati), let s = try? JSONDecoder().decode(StatoPalestra.self, from: d) { return s }
        return StatoPalestra()
    }

    private func salva() {
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

    func settimana(_ iso: String) -> String {
        (Self.numeroSettimana(iso) + (stato.scambia ? 1 : 0)) % 2 == 0 ? "A" : "B"
    }

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
    @discardableResult
    func termina() -> Allenamento? {
        guard var a = stato.inCorso else { return nil }
        a.fine = Date()
        a.esercizi = a.esercizi.compactMap { e in
            var e = e
            e.serie = e.serie.filter { $0.fatta && ($0.rip ?? 0) > 0 }
            return e.serie.isEmpty ? nil : e
        }
        stato.inCorso = nil
        guard !a.esercizi.isEmpty else { return nil }
        stato.allenamenti.append(a)
        stato.saltati.removeAll { $0 == a.giorno }
        return a
    }

    func annulla() { stato.inCorso = nil }

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

    // Mese da pagare e testo del promemoria, dal 25 al 2 del mese finché non è segnato pagato
    func promemoriaPagamento() -> (mese: String, testo: String)? {
        let oggi = Giorni.oggi()
        let giorno = Giorni.calendario.component(.day, from: Date())
        if giorno > 2 && giorno < 25 { return nil }
        var mese = Self.mese(oggi)
        var testo = "Oggi si paga la palestra (1 o 2 del mese)."
        if giorno >= 25 {
            let primo = Giorni.calendario.date(byAdding: .month, value: 1, to: Giorni.data(String(oggi.prefix(8)) + "01")) ?? Date()
            mese = Self.mese(Giorni.iso(primo))
            let mancano = Giorni.calendario.dateComponents([.day], from: Giorni.data(oggi), to: primo).day ?? 0
            testo = mancano == 1 ? "Domani si paga la palestra (1 o 2 del mese)." : "Tra \(mancano) giorni si paga la palestra (1 o 2 del mese)."
        }
        return stato.pagamenti[mese] == nil ? (mese, testo) : nil
    }

    func segnaPagato(_ mese: String) {
        stato.pagamenti[mese] = Giorni.oggi()
        Task { await programmaPagamento() }
    }

    func annullaPagamento(_ mese: String) {
        stato.pagamenti[mese] = nil
        Task { await programmaPagamento() }
    }

    // Una sola notifica, il primo giorno utile (1 o 2 alle 9:00) di un mese non ancora pagato
    func programmaPagamento() async {
        guard !demo else { return }
        let centro = UNUserNotificationCenter.current()
        centro.removePendingNotificationRequests(withIdentifiers: ["pagamento"])
        let ora = Date()
        let questoMese = Giorni.data(String(Giorni.oggi().prefix(8)) + "01")
        for m in 0..<3 {
            guard let mese = Giorni.calendario.date(byAdding: .month, value: m, to: questoMese) else { continue }
            if stato.pagamenti[Self.mese(Giorni.iso(mese))] != nil { continue }
            for giorno in [1, 2] {
                var dc = Giorni.calendario.dateComponents([.year, .month], from: mese)
                dc.day = giorno
                dc.hour = 9
                guard let quando = Giorni.calendario.date(from: dc), quando > ora else { continue }
                await Notifiche.una(id: "pagamento", titolo: "Palestra",
                                    testo: giorno == 1 ? "Oggi si paga la palestra (1 o 2 del mese)." : "Ultimo giorno per pagare la palestra.",
                                    quando: dc)
                return
            }
        }
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
