import SwiftUI

// Un pasto di un giorno: l'alternativa, le quantità riga per riga e «Fatto» in barra (la stessa spunta di Oggi e Dieta)
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
            if let pasto {
                contenuto(pasto)
            }
        }
        .sfondoTema()
        .navigationTitle(pasto?.nome ?? String(localized: "Pasto"))
        .navigationSubtitleSePossibile(Testi.data(iso: giorno))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let pasto { ToolbarItem(placement: .confirmationAction) { pulsanteFatto(pasto) } }
        }
    }

    // «Fatto» pieno in barra; segnato diventa «Fatto ✓» e si annulla ritoccandolo
    private func pulsanteFatto(_ pasto: Pasto) -> some View {
        let fatto = archivio.slot(giorno, indice).fatto
        return Button {
            archivio.cambiaSlot(giorno, indice) { $0.fatto.toggle() }
        } label: {
            if fatto { Label("Fatto", systemImage: "checkmark") } else { Text("Fatto") }
        }
        .buttonStyle(.borderedProminent)
        .tint(Colori.accento)
        .foregroundStyle(Colori.sulAccento)
        .disabled(giorno > Giorni.oggi())   // un pasto futuro non si segna
        .sensoryFeedback(.selection, trigger: fatto)
        .accessibilityLabel("Segna \(pasto.nome)")
        .accessibilityValue(fatto ? Text("fatto") : Text("da fare"))
        .accessibilityAddTraits(fatto ? .isSelected : [])
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
                        Text(pasto.nomeAlternativa(j)).tag(j)
                    }
                }
                Group {
                    if pasto.opzioni.count <= 3 {
                        scelte.segmentiOMenu()
                    } else {
                        scelte.pickerStyle(.menu)
                    }
                }
                .righeTema()
            }
        }
        if pasto.opzioni.indices.contains(scelta) {
            let alimenti = pasto.opzioni[scelta].alimenti
            Section {
                ForEach(alimenti.indices, id: \.self) { i in
                    // Nome che va a capo e quantità sempre intera a destra (o sotto, a testo molto grande)
                    Riga(Text(alimenti[i].nome),
                         valore: alimenti[i].quantita.isEmpty ? nil : Text(alimenti[i].quantita),
                         fatta: s.fatto)
                        .righeTema()
                }
            }
        }
    }
}
