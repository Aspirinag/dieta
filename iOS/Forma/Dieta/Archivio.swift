import SwiftUI
import UserNotifications

// Tiene i dati dell'app e li salva in un file JSON a ogni modifica
@Observable
final class Archivio {
    var stato: Stato {
        didSet { if !demo { programmaSalvataggio() } }
    }

    private let demo: Bool
    // Copia del file dati che all'avvio non si leggeva (l'app è ripartita senza toccarlo)
    @ObservationIgnored private(set) var fileIlleggibile: URL?

    static let oliPredefiniti = 6       // cucchiaini al giorno
    static let acquaPredefinita = 2.0   // litri al giorno
    static let notePredefinite = "Pane e olio puoi distribuirli come preferisci nella giornata. Puoi sostituire la frutta mantenendo la stessa porzione, ma non con la banana. Puoi invertire giornate intere, non singoli pasti."

    init() {
        demo = Avvio.demo
        var illeggibile: URL?
        var s = demo ? Stato.demo : Self.carica(&illeggibile)
        fileIlleggibile = illeggibile
        if let p = s.preferito, s.profili[p] != nil { s.attivo = p }
        stato = s
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

    private static var fileDati: URL {
        URL.applicationSupportDirectory.appending(path: "dieta.json")
    }

    // Ordine: file dell'app, poi i dati della prima versione dell'app (Capacitor), poi i profili iniziali
    private static func carica(_ illeggibile: inout URL?) -> Stato {
        switch FileDati.leggi(fileDati, come: Stato.self) {
        case .ok(let s): return s
        case .illeggibile(let copia):
            illeggibile = copia
            return .iniziale
        case .assente: break
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
        stato.profili[id] = Profilo(nome: nome, note: "")
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

    func aggiungiPiano(_ p: Piano) { profilo.aggiungiPiano(p) }

    // ---------- BIA ----------

    // Aggiunge o sostituisce la misura della stessa data
    func salvaMisura(_ m: Misura) {
        profilo.bia = profilo.bia.filter { $0.data != m.data } + [m]
    }

    // ---------- Lista della spesa ----------

    // Le spunte valgono per una settimana alla volta (quella dell'ultima spunta)
    func spunteSpesa(lunedi lun: String) -> [String: Bool] {
        return profilo.spesa?.settimana == lun ? profilo.spesa?.presi ?? [:] : [:]
    }

    func spunta(_ chiave: String, lunedi lun: String) {
        var s = profilo.spesa?.settimana == lun ? profilo.spesa! : Spesa(settimana: lun)
        s.presi[chiave] = !(s.presi[chiave] ?? false)
        profilo.spesa = s
    }

    func azzeraSpesa() { profilo.spesa = nil }

    // ---------- Promemoria ----------

    // Una programmazione alla volta: se ne parte un'altra aspetta la precedente,
    // così non restano promemoria con orari vecchi
    @ObservationIgnored private var programmazione: Task<Void, Never>?

    func programmaPromemoria() async {
        guard !demo else { return }
        let precedente = programmazione
        let t = Task { await precedente?.value; await eseguiProgrammazione() }
        programmazione = t
        await t.value
    }

    private func eseguiProgrammazione() async {
        let centro = UNUserNotificationCenter.current()
        // Toglie tutti i promemoria della dieta, anche quelli con orari vecchi
        let vecchi = await centro.pendingNotificationRequests().map(\.identifier)
            .filter { $0 == "mattino" || $0 == "pasti" || $0.hasPrefix("acqua-") }
        centro.removePendingNotificationRequests(withIdentifiers: vecchi)
        for n in (stato.promemoria ?? Promemoria()).notifiche {
            await Notifiche.giornaliera(id: n.id, titolo: n.titolo, testo: n.testo, minuti: n.minuti)
        }
    }
}

extension Profilo {
    var olio: Int { olioTot ?? Archivio.oliPredefiniti }
    var acqua: Double { acquaTot ?? Archivio.acquaPredefinita }
    var testoNote: String { note ?? Archivio.notePredefinite }

    // Piano valido in una data: se più piani la coprono vince quello iniziato più di recente
    // (a parità di data, l'ultimo aggiunto)
    func piano(per iso: String) -> Piano? {
        var scelto: Piano?
        for p in piani where p.dal <= iso && (p.al.isEmpty || iso <= p.al) && p.giorni.count == 7 {
            if scelto == nil || p.dal >= scelto!.dal { scelto = p }
        }
        return scelto
    }

    // Un nuovo piano chiude quelli aperti il giorno prima della sua data di inizio e sostituisce
    // quelli che iniziano lo stesso giorno. Le spunte dei giorni già segnati da lì in poi
    // seguono il nome del pasto (le spunte sono salvate per posizione)
    mutating func aggiungiPiano(_ p: Piano) {
        cambiaPiani(giorniDa: p.dal, al: p.al) { piani in
            var nuovi = piani.filter { $0.dal != p.dal }
            for i in nuovi.indices where nuovi[i].dal < p.dal && (nuovi[i].al.isEmpty || nuovi[i].al >= p.dal) {
                nuovi[i].al = Giorni.aggiungi(p.dal, -1)
            }
            nuovi.append(p)
            return nuovi
        }
    }

    // Piano modificato a mano: prende il posto dell'originale, le spunte seguono il nome del pasto
    mutating func sostituisciPiano(_ originale: Piano, con nuovo: Piano) {
        let dal = min(originale.dal, nuovo.dal)
        let al = originale.al.isEmpty || nuovo.al.isEmpty ? "" : max(originale.al, nuovo.al)
        cambiaPiani(giorniDa: dal, al: al) { piani in
            piani.map { $0.id == originale.id ? nuovo : $0 }
        }
    }

    // Cambia l'elenco dei piani e rimappa per nome del pasto le spunte dei giorni nell'intervallo
    // (le spunte sono salvate per posizione del pasto)
    private mutating func cambiaPiani(giorniDa dal: String, al: String, _ cambia: ([Piano]) -> [Piano]) {
        let giorni = dieta.keys.filter { $0 >= dal && (al.isEmpty || $0 <= al) }
        let prima = Dictionary(uniqueKeysWithValues: giorni.map { ($0, piano(per: $0)) })
        piani = cambia(piani)
        for iso in giorni {
            guard var r = dieta[iso], let vecchio = prima[iso] ?? nil, let nuovo = piano(per: iso) else { continue }
            let g = Giorni.indice(iso)
            let nomiVecchi = vecchio.giorni[g].pasti.map(\.nome)
            let nomiNuovi = nuovo.giorni[g].pasti.map(\.nome)
            guard nomiVecchi != nomiNuovi else { continue }
            var slot: [String: Slot] = [:]
            for (k, s) in r.slot {
                guard let i = Int(k), nomiVecchi.indices.contains(i),
                      let j = nomiNuovi.firstIndex(of: nomiVecchi[i]) else { continue }
                slot[String(j)] = s
            }
            r.slot = slot
            dieta[iso] = r
        }
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
    // Settimana proposta per la spesa: da venerdì si pensa già alla prossima
    static func lunediSpesa(oggi: String) -> String {
        let lun = Giorni.lunedi(oggi)
        return Giorni.indice(oggi) >= 4 ? Giorni.aggiungi(lun, 7) : lun
    }

    func vociSpesa(lunedi lun: String) -> [VoceSpesa] {
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
