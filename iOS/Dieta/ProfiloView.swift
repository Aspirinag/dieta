import SwiftUI
import UniformTypeIdentifiers

// Profilo: profili, piani alimentari, tema, impostazioni, promemoria e backup.
// Le misurazioni si caricano e si gestiscono in Progressi
struct ProfiloView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.importa) private var importa
    @Environment(\.palette) private var palette

    @State private var errore: String?
    @State private var pianoDaEliminare: Piano?
    @State private var nomeProfilo = ""
    @State private var profiloDaRinominare: String?
    @State private var aggiungiProfilo = false
    @State private var profiloDaEliminare: String?

    // Il corpo è diviso in passaggi: tutti i modificatori in un'unica espressione sono troppi per il compilatore
    var body: some View {
        NavigationStack { conDialoghi }
    }

    private var lista: some View {
        List {
            profili
            piani
            tema
            impostazioni
            promemoria
            backup
            versione
        }
        .navigationTitle("Profilo")
        .sfondoTema()
        .toolbar { ToolbarItem(placement: .topBarTrailing) { MenuProfilo(conSfondo: false) } }
    }

    private var conAvvisi: some View {
        lista
            .alert("Errore", isPresented: Binding(get: { errore != nil }, set: { if !$0 { errore = nil } })) {
                Button("OK") {}
            } message: {
                Text(errore ?? "")
            }
    }

    private var conDialoghi: some View {
        conAvvisi
            .confirmationDialog("Eliminare il piano?", isPresented: Binding(
                get: { pianoDaEliminare != nil }, set: { if !$0 { pianoDaEliminare = nil } }
            ), titleVisibility: .visible, presenting: pianoDaEliminare) { p in
                Button("Elimina \(p.nome)", role: .destructive) {
                    archivio.profilo.piani.removeAll { $0.id == p.id }
                }
            } message: { _ in
                Text("I pasti già segnati restano.")
            }
            .confirmationDialog("Eliminare il profilo?", isPresented: Binding(
                get: { profiloDaEliminare != nil }, set: { if !$0 { profiloDaEliminare = nil } }
            ), titleVisibility: .visible, presenting: profiloDaEliminare) { id in
                Button("Elimina \(archivio.stato.profili[id]?.nome ?? "")", role: .destructive) {
                    archivio.eliminaProfilo(id)
                }
            } message: { _ in
                Text("Vengono eliminati piani, pasti e misurazioni del profilo. Non si può annullare.")
            }
            .alert("Nuovo profilo", isPresented: $aggiungiProfilo) {
                TextField("Nome", text: $nomeProfilo)
                Button("Aggiungi") {
                    let n = nomeProfilo.trimmingCharacters(in: .whitespaces)
                    if !n.isEmpty { archivio.aggiungiProfilo(n) }
                }
                Button("Annulla", role: .cancel) {}
            }
            .alert("Rinomina profilo", isPresented: Binding(
                get: { profiloDaRinominare != nil }, set: { if !$0 { profiloDaRinominare = nil } }
            )) {
                TextField("Nome", text: $nomeProfilo)
                Button("Salva") {
                    let n = nomeProfilo.trimmingCharacters(in: .whitespaces)
                    if let id = profiloDaRinominare, !n.isEmpty { archivio.stato.profili[id]?.nome = n }
                }
                Button("Annulla", role: .cancel) {}
            }
    }


    // ---------- Sezioni ----------

    private var piani: some View {
        Section {
            ForEach(archivio.profilo.piani.sorted { $0.dal > $1.dal }) { p in
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.nome).font(.georgia(.headline))
                    Text("\(Giorni.breve(p.dal)) → \(p.al.isEmpty ? "in corso" : Giorni.breve(p.al))")
                        .font(.georgia(.subheadline))
                        .foregroundStyle(palette.secondario)
                }
                .swipeActions {
                    Button("Elimina", systemImage: "trash", role: .destructive) { pianoDaEliminare = p }
                }
            }
            Button("Carica piano alimentare (PDF)", systemImage: "doc.badge.plus") { importa(.schema) }
        } header: {
            IntestazioneSezione(testo: "Piani alimentari")
        } footer: {
            PiedeSezione(testo: "Il PDF viene letto e diventa il piano di Oggi e Dieta. Scorri a sinistra su un piano per eliminarlo.")
        }
        .sezioneTema()
    }

    private var profili: some View {
        Section {
            ForEach(archivio.idProfili, id: \.self) { id in
                let nome = archivio.stato.profili[id]?.nome ?? ""
                Menu {
                    Button(archivio.stato.preferito == id ? "Non aprire all'avvio" : "Apri all'avvio", systemImage: "star") {
                        archivio.stato.preferito = archivio.stato.preferito == id ? nil : id
                    }
                    Button("Rinomina", systemImage: "pencil") {
                        nomeProfilo = nome
                        profiloDaRinominare = id
                    }
                    if archivio.stato.profili.count > 1 {
                        Button("Elimina", systemImage: "trash", role: .destructive) { profiloDaEliminare = id }
                    }
                } label: {
                    HStack {
                        // Iniziale in un cerchio: piena per il profilo attivo
                        let attivo = id == archivio.stato.attivo
                        Text(String(nome.prefix(1)).uppercased())
                            .font(.georgiaFissa(17, grassetto: true))
                            .foregroundStyle(attivo ? palette.suTasto : palette.testo)
                            .frame(width: 34, height: 34)
                            .background(attivo ? palette.tasto : palette.riempimento, in: .circle)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(nome).foregroundStyle(palette.testo)
                            if attivo { Text("In uso").font(.georgia(.caption)).foregroundStyle(palette.secondario) }
                        }
                        Spacer()
                        if archivio.stato.preferito == id {
                            Image(systemName: "star.fill").foregroundStyle(palette.caldo)
                        }
                    }
                }
                .tint(palette.testo)
            }
            Button("Aggiungi profilo", systemImage: "person.badge.plus") {
                nomeProfilo = ""
                aggiungiProfilo = true
            }
        } header: {
            IntestazioneSezione(testo: "Profili")
        } footer: {
            PiedeSezione(testo: "★ si apre all'avvio. Il profilo si cambia dal menu in alto a destra.")
        }
        .sezioneTema()
    }

    private var impostazioni: some View {
        let p = archivio.profilo
        return Section {
            Stepper(value: Binding(get: { p.olio }, set: { archivio.profilo.olioTot = $0 }), in: 0...15) {
                LabeledContent("Olio al giorno", value: "\(p.olio) cucchiaini")
            }
            Stepper(value: Binding(get: { p.acqua }, set: { archivio.profilo.acquaTot = $0 }), in: 0.5...5, step: 0.25) {
                LabeledContent("Acqua al giorno", value: "\(num(p.acqua)) L")
            }
            TextField("Note in fondo a Oggi", text: Binding(
                get: { p.testoNote },
                set: { archivio.profilo.note = $0 }
            ), axis: .vertical)
            .lineLimit(3...8)
        } header: {
            IntestazioneSezione(testo: "Impostazioni di \(p.nome)")
        }
        .sezioneTema()
    }

    // Il nome del tema con i suoi colori: la scelta si vede e resta salvata
    private var tema: some View {
        let scelto = Tema.scelto(archivio.stato.tema)
        return Section {
            ForEach(Tema.allCases) { t in
                let colori = t.palette
                Button {
                    archivio.stato.tema = t.rawValue
                } label: {
                    HStack(spacing: 12) {
                        HStack(spacing: -6) {
                            Circle().fill(colori.fondo).frame(width: 24, height: 24)
                                .overlay { Circle().strokeBorder(palette.traccia) }
                            Circle().fill(colori.accento).frame(width: 24, height: 24)
                            Circle().fill(colori.caldo).frame(width: 24, height: 24)
                        }
                        .accessibilityHidden(true)
                        Text(t.nome).foregroundStyle(palette.testo)
                        Spacer()
                        if t == scelto {
                            Image(systemName: "checkmark").foregroundStyle(palette.accento)
                        }
                    }
                    .frame(minHeight: 32)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(t == scelto ? .isSelected : [])
            }
        } header: {
            IntestazioneSezione(testo: "Tema")
        }
        .sezioneTema()
    }

    private var promemoria: some View {
        let pr = archivio.stato.promemoria ?? Promemoria()
        return Section {
            Toggle(isOn: Binding(get: { pr.acqua }, set: { v in Task { await cambiaPromemoria { $0.acqua = v } } })) {
                Label {
                    VStack(alignment: .leading) {
                        Text("Bevi acqua")
                        Text("alle " + Archivio.oreAcqua.map(String.init).joined(separator: ", ")).font(.georgia(.caption)).foregroundStyle(palette.secondario)
                    }
                } icon: { Image(systemName: "drop.fill") }
            }
            Toggle(isOn: Binding(get: { pr.pasti }, set: { v in Task { await cambiaPromemoria { $0.pasti = v } } })) {
                Label {
                    VStack(alignment: .leading) {
                        Text("Segna i pasti")
                        Text("ogni sera alle 21").font(.georgia(.caption)).foregroundStyle(palette.secondario)
                    }
                } icon: { Image(systemName: "checklist") }
            }
        } header: {
            IntestazioneSezione(testo: "Promemoria")
        }
        .sezioneTema()
    }

    private func cambiaPromemoria(_ modifica: (inout Promemoria) -> Void) async {
        var p = archivio.stato.promemoria ?? Promemoria()
        modifica(&p)
        if (p.acqua || p.pasti), !(await Notifiche.permesso()) {
            errore = "Per i promemoria consenti le notifiche in Impostazioni → Notifiche → èffort."
            return
        }
        archivio.stato.promemoria = p
        await archivio.programmaPromemoria()
    }

    private var backup: some View {
        Section {
            ShareLink(
                item: FileBackup(dati: archivio.backup(), nome: "dieta-backup-\(Giorni.oggi()).json"),
                preview: SharePreview("Backup èffort")
            ) {
                Label("Esporta backup", systemImage: "square.and.arrow.up")
            }
            Button("Importa backup", systemImage: "square.and.arrow.down") { importa(.backup) }
        } header: {
            IntestazioneSezione(testo: "Backup")
        } footer: {
            PiedeSezione(testo: "Il backup è lo stesso della web app: esportalo dalla web app e importalo qui per portare i dati nell'app.")
        }
        .sezioneTema()
    }

    private var versione: some View {
        Section {
            LabeledContent("Versione", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
        }
        .sezioneTema()
    }
}

// Backup condivisibile come file .json
struct FileBackup: Transferable {
    let dati: Data
    let nome: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { $0.dati }
            .suggestedFileName { $0.nome }
    }
}

