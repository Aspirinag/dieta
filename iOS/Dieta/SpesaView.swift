import SwiftUI

// Lista della spesa dei prossimi 7 giorni, per tutti i profili.
// Divisa per reparto come al supermercato; quantità a destra in grassetto; ciò che è già preso scende in fondo
struct SpesaView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.palette) private var palette

    var body: some View {
        let voci = archivio.vociSpesa()
        Group {
            if voci.isEmpty {
                ScrollView {
                    StatoVuoto(titolo: "Nessun piano nei prossimi 7 giorni", icona: "cart").padding(16)
                }
            } else {
                elenco(voci)
            }
        }
        .navigationTitle("Lista della spesa")
        .navigationBarTitleDisplayMode(.inline)
        .sfondoTema()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: testoSpesa, preview: SharePreview("Lista della spesa")) {
                    Label("Condividi", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    private func elenco(_ voci: [VoceSpesa]) -> some View {
        let profili = archivio.profiliSpesa
        let presi = archivio.spunteSpesa()
        let giorni = Giorni.prossimi7()
        let daPrendere = voci.filter { presi[$0.chiave] != true }
        let nelCarrello = voci.filter { presi[$0.chiave] == true }
        return List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(daPrendere.isEmpty ? "Tutto preso" : "Ancora \(daPrendere.count) da prendere")
                            .font(.georgia(.headline))
                            .contentTransition(.numericText())
                        Spacer()
                        Text("\(nelCarrello.count)/\(voci.count)").foregroundStyle(palette.secondario)
                    }
                    ProgressView(value: Double(nelCarrello.count), total: Double(voci.count))
                    Text("Dal \(Giorni.breve(giorni[0])) al \(Giorni.breve(giorni[6]))"
                         + (profili.count > 1 ? " · per \(profili.map(\.nome).formatted(.list(type: .and)))" : ""))
                        .font(.georgia(.caption))
                        .foregroundStyle(palette.secondario)
                }
                .padding(.vertical, 4)
            }
            .sezioneTema()
            ForEach(Calorie.Reparto.allCases, id: \.self) { r in
                let righe = daPrendere.filter { $0.reparto == r }
                if !righe.isEmpty {
                    Section {
                        ForEach(righe) { v in rigaSpesa(v, preso: false) }
                    } header: {
                        HStack(spacing: 8) {
                            Image(systemName: r.icona)
                                .font(.georgia(.caption, grassetto: true))
                                .foregroundStyle(palette.accento)
                                .frame(width: 24, height: 24)
                                .background(palette.riempimento, in: .rect(cornerRadius: 7))
                            Text(r.nome)
                            Spacer()
                            Text("\(righe.count)")
                        }
                        .font(.georgia(.subheadline))
                        .foregroundStyle(palette.secondario)
                        .textCase(nil)
                    }
                    .sezioneTema()
                }
            }
            if !nelCarrello.isEmpty {
                Section {
                    ForEach(nelCarrello) { v in rigaSpesa(v, preso: true) }
                    Button("Togli tutte le spunte", systemImage: "arrow.counterclockwise") { archivio.azzeraSpesa() }
                } header: {
                    Label("Già nel carrello", systemImage: "cart.fill")
                        .font(.georgia(.subheadline))
                        .foregroundStyle(palette.secondario)
                        .textCase(nil)
                }
                .sezioneTema()
            }
            Section {
            } footer: {
                Text((profili.count > 1 ? "Le quantità sono la somma di tutti i profili (sotto ogni voce la parte di ciascuno) e le spunte valgono per tutti. " : "")
                     + "×5 vuol dire 5 di quell'alimento (es. 5 banane). Comprende oggi e i 6 giorni successivi; per ogni pasto conta l'alternativa scelta in Dieta, altrimenti la prima. Ogni spunta dura 7 giorni.")
                    .font(.georgia(.footnote))
                    .foregroundStyle(palette.secondario)
            }
        }
    }

    private func rigaSpesa(_ v: VoceSpesa, preso: Bool) -> some View {
        Button {
            withAnimation(.snappy) { archivio.spunta(v.chiave) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: preso ? "checkmark.circle.fill" : "circle")
                    .font(.georgia(.title3))
                    .foregroundStyle(preso ? palette.accento : palette.secondario)
                VStack(alignment: .leading, spacing: 2) {
                    Text(v.nome).strikethrough(preso)
                    if let d = v.dettaglio, !preso {
                        Text(d).font(.georgia(.caption)).foregroundStyle(palette.secondario)
                    }
                }
                Spacer(minLength: 12)
                Text(v.quanto)
                    .font(.georgia(.body, grassetto: v.quanto != "q.b."))
                    .foregroundStyle(v.quanto == "q.b." || preso ? palette.secondario : palette.testo)
                    .multilineTextAlignment(.trailing)
            }
            .opacity(preso ? 0.55 : 1)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: preso)
    }

    // Da condividere (es. su WhatsApp): solo ciò che manca, per reparto
    private var testoSpesa: String {
        let presi = archivio.spunteSpesa()
        let mancano = archivio.vociSpesa().filter { presi[$0.chiave] != true }
        var righe = ["Lista della spesa"]
        for r in Calorie.Reparto.allCases {
            let voci = mancano.filter { $0.reparto == r }
            guard !voci.isEmpty else { continue }
            righe.append("\n" + r.nome.uppercased())
            righe += voci.map { "- \($0.nome)" + ($0.quanto.isEmpty ? "" : ": \($0.quanto)") }
        }
        return righe.joined(separator: "\n")
    }
}
