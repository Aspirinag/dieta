import SwiftUI

// Temi dell'app: i temi Halloween di Slack più il tema classico; ognuno in versione chiara e scura, come il telefono
enum Tema: String, CaseIterable, Identifiable {
    case slimeTime, fangtastic, friendlyGhost, candyCorn, frankenstein, witchingHour, classico

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .slimeTime: "Slime Time"
        case .fangtastic: "Fangtastic"
        case .friendlyGhost: "Friendly Ghost"
        case .candyCorn: "Candy Corn"
        case .frankenstein: "Frankenstein"
        case .witchingHour: "Witching Hour"
        case .classico: "Classico"
        }
    }

    // Palette: sfondo in alto, sfondo in basso, accento, secondo accento, primario (pulsanti pieni), testo sul primario
    struct Palette {
        let alto: UInt32, basso: UInt32, accento: UInt32, secondo: UInt32, primario: UInt32, suPrimario: UInt32
    }

    // Versione scura (i temi Halloween di Slack) e chiara (scelta a mano, accenti scuriti per leggersi sul chiaro)
    func palette(_ schema: ColorScheme) -> Palette? {
        let scuro = schema == .dark
        switch self {
        case .slimeTime: return scuro
            ? Palette(alto: 0x0A0A0F, basso: 0x1A1030, accento: 0x39FF14, secondo: 0xFF6A00, primario: 0xF5F5FA, suPrimario: 0x0A0A0F)
            : Palette(alto: 0xF7F5FC, basso: 0xECE6F7, accento: 0x1A7009, secondo: 0xB03A0A, primario: 0x0A0A0F, suPrimario: 0xF5F5FA)
        case .fangtastic: return scuro
            ? Palette(alto: 0x120C0C, basso: 0x2A1515, accento: 0xEE5A60, secondo: 0x8FBF6A, primario: 0xF2E6C9, suPrimario: 0x120C0C)
            : Palette(alto: 0xFBF4EC, basso: 0xF2E3D3, accento: 0xA3101A, secondo: 0x44692A, primario: 0x120C0C, suPrimario: 0xF2E6C9)
        case .friendlyGhost: return scuro
            ? Palette(alto: 0x14173A, basso: 0x2A2F66, accento: 0xB9A7F0, secondo: 0x8FE3B0, primario: 0xF1EEFF, suPrimario: 0x14173A)
            : Palette(alto: 0xF5F3FF, basso: 0xE6E1FA, accento: 0x5B45B8, secondo: 0x23704A, primario: 0x14173A, suPrimario: 0xF1EEFF)
        case .candyCorn: return scuro
            ? Palette(alto: 0x1E1408, basso: 0x3A2810, accento: 0xF07A2E, secondo: 0xFBD98A, primario: 0xFFF3D6, suPrimario: 0x1E1408)
            : Palette(alto: 0xFFF3D6, basso: 0xFBD98A, accento: 0xA93F08, secondo: 0x465F2B, primario: 0x4A2C12, suPrimario: 0xFFF3D6)
        case .frankenstein: return scuro
            ? Palette(alto: 0x2A302C, basso: 0x3A433D, accento: 0x8FBF6A, secondo: 0xB7D98A, primario: 0xE4E8E1, suPrimario: 0x2A302C)
            : Palette(alto: 0xF1F4EF, basso: 0xE1E8DC, accento: 0x3F6B2A, secondo: 0x4E6E30, primario: 0x2A302C, suPrimario: 0xE4E8E1)
        case .witchingHour: return scuro
            ? Palette(alto: 0x0B1330, basso: 0x1F2E5C, accento: 0x7FD1AE, secondo: 0xC9D1E0, primario: 0xEEF1F8, suPrimario: 0x0B1330)
            : Palette(alto: 0xF3F5FB, basso: 0xE2E8F5, accento: 0x1B6E53, secondo: 0x3B4A6B, primario: 0x0B1330, suPrimario: 0xEEF1F8)
        case .classico: return nil
        }
    }

    func accento(_ s: ColorScheme) -> Color { palette(s).map { Color(esa: $0.accento) } ?? Color.accentColor }
    func secondo(_ s: ColorScheme) -> Color { palette(s).map { Color(esa: $0.secondo) } ?? .blue }
    func primario(_ s: ColorScheme) -> Color { palette(s).map { Color(esa: $0.primario) } ?? Color.accentColor }
    func suPrimario(_ s: ColorScheme) -> Color { palette(s).map { Color(esa: $0.suPrimario) } ?? .white }

    func sfondo(_ s: ColorScheme) -> AnyShapeStyle? {
        guard let p = palette(s) else { return nil }
        return AnyShapeStyle(LinearGradient(colors: [Color(esa: p.alto), Color(esa: p.basso)], startPoint: .top, endPoint: .bottom))
    }

    // Tinta delle righe delle liste: vetro sopra lo sfondo del tema
    func riga(_ s: ColorScheme) -> Color? {
        guard palette(s) != nil else { return nil }
        return s == .light ? Color.white.opacity(0.55) : Color.white.opacity(0.08)
    }

    static let predefinito = Tema.slimeTime
    static let chiave = "tema"
}

