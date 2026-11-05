import SwiftUI

// SISTEMA VISIVO — ingranaggio delle Impostazioni, in alto a destra in TUTTE e quattro le schede (S4).
// Apre il foglio delle Impostazioni (Navigazione.impostazioniAperte). Va messo come ultima voce a destra:
//   .toolbar { ToolbarItem(placement: .topBarTrailing) { PulsanteImpostazioni() } }
// oppure dentro un ToolbarItemGroup(placement: .topBarTrailing) già presente, per ultimo.
// L'icona è .primary come le altre icone della barra: il verde resta all'azione principale.
// Nei test dell'interfaccia: app.buttons["Impostazioni"].
struct PulsanteImpostazioni: View {
    @Environment(Navigazione.self) private var navigazione

    var body: some View {
        Button("Impostazioni", systemImage: "gearshape") { navigazione.impostazioniAperte = true }
            .tint(.primary)
    }
}
