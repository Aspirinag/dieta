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
    // Il file dati c'è ma non si è potuto leggere: in questa sessione non si salva niente
    @ObservationIgnored private(set) var salvataggioBloccato = false
    // Nessun dato salvato: è la prima apertura dell'app
    @ObservationIgnored private(set) var primaApertura = false

    static let oliPredefiniti = 6       // cucchiaini al giorno
    static let acquaPredefinita = 2.0   // litri al giorno
    static let notePredefinite = "Pane e olio puoi distribuirli come preferisci nella giornata. Puoi sostituire la frutta mantenendo la stessa porzione, ma non con la banana. Puoi invertire giornate intere, non singoli pasti."

    init() {
        demo = Avvio.demo
        var illeggibile: URL?
        var s = demo ? Stato.demo : Self.carica(&illeggibile)
        salvataggioBloccato = illeggibile?.path == "/bloccato"
        fileIlleggibile = salvataggioBloccato ? nil : illeggibile
        primaApertura = !demo && illeggibile == nil && s == .iniziale
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
        case .bloccato:
            illeggibile = URL(fileURLWithPath: "/bloccato")
            return .iniziale
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
        guard !salvataggioBloccato else { return }
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
    // Peso di oggi dal foglio veloce di Oggi
    func salvaPeso(_ kg: Double, il giorno: String = Giorni.oggi()) {
        profilo.bia = PesoVeloce.registra(kg, il: giorno, in: profilo.bia)
    }

    func salvaMisura(_ m: Misura) {
        profilo.bia = profilo.bia.filter { $0.data != m.data } + [m]
    }

    // ---------- Lista della spesa ----------

    func spunteSpesa(lunedi lun: String) -> [String: Bool] { profilo.spunteSpesa(lunedi: lun) }
    func spunta(_ chiave: String, lunedi lun: String) { profilo.spunta(chiave, lunedi: lun) }
    func azzeraSpesa(lunedi lun: String) { profilo.azzeraSpesa(lunedi: lun) }

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
        Notifiche.registraLingua()
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
        cambiaPiani(giorniDa: p.dal, al: p.al) { Self.inserisci(p, in: $0) }
    }

    // Piano modificato a mano: prende il posto dell'originale con le stesse regole di un piano nuovo
    // (sostituisce quello che inizia lo stesso giorno, chiude quelli aperti prima); le spunte seguono il nome del pasto
    mutating func sostituisciPiano(_ originale: Piano, con nuovo: Piano) {
        let dal = min(originale.dal, nuovo.dal)
        cambiaPiani(giorniDa: dal, al: "") { piani in
            Self.inserisci(nuovo, in: piani.filter { $0.id != originale.id })
        }
    }

    private static func inserisci(_ p: Piano, in piani: [Piano]) -> [Piano] {
        var nuovi = piani.filter { $0.dal != p.dal }
        for i in nuovi.indices where nuovi[i].dal < p.dal && (nuovi[i].al.isEmpty || nuovi[i].al >= p.dal) {
            nuovi[i].al = Giorni.aggiungi(p.dal, -1)
        }
        nuovi.append(p)
        return nuovi
    }

    // Chiave di ogni pasto: nome (senza spazi e maiuscole) e quante volte è già comparso,
    // così il secondo "Spuntino" corrisponde al secondo "Spuntino"
    static func chiaviPasti(_ pasti: [Pasto]) -> [String] {
        var visti: [String: Int] = [:]
        return pasti.map { p in
            let n = p.nome.trimmingCharacters(in: .whitespaces).lowercased()
            visti[n, default: 0] += 1
            return "\(n)#\(visti[n]!)"
        }
    }

    // Piano già presente che inizia la stessa data (quello nuovo lo sostituirebbe)
    func pianoConStessaData(_ dal: String, escluso: Piano?) -> Piano? {
        piani.first { $0.dal == dal && $0.id != escluso?.id }
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
            let nomiVecchi = Self.chiaviPasti(vecchio.giorni[g].pasti)
            let nomiNuovi = Self.chiaviPasti(nuovo.giorni[g].pasti)
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
        let quanto: String              // vuoto per le voci aggiunte a mano
        let reparto: Reparto
        let giorni: [(giorno: String, quanto: String)]
        let aggiunta: Bool
        var id: String { chiave }
    }

    // Settimana proposta per la spesa: da venerdì si pensa già alla prossima
    static func lunediSpesa(oggi: String) -> String {
        let lun = Giorni.lunedi(oggi)
        return Giorni.indice(oggi) >= 4 ? Giorni.aggiungi(lun, 7) : lun
    }

    // Reparto scelto a mano, altrimenti stimato dal nome
    func reparto(di chiave: String) -> Reparto {
        let k = chiave.lowercased()
        return repartiSpesa?[k].flatMap(Reparto.init(rawValue:)) ?? Reparto.indovina(k)
    }

    mutating func sposta(_ chiave: String, in r: Reparto) {
        var m = repartiSpesa ?? [:]
        m[chiave.lowercased()] = r.rawValue
        repartiSpesa = m
    }

    // Falso se il nome è vuoto o è già nella lista (tra i prodotti del piano o tra gli extra)
    @discardableResult
    mutating func aggiungiExtra(_ nome: String, lunedi lun: String) -> Bool {
        let pulito = nome.trimmingCharacters(in: .whitespaces)
        // Maiuscole e accenti non contano («caffe» è già «Caffè»), come in Reparto.indovina
        let piega: (String) -> String = { $0.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil) }
        guard !pulito.isEmpty, !vociSpesa(lunedi: lun).contains(where: { piega($0.chiave) == piega(pulito) }) else { return false }
        var settimane = settimaneSpesa
        if !settimane.contains(where: { $0.settimana == lun }) { settimane.append(Spesa(settimana: lun)) }
        guard let i = settimane.firstIndex(where: { $0.settimana == lun }) else { return false }
        settimane[i].extra.append(pulito)
        salvaSettimane(settimane)
        return true
    }

    // Senza prodotti dal piano (la lista è vuota o ha solo le voci aggiunte a mano)
    static func senzaPiano(_ voci: [VoceSpesa]) -> Bool { voci.allSatisfy(\.aggiunta) }

    // Se l'app resta aperta oltre la mezzanotte la settimana proposta si aggiorna; in uno stesso giorno resta quella scelta
    static func settimanaSpesaAggiornata(corrente: String, ultimoOggi: String, oggi: String) -> String {
        oggi == ultimoOggi ? corrente : lunediSpesa(oggi: oggi)
    }

    // Toglie le spunte di tutte le settimane e tiene le settimane e le voci aggiunte a mano
    mutating func togliSpunte() {
        spesa?.presi = [:]
        spesaProssima?.presi = [:]
    }

    mutating func togliExtra(_ nome: String, lunedi lun: String) {
        var settimane = settimaneSpesa
        guard let i = settimane.firstIndex(where: { $0.settimana == lun }) else { return }
        settimane[i].extra.removeAll { $0.lowercased() == nome.lowercased() }
        salvaSettimane(settimane)
    }

    // Quantità somma di grammi/millilitri (kg e l si convertono), sempre a numeri interi nelle unità piccole;
    // senza quantità in g o ml l'alimento è «a piacere» (non si compra a porzioni)
    // Le unità restano metriche in ogni lingua; cambiano solo il separatore decimale e le parole
    private static func testoQuantita(_ unita: [String: Double], porzioni: Int, locale: Locale) -> String {
        var parti: [String] = []
        if let g = unita["g"] { parti.append(g >= 1000 ? "\(num(g / 1000, locale: locale)) kg" : "\(num(g.rounded(), locale: locale)) g") }
        if let ml = unita["ml"] { parti.append(ml >= 1000 ? "\(num(ml / 1000, locale: locale)) L" : "\(num(ml.rounded(), locale: locale)) ml") }
        if !parti.isEmpty { return parti.joined(separator: " + ") }
        return String(localized: "a piacere", locale: locale)
    }

    // Alimenti della settimana: per ogni pasto vale l'alternativa scelta, altrimenti la prima.
    // Le quantità in g, ml, kg o l si sommano, le altre si contano come porzioni
    func vociSpesa(lunedi lun: String, locale: Locale = .current) -> [VoceSpesa] {
        struct Somma { var unita: [String: Double] = [:]; var volte = 0 }
        var voci: [String: (nome: String, tot: Somma, giorni: [Int: Somma])] = [:]
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
                    var v = voci[k] ?? (nome: nome, tot: Somma(), giorni: [:])
                    var g = v.giorni[i] ?? Somma()
                    v.tot.volte += 1
                    g.volte += 1
                    if let m = a.quantita.firstMatch(of: regex), var n = leggiNumero(String(m.1)) {
                        var u = m.2.lowercased()
                        if u == "gr" { u = "g" }
                        if u == "kg" { u = "g"; n *= 1000 }
                        if u == "l" { u = "ml"; n *= 1000 }
                        v.tot.unita[u, default: 0] += n
                        g.unita[u, default: 0] += n
                    }
                    v.giorni[i] = g
                    voci[k] = v
                }
            }
        }
        var risultato = voci
            .sorted { $0.value.nome.localizedCompare($1.value.nome) == .orderedAscending }
            .map { k, v in
                VoceSpesa(chiave: k, nome: v.nome,
                          quanto: Self.testoQuantita(v.tot.unita, porzioni: v.tot.volte, locale: locale),
                          reparto: reparto(di: k),
                          giorni: v.giorni.sorted { $0.key < $1.key }.map { (Giorni.sigla($0.key), Self.testoQuantita($0.value.unita, porzioni: $0.value.volte, locale: locale)) },
                          aggiunta: false)
            }
        if let sett = settimaneSpesa.first(where: { $0.settimana == lun }) {
            for nome in sett.extra.sorted(by: { $0.localizedStandardCompare($1) == .orderedAscending }) {
                let k = nome.lowercased()
                guard !risultato.contains(where: { $0.chiave == k }) else { continue }
                risultato.append(VoceSpesa(chiave: k, nome: nome, quanto: "", reparto: repartiSpesa?[k].flatMap(Reparto.init(rawValue:)) ?? .altro, giorni: [], aggiunta: true))
            }
        }
        return risultato
    }
}