// Dopo la lettura dello schema PDF: nome del piano e data di inizio
struct FoglioNuovoPiano: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.dismiss) private var chiudi
    @Environment(\.palette) private var palette
    @State var piano: Piano
    var salvato: (String) -> Void = { _ in }
    @State private var dal = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome", text: $piano.nome)
                    DatePicker("Valido dal", selection: $dal, displayedComponents: .date)
                } footer: {
                    PiedeSezione(testo: "Il piano precedente si chiude il giorno prima.")
                }
                .sezioneTema()
                Section {
                    ForEach(Array((piano.giorni.first?.pasti ?? []).enumerated()), id: \.offset) { _, pasto in
                        LabeledContent(pasto.nome, value: pasto.opzioni.first?.alimenti.map(\.nome).joined(separator: ", ") ?? "")
                    }
                } header: {
                    IntestazioneSezione(testo: "Anteprima: \(piano.giorni.first?.nome ?? "")")
                }
                .sezioneTema()
            }
            .navigationTitle("Nuovo piano")
            .navigationBarTitleDisplayMode(.inline)
            .sfondoTema()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla", role: .cancel) { chiudi() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", systemImage: "checkmark") {
                        piano.dal = Giorni.iso(dal)
                        archivio.aggiungiPiano(piano)
                        salvato(piano.nome)
                        chiudi()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(palette.fondo)
    }
}
