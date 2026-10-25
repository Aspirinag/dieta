import SwiftUI
import UserNotifications

// Tiene i dati dell'app e li salva in un file JSON a ogni modifica
@Observable
final class Archivio {
    var stato: Stato {
        didSet { if !demo { salva() } }
    }

    private let demo: Bool

    static let oliPredefiniti = 6       // cucchiaini al giorno
    static let acquaPredefinita = 2.0   // litri al giorno
    static let notePredefinite = "Pane e olio puoi distribuirli come preferisci nella giornata. Puoi sostituire la frutta mantenendo la stessa porzione, ma non con la banana. Puoi invertire giornate intere, non singoli pasti."

    init() {
        demo = Avvio.demo
        var s = demo ? Stato.demo : Self.carica()
        if let p = s.preferito, s.profili[p] != nil { s.attivo = p }
        stato = s
    }

    // ---------- File ----------

    private static var fileDati: URL {
        URL.applicationSupportDirectory.appending(path: "dieta.json")
    }

    // Ordine: file dell'app, poi i dati della prima versione dell'app (Capacitor), poi i profili iniziali
    private static func carica() -> Stato {
        if let d = try? Data(contentsOf: fileDati), let s = try? JSONDecoder().decode(Stato.self, from: d) {
            return s
        }
        if let j = UserDefaults.standard.string(forKey: "CapacitorStorage.dieta:v1"),
           let s = try? JSONDecoder().decode(Stato.self, from: Data(j.utf8)) {
            return s
        }
        return .iniziale
    }

    private func salva() {
        do {
            try FileManager.default.createDirectory(at: URL.applicationSupportDirectory, withIntermediateDirectories: true)
            try backup().write(to: Self.fileDati, options: .atomic)
        } catch {
            print("Salvataggio non riuscito: \(error)")
        }
    }

    func backup() -> Data {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? e.encode(stato)) ?? Data()
    }

    func importa(_ dati: Data) throws {
        stato = try JSONDecoder().decode(Stato.self, from: dati)
    }

    // ---------- Profili ----------

    var profilo: Profilo {
        get { stato.profili[stato.attivo] ?? stato.profili.values.first ?? Profilo(nome: "") }
        set { stato.profili[stato.attivo] = newValue }
    }

    // Il preferito per primo, poi in ordine di nome
    var idProfili: [String] {
        stato.profili.keys.sorted { a, b in
            if a == stato.preferito { return true }
            if b == stato.preferito { return false }
            return (stato.profili[a]?.nome ?? "") < (stato.profili[b]?.nome ?? "")
        }
    }

    func aggiungiProfilo(_ nome: String) {
        let id = "p\(Int(Date().timeIntervalSince1970 * 1000))"
        stato.profili[id] = Profilo(nome: nome)
        stato.attivo = id
    }

    func eliminaProfilo(_ id: String) {
        guard stato.profili.count > 1 else { return }
        stato.profili[id] = nil
        if stato.preferito == id { stato.preferito = nil }
        if stato.attivo == id { stato.attivo = idProfili[0] }
    }

    // ---------- Giorni ----------

    func registro(_ iso: String) -> Registro { profilo.dieta[iso] ?? Registro() }

    func slot(_ iso: String, _ i: Int) -> Slot { registro(iso).slot[String(i)] ?? Slot() }

    func cambiaSlot(_ iso: String, _ i: Int, _ modifica: (inout Slot) -> Void) {
        var r = registro(iso)
        var s = r.slot[String(i)] ?? Slot()
        modifica(&s)
        r.slot[String(i)] = s
        profilo.dieta[iso] = r
    }

    func cambiaRegistro(_ iso: String, _ modifica: (inout Registro) -> Void) {
        var r = registro(iso)
        modifica(&r)
        profilo.dieta[iso] = r
    }

    // ---------- Piani ----------

    // Un nuovo piano chiude quelli aperti il giorno prima della sua data di inizio
    func aggiungiPiano(_ p: Piano) {
        var piani = profilo.piani.filter { !($0.nome == p.nome && $0.dal == p.dal) }
        for i in piani.indices where piani[i].dal < p.dal && (piani[i].al.isEmpty || piani[i].al >= p.dal) {
            piani[i].al = Giorni.aggiungi(p.dal, -1)
        }
        piani.append(p)
        profilo.piani = piani
    }

    // ---------- BIA ----------

    // Aggiunge o sostituisce la misura della stessa data
    func salvaMisura(_ m: Misura) {
        profilo.bia = profilo.bia.filter { $0.data != m.data } + [m]
    }

    // ---------- Lista della spesa ----------

    func spunteSpesa() -> [String: Bool] {
        let lun = Giorni.lunedi(Giorni.oggi())
        return profilo.spesa?.settimana == lun ? profilo.spesa?.presi ?? [:] : [:]
    }

    func spunta(_ chiave: String) {
        let lun = Giorni.lunedi(Giorni.oggi())
        var s = profilo.spesa?.settimana == lun ? profilo.spesa! : Spesa(settimana: lun)
        s.presi[chiave] = !(s.presi[chiave] ?? false)
        profilo.spesa = s
    }

    func azzeraSpesa() { profilo.spesa = nil }

    // ---------- Promemoria ----------

    static let oreAcqua = [10, 12, 14, 16, 18, 20]

    func programmaPromemoria() async {
        guard !demo else { return }
        let centro = UNUserNotificationCenter.current()
        centro.removePendingNotificationRequests(withIdentifiers: Self.oreAcqua.map { "acqua-\($0)" } + ["pasti"])
        let p = stato.promemoria ?? Promemoria()
        if p.acqua {
            for ora in Self.oreAcqua {
                await Notifiche.giornaliera(id: "acqua-\(ora)", titolo: "Acqua 💧", testo: "È il momento di un bicchiere d'acqua.", ora: ora)
            }
        }
        if p.pasti {
            await Notifiche.giornaliera(id: "pasti", titolo: "Dieta", testo: "Hai segnato i pasti di oggi?", ora: 21)
        }
    }
}

