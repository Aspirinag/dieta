import Foundation
import PDFKit

// Esercizio trovato in una scheda letta da PDF
struct VoceLetta: Hashable {
    var esercizio: Esercizio
    var nuovo: Bool          // non è nella libreria: va creato
    var serie: Int
    var ripMin: Int
    var ripMax: Int
    var recupero: Int        // secondi

    // «3 × 8–10»
    var obiettivo: String { ripMin == ripMax ? "\(serie) × \(ripMin)" : "\(serie) × \(ripMin)–\(ripMax)" }
}

struct SchedaLetta: Hashable {
    var nome: String
    var voci: [VoceLetta]
}

// Legge le schede di allenamento dal testo di un PDF. Componente puro: niente file, niente stato
enum LettoreScheda {
    static let recuperoPredefinito = 90

    // Testo di tutte le pagine di un PDF (nil se il file non si apre o non ha testo)
    static func testo(pdf dati: Data) -> String? {
        PDFDocument(data: dati)?.string
    }

    static func leggi(testo: String, libreria: [Esercizio]) -> [SchedaLetta] {
        var schede: [SchedaLetta] = []
        var nuovi: [String: Esercizio] = [:]   // nomi sconosciuti già visti, per non farne due uguali

        var precedente: String?   // riga di solo testo subito prima: può essere l'inizio di un nome andato a capo

        for grezza in pulisci(testo).components(separatedBy: .newlines) {
            let riga = grezza.trimmingCharacters(in: .whitespaces)
            if riga.isEmpty { precedente = nil; continue }
            if apreScheda(riga) {
                schede.append(SchedaLetta(nome: nomeScheda(riga), voci: []))
                precedente = nil
                continue
            }
            let prima = precedente
            precedente = riga
            guard !schede.isEmpty, let (nomeLetto, serie, ripMin, ripMax, recupero) = esercizio(riga) else { continue }
            precedente = nil
            var nome = nomeLetto
            // «Estensioni sopra la testa con» a capo «manubrio 2 10-12»: il nome continua dalla riga prima
            if let prima, nome.first?.isLowercase == true, prima.first?.isUppercase == true,
               !prima.contains(where: \.isNumber), nomeValido(prima + " " + nome) {
                nome = prima + " " + nome
            }
            let chiave = normalizza(nome)
            let trovato = abbina(chiave, libreria: libreria)
            let e: Esercizio, nuovo: Bool
            if let trovato {
                e = trovato; nuovo = false
            } else if let gia = nuovi[chiave] {
                e = gia; nuovo = true
            } else {
                e = Esercizio(nome: nome, muscolo: .altro, attrezzo: .altro)
                nuovi[chiave] = e; nuovo = true
            }
            schede[schede.count - 1].voci.append(VoceLetta(esercizio: e, nuovo: nuovo, serie: serie,
                                                           ripMin: ripMin, ripMax: ripMax, recupero: recupero))
        }
        return schede.filter { !$0.voci.isEmpty }
    }

    // ---------- Testo ----------

    private static func pulisci(_ t: String) -> String {
        var s = t.replacingOccurrences(of: "\u{00A0}", with: " ")
        for (da, a) in [("’", "'"), ("‘", "'"), ("′", "'"), ("“", "\""), ("”", "\""), ("″", "\""), ("''", "\"")] {
            s = s.replacingOccurrences(of: da, with: a)
        }
        return s
    }

