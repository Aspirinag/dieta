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

    // Ogni elemento da toccare è alto 44 punti e largo fino a 44: sulla stessa riga si stringono (mai sotto 32), poi vanno a capo
    private static let lato: CGFloat = 44
    private static let latoMinimo: CGFloat = 32
    @State private var larghezza: CGFloat = 0

    private var massimo: Int { max(dose * 2, 1) }
    // Con la dose raggiunta compare un elemento vuoto in più, per poter andare oltre
    private var visibili: Int { min(max(dose, valore + (valore >= dose ? 1 : 0)), massimo) }

    var testo: String {
        "\(num(Double(valore) * quantitaPerElemento)) di \(doseTesto ?? num(Double(dose) * quantitaPerElemento)) \(unita)"
    }

    var body: some View {
        let larghezzaElemento = larghezza > 0 ? min(Self.lato, larghezza / CGFloat(visibili)) : Self.lato
        VStack(alignment: .leading, spacing: 0) {
            etichetta
            if larghezzaElemento >= Self.latoMinimo {
                // La riga non decide la larghezza: la misura viene dal segnaposto, gli elementi stanno sopra
                Color.clear.frame(maxWidth: .infinity).frame(height: Self.lato)
                    .overlay(alignment: .leading) { HStack(spacing: 0) { elementi(larghezzaElemento) } }
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: Self.latoMinimo, maximum: Self.lato), spacing: 0)], alignment: .leading, spacing: 0) {
                    elementi(Self.latoMinimo)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { Color.clear.onGeometryChange(for: CGFloat.self) { $0.size.width } action: { larghezza = $0 } }
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

    private func elementi(_ larghezza: CGFloat) -> some View {
        ForEach(1...visibili, id: \.self) { n in
            let pieno = n <= valore
            let oltre = n > dose
            Button {
                valore = (n == valore) ? n - 1 : n
            } label: {
                forma
                    .fill(pieno ? (oltre ? Color.orange : colore) : (oltre ? Color.orange.opacity(0.25) : Color(.systemFill)))
                    .frame(width: simbolo == .cucchiaino ? 12 : 16, height: simbolo == .cucchiaino ? 26 : 18)
                    .frame(width: larghezza, height: Self.lato)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var forma: AnyShape {
        simbolo == .cucchiaino ? AnyShape(Cucchiaino()) : AnyShape(Goccia())
    }
}
