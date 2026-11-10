import SwiftUI

// Date come nella web app: stringhe yyyy-MM-dd nel fuso del telefono, settimana da lunedì
enum Giorni {
    // Lunedì = 0 … Domenica = 6. I testi da mostrare sono nel catalogo delle stringhe;
    // `nomi` sono i valori salvati nel JSON della dieta e restano in italiano
    static let nomi = ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"]

    static var iniziali: [String] { (0..<7).map(iniziale) }

    static func iniziale(_ i: Int) -> String {
        switch i {
        case 0: String(localized: "iniziale-lun", defaultValue: "L", comment: "Iniziale di lunedì")
        case 1: String(localized: "iniziale-mar", defaultValue: "M", comment: "Iniziale di martedì")
        case 2: String(localized: "iniziale-mer", defaultValue: "M", comment: "Iniziale di mercoledì")
        case 3: String(localized: "iniziale-gio", defaultValue: "G", comment: "Iniziale di giovedì")
        case 4: String(localized: "iniziale-ven", defaultValue: "V", comment: "Iniziale di venerdì")
        case 5: String(localized: "iniziale-sab", defaultValue: "S", comment: "Iniziale di sabato")
        default: String(localized: "iniziale-dom", defaultValue: "D", comment: "Iniziale di domenica")
        }
    }

    static func nomeGiorno(_ i: Int) -> String {
        switch i {
        case 0: String(localized: "Lunedì")
        case 1: String(localized: "Martedì")
        case 2: String(localized: "Mercoledì")
        case 3: String(localized: "Giovedì")
        case 4: String(localized: "Venerdì")
        case 5: String(localized: "Sabato")
        default: String(localized: "Domenica")
        }
    }

    // Tre lettere minuscole: lun · mar … (Mon · Tue … in inglese)
    static func sigla(_ i: Int) -> String {
        switch i {
        case 0: String(localized: "sigla-lun", defaultValue: "lun", comment: "Sigla di lunedì")
        case 1: String(localized: "sigla-mar", defaultValue: "mar", comment: "Sigla di martedì")
        case 2: String(localized: "sigla-mer", defaultValue: "mer", comment: "Sigla di mercoledì")
        case 3: String(localized: "sigla-gio", defaultValue: "gio", comment: "Sigla di giovedì")
        case 4: String(localized: "sigla-ven", defaultValue: "ven", comment: "Sigla di venerdì")
        case 5: String(localized: "sigla-sab", defaultValue: "sab", comment: "Sigla di sabato")
        default: String(localized: "sigla-dom", defaultValue: "dom", comment: "Sigla di domenica")
        }
    }

    // Creato a ogni uso: segue il fuso e la lingua attuali anche se cambiano con l'app aperta
    static var calendario: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.locale = .current
        c.timeZone = .autoupdatingCurrent
        c.firstWeekday = 2
        return c
    }

    static func iso(_ data: Date) -> String {
        let c = calendario.dateComponents([.year, .month, .day], from: data)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func data(_ iso: String) -> Date {
        let p = iso.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return Date() }
        return calendario.date(from: DateComponents(year: p[0], month: p[1], day: p[2])) ?? Date()
    }

    static func oggi() -> String { oggi(argomenti: Avvio.argomenti) }

    // Con `-demo -oggi AAAA-MM-GG` la data è fissa: serve ai test dell'interfaccia, che altrimenti
    // dipenderebbero dal giorno della settimana in cui girano. Fuori dalla demo conta solo l'orologio
    static func oggi(argomenti: [String]) -> String {
        if argomenti.contains("-demo"), let i = argomenti.firstIndex(of: "-oggi"), i + 1 < argomenti.count {
            let v = argomenti[i + 1]
            if v.count == 10, iso(data(v)) == v { return v }
        }
        return iso(Date())
    }

    static func aggiungi(_ iso: String, _ giorni: Int) -> String {
        Self.iso(calendario.date(byAdding: .day, value: giorni, to: data(iso)) ?? Date())
    }

    // Lunedì = 0 … Domenica = 6
    static func indice(_ iso: String) -> Int {
        (calendario.component(.weekday, from: data(iso)) + 5) % 7
    }

    static func lunedi(_ iso: String) -> String { aggiungi(iso, -indice(iso)) }

    // Giorno da tenere scelto in Dieta quando l'app si riapre: oggi se si guardava il vecchio «oggi»
    // o un giorno di un'altra settimana, altrimenti resta quello scelto
    static func giornoScelto(_ scelto: String, ultimoOggi: String, oggi: String) -> String {
        scelto == ultimoOggi || lunedi(scelto) != lunedi(oggi) ? oggi : scelto
    }

    // Data breve nel formato del telefono: 04/11/2026 in Italia, 11/4/2026 negli Stati Uniti.
    // Solo per campi stretti già esistenti: per i testi nuovi usare Testi.data (vedi Stile.swift)
    static func breve(_ iso: String, locale: Locale = .current) -> String {
        guard iso.split(separator: "-").count == 3 else { return iso }
        return data(iso).formatted(Date.FormatStyle(date: .numeric, time: .omitted).locale(locale))
    }
}

