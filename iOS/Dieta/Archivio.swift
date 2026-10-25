import SwiftUI
import UserNotifications

// Tiene i dati dell'app e li salva in un file JSON dopo ogni modifica
@Observable
final class Archivio {
    var stato: Stato {
        didSet { if !demo { programmaSalvataggio() } }
    }

    // Messaggio da mostrare se il file dei dati non si riesce a scrivere
    var erroreSalvataggio: String?

    private let demo: Bool
    @ObservationIgnored private var salvataggio: Task<Void, Never>?

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

    // Le modifiche ravvicinate (es. lo stepper dell'acqua) si salvano insieme, poco dopo l'ultima
    private func programmaSalvataggio() {
        salvataggio?.cancel()
        salvataggio = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            salva()
        }
    }

    // Quando l'app va in secondo piano: salva subito ciò che è in attesa
    func salvaSubito() {
        guard salvataggio != nil else { return }
        salvataggio?.cancel()
        salva()
    }

    private func salva() {
        salvataggio = nil
        do {
            try FileManager.default.createDirectory(at: URL.applicationSupportDirectory, withIntermediateDirectories: true)
            try backup().write(to: Self.fileDati, options: .atomic)
        } catch {
            erroreSalvataggio = "Non riesco a salvare i dati (\(error.localizedDescription)). Le ultime modifiche potrebbero andare perse: esporta un backup da Dati."
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

    // Una sola lista per tutti i profili: alimenti sommati e spunte condivise.
    // Una spunta vale 7 giorni da quando è messa, come il periodo della lista
    func spunteSpesa() -> [String: Bool] {
        let limite = Giorni.aggiungi(Giorni.oggi(), -6)
        return (stato.spunte ?? [:]).filter { $0.value >= limite }.mapValues { _ in true }
    }

    func spunta(_ chiave: String) {
        var s = (stato.spunte ?? [:]).filter { $0.value >= Giorni.aggiungi(Giorni.oggi(), -6) }
        s[chiave] = s[chiave] == nil ? Giorni.oggi() : nil
        stato.spunte = s
    }

    func azzeraSpesa() { stato.spunte = nil }

    // Profili che hanno un piano nei 7 giorni della lista, nell'ordine del menu
    var profiliSpesa: [Profilo] {
        idProfili.compactMap { stato.profili[$0] }
            .filter { p in Giorni.prossimi7().contains { p.piano(per: $0) != nil } }
    }

    func vociSpesa() -> [VoceSpesa] {
        let profili = profiliSpesa
        var voci: [String: (nome: String, conti: [Profilo.Conto])] = [:]
        for p in profili {
            for (k, c) in p.alimentiSettimana() {
                voci[k, default: (nome: c.nome, conti: [])].conti.append(c)
            }
        }
        return voci
            .sorted { $0.value.nome.localizedCompare($1.value.nome) == .orderedAscending }
            .map { k, v in
                var totale = Profilo.Conto(nome: v.nome, profilo: "")
                for c in v.conti {
                    totale.qb = totale.qb || c.qb
                    totale.unita.merge(c.unita, uniquingKeysWith: +)
                }
                // Con più profili si vede anche quanto serve a ciascuno (non se è solo «q.b.»)
                let dettaglio = profili.count > 1 && !totale.unita.isEmpty ? v.conti.map { "\($0.profilo) \($0.quanto)" }.joined(separator: " · ") : nil
                return VoceSpesa(chiave: k, nome: v.nome, quanto: totale.quanto, dettaglio: dettaglio,
                                 reparto: Calorie.voce(v.nome)?.reparto ?? .altro)
            }
    }

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

    // Il primo piano che inizia dopo questa data (caricato in anticipo)
    func prossimoPiano(dopo iso: String) -> Piano? {
        piani.filter { $0.dal > iso && $0.giorni.count == 7 }.min { $0.dal < $1.dal }
    }

    // Calorie stimate di un giorno: previste (alternative scelte e olio del piano) e dei pasti segnati (con l'olio segnato)
    func calorie(_ iso: String) -> (previste: Double, segnate: Double)? {
        guard let p = piano(per: iso) else { return nil }
        let r = dieta[iso] ?? Registro()
        var previste = Double(olio) * Calorie.kcalCucchiainoOlio
        var segnate = Double(r.olio) * Calorie.kcalCucchiainoOlio
        for (i, pasto) in p.giorni[Giorni.indice(iso)].pasti.enumerated() {
            let s = r.slot[String(i)] ?? Slot()
            guard let o = pasto.opzioni.indices.contains(s.opt) ? pasto.opzioni[s.opt] : pasto.opzioni.first else { continue }
            previste += o.kcal
            if s.fatto { segnate += o.kcal }
        }
        return (previste, segnate)
    }

    // Quota (0…1) dei pasti segnati in un giorno; nil se quel giorno non c'è un piano
    func quotaSegnata(_ iso: String) -> Double? {
        guard let p = piano(per: iso) else { return nil }
        let pasti = p.giorni[Giorni.indice(iso)].pasti
        guard !pasti.isEmpty else { return nil }
        return Double(pasti.indices.filter { dieta[iso]?.slot[String($0)]?.fatto == true }.count) / Double(pasti.count)
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

    // Quanto serve di un alimento nella settimana (a un profilo o a tutti)
    // Quanto serve di un alimento (a un profilo o a tutti): quantità sommate per unità,
    // es. «420 g», «2,1 kg + 3 pezzi», «4 cucchiaini»; «q.b.» se non c'è niente da pesare o contare
    struct Conto {
        let nome: String
        let profilo: String
        var unita: [String: Double] = [:]
        var qb = false

        static let ordine = ["kg", "g", "l", "ml", "pezzi", "fette", "cucchiai", "cucchiaini"]
        static let singolare = ["fette": "fetta", "cucchiai": "cucchiaio", "cucchiaini": "cucchiaino"]

        var quanto: String {
            var u = unita
            // Se l'alimento compare sia a peso sia a pezzi, i pezzi diventano grammi (peso medio di un pezzo)
            if let pz = u["pezzi"], u["g"] != nil || u["kg"] != nil, let v = Calorie.voce(nome) {
                u["g", default: 0] += pz * v.pezzo
                u["pezzi"] = nil
            }
            // Grammi e millilitri passano a kg e litri da 1000 in su
            for (piccola, grande) in [("g", "kg"), ("ml", "l")] {
                if let v = u[piccola], v + (u[grande] ?? 0) * 1000 >= 1000 {
                    u[grande, default: 0] += v / 1000
                    u[piccola] = nil
                }
            }
            // I pezzi si scrivono «×5» accanto al nome (5 banane, 5 panini): «5 pezzi» non diceva di cosa
            let parti = Self.ordine.compactMap { k in
                u[k].map { v in k == "pezzi" ? "×\(num(v))" : "\(num(v)) \(v == 1 ? Self.singolare[k] ?? k : k)" }
            }
            return (parti + (qb ? ["q.b."] : [])).joined(separator: " + ")
        }

        // Dalla quantità dello schema vale la prima alternativa: «40g/120g» = 40 g (da secco), «100ml o n°1» = 100 ml
        mutating func aggiungi(_ quantita: String) {
            let q = quantita.lowercased()
            let prima = (q.split(separator: "/").first.map(String.init) ?? q).components(separatedBy: " o ").first ?? q
            if let m = prima.firstMatch(of: #/(\d+(?:[.,]\d+)?)\s*(kg|gr|g|ml|l)\b/#), let n = leggiNumero(String(m.1)) {
                unita[m.2 == "gr" ? "g" : String(m.2), default: 0] += n
            } else if let m = prima.firstMatch(of: #/n°?\s*(\d+)\s*([a-z]*)/#), let n = Double(m.1) {
                let parola = String(m.2)
                let u = parola.hasPrefix("cucchiain") ? "cucchiaini" : parola.hasPrefix("cucchia") ? "cucchiai"
                    : parola.hasPrefix("fett") ? "fette" : "pezzi"
                unita[u, default: 0] += n
            } else {
                qb = true
            }
        }
    }

    // Alimenti dei prossimi 7 giorni, oggi compreso (non da lunedì: un piano che inizia a metà
    // settimana coprirebbe solo pochi giorni). Per ogni pasto vale l'alternativa scelta, altrimenti la prima.
    // Le quantità in g, ml, kg o l si sommano, le altre si contano
    func alimentiSettimana() -> [String: Conto] {
        var voci: [String: Conto] = [:]
        for iso in Giorni.prossimi7() {
            guard let p = piano(per: iso) else { continue }
            for (j, pasto) in p.giorni[Giorni.indice(iso)].pasti.enumerated() {
                let scelta = dieta[iso]?.slot[String(j)]?.opt ?? 0
                let opz = pasto.opzioni.indices.contains(scelta) ? pasto.opzioni[scelta] : pasto.opzioni.first
                // Senza quantità è il titolo di un piatto: i suoi ingredienti sono nelle righe sotto
                for a in opz?.alimenti ?? [] where !a.quantita.trimmingCharacters(in: .whitespaces).isEmpty {
                    var pulito = a.nome
                    for prefisso in ["Contorno: ", "Secondo: "] where pulito.hasPrefix(prefisso) {
                        pulito.removeFirst(prefisso.count)
                    }
                    pulito = pulito.trimmingCharacters(in: .whitespaces)
                    let nome = pulito.prefix(1).uppercased() + pulito.dropFirst()
                    // Nomi quasi uguali nello schema diventano una voce sola («Verdura a scelta» e «Verdure a scelta»)
                    let k = nome.lowercased()
                        .replacingOccurrences(of: "verdura ", with: "verdure ")
                        .replacingOccurrences(of: " e ", with: ", ")
                    var v = voci[k] ?? Conto(nome: nome, profilo: self.nome)
                    v.aggiungi(a.quantita)
                    voci[k] = v
                }
            }
        }
        return voci
    }
}

struct VoceSpesa: Identifiable {
    let chiave: String
    let nome: String
    let quanto: String
    var dettaglio: String?
    var reparto = Calorie.Reparto.altro
    var id: String { chiave }
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
