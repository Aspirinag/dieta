import SwiftUI

// SISTEMA VISIVO — colori. Ogni colore ha un solo significato; nessuna schermata scrive colori a mano.
//
// Colori.accento     verde #2F6B4F (scuro #7FB89A): SOLO pulsante principale pieno e stato «fatto»
//                    (spunta, serie fatta). Mai nomi, link, titoli, icone di riga, «Precedente», variazioni di peso.
// Colori.sulAccento  testo e segni sopra l'accento
// Colori.sfondoFatto sfondo di una riga fatta (serie dell'allenamento): accento al 25 % in chiaro, 35 % in scuro
// Colori.olio        giallo olio: SOLO cucchiaini pieni
// Colori.acqua       blu acqua: SOLO gocce piene
// Colori.oltre       arancione: SOLO oltre la dose, sempre insieme a un «+N» scritto
// Colori.vuoto       contorno degli elementi vuoti (cerchi, cucchiaini, gocce), spessore Misure.contorno;
// Colori.riempimentoVuoto  riempimento leggero sotto quel contorno
//   Tutti hanno varianti chiaro, scuro e Aumenta contrasto; contrasti controllati in SistemaVisivoTests.
// Testi solo .primary/.secondary/.tertiary; sfondi solo quelli raggruppati di sistema (sfondoTema, righeTema).
// Variazioni del corpo (peso, grasso, vita): .secondary con il segno (Testi.conSegno), mai verde o rosso.
//
// Modificatori: .applicaTema() (radice e fogli a schermo intero), .sfondoTema() (dietro List/Form/ScrollView),
// .righeTema() (sulle righe di una List). Pulsante pieno: `Button("Inizia") { … }.buttonStyle(PulsanteAccento())`,
// al massimo uno per schermata.
enum Colori {
    static let accento = Color(chiaro: 0x2F6B4F, scuro: 0x7FB89A, chiaroContrasto: 0x245A40, scuroContrasto: 0x9FD0B5)
    // Il bianco sul verde chiaro dello scuro si legge male: lì il segno è verde scurissimo
    static let sulAccento = Color(chiaro: 0xFFFFFF, scuro: 0x0F2218)
    static let sfondoFatto = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(esa: t.accessibilityContrast == .high ? 0x9FD0B5 : 0x7FB89A).withAlphaComponent(0.35)
            : UIColor(esa: t.accessibilityContrast == .high ? 0x245A40 : 0x2F6B4F).withAlphaComponent(0.25)
    })
    // Giallo più scuro in chiaro per arrivare a 3:1 sul bianco (#D6A21E era 2,3:1)
    static let olio = Color(chiaro: 0xB07F0C, scuro: 0xD6A21E, chiaroContrasto: 0x8C6508, scuroContrasto: 0xE8BC4A)
    // In scuro un po' più chiaro, per restare sopra 3:1 anche sul grigio dei fogli
    static let acqua = Color(chiaro: 0x3D7FA6, scuro: 0x5A9CC4, chiaroContrasto: 0x2C6688, scuroContrasto: 0x7DB4D6)
    // L'arancione di sistema è 2,2:1 sul bianco: in chiaro uno più scuro
    static let oltre = Color(chiaro: 0xC4610A, scuro: 0xFF9F0A, chiaroContrasto: 0xA34F06, scuroContrasto: 0xFFB340)
    // Grigio secondario di sistema (≈ 3,4:1 sul bianco, ≈ 5,9:1 sul grigio scuro; più scuro con Aumenta contrasto)
    static let vuoto = Color(.secondaryLabel)
    static let riempimentoVuoto = Color(.quaternarySystemFill)
}

extension Color {
    init(esa: UInt32) {
        self.init(red: Double((esa >> 16) & 0xFF) / 255, green: Double((esa >> 8) & 0xFF) / 255, blue: Double(esa & 0xFF) / 255)
    }

