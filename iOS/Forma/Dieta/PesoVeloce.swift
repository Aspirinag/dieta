import SwiftUI

// Peso veloce da Oggi: un foglio con il solo peso. La logica sta qui, senza vista, per i test
enum PesoVeloce {
    // Aggiunge la misura del giorno, o ne aggiorna il peso lasciando gli altri dati
    static func registra(_ kg: Double, il giorno: String, in misure: [Misura]) -> [Misura] {
        var m = misure.first { $0.data == giorno } ?? Misura(data: giorno)
        m.peso = kg
        return misure.filter { $0.data != giorno } + [m]
    }

    // Ultima misura che ha il peso (le altre, per esempio solo la vita, non contano)
    static func ultimo(_ misure: [Misura]) -> Misura? {
        misure.filter { $0.peso != nil }.max { $0.data < $1.data }
    }

    // Da quando è l'ultimo peso: oggi, ieri, 3 giorni fa; oltre una settimana la data
    static func etichetta(_ data: String, oggi: String, bundle: Bundle = .main) -> String {
        let giorni = Giorni.calendario.dateComponents([.day], from: Giorni.data(data), to: Giorni.data(oggi)).day ?? 0
        switch giorni {
        case ..<1: return String(localized: "oggi", bundle: bundle)
        case 1: return String(localized: "ieri", bundle: bundle)
        case 2...6: return String(localized: "\(giorni) giorni fa", bundle: bundle)
        default: return Giorni.breve(data)
        }
    }
}

extension Pasto {
    // Gli alimenti dell'alternativa su una riga: «Yogurt greco 150 g, avena 40 g»
    static func riga(_ o: Opzione) -> String? {
        let voci = o.alimenti.enumerated().compactMap { i, a -> String? in
            let nome = a.nome.trimmingCharacters(in: .whitespaces)
            guard !nome.isEmpty else { return nil }
            let testo = ((i == 0 ? nome : nome.prefix(1).lowercased() + nome.dropFirst()) + " " + a.quantita)
            return testo.trimmingCharacters(in: .whitespaces)
        }
        return voci.isEmpty ? nil : voci.joined(separator: ", ")
    }
}

// Foglio piccolo: il peso, «Salva», e il rimando al modulo completo
struct PesoVeloceView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.dismiss) private var chiudi
    // Quando si sceglie «Altri dati»: il peso scritto fin lì
    let altriDati: (Double?) -> Void

    @State private var testo = ""
    @FocusState private var scrivendo: Bool

    // L'ultimo peso è solo un suggerimento in grigio: non si salva mai senza averlo scritto
    private var suggerimento: String { PesoVeloce.ultimo(archivio.profilo.bia)?.peso.map { num($0) } ?? "–" }

    private var kg: Double? { leggiNumero(testo).flatMap { $0 > 0 && $0 < 500 ? $0 : nil } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Peso").font(.headline)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField(suggerimento, text: $testo)
                    .font(.system(size: 44, weight: .bold))
                    .monospacedDigit()
                    .keyboardType(.decimalPad)
                    .focused($scrivendo)
                    .accessibilityIdentifier("campo-peso")
                    .accessibilityLabel("Peso")
                Text("kg").font(.title3).foregroundStyle(.secondary)
            }
            Button {
                guard let kg else { return }
                archivio.salvaPeso(kg)
                chiudi()
            } label: {
                Text("Salva").frame(maxWidth: .infinity, minHeight: 28)
            }
            .buttonStyle(PulsanteAccento())
            .disabled(kg == nil)
            .accessibilityIdentifier("salva-peso")
            Button("Altri dati") {
                altriDati(kg)
                chiudi()
            }
            .font(.subheadline)
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
        .sfondoTema()
        .onAppear { scrivendo = true }
    }
}