extension Profilo {
    var olio: Int { olioTot ?? Archivio.oliPredefiniti }
    var acqua: Double { acquaTot ?? Archivio.acquaPredefinita }
    var testoNote: String { note ?? Archivio.notePredefinite }

    // Piano valido in una data: se più piani la coprono vince quello iniziato più di recente
    func piano(per iso: String) -> Piano? {
        piani
            .filter { $0.dal <= iso && ($0.al.isEmpty || iso <= $0.al) && $0.giorni.count == 7 }
            .max { $0.dal < $1.dal }
    }

    // Percentuale di pasti segnati negli ultimi 7 giorni, oggi escluso
    func aderenza() -> Int? {
        var tot = 0, fatti = 0
        let oggi = Giorni.oggi()
        for k in 1...7 {
            let iso = Giorni.aggiungi(oggi, -k)
            guard let p = piano(per: iso) else { continue }
            for i in p.giorni[Giorni.indice(iso)].pasti.indices {
                tot += 1
                if dieta[iso]?.slot[String(i)]?.fatto == true { fatti += 1 }
            }
        }
        return tot > 0 ? Int((Double(fatti) / Double(tot) * 100).rounded()) : nil
    }

    struct VoceSpesa: Identifiable {
        let chiave: String
        let nome: String
        let quanto: String
        var id: String { chiave }
    }

    // Alimenti della settimana in corso: per ogni pasto vale l'alternativa scelta, altrimenti la prima.
    // Le quantità in g, ml, kg o l si sommano, le altre si contano
    func vociSpesa() -> [VoceSpesa] {
        let lun = Giorni.lunedi(Giorni.oggi())
        var voci: [String: (nome: String, unita: [String: Double], volte: Int)] = [:]
        let regex = #/^(\d+(?:[.,]\d+)?)\s*(g|gr|ml|kg|l)\b/#.ignoresCase()
        for i in 0..<7 {
            let iso = Giorni.aggiungi(lun, i)
            guard let p = piano(per: iso) else { continue }
            for (j, pasto) in p.giorni[i].pasti.enumerated() {
                let scelta = dieta[iso]?.slot[String(j)]?.opt ?? 0
                let opz = pasto.opzioni.indices.contains(scelta) ? pasto.opzioni[scelta] : pasto.opzioni.first
                for a in opz?.alimenti ?? [] {
                    var pulito = a.nome
                    for prefisso in ["Contorno: ", "Secondo: "] where pulito.hasPrefix(prefisso) {
                        pulito.removeFirst(prefisso.count)
                    }
                    pulito = pulito.trimmingCharacters(in: .whitespaces)
                    let nome = pulito.prefix(1).uppercased() + pulito.dropFirst()
                    let k = nome.lowercased()
                    var v = voci[k] ?? (nome: nome, unita: [:], volte: 0)
                    v.volte += 1
                    if let m = a.quantita.firstMatch(of: regex), let n = leggiNumero(String(m.1)) {
                        var u = m.2.lowercased()
                        if u == "gr" { u = "g" }
                        v.unita[u, default: 0] += n
                    }
                    voci[k] = v
                }
            }
        }
        return voci
            .sorted { $0.value.nome.localizedCompare($1.value.nome) == .orderedAscending }
            .map { k, v in
                let volte = v.volte == 1 ? "1 volta" : "\(v.volte) volte"
                let tot = v.unita.sorted { $0.key < $1.key }.map { "\(num($0.value)) \($0.key)" }.joined(separator: " + ")
                return VoceSpesa(chiave: k, nome: v.nome, quanto: tot.isEmpty ? volte : "\(tot) (\(volte))")
            }
    }
}

// Notifiche locali
enum Notifiche {
    static func permesso() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func giornaliera(id: String, titolo: String, testo: String, ora: Int) async {
        let c = UNMutableNotificationContent()
        c.title = titolo
        c.body = testo
        c.sound = .default
        let quando = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: ora, minute: 0), repeats: true)
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: c, trigger: quando))
    }
}

// Mostra le notifiche anche con l'app aperta
final class DelegatoNotifiche: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
