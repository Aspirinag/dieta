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

    // Variazione rispetto a circa 30 giorni prima dell'ultimo peso (non rispetto alla prima misura).
    // Si usa la misura più vicina a 30 giorni prima, purché sia tra 23 e 37 giorni prima: altrimenti
    // «in 30 giorni» non sarebbe vero e non si mostra niente
    static func variazione(_ misure: [Misura], ultimo: Misura) -> Double? {
        guard let kg = ultimo.peso else { return nil }
        let fine = Giorni.data(ultimo.data)
        let candidate = misure.compactMap { m -> (Double, Int)? in
            guard let peso = m.peso, m.data != ultimo.data else { return nil }
            let giorni = Giorni.calendario.dateComponents([.day], from: Giorni.data(m.data), to: fine).day ?? 0
            return (23...37).contains(giorni) ? (peso, abs(giorni - 30)) : nil
        }
        guard let scelta = candidate.min(by: { $0.1 < $1.1 }) else { return nil }
        return kg - scelta.0
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

// Foglio piccolo: il peso (già compilato con l'ultimo, è un valore vero), −0,1 / +0,1, «Salva» e il rimando al modulo completo
struct PesoVeloceView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.dismiss) private var chiudi
    // Quando si sceglie «Altri dati»: il peso scritto fin lì
    let altriDati: (Double?) -> Void

    @State private var testo = ""
    @State private var iniziato = false
    @FocusState private var scrivendo: Bool

    private var kg: Double? { leggiNumero(testo).flatMap { $0 > 0 && $0 < 500 ? $0 : nil } }

    private func passo(_ delta: Double) {
        guard let kg else { return }
        testo = num(((kg + delta) * 10).rounded() / 10)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Peso").font(.headline)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField("–", text: $testo)
                    .numero(.largeTitle)
                    .keyboardType(.decimalPad)
                    .focused($scrivendo)
                    .accessibilityIdentifier("campo-peso")
                    .accessibilityLabel("Peso")
                Text("kg").font(.title3).foregroundStyle(.secondary)
                Button { passo(-0.1) } label: {
                    Text(verbatim: "\u{2212}" + num(0.1)).numero(.body).frame(minWidth: Misure.tocco, minHeight: Misure.tocco)
                }
                .buttonStyle(.bordered)
                .disabled(kg == nil)
                .accessibilityLabel("Diminuisci di 0,1 kg")
                .accessibilityIdentifier("peso-meno")
                Button { passo(0.1) } label: {
                    Text(verbatim: "+" + num(0.1)).numero(.body).frame(minWidth: Misure.tocco, minHeight: Misure.tocco)
                }
                .buttonStyle(.bordered)
                .disabled(kg == nil)
                .accessibilityLabel("Aumenta di 0,1 kg")
                .accessibilityIdentifier("peso-piu")
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
            if kg == nil {
                Text("Scrivi il tuo peso per poterlo salvare")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("peso-spiegazione")
            }
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
        .onAppear {
            guard !iniziato else { return }
            iniziato = true
            // L'ultimo peso è un valore vero: si salva com'è, o si cambia di 0,1 o lo si riscrive
            if let ultimo = PesoVeloce.ultimo(archivio.profilo.bia)?.peso { testo = num(ultimo) }
            scrivendo = true
        }
        // Toccando il campo il numero si seleziona tutto: scrivere lo sostituisce
        .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { n in
            (n.object as? UITextField)?.selectAll(nil)
        }
    }
}