// Spunte della spesa: si tengono le due settimane più recenti (di solito questa e la prossima)
extension Profilo {
    var settimaneSpesa: [Spesa] { [spesa, spesaProssima].compactMap { $0 } }

    func spunteSpesa(lunedi lun: String) -> [String: Bool] {
        settimaneSpesa.first { $0.settimana == lun }?.presi ?? [:]
    }

    mutating func spunta(_ chiave: String, lunedi lun: String) {
        var settimane = settimaneSpesa
        if !settimane.contains(where: { $0.settimana == lun }) { settimane.append(Spesa(settimana: lun)) }
        if let i = settimane.firstIndex(where: { $0.settimana == lun }) {
            settimane[i].presi[chiave] = !(settimane[i].presi[chiave] ?? false)
        }
        salvaSettimane(settimane)
    }

    // Toglie le spunte di quella settimana e tiene le sue voci aggiunte a mano
    mutating func azzeraSpesa(lunedi lun: String) {
        var settimane = settimaneSpesa
        guard let i = settimane.firstIndex(where: { $0.settimana == lun }) else { return }
        settimane[i].presi = [:]
        if settimane[i].extra.isEmpty { settimane.remove(at: i) }
        salvaSettimane(settimane)
    }

    mutating func salvaSettimane(_ settimane: [Spesa]) {
        let ultime = settimane.sorted { $0.settimana < $1.settimana }.suffix(2)
        spesa = ultime.first
        spesaProssima = ultime.count > 1 ? ultime.last : nil
    }
}
