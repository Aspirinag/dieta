import SwiftUI

// Nuova misurazione BIA a mano, oppure modifica di una esistente.
// In modifica restano anche i valori letti dal PDF che il modulo non mostra
struct EditorMisura: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.dismiss) private var chiudi
    let dataEsistente: String?

    @State private var data = Date()
    @State private var valori: [CampoMisura: String] = [:]
    @State private var caricato = false
    @State private var chiediSostituzione = false

    private var esistente: Misura? {
        dataEsistente.flatMap { d in archivio.profilo.bia.first { $0.data == d } }
    }

    var body: some View {
        Form {
            Section {
                if let d = dataEsistente {
                    LabeledContent("Data", value: Giorni.breve(d))
                } else {
                    DatePicker("Data", selection: $data, in: ...Date(), displayedComponents: .date)
                }
            }
            Section {
                ForEach(CampoMisura.allCases) { c in
                    LabeledContent(c.nome) {
                        HStack {
                            TextField("–", text: Binding(get: { valori[c] ?? "" }, set: { valori[c] = $0 }))
                                .keyboardType(c == .bmr || c == .vat ? .numberPad : .decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text(c.unita).foregroundStyle(.secondary).frame(width: 40, alignment: .leading)
                        }
                    }
                }
            } footer: {
                Text("Serve almeno il peso.")
            }
            if dataEsistente != nil {
                Section {
                    Button("Elimina misurazione", role: .destructive) {
                        archivio.profilo.bia.removeAll { $0.data == dataEsistente }
                        chiudi()
                    }
                }
            }
        }
        .navigationTitle(dataEsistente == nil ? "Nuova misurazione" : "Modifica misurazione")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if dataEsistente == nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla", role: .cancel) { chiudi() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Salva", systemImage: "checkmark") { salva(conferma: false) }
                    .disabled(leggiNumero(valori[.peso] ?? "") == nil)
            }
        }
        .alert("C'è già una misurazione in questa data", isPresented: $chiediSostituzione) {
            Button("Sostituisci", role: .destructive) { salva(conferma: true) }
            Button("Annulla", role: .cancel) {}
        }
        .onAppear {
            guard !caricato else { return }
            caricato = true
            if let m = esistente {
                for c in CampoMisura.allCases { valori[c] = m[c].map { num($0) } ?? "" }
            }
        }
    }

    private func salva(conferma: Bool) {
        let iso = dataEsistente ?? Giorni.iso(data)
        if dataEsistente == nil, !conferma, archivio.profilo.bia.contains(where: { $0.data == iso }) {
            chiediSostituzione = true
            return
        }
        var m = esistente ?? Misura(data: iso)
        for c in CampoMisura.allCases { m[c] = leggiNumero(valori[c] ?? "") }
        archivio.salvaMisura(m)
        chiudi()
    }
}