extension Color {
    init(esa: UInt32) {
        self.init(red: Double((esa >> 16) & 0xFF) / 255, green: Double((esa >> 8) & 0xFF) / 255, blue: Double(esa & 0xFF) / 255)
    }
}

private struct ChiaveTema: EnvironmentKey {
    static let defaultValue: Tema = .predefinito
}

extension EnvironmentValues {
    var tema: Tema {
        get { self[ChiaveTema.self] }
        set { self[ChiaveTema.self] = newValue }
    }
}

// Applica il tema a tutta l'app (o a una schermata presentata a parte): chiaro o scuro lo decide il telefono
struct ApplicaTema: ViewModifier {
    let tema: Tema
    @Environment(\.colorScheme) private var schema

    func body(content: Content) -> some View {
        content
            .environment(\.tema, tema)
            .tint(tema.accento(schema))
    }
}

// Sfondo del tema dietro una lista o un modulo
struct SfondoTema: ViewModifier {
    @Environment(\.tema) private var tema
    @Environment(\.colorScheme) private var schema

    func body(content: Content) -> some View {
        if let sfondo = tema.sfondo(schema) {
            content
                .scrollContentBackground(.hidden)
                .background(sfondo, ignoresSafeAreaEdges: .all)
        } else {
            content
        }
    }
}

extension View {
    func applicaTema(_ tema: Tema) -> some View { modifier(ApplicaTema(tema: tema)) }
    func sfondoTema() -> some View { modifier(SfondoTema()) }
}

// Scelta del tema nel Profilo
struct SezioneTema: View {
    @Environment(\.colorScheme) private var schema
    @AppStorage(Tema.chiave) private var scelto = Tema.predefinito.rawValue

    var body: some View {
        Section {
            ForEach(Tema.allCases) { t in
                Button { scelto = t.rawValue } label: {
                    HStack(spacing: 12) {
                        Anteprima(tema: t, schema: schema)
                        Text(t.nome).foregroundStyle(.primary)
                        Spacer()
                        if scelto == t.rawValue { Image(systemName: "checkmark").foregroundStyle(.tint).fontWeight(.semibold) }
                    }
                }
            }
        } header: {
            Text("Tema")
        } footer: {
            Text("I temi Halloween di Slack. Chiaro o scuro segue il telefono.")
        }
    }

    private struct Anteprima: View {
        let tema: Tema
        let schema: ColorScheme

        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(tema.sfondo(schema) ?? AnyShapeStyle(Color(.secondarySystemBackground)))
                HStack(spacing: 3) {
                    Circle().fill(tema.accento(schema)).frame(width: 10, height: 10)
                    Circle().fill(tema.secondo(schema)).frame(width: 10, height: 10)
                }
            }
            .frame(width: 44, height: 28)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.secondary.opacity(0.3)))
        }
    }
}

// Righe delle liste in vetro sopra lo sfondo del tema
struct RigheTema: ViewModifier {
    @Environment(\.tema) private var tema
    @Environment(\.colorScheme) private var schema

    func body(content: Content) -> some View {
        if let riga = tema.riga(schema) {
            content.listRowBackground(Rectangle().fill(riga))
        } else {
            content
        }
    }
}

extension View {
    func righeTema() -> some View { modifier(RigheTema()) }
}

// Pulsanti pieni: primario del tema (bianco in scuro, quasi nero in chiaro) con testo leggibile
struct ColoriPrimario: ViewModifier {
    @Environment(\.tema) private var tema
    @Environment(\.colorScheme) private var schema

    func body(content: Content) -> some View {
        content
            .tint(tema.primario(schema))
            .foregroundStyle(tema.suPrimario(schema))
    }
}