    // Colore che segue chiaro/scuro e, se dati, Aumenta contrasto
    init(chiaro: UInt32, scuro: UInt32, chiaroContrasto: UInt32? = nil, scuroContrasto: UInt32? = nil) {
        self.init(UIColor { t in
            let alto = t.accessibilityContrast == .high
            if t.userInterfaceStyle == .dark { return UIColor(esa: alto ? (scuroContrasto ?? scuro) : scuro) }
            return UIColor(esa: alto ? (chiaroContrasto ?? chiaro) : chiaro)
        })
    }
}

extension UIColor {
    convenience init(esa: UInt32) {
        self.init(red: CGFloat((esa >> 16) & 0xFF) / 255, green: CGFloat((esa >> 8) & 0xFF) / 255, blue: CGFloat(esa & 0xFF) / 255, alpha: 1)
    }
}

// Rapporto di contrasto WCAG tra un colore e lo sfondo su cui sta (1…21), nello stile e contrasto dati.
// Un colore trasparente si compone prima sullo sfondo. Testo ≥ 4,5; forme con significato ≥ 3.
//   Contrasto.rapporto(Colori.olio, su: Color(.secondarySystemGroupedBackground), stile: .dark)
enum Contrasto {
    static func rapporto(_ colore: Color, su sfondo: Color, stile: UIUserInterfaceStyle,
                         contrastoAlto: Bool = false) -> Double {
        let tratti = UITraitCollection { t in
            t.userInterfaceStyle = stile
            t.accessibilityContrast = contrastoAlto ? .high : .normal
        }
        let f = componenti(UIColor(sfondo).resolvedColor(with: tratti))
        let c = componenti(UIColor(colore).resolvedColor(with: tratti))
        let sotto = (f.0, f.1, f.2)   // lo sfondo si considera opaco
        let sopra = (c.0 * c.3 + sotto.0 * (1 - c.3), c.1 * c.3 + sotto.1 * (1 - c.3), c.2 * c.3 + sotto.2 * (1 - c.3))
        let a = luminanza(sopra), b = luminanza(sotto)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    private static func componenti(_ c: UIColor) -> (Double, Double, Double, Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }

    private static func luminanza(_ c: (Double, Double, Double)) -> Double {
        let l = [c.0, c.1, c.2].map { $0 <= 0.03928 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
        return 0.2126 * l[0] + 0.7152 * l[1] + 0.0722 * l[2]
    }
}

// Applica l'accento a tutta l'app (o a una schermata presentata a parte)
struct ApplicaTema: ViewModifier {
    func body(content: Content) -> some View {
        content.tint(Colori.accento)
    }
}

// Sfondo di sistema raggruppato dietro una lista o un modulo
struct SfondoTema: ViewModifier {
    @State private var larghezza: CGFloat = 0

    func body(content: Content) -> some View {
        // Su schermi larghi (iPhone in orizzontale, iPhone Duo aperto) il contenuto resta a larghezza leggibile
        let margine = max((larghezza - 640) / 2, 0)
        content
            .modifier(MargineLeggibile(margine: margine))
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { larghezza = $0 }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground), ignoresSafeAreaEdges: .all)
    }
}

// Righe delle liste: sfondo di sistema
struct RigheTema: ViewModifier {
    func body(content: Content) -> some View {
        content.listRowBackground(Color(.secondarySystemGroupedBackground))
    }
}

// Pulsante pieno con l'accento (Inizia, Riprendi)
struct PulsanteAccento: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Colori.sulAccento)
            .padding(.horizontal, Spazio.l)
            .padding(.vertical, Spazio.s)
            .frame(minHeight: Misure.tocco)
            .background(Colori.accento, in: .capsule)
            .contentShape(.capsule)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension View {
    func applicaTema() -> some View { modifier(ApplicaTema()) }
    func sfondoTema() -> some View { modifier(SfondoTema()) }
    func righeTema() -> some View { modifier(RigheTema()) }
}

struct MargineLeggibile: ViewModifier {
    let margine: CGFloat
    func body(content: Content) -> some View {
        if margine > 0 { content.contentMargins(.horizontal, margine, for: .scrollContent) } else { content }
    }
}
