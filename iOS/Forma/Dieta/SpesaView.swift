import SwiftUI

// Spesa della settimana, aperta da Dieta: prodotti per reparto nell'ordine del negozio.
// Il cerchio segna il prodotto come preso (resta al suo posto, sbiadito e barrato);
// il nome apre i giorni in cui serve; in fondo si aggiunge ciò che non è nel piano
struct SpesaView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.dynamicTypeSize) private var dimensione
    @Environment(\.scenePhase) private var fase
    @State private var ultimoOggi = Giorni.oggi()
    @State private var giaPresente = false
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
                    // Solo voci aggiunte a mano: la lista le mostra e un cenno ricorda che manca il piano
                    if Profilo.senzaPiano(voci) {
                        Text(Self.indicazioneVuoto)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                    ForEach(Reparto.allCases, id: \.self) { reparto in
                        let righe = voci.filter { $0.reparto == reparto }
                        if !righe.isEmpty { sezione(reparto, righe, presi: presi) }
                    }
                }
                aggiungi
                Text("Le spunte restano per questa settimana e la prossima.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        // Se l'app resta aperta oltre la mezzanotte la lista passa alla settimana giusta
        .onChange(of: fase) { _, nuova in
            guard nuova == .active else { return }
            let oggi = Giorni.oggi()
            lunSpesa = Profilo.settimanaSpesaAggiornata(corrente: lunSpesa, ultimoOggi: ultimoOggi, oggi: oggi)
            ultimoOggi = oggi
        }
        .sfondoTema()
        .navigationTitle("Spesa")
        .toolbar {
            if !voci.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: testo(voci: voci, presi: presi), preview: SharePreview("Lista della spesa")) {
                        Label("Condividi", systemImage: "square.and.arrow.up")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Togli le spunte", systemImage: "arrow.counterclockwise") {
                        archivio.azzeraSpesa(lunedi: lunSpesa)
                    }
                    .disabled(presi.values.allSatisfy { !$0 })
                } label: {
                    Label("Opzioni", systemImage: "ellipsis.circle")
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
                VStack(spacing: 2) {
                    Text(verbatim: lunSpesa == questa ? periodo : String(localized: "Prossima settimana · \(periodo)"))
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(dimensione.isAccessibilitySize ? nil : 1)
                        .minimumScaleFactor(dimensione.isAccessibilitySize ? 1 : 0.7)
                        .multilineTextAlignment(.center)
                    Text("\(quanti) di \(voci.count) presi")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                freccia("chevron.right", "Settimana successiva", attiva: lunSpesa != prossima) { lunSpesa = prossima }
            }
            ProgressView(value: Double(quanti), total: Double(max(voci.count, 1)))
                .tint(Colori.accento)
                .accessibilityLabel("Prodotti presi")
                .accessibilityValue("\(quanti) di \(voci.count)")
        }
        .padding(.top, 4)
    }

    private func freccia(_ simbolo: String, _ nome: LocalizedStringResource, attiva: Bool, azione: @escaping () -> Void) -> some View {
        Button(action: azione) {
            Image(systemName: simbolo)
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(attiva ? Colori.accento : Color(.tertiaryLabel))
        .disabled(!attiva)
        .accessibilityLabel(Text(nome))
    }

    // «2 – 8 novembre» (in inglese «2 – 8 November»), «30 novembre – 6 dicembre» a cavallo di due mesi
    private var periodo: String {
        let dal = Giorni.data(lunSpesa)
        let al = Giorni.data(Giorni.aggiungi(lunSpesa, 6))   // la domenica a mezzanotte, dentro l'intervallo
        return (dal..<al).formatted(.interval.day().month(.wide))
    }

    // ---------- Reparti ----------

    private func sezione(_ reparto: Reparto, _ righe: [Profilo.VoceSpesa], presi: [String: Bool]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(reparto.nome)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("reparto.\(reparto.rawValue)")
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
            .accessibilityLabel("Segna \(v.nome)")
            .accessibilityValue(preso ? Text("preso") : Text("da prendere"))

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
            .accessibilityHint(v.giorni.isEmpty ? Text(verbatim: "") : Text("Mostra i giorni"))
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
                        let aggiunto = archivio.profilo.aggiungiExtra(nuovo, lunedi: lunSpesa)
                        if !aggiunto && !nuovo.trimmingCharacters(in: .whitespaces).isEmpty { avvisaGiaPresente() }
                        nuovo = ""
                        scrivendo = true
                    }
                    .frame(minHeight: 44)
            }
            if giaPresente {
                Text("È già nella lista")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 48)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .padding(.top, 4)
    }

    // L'avviso resta due secondi (e lo legge anche VoiceOver)
    private func avvisaGiaPresente() {
        withAnimation { giaPresente = true }
        AccessibilityNotification.Announcement(String(localized: "È già nella lista")).post()
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { giaPresente = false }
        }
    }

    static var indicazioneVuoto: String { String(localized: "Carica un piano alimentare da Impostazioni → Piani alimentari.") }

    private var vuoto: some View {
        Riquadro {
            Text("Nessun piano in questa settimana").font(.headline)
            Text(Self.indicazioneVuoto)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
    }

    // ---------- Condivisione ----------

    // Testo semplice, un reparto per volta, senza i prodotti già presi
    private func testo(voci: [Profilo.VoceSpesa], presi: [String: Bool]) -> String {
        var righe = [String(localized: "Lista della spesa")]
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
