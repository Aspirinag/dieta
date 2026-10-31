import SwiftUI

// Per ora solo il posto della scheda: routine, allenamento libero, storico e cardio arrivano dopo
struct AllenamentoView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                StatoVuoto(titolo: "Allenamento in arrivo", icona: "dumbbell",
                           descrizione: "Qui troverai routine, allenamento libero, storico e cardio.")
                    .padding(16)
            }
            .navigationTitle("Allenamento")
            .sfondoTema()
        }
    }
}
