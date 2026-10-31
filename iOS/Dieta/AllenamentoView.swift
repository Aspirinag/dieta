import SwiftUI

// Per ora solo l'allenamento libero: routine, storico e cardio arrivano dopo.
// L'allenamento interrotto da una chiusura dell'app si riapre da solo (vedi schermataAllenamento)
struct AllenamentoView: View {
    @Environment(Archivio.self) private var archivio

    var body: some View {
        NavigationStack {
            ScrollView {
                StatoVuoto(titolo: "Allenamento libero", icona: "dumbbell",
                           descrizione: "Scegli gli esercizi mentre ti alleni: ogni serie segnata si salva subito.") {
                    if archivio.profilo.allenamentoInCorso != nil {
                        Button("Riprendi allenamento") { archivio.allenamentoAperto = true }
                            .buttonStyle(TastoTema())
                    } else {
                        Button("Inizia allenamento") { archivio.iniziaAllenamento(nil) }
                            .buttonStyle(TastoTema())
                    }
                }
                .padding(16)
            }
            .navigationTitle("Allenamento")
            .sfondoTema()
        }
    }
}
