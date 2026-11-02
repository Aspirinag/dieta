import SwiftUI

// Temi dell'app: i temi Halloween di Slack più il tema classico (arancione, chiaro o scuro come il sistema)
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

    // Colori: sfondo in alto, sfondo in basso, accento, secondo accento, testo sui pulsanti pieni
    private var colori: (alto: UInt32, basso: UInt32, accento: UInt32, secondo: UInt32, testo: UInt32)? {
        switch self {
        case .slimeTime: (0x0A0A0F, 0x1A1030, 0x39FF14, 0xFF6A00, 0x0A0A0F)
        case .fangtastic: (0x120C0C, 0x2A1515, 0xB3121B, 0x8FBF6A, 0xF2E6C9)
        case .friendlyGhost: (0x14173A, 0x2A2F66, 0xB9A7F0, 0x8FE3B0, 0x14173A)
        case .candyCorn: (0xFFF3D6, 0xFBD98A, 0xE8590C, 0x5B7B3A, 0xFFF3D6)
        case .frankenstein: (0x2A302C, 0x3A433D, 0x8FBF6A, 0xB7D98A, 0x2A302C)
        case .witchingHour: (0x0B1330, 0x1F2E5C, 0x7FD1AE, 0xC9D1E0, 0x0B1330)
        case .classico: nil
        }
    }

    // nil = segue il sistema (solo il tema classico)
    var schema: ColorScheme? {
        switch self {
        case .classico: nil
        case .candyCorn: .light
        default: .dark
        }
    }

    var accento: Color { colori.map { Color(esa: $0.accento) } ?? Color.accentColor }
    var secondo: Color { colori.map { Color(esa: $0.secondo) } ?? .blue }
    var testoSuAccento: Color { colori.map { Color(esa: $0.testo) } ?? .white }

    var sfondo: AnyShapeStyle? {
        guard let c = colori else { return nil }
        return AnyShapeStyle(LinearGradient(colors: [Color(esa: c.alto), Color(esa: c.basso)], startPoint: .top, endPoint: .bottom))
    }

    // Tinta delle righe delle liste: vetro scuro (o chiaro) sopra lo sfondo del tema
    var riga: Color? {
        guard colori != nil else { return nil }
        return schema == .light ? Color.white.opacity(0.55) : Color.white.opacity(0.08)
    }

    static let chiave = "tema"
    static var salvato: Tema { Tema(rawValue: UserDefaults.standard.string(forKey: chiave) ?? "") ?? .slimeTime }
}

extension Color {
    init(esa: UInt32) {
        self.init(red: Double((esa >> 16) & 0xFF) / 255, green: Double((esa >> 8) & 0xFF) / 255, blue: Double(esa & 0xFF) / 255)
    }
}

private struct ChiaveTema: EnvironmentKey {
    static let defaultValue: Tema = .slimeTime
}

extension EnvironmentValues {
    var tema: Tema {
        get { self[ChiaveTema.self] }
        set { self[ChiaveTema.self] = newValue }
    }
}

// Applica il tema a tutta l'app (o a una schermata presentata a parte)
struct ApplicaTema: ViewModifier {
    let tema: Tema

    func body(content: Content) -> some View {
        content
            .environment(\.tema, tema)
            .tint(tema.accento)
            .preferredColorScheme(tema.schema)
    }
}

// Sfondo del tema dietro una lista o un modulo
struct SfondoTema: ViewModifier {
    @Environment(\.tema) private var tema

    func body(content: Content) -> some View {
        if let sfondo = tema.sfondo {
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
    @AppStorage(Tema.chiave) private var scelto = Tema.slimeTime.rawValue

    var body: some View {
        Section {
            ForEach(Tema.allCases) { t in
                Button { scelto = t.rawValue } label: {
                    HStack(spacing: 12) {
                        Anteprima(tema: t)
                        Text(t.nome).foregroundStyle(.primary)
                        Spacer()
                        if scelto == t.rawValue { Image(systemName: "checkmark").foregroundStyle(.tint).fontWeight(.semibold) }
                    }
                }
            }
        } header: {
            Text("Tema")
        } footer: {
            Text("I temi Halloween di Slack. Classico segue il chiaro o scuro del telefono.")
        }
    }

    private struct Anteprima: View {
        let tema: Tema

        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(tema.sfondo ?? AnyShapeStyle(Color(.secondarySystemBackground)))
                HStack(spacing: 3) {
                    Circle().fill(tema.accento).frame(width: 10, height: 10)
                    Circle().fill(tema.secondo).frame(width: 10, height: 10)
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

    func body(content: Content) -> some View {
        if let riga = tema.riga {
            content.listRowBackground(Rectangle().fill(riga))
        } else {
            content
        }
    }
}

extension View {
    func righeTema() -> some View { modifier(RigheTema()) }
}

// Testo leggibile sui pulsanti pieni (nero sul verde slime, chiaro sul rosso)
struct TestoSuAccento: ViewModifier {
    @Environment(\.tema) private var tema

    func body(content: Content) -> some View {
        content.foregroundStyle(tema.testoSuAccento)
    }
}