// Numeri nel formato del telefono, senza decimali inutili: 81,1 · 80 · 0,25 (in inglese 81.1)
func num(_ v: Double?, locale: Locale = .current) -> String {
    guard let v else { return "–" }
    return FormatoNumeri.formatter(locale).string(from: NSNumber(value: (v * 100).rounded() / 100)) ?? String(v)
}

// Un formatter per lingua, creato una volta sola
enum FormatoNumeri {
    private static var cache: [String: NumberFormatter] = [:]

    static func formatter(_ locale: Locale) -> NumberFormatter {
        if let f = cache[locale.identifier] { return f }
        let f = NumberFormatter()
        f.locale = locale
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        cache[locale.identifier] = f
        return f
    }
}

// Peso in chili: sempre metrico, anche con il telefono in inglese americano
func kgTesto(_ v: Double?, locale: Locale = .current) -> String {
    "\(num(v, locale: locale)) kg"
}

// Legge un numero scritto con la virgola o con il punto, anche con cifre non latine (arabo-indiche, devanagari...)
func leggiNumero(_ testo: String) -> Double? {
    var latino = ""
    for c in testo.trimmingCharacters(in: .whitespaces) {
        if let d = c.wholeNumberValue, c.isNumber, c.unicodeScalars.allSatisfy({ $0.properties.numericType == .decimal }) {
            latino += String(d)
        } else if c == "," || c == "٫" {
            latino += "."
        } else {
            latino.append(c)
        }
    }
    // Solo cifre, segno e separatore: niente "nan", "inf", "1e5" o esadecimali; e mai un risultato non finito
    guard !latino.isEmpty, latino.allSatisfy({ "0123456789.+-".contains($0) }),
          let v = Double(latino), v.isFinite else { return nil }
    return v
}

// Argomenti di avvio usati per le schermate di prova nel simulatore (es. -tab andamento -demo)
enum Avvio {
    static let argomenti = ProcessInfo.processInfo.arguments
    static var demo: Bool { argomenti.contains("-demo") }

    static func valore(_ chiave: String) -> String? {
        guard let i = argomenti.firstIndex(of: chiave), i + 1 < argomenti.count else { return nil }
        return argomenti[i + 1]
    }
}

extension View {
    // Pulsanti Liquid Glass su iOS 26, pulsanti classici sulle versioni precedenti
    @ViewBuilder
    func pulsanteVetro(evidente: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            if evidente { buttonStyle(.glassProminent) } else { buttonStyle(.glass) }
        } else {
            if evidente { buttonStyle(.borderedProminent) } else { buttonStyle(.bordered) }
        }
    }
}

// Voce di una checklist: tutta la riga è il pulsante, a sinistra CerchioSpunta (la spunta unica dell'app).
// Fatta: cerchio pieno e testo grigio. VoiceOver: etichetta + «fatto»/«da fare».
//   RigaSpunta(fatto: s.fatto, azione: { … }) { Text("Riscaldamento") }
struct RigaSpunta<Etichetta: View>: View {
    let fatto: Bool
    let azione: () -> Void
    @ViewBuilder let etichetta: Etichetta

    var body: some View {
        Button(action: azione) {
            HStack(spacing: Spazio.s) {
                CerchioSpunta(fatta: fatto)   // solo disegno: lo stato lo dice già accessibilityValue
                etichetta
                    .foregroundStyle(fatto ? .secondary : .primary)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: fatto)
        .accessibilityValue(fatto ? Text("fatto") : Text("da fare"))
        .accessibilityAddTraits(fatto ? .isSelected : [])
    }
}

// Alimento con la quantità: sulla stessa riga, oppure sotto il nome con il testo molto grande
struct RigaAlimento: View {
    let nome: String
    let quantita: String
    @Environment(\.dynamicTypeSize) private var dimensione

    var body: some View {
        if dimensione.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 2) {
                Text(nome)
                if !quantita.isEmpty { Text(quantita).monospacedDigit().foregroundStyle(.secondary) }
            }
        } else {
            // Il nome va a capo, la quantità resta intera a destra
            HStack(alignment: .firstTextBaseline, spacing: Spazio.m) {
                Text(nome).frame(maxWidth: .infinity, alignment: .leading)
                Text(quantita).monospacedDigit().foregroundStyle(.secondary).fixedSize()
            }
        }
    }
}

extension View {
    // Selettore a segmenti, che con il testo molto grande diventa un menu (i segmenti si taglierebbero)
    func segmentiOMenu() -> some View { modifier(SegmentiOMenu()) }
}

struct SegmentiOMenu: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dimensione

    func body(content: Content) -> some View {
        if dimensione.isAccessibilitySize {
            content.pickerStyle(.menu)
        } else {
            content.pickerStyle(.segmented)
        }
    }
}
