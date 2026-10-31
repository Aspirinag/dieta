import SwiftUI

// I quattro temi di Èffort. Halloween è quello predefinito, anche con l'iPhone in modo chiaro
enum Tema: String, CaseIterable, Identifiable {
    case halloween, giorno, notte, ossidiana

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .halloween: "Halloween"
        case .giorno: "Giorno"
        case .notte: "Notte"
        case .ossidiana: "Ossidiana"
        }
    }

    // Nome salvato (o assente, o sconosciuto) → tema; nel dubbio Halloween
    static func scelto(_ nome: String?) -> Tema {
        nome.flatMap(Tema.init(rawValue:)) ?? .halloween
    }

    // Solo Giorno è chiaro
    var schemaColori: ColorScheme { self == .giorno ? .light : .dark }

    var palette: Palette { Palette(esadecimali: valori) }

    private var valori: Palette.Esadecimali {
        switch self {
        case .halloween:
            .init(fondo: [0x0A0F0C, 0x18211C, 0x3B4841], schedaDa: 0x25302A, schedaA: 0x171F1B,
                  testo: 0xF4F7F1, secondario: 0xB9C4BB, accento: 0x39FF14, suAccento: 0x0A1A04,
                  tasto: 0x39FF14, suTasto: 0x0A1A04, caldo: 0xFF7A00, freddo: 0xB98CFF, riempimento: 0x2F3B34)
        case .notte:
            .init(fondo: [0x0F0B1A, 0x1C1530, 0x3A2E58], schedaDa: 0x2A2042, schedaA: 0x1A142B,
                  testo: 0xF5F1FF, secondario: 0xB9AED1, accento: 0xA98BFF, suAccento: 0x160E2B,
                  tasto: 0xA98BFF, suTasto: 0x160E2B, caldo: 0xFFB454, freddo: 0x7CC7FF, riempimento: 0x352A52)
        case .ossidiana:
            .init(fondo: [0x000000, 0x0B0910, 0x1C1727], schedaDa: 0x1D1826, schedaA: 0x120F18,
                  testo: 0xFFFFFF, secondario: 0xB4AEC2, accento: 0xC4B5FD, suAccento: 0x17102E,
                  tasto: 0xC4B5FD, suTasto: 0x17102E, caldo: 0xF9A8D4, freddo: 0x93C5FD, riempimento: 0x262033)
        case .giorno:
            // Il neon su fondo chiaro non si legge: resta sui tasti, testi e anelli usano un verde scuro
            .init(fondo: [0xF7FAF5, 0xE7EFE4, 0xCBD8C9], schedaDa: 0xFFFFFF, schedaA: 0xF1F6EF,
                  testo: 0x18211B, secondario: 0x4E5B52, accento: 0x1C7F08, suAccento: 0xFFFFFF,
                  tasto: 0x39FF14, suTasto: 0x0A1A04, caldo: 0xC2410C, freddo: 0x6D3FD1, riempimento: 0xE4ECE1)
        }
    }
}

struct Palette {
    // I colori in esadecimale (0xRRGGBB): servono anche ai test del contrasto
    struct Esadecimali {
        var fondo: [UInt32]   // tre tappe, a 165°
        var schedaDa, schedaA: UInt32   // due tappe, a 160°
        var testo, secondario, accento, suAccento, tasto, suTasto, caldo, freddo, riempimento: UInt32
    }

    let esadecimali: Esadecimali
    let fondo: LinearGradient
    let scheda: LinearGradient
    let testo, secondario, accento, suAccento, tasto, suTasto, caldo, freddo, riempimento: Color

    init(esadecimali e: Esadecimali) {
        esadecimali = e
        fondo = LinearGradient(colors: e.fondo.map(Palette.colore), startPoint: Palette.punto(165).0, endPoint: Palette.punto(165).1)
        scheda = LinearGradient(colors: [Palette.colore(e.schedaDa), Palette.colore(e.schedaA)],
                                startPoint: Palette.punto(160).0, endPoint: Palette.punto(160).1)
        testo = Palette.colore(e.testo)
        secondario = Palette.colore(e.secondario)
        accento = Palette.colore(e.accento)
        suAccento = Palette.colore(e.suAccento)
        tasto = Palette.colore(e.tasto)
        suTasto = Palette.colore(e.suTasto)
        caldo = Palette.colore(e.caldo)
        freddo = Palette.colore(e.freddo)
        riempimento = Palette.colore(e.riempimento)
    }

    static func colore(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }

    // Angolo CSS (0° = verso l'alto, in senso orario) → punti di partenza e arrivo
    private static func punto(_ gradi: Double) -> (UnitPoint, UnitPoint) {
        let r = gradi * .pi / 180
        let (dx, dy) = (sin(r) / 2, -cos(r) / 2)
        return (UnitPoint(x: 0.5 - dx, y: 0.5 - dy), UnitPoint(x: 0.5 + dx, y: 0.5 + dy))
    }
}

extension EnvironmentValues {
    @Entry var palette: Palette = Tema.halloween.palette
}

extension Text {
    // Georgia solo per il nome dell'app e i titoli: mai per i numeri
    func titoloApp(_ stile: Font.TextStyle) -> Text {
        font(.custom("Georgia", size: Self.dimensione(stile), relativeTo: stile))
    }

    private static func dimensione(_ stile: Font.TextStyle) -> CGFloat {
        switch stile {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body: 17
        case .callout: 16
        case .subheadline: 15
        default: 13
        }
    }
}
