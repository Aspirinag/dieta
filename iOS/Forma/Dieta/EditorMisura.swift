import SwiftUI

// Nuova misurazione BIA a mano, oppure modifica di una esistente.
// In modifica restano anche i valori letti dal PDF che il modulo non mostra
struct EditorMisura: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.dismiss) private var chiudi
    let dataEsistente: String?
    // Peso già scritto nel foglio veloce di Oggi
    var pesoIniziale: Double?

    @State private var data = Date()
    @State private var valori: [CampoMisura: String] = [:]
    @State private var caricato = false
    @State private var chiediSostituzione = false
    @ScaledMetric(relativeTo: .body) private var larghezzaUnita: CGFloat = 44   // colonna delle unità, uguale per tutte le righe

    private var esistente: Misura? {
        dataEsistente.flatMap { d in archivio.profilo.bia.first { $0.data == d } }
    }

    // Valore dell'ultima volta (misura precedente a questa), mostrato in grigio sotto l'etichetta: non è nel campo
    private func ultima(_ c: CampoMisura) -> Double? {
        archivio.profilo.bia
            .filter { m in m[c] != nil && m.data != dataEsistente && (dataEsistente.map { m.data < $0 } ?? true) }
            .max { $0.data < $1.data }?[c]
    }

    var body: some View {
        Form {
            Group {
                Section {
                    if let d = dataEsistente {
                        LabeledContent("Data", value: Testi.data(iso: d, anno: true))
                    } else {
                        DatePicker("Data", selection: $data, in: ...Date(), displayedComponents: .date)
                    }
                } footer: {
                    // Il ✓ in alto resta spento finché manca il peso: lo si dice subito sotto la data, in vista
                    if leggiNumero(valori[.peso] ?? "") == nil {
                        Text("Per salvare scrivi almeno il peso.")
                    }
                }
                Section {
                    ForEach(CampoMisura.allCases) { c in
                        LabeledContent {
                            HStack {
                                TextField("", text: Binding(get: { valori[c] ?? "" }, set: { valori[c] = $0 }))
                                    .keyboardType(c == .bmr || c == .vat ? .numberPad : .decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .accessibilityLabel(c.nome)
                                    .frame(minHeight: Misure.tocco)
                                Text(c.unita).foregroundStyle(.secondary)
                                    .frame(width: larghezzaUnita, alignment: .leading)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(c.nome)
                                if let u = ultima(c) {
                                    Text("ultima: \(num(u)) \(c.unita)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
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
            .righeTema()
        }
        .sfondoTema()
        .navigationTitle(dataEsistente == nil ? LocalizedStringKey("Nuova misurazione") : LocalizedStringKey("Modifica misurazione"))
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
            if let p = pesoIniziale { valori[.peso] = num(p) }
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