    // Minuscole, senza accenti, spazi singoli
    static func normalizza(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "it_IT"))
            .lowercased()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private static func prova(_ modello: String, _ testo: String) -> NSTextCheckingResult? {
        guard let re = try? NSRegularExpression(pattern: modello, options: [.caseInsensitive]) else { return nil }
        return re.firstMatch(in: testo, range: NSRange(testo.startIndex..., in: testo))
    }

    private static func gruppo(_ m: NSTextCheckingResult, _ i: Int, in t: String) -> String? {
        guard let r = Range(m.range(at: i), in: t) else { return nil }
        return String(t[r])
    }

    // ---------- Schede ----------

    private static let giorni = "luned[iì]|marted[iì]|mercoled[iì]|gioved[iì]|venerd[iì]|sabato|domenica"

    private static func apreScheda(_ riga: String) -> Bool {
        prova("^(scheda|allenamento)\\s+([a-z]|\\d{1,2})(?![\\p{L}\\d])", riga) != nil
            || prova("^giorno\\s+([a-z]|\\d{1,2})(?![\\p{L}\\d])", riga) != nil
            || prova("^(\(giorni))(?![\\p{L}])", riga) != nil
    }

    // La riga intera, oppure la parte prima del «—»
    private static func nomeScheda(_ riga: String) -> String {
        for sep in ["—", "–", " - "] {
            if let r = riga.range(of: sep) {
                let prima = riga[..<r.lowerBound].trimmingCharacters(in: .whitespaces)
                if !prima.isEmpty { return prima }
            }
        }
        return riga
    }

    // ---------- Esercizi ----------

    // nome, serie, ripetizioni (min e max), recupero in secondi
    private static func esercizio(_ riga: String) -> (String, Int, Int, Int, Int)? {
        let modello = "^(.+?)\\s+(\\d{1,2})\\s*(?:[x×]\\s*|\\s+)(\\d{1,3})(?:\\s*[-–]\\s*(\\d{1,3}))?(?=\\s|$)(.*)$"
        guard let m = prova(modello, riga),
              let nomeGrezzo = gruppo(m, 1, in: riga),
              let serie = gruppo(m, 2, in: riga).flatMap({ Int($0) }),
              let a = gruppo(m, 3, in: riga).flatMap({ Int($0) }) else { return nil }
        let b = gruppo(m, 4, in: riga).flatMap { Int($0) } ?? a
        let resto = (gruppo(m, 5, in: riga) ?? "").trimmingCharacters(in: .whitespaces)

        let nome = nomeGrezzo.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard nomeValido(nome), (1...20).contains(serie), a >= 1, b >= 1 else { return nil }
        return (nome, serie, min(a, b), max(a, b), recupero(resto) ?? recuperoPredefinito)
    }

    // Un nome è breve e non è una frase
    private static func nomeValido(_ n: String) -> Bool {
        guard n.count <= 60, n.contains(where: \.isLetter), let primo = n.first, !primo.isNumber else { return false }
        if n.hasSuffix(".") || n.hasSuffix(":") || n.hasSuffix(";") || n.contains(". ") || n.contains(": ") { return false }
        return true
    }

    // «1'30"», «1:30», «2 min», «90"», «90s», «2'» (all'inizio di quello che resta della riga)
    static func recupero(_ t: String) -> Int? {
        func n(_ m: NSTextCheckingResult, _ i: Int) -> Int { gruppo(m, i, in: t).flatMap { Int($0) } ?? 0 }
        if let m = prova("^(\\d{1,2})\\s*'(\\d{1,2})\\s*\"?(?![\\d])", t) { return n(m, 1) * 60 + n(m, 2) }
        if let m = prova("^(\\d{1,2}):(\\d{2})(?![\\d])", t) { return n(m, 1) * 60 + n(m, 2) }
        if let m = prova("^(\\d{1,2})\\s*min(?:uti|uto)?(?![\\p{L}])", t) { return n(m, 1) * 60 }
        if let m = prova("^(\\d{1,3})\\s*(?:\"|s(?![\\p{L}])|sec(?![\\p{L}])|secondi(?![\\p{L}]))", t) { return n(m, 1) }
        if let m = prova("^(\\d{1,2})\\s*'", t) { return n(m, 1) * 60 }
        return nil
    }

    // ---------- Libreria ----------

    // Prima il nome identico, poi il nome più lungo della libreria contenuto in quello letto
    private static func abbina(_ chiave: String, libreria: [Esercizio]) -> Esercizio? {
        func nomi(_ e: Esercizio) -> [String] { [normalizza(e.nome), normalizza(e.titolo)] }
        if let e = libreria.first(where: { nomi($0).contains(chiave) }) { return e }
        var migliore: (Esercizio, Int)?
        for e in libreria {
            for n in nomi(e) where !n.isEmpty && " \(chiave) ".contains(" \(n) ") {
                if n.count > (migliore?.1 ?? 0) { migliore = (e, n.count) }
            }
        }
        return migliore?.0
    }
}
