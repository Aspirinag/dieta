import SwiftUI

// Un pasto di un giorno: l'alternativa, le quantità riga per riga e la spunta (la stessa di Oggi)
struct DettaglioPastoView: View {
    @Environment(Archivio.self) private var archivio
    let giorno: String
    let indice: Int

    private var pasto: Pasto? {
        guard let piano = archivio.profilo.piano(per: giorno) else { return nil }
        let pasti = piano.giorni[Giorni.indice(giorno)].pasti
        return pasti.indices.contains(indice) ? pasti[indice] : nil
    }

    var body: some View {
        List {
            Group {
                if let pasto {
                    contenuto(pasto)
                }
            }
            .righeTema()
        }
        .sfondoTema()
        .navigationTitle(pasto?.nome ?? "Pasto")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func contenuto(_ pasto: Pasto) -> some View {
        let s = archivio.slot(giorno, indice)
        let scelta = pasto.opzioni.indices.contains(s.opt) ? s.opt : 0
        if pasto.opzioni.count > 1 {
            Section {
                let scelte = Picker("Alternativa", selection: Binding(
                    get: { scelta },
                    set: { nuova in archivio.cambiaSlot(giorno, indice) { $0.opt = nuova } }
                )) {
                    ForEach(pasto.opzioni.indices, id: \.self) { j in
                        Text(pasto.opzioni[j].titolo ?? "Opzione \(j + 1)").tag(j)
                    }
                }
                if pasto.opzioni.count <= 3 {
                    scelte.segmentiOMenu()
                } else {
                    scelte.pickerStyle(.menu)
                }
            }
        }
        Section {
            if pasto.opzioni.indices.contains(scelta) {
                ForEach(Array(pasto.opzioni[scelta].alimenti.enumerated()), id: \.offset) { _, a in
                    RigaAlimento(nome: a.nome, quantita: a.quantita)
                        .opacity(s.fatto ? 0.5 : 1)
                }
            }
        } header: {
            Text("\(Giorni.nomi[Giorni.indice(giorno)]) \(Giorni.calendario.component(.day, from: Giorni.data(giorno)))")
        }
        Section {
            RigaSpunta(fatto: s.fatto, azione: {
                archivio.cambiaSlot(giorno, indice) { $0.fatto.toggle() }
            }) {
                Text(s.fatto ? "Fatto" : "Segna come fatto")
            }
            // VoiceOver: «Colazione, fatto» invece di «Fatto, fatto»
            .accessibilityLabel(pasto.nome)
        }
    }
}
