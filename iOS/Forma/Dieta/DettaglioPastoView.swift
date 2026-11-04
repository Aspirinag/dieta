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
        ScrollView {
            VStack(spacing: 12) {
                if let pasto {
                    contenuto(pasto)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .sfondoTema()
        .navigationTitle(pasto?.nome ?? String(localized: "Pasto"))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func contenuto(_ pasto: Pasto) -> some View {
        let s = archivio.slot(giorno, indice)
        let scelta = pasto.opzioni.indices.contains(s.opt) ? s.opt : 0
        Riquadro {
            Text("\(Giorni.nomeGiorno(Giorni.indice(giorno))) \(Giorni.calendario.component(.day, from: Giorni.data(giorno)))")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.bottom, 6)
            if pasto.opzioni.count > 1 {
                let scelte = Picker("Alternativa", selection: Binding(
                    get: { scelta },
                    set: { nuova in archivio.cambiaSlot(giorno, indice) { $0.opt = nuova } }
                )) {
                    ForEach(pasto.opzioni.indices, id: \.self) { j in
                        Text(pasto.opzioni[j].titolo ?? String(localized: "Alternativa \(j + 1)")).tag(j)
                    }
                }
                Group {
                    if pasto.opzioni.count <= 3 {
                        scelte.segmentiOMenu()
                    } else {
                        scelte.pickerStyle(.menu)
                    }
                }
                .padding(.bottom, 4)
            }
            if pasto.opzioni.indices.contains(scelta) {
                let alimenti = pasto.opzioni[scelta].alimenti
                ForEach(alimenti.indices, id: \.self) { i in
                    if i > 0 { Divider() }
                    RigaAlimento(nome: alimenti[i].nome, quantita: alimenti[i].quantita)
                        .padding(.vertical, 8)
                        .opacity(s.fatto ? 0.5 : 1)
                }
            }
        }
        Riquadro {
            RigaSpunta(fatto: s.fatto, azione: {
                archivio.cambiaSlot(giorno, indice) { $0.fatto.toggle() }
            }) {
                Text(s.fatto ? LocalizedStringKey("Fatto") : LocalizedStringKey("Segna come fatto"))
            }
            .frame(minHeight: 44)
            // VoiceOver: «Colazione, fatto» invece di «Fatto, fatto»
            .accessibilityLabel(pasto.nome)
        }
    }
}
