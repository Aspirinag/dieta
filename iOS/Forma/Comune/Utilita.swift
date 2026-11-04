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

    static let calendario: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = .current
        c.firstWeekday = 2
        return c
    }()

    static func iso(_ data: Date) -> String {
        let c = calendario.dateComponents([.year, .month, .day], from: data)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func data(_ iso: String) -> Date {
        let p = iso.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return Date() }
        return calendario.date(from: DateComponents(year: p[0], month: p[1], day: p[2])) ?? Date()
    }

    static func oggi() -> String { iso(Date()) }

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

    // Data breve nel formato del telefono: 04/11/2026 in Italia, 11/4/2026 negli Stati Uniti
    static func breve(_ iso: String) -> String {
        guard iso.split(separator: "-").count == 3 else { return iso }
        return data(iso).formatted(date: .numeric, time: .omitted)
    }
}

// Numeri nel formato del telefono, senza decimali inutili: 81,1 · 80 · 0,25 (in inglese 81.1)
func num(_ v: Double?, locale: Locale = .current) -> String {
    guard let v else { return "–" }
    let f = NumberFormatter()
    f.locale = locale
    f.numberStyle = .decimal
    f.usesGroupingSeparator = false
    f.minimumFractionDigits = 0
    f.maximumFractionDigits = 2
    return f.string(from: NSNumber(value: (v * 100).rounded() / 100)) ?? String(v)
}

// Peso in chili: sempre metrico, anche con il telefono in inglese americano
func kgTesto(_ v: Double?, locale: Locale = .current) -> String {
    "\(num(v, locale: locale)) kg"
}

// Legge un numero scritto con la virgola o con il punto
func leggiNumero(_ testo: String) -> Double? {
    Double(testo.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
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

// Voce di una checklist: cerchio pieno quando è fatta
struct RigaSpunta<Etichetta: View>: View {
    let fatto: Bool
    let azione: () -> Void
    @ViewBuilder let etichetta: Etichetta

    var body: some View {
        Button(action: azione) {
            HStack(spacing: 12) {
                Image(systemName: fatto ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(fatto ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)   // lo stato lo dice già accessibilityValue
                etichetta
                    .foregroundStyle(.primary)
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
                if !quantita.isEmpty { Text(quantita).foregroundStyle(.secondary) }
            }
        } else {
            HStack(alignment: .firstTextBaseline) {
                Text(nome)
                Spacer()
                Text(quantita).foregroundStyle(.secondary)
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
