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

    // Ogni elemento da toccare è largo e alto almeno 44 punti; se non stanno in una riga vanno a capo
    private static let lato: CGFloat = 44

    private var massimo: Int { max(dose * 2, 1) }
    // Con la dose raggiunta compare un elemento vuoto in più, per poter andare oltre
    private var visibili: Int { min(max(dose, valore + (valore >= dose ? 1 : 0)), massimo) }

    var testo: String {
        "\(num(Double(valore) * quantitaPerElemento)) di \(doseTesto ?? num(Double(dose) * quantitaPerElemento)) \(unita)"
    }

    var body: some View {
        let colonne = [GridItem(.adaptive(minimum: Self.lato, maximum: Self.lato), spacing: 0, alignment: .center)]
        VStack(alignment: .leading, spacing: 0) {
            etichetta
            LazyVGrid(columns: colonne, alignment: .leading, spacing: 0) { elementi }
                .padding(.leading, -12)    // il primo segno si allinea al testo
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                    .frame(width: simbolo == .cucchiaino ? 28 : 16, height: simbolo == .cucchiaino ? 14 : 18)
                    .rotationEffect(.degrees(simbolo == .cucchiaino ? -40 : 0))
                    .frame(width: Self.lato, height: Self.lato)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var forma: AnyShape {
        simbolo == .cucchiaino ? AnyShape(Cucchiaino()) : AnyShape(Goccia())
    }
}
