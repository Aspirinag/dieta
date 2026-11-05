import SwiftUI

// Spesa della settimana, aperta da Dieta: prodotti per reparto nell'ordine del negozio.
// Il cerchio segna il prodotto come preso (resta al suo posto, sbiadito e barrato);
// il nome apre i giorni in cui serve; in fondo si aggiunge ciò che non è nel piano
struct SpesaView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.scenePhase) private var fase
    @State private var ultimoOggi = Giorni.oggi()
    @State private var giaPresente = false
    @State private var avvisoNascosto: Task<Void, Never>?
    @State private var lunSpesa = Profilo.lunediSpesa(oggi: Giorni.oggi())
    @State private var aperti: Set<String> = []
    @State private var nuovo = ""
    @FocusState private var scrivendo: Bool

    private var questa: String { Giorni.lunedi(Giorni.oggi()) }
    private var prossima: String { Giorni.aggiungi(questa, 7) }

    var body: some View {
        let voci = archivio.profilo.vociSpesa(lunedi: lunSpesa)
        let presi = archivio.spunteSpesa(lunedi: lunSpesa)
        List {
            Section {
                intestazione(voci: voci, presi: presi)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            if voci.isEmpty {
                vuoto
            } else {
                // Solo voci aggiunte a mano: la lista le mostra e un cenno ricorda che manca il piano
                if Profilo.senzaPiano(voci) {
                    Section {
                        Text(Self.indicazioneVuoto)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .listRowBackground(Color.clear)
                    }
                }
                ForEach(Reparto.allCases, id: \.self) { reparto in
                    let righe = voci.filter { $0.reparto == reparto }
                    // Quello che manca in alto, i prodotti presi in fondo alla sezione
                    let ordinate = righe.filter { presi[$0.chiave] != true } + righe.filter { presi[$0.chiave] == true }
                    if !righe.isEmpty { sezione(reparto, ordinate, presi: presi) }
                }
            }
            aggiungi
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
        .tint(.primary)
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
        return HStack(spacing: 0) {
            freccia("chevron.left", "Settimana precedente", attiva: lunSpesa != questa) { lunSpesa = questa }
            VStack(spacing: 2) {
                Text(verbatim: lunSpesa == questa ? periodo : String(localized: "Prossima settimana · \(periodo)"))
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text("\(quanti) di \(voci.count) presi")
                    .font(.numero(.footnote))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            freccia("chevron.right", "Settimana successiva", attiva: lunSpesa != prossima) { lunSpesa = prossima }
        }
    }

    private func freccia(_ simbolo: String, _ nome: LocalizedStringResource, attiva: Bool, azione: @escaping () -> Void) -> some View {
        Button(action: azione) {
            Image(systemName: simbolo)
                .font(.body.weight(.semibold))
                .frame(width: Misure.tocco, height: Misure.tocco)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(attiva ? Color.primary : Color(.tertiaryLabel))
        .disabled(!attiva)
        .accessibilityLabel(Text(nome))
    }

    // «2–8 novembre» (in inglese «November 2 – 8»), «30 novembre – 6 dicembre» a cavallo di due mesi
    private var periodo: String { Self.periodo(lunedi: lunSpesa) }

    static func periodo(lunedi: String, locale: Locale = .current) -> String {
        let dal = Giorni.data(lunedi)
        let al = Giorni.data(Giorni.aggiungi(lunedi, 6))   // la domenica a mezzanotte, dentro l'intervallo
        return Testi.periodo(da: dal, a: al, locale: locale)
    }

    // ---------- Reparti ----------

    private func sezione(_ reparto: Reparto, _ righe: [Profilo.VoceSpesa], presi: [String: Bool]) -> some View {
        Section {
            ForEach(righe, id: \.id) { voce in
                riga(voce, preso: presi[voce.chiave] == true)
            }
        } header: {
            Text(reparto.nome)
                .textCase(nil)
                .accessibilityIdentifier("reparto.\(reparto.rawValue)")
        }
    }

    private func riga(_ v: Profilo.VoceSpesa, preso: Bool) -> some View {
        let aperta = aperti.contains(v.chiave)
        let giorni = v.giorni.map { "\($0.giorno) \($0.quanto)" }.joined(separator: " · ")
        let apriGiorni = {
            guard !v.giorni.isEmpty else { return }
            withAnimation(.snappy) {
                if aperti.contains(v.chiave) { aperti.remove(v.chiave) } else { aperti.insert(v.chiave) }
            }
        }
        return Riga(Text(v.nome).strikethrough(preso),
                    dettaglio: aperta ? Text(verbatim: giorni) : nil,
                    valore: v.quanto.isEmpty ? nil : Text(v.quanto),
                    fatta: preso,
                    inizio: CerchioSpunta(fatta: preso, etichetta: Text("Segna \(v.nome)"), stati: ("preso", "da prendere")) {
                        withAnimation(.snappy) { archivio.spunta(v.chiave, lunedi: lunSpesa) }
                    }
                    .accessibilityIdentifier("spunta.\(v.chiave)"))
            .righeTema()
            // Il nome apre i giorni in cui serve il prodotto
            .contentShape(Rectangle())
            .onTapGesture(perform: apriGiorni)
            .accessibilityAction(named: Text("Mostra i giorni"), apriGiorni)
            .swipeActions(edge: .trailing) {
                if v.aggiunta {
                    Button("Togli dalla lista", systemImage: "trash", role: .destructive) {
                        archivio.profilo.togliExtra(v.nome, lunedi: lunSpesa)
                    }
                }
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

    // ---------- Aggiunta e stato vuoto ----------

    // Voce libera: una riga con il campo; la nuova voce va in «Altro» e si può spostare con il tocco lungo
    private var aggiungi: some View {
        Section {
            HStack(spacing: Spazio.xs) {
                Image(systemName: "plus")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: Misure.tocco, height: Misure.tocco)
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
                    .frame(minHeight: Misure.tocco)
            }
            .righeTema()
            if giaPresente {
                Text("È già nella lista")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.updatesFrequently)
                    .righeTema()
            }
        } footer: {
            Text("Le spunte restano per questa settimana e la prossima.")
        }
    }

    // L'avviso resta due secondi (e lo legge anche VoiceOver)
    private func avvisaGiaPresente() {
        withAnimation { giaPresente = true }
        AccessibilityNotification.Announcement(String(localized: "È già nella lista")).post()
        avvisoNascosto?.cancel()
        avvisoNascosto = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation { giaPresente = false }
        }
    }

    static var indicazioneVuoto: String { String(localized: "Carica un piano alimentare da Impostazioni → Piani alimentari.") }

    private var vuoto: some View {
        Section {
            VStack(alignment: .leading, spacing: Spazio.xs) {
                Text("Nessun piano in questa settimana").font(.headline)
                Text(Self.indicazioneVuoto)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, Spazio.xs)
            .righeTema()
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
