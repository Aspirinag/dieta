import SwiftUI

// Date come nella web app: stringhe yyyy-MM-dd nel fuso del telefono, settimana da lunedì
enum Giorni {
    static let nomi = ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"]
    static let mesi = ["gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno", "luglio", "agosto", "settembre", "ottobre", "novembre", "dicembre"]

    static let calendario: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "it_IT")
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

    // Oggi e i 6 giorni successivi: il periodo della lista della spesa
    static func prossimi7() -> [String] { (0..<7).map { aggiungi(oggi(), $0) } }

    // «Sabato 31 ottobre»
    static func estesa(_ iso: String) -> String {
        let p = iso.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3, mesi.indices.contains(p[1] - 1) else { return iso }
        return "\(nomi[indice(iso)]) \(p[2]) \(mesi[p[1] - 1])"
    }

    // gg/mm/aaaa
    static func breve(_ iso: String) -> String {
        let p = iso.split(separator: "-")
        guard p.count == 3 else { return iso }
        return "\(p[2])/\(p[1])/\(p[0])"
    }
}

// Numeri all'italiana, senza decimali inutili: 81,1 · 80 · 0,25
func num(_ v: Double?) -> String {
    guard let v else { return "–" }
    let arrotondato = (v * 100).rounded() / 100
    if arrotondato == arrotondato.rounded() { return String(Int(arrotondato)) }
    return String(arrotondato).replacingOccurrences(of: ".", with: ",")
}

// Calorie stimate, arrotondate alla decina: ≈ 1.650 kcal
func kcal(_ v: Double, incompleto: Bool = false) -> String {
    "≈ " + numeroKcal(v) + (incompleto ? "+" : "") + " kcal"
}

func numeroKcal(_ v: Double) -> String {
    Int((v / 10).rounded() * 10).formatted(.number.locale(Locale(identifier: "it_IT")))
}

// Legge un numero scritto con la virgola o con il punto
func leggiNumero(_ testo: String) -> Double? {
    Double(testo.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
}

// Argomenti di avvio usati per le schermate di prova nel simulatore (es. -tab progressi -demo)
enum Avvio {
    static let argomenti = ProcessInfo.processInfo.arguments
    static var demo: Bool { argomenti.contains("-demo") }

    static func valore(_ chiave: String) -> String? {
        guard let i = argomenti.firstIndex(of: chiave), i + 1 < argomenti.count else { return nil }
        return argomenti[i + 1]
    }
}

// Nome che va a capo tra le parole e mai dentro una parola: una riga per parola al massimo,
// poi rimpicciolisce (è il limite di righe che fa scattare minimumScaleFactor)
struct TestoIntero: View {
    let testo: String

    static func righe(_ testo: String) -> Int {
        max(1, testo.split(whereSeparator: \.isWhitespace).count)
    }

    var body: some View {
        Text(testo)
            .lineLimit(Self.righe(testo))
            .minimumScaleFactor(0.5)
    }
}

// Riquadro delle schede: gradiente del tema, angoli ampi
extension View {
    func scheda() -> some View {
        modifier(StileScheda())
    }

    // Sfondo a gradiente del tema dentro una NavigationStack
    func sfondoTema() -> some View { modifier(SfondoTema()) }

    // Schede senza barra di navigazione: il testo si ferma prima dell'ora e della barra in basso,
    // e il rimbalzo c'è solo quando c'è davvero da scorrere
    func scorrimentoTema() -> some View { clipped().scrollBounceBehavior(.basedOnSize) }

    // Righe di List e Form nei colori del tema
    func sezioneTema() -> some View { modifier(StileSezione()) }

    // Se l'app resta aperta oltre la mezzanotte, chi guardava oggi passa al nuovo giorno
    func seguiMezzanotte(_ giorno: Binding<String>) -> some View { modifier(SeguiMezzanotte(giorno: giorno)) }
}

private struct SfondoTema: ViewModifier {
    @Environment(\.palette) private var palette

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)   // nei fogli quello della radice non arriva
            .background(palette.fondo.ignoresSafeArea())
    }
}

private struct StileScheda: ViewModifier {
    @Environment(\.palette) private var palette

    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.scheda, in: .rect(cornerRadius: 22))
    }
}

private struct StileSezione: ViewModifier {
    @Environment(\.palette) private var palette

