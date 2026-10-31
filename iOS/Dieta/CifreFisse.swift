import SwiftUI

// Georgia ha cifre proporzionali (altezze e larghezze diverse): ogni cifra sta in una casella
// larga quanto la cifra più larga, così timer e colonne non ballano
struct CifreFisse: View {
    let testo: String
    var stile: Font.TextStyle = .body
    var grassetto = false
    var colore: Color?
    @Environment(\.palette) private var palette

    private static let larghezze = NSCache<NSString, NSNumber>()

    private var larghezza: CGFloat {
        let font = UIFont.georgia(Self.stileUIKit(stile), grassetto: grassetto)
        let chiave = "\(font.fontName)-\(font.pointSize)"
        if let w = Self.larghezze.object(forKey: chiave as NSString) { return CGFloat(w.doubleValue) }
        let w = ceil("0123456789".map { String($0).size(withAttributes: [.font: font]).width }.max() ?? font.pointSize / 2)
        Self.larghezze.setObject(NSNumber(value: Double(w)), forKey: chiave as NSString)
        return w
    }

    var body: some View {
        let w = larghezza
        HStack(spacing: 0) {
            ForEach(Array(testo.enumerated()), id: \.offset) { _, c in
                if c.isASCII, c.isNumber {
                    Text(String(c)).frame(width: w)
                } else {
                    Text(String(c))
                }
            }
        }
        .font(.georgia(stile, grassetto: grassetto))
        .foregroundStyle(colore ?? palette.testo)
        .lineLimit(1)
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(testo)
    }

    static func stileUIKit(_ s: Font.TextStyle) -> UIFont.TextStyle {
        switch s {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .callout: .callout
        case .subheadline: .subheadline
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: .body
        }
    }
}

func formatoDurata(_ secondi: TimeInterval) -> String {
    let s = max(0, Int(secondi))
    return s >= 3600 ? String(format: "%d:%02d:%02d", s / 3600, s % 3600 / 60, s % 60) : String(format: "%02d:%02d", s / 60, s % 60)
}

