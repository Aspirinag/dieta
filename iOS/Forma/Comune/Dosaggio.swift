import SwiftUI

// Una dose da segnare toccando: un cucchiaino o una goccia per unità.
// Toccare l'elemento n segna n; ritoccare l'ultimo segnato lo toglie.
// Oltre la dose gli elementi diventano arancioni, fino al doppio della dose.
struct Dosaggio: View {
    let nome: String
    let unita: String
    @Binding var valore: Int
    let dose: Int
    let colore: Color
    let simbolo: SimboloDose
    var quantitaPerElemento: Double = 1     // 0,25 per le gocce (litri)
    var doseTesto: String? = nil            // dose esatta, se non è un multiplo degli elementi
    @Environment(\.dynamicTypeSize) private var dimensione

    private static let lato: CGFloat = 24

    private var massimo: Int { max(dose * 2, 1) }
    // Con la dose raggiunta compare un elemento vuoto in più, per poter andare oltre
    private var visibili: Int { min(max(dose, valore + (valore >= dose ? 1 : 0)), massimo) }

    var testo: String {
        "\(num(Double(valore) * quantitaPerElemento)) di \(doseTesto ?? num(Double(dose) * quantitaPerElemento)) \(unita)"
    }

    var body: some View {
        let colonne = [GridItem(.adaptive(minimum: Self.lato, maximum: Self.lato), spacing: 0, alignment: .center)]
        Group {
            if dimensione.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    etichetta
                    LazyVGrid(columns: colonne, alignment: .leading, spacing: 0) { elementi }
                }
            } else {
                HStack(spacing: 8) {
                    etichetta
                    Spacer(minLength: 8)
                    LazyVGrid(columns: colonne, alignment: .trailing, spacing: 0) { elementi }
                        .frame(maxWidth: Self.lato * CGFloat(min(visibili, 12)), alignment: .trailing)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(nome)
        .accessibilityValue(testo)
        .accessibilityAdjustableAction { direzione in
            switch direzione {
            case .increment: valore = min(valore + 1, massimo)
            case .decrement: valore = max(valore - 1, 0)
            @unknown default: break
            }
        }
        .sensoryFeedback(.selection, trigger: valore)
    }

    private var etichetta: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(nome)
            Text(testo).font(.footnote).foregroundStyle(.secondary).monospacedDigit()
        }
    }

    private var elementi: some View {
        ForEach(1...visibili, id: \.self) { n in
            let pieno = n <= valore
            let oltre = n > dose
            Button {
                valore = (n == valore) ? n - 1 : n
            } label: {
                forma
                    .fill(pieno ? (oltre ? Color.orange : colore) : (oltre ? Color.orange.opacity(0.25) : Color(.systemFill)))
                    .frame(width: simbolo == .cucchiaino ? 13 : 16, height: simbolo == .cucchiaino ? 22 : 18)
                    .frame(width: Self.lato, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var forma: AnyShape {
        simbolo == .cucchiaino ? AnyShape(Cucchiaino()) : AnyShape(Goccia())
    }
}
