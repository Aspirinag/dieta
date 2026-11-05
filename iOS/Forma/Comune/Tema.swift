import SwiftUI

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
