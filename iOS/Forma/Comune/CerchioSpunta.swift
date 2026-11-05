import SwiftUI

// SISTEMA VISIVO — l'UNICA spunta dell'app (pasti, spesa, dettaglio pasto, riscaldamento, serie).
// Cerchio di Misure.spunta (26 pt, cresce con il testo grande) dentro un'area di almeno 44 × 44.
//   vuota: contorno Colori.vuoto (Misure.contorno) su Colori.riempimentoVuoto (≥ 3:1 anche in scuro)
//   fatta: cerchio pieno Colori.accento con il segno Colori.sulAccento
// Lo stato «fatto» va sempre segnato anche in un secondo modo: nome grigio (pasti, spesa) o
// Colori.sfondoFatto sulla riga (serie).
//
// Due usi:
// 1. Pulsante a sé (la spunta ha la sua area di tocco, il resto della riga fa altro):
//      CerchioSpunta(fatta: s.fatto, etichetta: Text("Segna \(pasto.nome)")) { archivio.… .toggle() }
//    Vibrazione .selection, VoiceOver «fatto»/«da fare» (o `stati:` per altri testi, es. «preso»/«da prendere»).
//    `.disabled(true)` lo spegne e lo schiarisce. `vibra: false` se la vibrazione la fa già chi lo usa.
// 2. Solo disegno, dentro un pulsante più grande che ha già etichetta e stato (nascosto a VoiceOver):
//      Button { … } label: { HStack { CerchioSpunta(fatta: fatto); Text(nome) } }
struct CerchioSpunta: View {
    let fatta: Bool
    private let etichetta: Text?
    private let stati: (fatta: LocalizedStringResource, daFare: LocalizedStringResource)
    private let vibra: Bool
    private let azione: (() -> Void)?

    // Solo disegno
    init(fatta: Bool) {
        self.fatta = fatta
        self.etichetta = nil
        self.stati = ("fatto", "da fare")
        self.vibra = false
        self.azione = nil
    }

    // Pulsante
    init(fatta: Bool, etichetta: Text,
         stati: (fatta: LocalizedStringResource, daFare: LocalizedStringResource) = ("fatto", "da fare"),
         vibra: Bool = true, azione: @escaping () -> Void) {
        self.fatta = fatta
        self.etichetta = etichetta
        self.stati = stati
        self.vibra = vibra
        self.azione = azione
    }

    var body: some View {
        if let azione {
            Button(action: azione) { DisegnoSpunta(fatta: fatta) }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: fatta) { _, _ in vibra }
                .accessibilityLabel(etichetta ?? Text(verbatim: ""))
                .accessibilityValue(Text(fatta ? stati.fatta : stati.daFare))
                .accessibilityAddTraits(fatta ? .isSelected : [])
        } else {
            DisegnoSpunta(fatta: fatta).accessibilityHidden(true)
        }
    }
}

// Il disegno, con la sua area di tocco
private struct DisegnoSpunta: View {
    let fatta: Bool
    @ScaledMetric(relativeTo: .body) private var lato = Misure.spunta
    @Environment(\.isEnabled) private var attivo

    var body: some View {
        let d = min(lato, Misure.spunta * 1.6)
        ZStack {
            Circle().fill(fatta ? Colori.accento : Colori.riempimentoVuoto)
            if fatta {
                Image(systemName: "checkmark")
                    .resizable()
                    .scaledToFit()
                    .fontWeight(.bold)
                    .foregroundStyle(Colori.sulAccento)
                    .frame(width: d * 0.46, height: d * 0.46)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Circle().strokeBorder(Colori.vuoto, lineWidth: Misure.contorno)
            }
        }
        .frame(width: d, height: d)
        .frame(minWidth: Misure.tocco, minHeight: Misure.tocco)
        .contentShape(.rect)
        .opacity(attivo ? 1 : 0.4)
        .animation(.snappy(duration: 0.2), value: fatta)
    }
}

#Preview {
    @Previewable @State var a = false
    List {
        HStack { CerchioSpunta(fatta: a, etichetta: Text(verbatim: "Colazione")) { a.toggle() }; Text(verbatim: "Colazione") }
        HStack { CerchioSpunta(fatta: true); Text(verbatim: "Pranzo") }
        HStack { CerchioSpunta(fatta: false, etichetta: Text(verbatim: "Cena")) {}.disabled(true); Text(verbatim: "Cena") }
    }
}