    func body(content: Content) -> some View {
        content
            .listRowBackground(palette.scheda)
            .listRowSeparatorTint(palette.traccia)
            .id(palette.esadecimali.traccia)   // cambiando tema le linee già disegnate resterebbero nere
    }
}

private struct SeguiMezzanotte: ViewModifier {
    @Environment(\.scenePhase) private var fase
    @Binding var giorno: String
    @State private var ultimoOggi = Giorni.oggi()

    func body(content: Content) -> some View {
        content.onChange(of: fase) { _, nuova in
            guard nuova == .active else { return }
            if giorno == ultimoOggi { giorno = Giorni.oggi() }
            ultimoOggi = Giorni.oggi()
        }
    }
}

// Intestazioni e piedi delle sezioni di List e Form: da soli userebbero il carattere di sistema
struct IntestazioneSezione: View {
    let testo: String
    @Environment(\.palette) private var palette

    var body: some View {
        Text(testo)
            .font(.georgia(.subheadline))
            .foregroundStyle(palette.secondario)
            .textCase(nil)
    }
}

struct PiedeSezione: View {
    let testo: String
    @Environment(\.palette) private var palette

    var body: some View {
        Text(testo)
            .font(.georgia(.footnote))
            .foregroundStyle(palette.secondario)
    }
}

// Tasti dell'app. Principale: il colore del tasto del tema (nel Giorno resta neon, con testo scuro).
// Secondario: stessa forma sul riempimento del tema. Sempre almeno 48 punti di altezza
struct TastoTema: ButtonStyle {
    var principale = true
    @Environment(\.palette) private var palette
    @Environment(\.isEnabled) private var attivo

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.georgia(.callout, grassetto: true))
            .multilineTextAlignment(.center)
            .foregroundStyle(principale ? palette.suTasto : palette.testo)
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .background(principale ? palette.tasto : palette.riempimento, in: .rect(cornerRadius: 14))
            .contentShape(.rect(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.75 : attivo ? 1 : 0.5)
    }
}

// Scheda per quando non c'è ancora niente da mostrare, con i tasti per rimediare
struct StatoVuoto<Azioni: View>: View {
    let titolo: String
    let icona: String
    var descrizione: String?
    @ViewBuilder let azioni: Azioni
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icona)
                .font(.georgia(.largeTitle))
                .foregroundStyle(palette.secondario)
            Text(titolo)
                .font(.georgia(.title3, grassetto: true))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            if let descrizione {
                Text(descrizione)
                    .font(.georgia(.subheadline))
                    .foregroundStyle(palette.secondario)
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: 8) { azioni }.padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .scheda()
    }
}

extension StatoVuoto where Azioni == EmptyView {
    init(titolo: String, icona: String, descrizione: String? = nil) {
        self.init(titolo: titolo, icona: icona, descrizione: descrizione) { EmptyView() }
    }
}

// Anello che si riempie con l'avanzamento (0…1), con un testo al centro
struct Anello: View {
    let valore: Double
    let testo: String
    var lato: CGFloat = 76
    var descrizione = ""     // per VoiceOver, es. «Pasti segnati: 1 su 4»
    var colore: Color?      // senza indicazione, l'accento del tema
    @Environment(\.palette) private var palette
    @ScaledMetric(relativeTo: .subheadline) private var scala = 1.0

    // Cresce con il testo, senza esagerare
    private var latoScalato: CGFloat { lato * min(scala, 1.6) }

    var body: some View {
        let colore = colore ?? palette.accento
        let spessore = latoScalato * 8 / 76
        ZStack {
            Circle().stroke(palette.traccia, lineWidth: spessore)
            Circle()
                .trim(from: 0, to: max(0.001, min(valore, 1)))
                .stroke(colore, style: StrokeStyle(lineWidth: spessore, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(testo)
                .font(.georgia(.headline))
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.horizontal, spessore + 3)
        }
        .frame(width: latoScalato, height: latoScalato)
        .animation(.spring(duration: 0.4), value: valore)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(descrizione.isEmpty ? testo : descrizione)
    }
}

// Variazione di una misura in una capsula: accento (bene), caldo (male) o neutra
struct BadgeVariazione: View {
    let testo: String
    let colore: Color?
    @Environment(\.palette) private var palette

    var body: some View {
        Text(testo)
            .font(.georgia(.subheadline, grassetto: true))
            .foregroundStyle(colore ?? palette.secondario)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(palette.riempimento, in: .capsule)
    }
}
