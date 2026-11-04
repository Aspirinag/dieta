import SwiftUI

// Aspetto unico dell'app: sfondo di sistema raggruppato, righe di sistema, un solo accento verde salvia.
// Chiaro o scuro lo decide il telefono.
enum Colori {
    // Verde salvia: #2F6B4F in chiaro, #7FB89A in scuro
    static let accento = Color(chiaro: 0x2F6B4F, scuro: 0x7FB89A)
    // Testo e segni sopra l'accento: bianco in chiaro, verde molto scuro in scuro (il bianco sul verde chiaro si legge male)
    static let sulAccento = Color(chiaro: 0xFFFFFF, scuro: 0x0F2218)
    static let olio = Color(esa: 0xD6A21E)
    static let acqua = Color(esa: 0x3D7FA6)
}

extension Color {
    init(esa: UInt32) {
        self.init(red: Double((esa >> 16) & 0xFF) / 255, green: Double((esa >> 8) & 0xFF) / 255, blue: Double(esa & 0xFF) / 255)
    }

    init(chiaro: UInt32, scuro: UInt32) {
        self.init(UIColor { $0.userInterfaceStyle == .dark ? UIColor(esa: scuro) : UIColor(esa: chiaro) })
    }
}

extension UIColor {
    convenience init(esa: UInt32) {
        self.init(red: CGFloat((esa >> 16) & 0xFF) / 255, green: CGFloat((esa >> 8) & 0xFF) / 255, blue: CGFloat(esa & 0xFF) / 255, alpha: 1)
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
            .contentMargins(.horizontal, margine, for: .scrollContent)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { larghezza = $0 }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground), ignoresSafeAreaEdges: .all)
    }
}

// Righe delle liste: sfondo di sistema
struct RigheTema: ViewModifier {
    func body(content: Content) -> some View {
        let righe = content.listRowBackground(Color(.secondarySystemGroupedBackground))
        // Sull'iPhone Duo il margine destro delle righe sparisce: lo si rimette
        if #available(iOS 26, *) { righe.listRowInsets(.trailing, 20) } else { righe }
    }
}

// Pulsante pieno con l'accento (Inizia, Riprendi)
struct PulsanteAccento: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Colori.sulAccento)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Colori.accento, in: .capsule)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension View {
    func applicaTema() -> some View { modifier(ApplicaTema()) }
    func sfondoTema() -> some View { modifier(SfondoTema()) }
    func righeTema() -> some View { modifier(RigheTema()) }
}
