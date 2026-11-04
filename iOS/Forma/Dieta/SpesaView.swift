import SwiftUI

// Spesa della settimana, aperta da Dieta: prodotti per reparto nell'ordine del negozio.
// Il cerchio segna il prodotto come preso (resta al suo posto, sbiadito e barrato);
// il nome apre i giorni in cui serve; in fondo si aggiunge ciò che non è nel piano
struct SpesaView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.dynamicTypeSize) private var dimensione
    @State private var lunSpesa = Profilo.lunediSpesa(oggi: Giorni.oggi())
    @State private var aperti: Set<String> = []
    @State private var nuovo = ""
    @FocusState private var scrivendo: Bool

    private var questa: String { Giorni.lunedi(Giorni.oggi()) }
    private var prossima: String { Giorni.aggiungi(questa, 7) }

    var body: some View {
        let voci = archivio.profilo.vociSpesa(lunedi: lunSpesa)
        let presi = archivio.spunteSpesa(lunedi: lunSpesa)
        ScrollView {
            VStack(spacing: 12) {
                intestazione(voci: voci, presi: presi)
                if voci.isEmpty {
                    vuoto
                } else {
                    ForEach(Reparto.allCases, id: \.self) { reparto in
                        let righe = voci.filter { $0.reparto == reparto }
                        if !righe.isEmpty { sezione(reparto, righe, presi: presi) }
                    }
                }
                aggiungi
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .sfondoTema()
        .navigationTitle("Spesa")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: testo(voci: voci, presi: presi), preview: SharePreview("Lista della spesa")) {
                    Label("Condividi", systemImage: "square.and.arrow.up")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Togli le spunte", systemImage: "arrow.counterclockwise") {
                        archivio.azzeraSpesa(lunedi: lunSpesa)
                    }
                    .disabled(presi.values.allSatisfy { !$0 })
                } label: {
                    Label("Altro", systemImage: "ellipsis.circle")
                }
            }
        }
    }

    // ---------- Intestazione ----------

    private func intestazione(voci: [Profilo.VoceSpesa], presi: [String: Bool]) -> some View {
        let quanti = voci.filter { presi[$0.chiave] == true }.count
        return VStack(spacing: 8) {
            HStack(spacing: 0) {
                freccia("chevron.left", "Settimana precedente", attiva: lunSpesa != questa) { lunSpesa = questa }
                Text("per la settimana \(periodo) · \(quanti) di \(voci.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                freccia("chevron.right", "Settimana successiva", attiva: lunSpesa != prossima) { lunSpesa = prossima }
            }
            ProgressView(value: Double(quanti), total: Double(max(voci.count, 1)))
                .tint(Colori.accento)
                .accessibilityLabel("Prodotti presi")
                .accessibilityValue("\(quanti) di \(voci.count)")
        }
        .padding(.top, 4)
    }

    private func freccia(_ simbolo: String, _ nome: String, attiva: Bool, azione: @escaping () -> Void) -> some View {
        Button(action: azione) {
            Image(systemName: simbolo)
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(attiva ? Colori.accento : Color(.tertiaryLabel))
        .disabled(!attiva)
        .accessibilityLabel(nome)
    }

    // «2 – 8 novembre», oppure «30 novembre – 6 dicembre» a cavallo di due mesi
    private var periodo: String {
        let dal = Giorni.data(lunSpesa)
        let al = Giorni.data(Giorni.aggiungi(lunSpesa, 6))
        let it = Locale(identifier: "it_IT")
        let giornoAl = al.formatted(.dateTime.day().month(.wide).locale(it))
        if Giorni.calendario.component(.month, from: dal) == Giorni.calendario.component(.month, from: al) {
            return "\(Giorni.calendario.component(.day, from: dal)) – \(giornoAl)"
        }
        return "\(dal.formatted(.dateTime.day().month(.wide).locale(it))) – \(giornoAl)"
    }

    // ---------- Reparti ----------

    private func sezione(_ reparto: Reparto, _ righe: [Profilo.VoceSpesa], presi: [String: Bool]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(reparto.nome)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
                .accessibilityAddTraits(.isHeader)
            Riquadro {
                ForEach(Array(righe.enumerated()), id: \.element.id) { i, voce in
                    if i > 0 { Divider() }
                    riga(voce, preso: presi[voce.chiave] == true)
                }
            }
        }
        .padding(.top, 4)
    }

    private func riga(_ v: Profilo.VoceSpesa, preso: Bool) -> some View {
        let aperta = aperti.contains(v.chiave)
        let giorni = v.giorni.map { "\($0.giorno) \($0.quanto)" }.joined(separator: " · ")
        return HStack(spacing: 4) {
            Button {
                withAnimation(.snappy) { archivio.spunta(v.chiave, lunedi: lunSpesa) }
            } label: {
                Image(systemName: preso ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(preso ? Colori.accento : Color(.secondaryLabel))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.selection, trigger: preso)
            .accessibilityIdentifier("spunta.\(v.chiave)")
            .accessibilityLabel(v.nome)
            .accessibilityValue(preso ? "preso" : "da prendere")

            Button {
                guard !v.giorni.isEmpty else { return }
                withAnimation(.snappy) {
                    if aperta { aperti.remove(v.chiave) } else { aperti.insert(v.chiave) }
                }
            } label: {
                etichetta(v, giorni: aperta ? giorni : "")
                    .opacity(preso ? 0.5 : 1)
                    .strikethrough(preso)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(v.quanto.isEmpty ? v.nome : "\(v.nome), \(v.quanto)")
            .accessibilityValue(aperta ? giorni : "")
            .accessibilityHint(v.giorni.isEmpty ? "" : "Mostra i giorni")
        }
        .contextMenu {
            Menu("Sposta in…", systemImage: "arrow.right") {
                ForEach(Reparto.allCases, id: \.self) { r in
                    Button {
                        archivio.profilo.sposta(v.chiave, in: r)
                    } label: {
                        if r == v.reparto { Label(r.nome, systemImage: "checkmark") } else { Text(r.nome) }
                    }
                }
            }
            if v.aggiunta {
                Button("Togli dalla lista", systemImage: "trash", role: .destructive) {
                    archivio.profilo.togliExtra(v.nome, lunedi: lunSpesa)
                }
            }
        }
    }

    // Nome a sinistra, quantità a destra (sotto il nome con il testo molto grande)
    @ViewBuilder private func etichetta(_ v: Profilo.VoceSpesa, giorni: String) -> some View {
        let nome = VStack(alignment: .leading, spacing: 2) {
            Text(v.nome).multilineTextAlignment(.leading)
            if !giorni.isEmpty {
                Text(giorni).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)
            }
        }
        if dimensione.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 2) {
                nome
                if !v.quanto.isEmpty { Text(v.quanto).foregroundStyle(.secondary) }
            }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                nome
                Spacer(minLength: 8)
                if !v.quanto.isEmpty {
                    Text(v.quanto).foregroundStyle(.secondary).monospacedDigit().multilineTextAlignment(.trailing)
                }
            }
        }
    }

    // ---------- Aggiunta e stato vuoto ----------

    private var aggiungi: some View {
        Riquadro {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.title3)
                    .foregroundStyle(Colori.accento)
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
                TextField("Aggiungi qualcos'altro", text: $nuovo)
                    .focused($scrivendo)
                    .submitLabel(.done)
                    .onSubmit {
                        archivio.profilo.aggiungiExtra(nuovo, lunedi: lunSpesa)
                        nuovo = ""
                        scrivendo = false
                    }
                    .frame(minHeight: 44)
            }
        }
        .padding(.top, 4)
    }

    private var vuoto: some View {
        Riquadro {
            Text("Nessun piano in questa settimana").font(.headline)
            Text("Carica il PDF del piano alimentare per avere la lista.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
    }

    // ---------- Condivisione ----------

    // Testo semplice, un reparto per volta, senza i prodotti già presi
    private func testo(voci: [Profilo.VoceSpesa], presi: [String: Bool]) -> String {
        var righe = ["Lista della spesa"]
        for r in Reparto.allCases {
            let da = voci.filter { $0.reparto == r && presi[$0.chiave] != true }
            guard !da.isEmpty else { continue }
            righe.append("")
            righe.append(r.nome)
            righe += da.map { $0.quanto.isEmpty ? "- \($0.nome)" : "- \($0.nome): \($0.quanto)" }
        }
        return righe.joined(separator: "\n")
    }
}
