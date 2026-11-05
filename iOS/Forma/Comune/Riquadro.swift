import SwiftUI

// SISTEMA VISIVO — riquadro fuori dalle liste. Solo per «un numero con il suo andamento» (peso, volume
// della settimana) o per «l'azione principale» della schermata (la scheda di oggi con «Inizia»). Mai per
// una riga di testo: per quello c'è Riga in una List. Dentro una List non serve: la sezione è già il riquadro.
//   Riquadro { Text("Peso").font(.headline); Text(num(kg)).numero(.largeTitle) }
// Bianco (grigio rialzato in scuro), margini Spazio.l / Spazio.m, raggio Misure.raggio.
struct Riquadro<Contenuto: View>: View {
    @ViewBuilder let contenuto: Contenuto

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { contenuto }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spazio.l)
            .padding(.vertical, Spazio.m)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: Misure.raggio, style: .continuous))
    }
}
