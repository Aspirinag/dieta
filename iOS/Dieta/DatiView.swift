import SwiftUI
import UniformTypeIdentifiers

// Piani e PDF, misurazioni, profili, impostazioni, promemoria e backup
struct DatiView: View {
    @Environment(Archivio.self) private var archivio

    private enum Importa { case schema, bia, backup }

    @State private var importa: Importa?
    @State private var nuovoPiano: Piano?
    @State private var nuovaBia: Misura?
    @State private var backupLetto: Data?
    @State private var errore: String?
    @State private var lettura = false
    @State private var nuovaMisura = false
    @State private var pianoDaEliminare: Piano?
    @State private var nomeProfilo = ""
    @State private var profiloDaRinominare: String?
    @State private var aggiungiProfilo = false
    @State private var profiloDaEliminare: String?

    var body: some View {
        NavigationStack {
            List {
                piani
                misure
                profili
                impostazioni
                promemoria
                backup
            }
            .navigationTitle("Dati")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { MenuProfilo() } }
            .overlay {
                if lettura {
                    ProgressView("Lettura del PDF…")
                        .padding(24)
                        .background(.regularMaterial, in: .rect(cornerRadius: 20))
                }
            }
            .fileImporter(
                isPresented: Binding(get: { importa != nil }, set: { if !$0 { importa = nil } }),
                allowedContentTypes: importa == .backup ? [.json] : [.pdf]
            ) { risultato in
                let tipo = importa
                importa = nil
                guard case .success(let url) = risultato, let tipo else { return }
                let accesso = url.startAccessingSecurityScopedResource()
                defer { if accesso { url.stopAccessingSecurityScopedResource() } }
                guard let dati = try? Data(contentsOf: url) else {
                    errore = "Non riesco ad aprire il file."
                    return
                }
                Task { await leggi(tipo, dati, nome: url.deletingPathExtension().lastPathComponent) }
            }
            .sheet(item: $nuovoPiano) { p in
                FoglioNuovoPiano(piano: p)
            }
            .sheet(isPresented: $nuovaMisura) {
                NavigationStack { EditorMisura(dataEsistente: nil) }
            }
            .alert("Aggiungo la BIA del \(Giorni.breve(nuovaBia?.data ?? ""))?", isPresented: Binding(
                get: { nuovaBia != nil }, set: { if !$0 { nuovaBia = nil } }
            ), presenting: nuovaBia) { m in
                Button("Aggiungi") { archivio.salvaMisura(m) }
                Button("Annulla", role: .cancel) {}
            } message: { m in
                Text("Peso \(num(m.peso)) kg · massa grassa \(num(m.grassoKg)) kg · vita \(num(m.vitaCm)) cm" +
                     (archivio.profilo.bia.contains { $0.data == m.data } ? "\nSostituisce la misurazione della stessa data." : ""))
            }
            .alert("Importare il backup?", isPresented: Binding(
                get: { backupLetto != nil }, set: { if !$0 { backupLetto = nil } }
            ), presenting: backupLetto) { dati in
                Button("Importa", role: .destructive) {
                    do { try archivio.importa(dati) } catch { errore = "File non valido: scegli un backup esportato dall'app Dieta." }
                }
                Button("Annulla", role: .cancel) {}
            } message: { _ in
                Text("Il backup sostituisce tutti i dati attuali.")
            }
            .alert("Errore", isPresented: Binding(get: { errore != nil }, set: { if !$0 { errore = nil } })) {
                Button("OK") {}
            } message: {
                Text(errore ?? "")
            }
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
    }

    private func leggi(_ tipo: Importa, _ dati: Data, nome: String) async {
        switch tipo {
        case .backup:
            backupLetto = dati
        case .schema:
            lettura = true
            defer { lettura = false }
            do {
                let giorni = try await LettorePDF.condiviso.schema(dati)
                guard giorni.count == 7, giorni.allSatisfy({ !$0.pasti.isEmpty }) else {
                    errore = "Non riesco a leggere lo schema da questo PDF. Controlla che sia lo schema dietetico."
                    return
                }
                nuovoPiano = Piano(nome: nome, dal: Giorni.oggi(), al: "", giorni: giorni)
            } catch {
                errore = "Non riesco a leggere questo PDF."
            }
        case .bia:
            lettura = true
            defer { lettura = false }
            do {
                let m = try await LettorePDF.condiviso.bia(dati)
                guard !m.data.isEmpty, m.peso != nil else {
                    errore = "Non riesco a leggere i valori da questo PDF. Controlla che sia il referto BIA."
                    return
                }
                nuovaBia = m
            } catch {
                errore = "Non riesco a leggere questo PDF."
            }
        }
    }

    // ---------- Sezioni ----------

    private var piani: some View {
        Section {
            ForEach(archivio.profilo.piani.sorted { $0.dal > $1.dal }) { p in
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.nome).font(.headline)
                    Text("\(Giorni.breve(p.dal)) → \(p.al.isEmpty ? "in corso" : Giorni.breve(p.al))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .swipeActions {
                    Button("Elimina", systemImage: "trash", role: .destructive) { pianoDaEliminare = p }
                }
            }
            Button("Carica schema dietetico (PDF)", systemImage: "doc.badge.plus") { importa = .schema }
        } header: {
            Text("Piani alimentari")
        } footer: {
            Text("Lo schema in PDF viene letto e diventa il piano di Oggi e Settimana. Scorri a sinistra su un piano per eliminarlo.")
        }
    }

    private var misure: some View {
        Section {
            Button("Carica referto BIA (PDF)", systemImage: "doc.text.magnifyingglass") { importa = .bia }
            Button("Aggiungi misurazione a mano", systemImage: "square.and.pencil") { nuovaMisura = true }
        } header: {
            Text("Misurazioni BIA")
        } footer: {
            Text("Le misurazioni si vedono, modificano ed eliminano in Andamento.")
        }
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
                        Image(systemName: id == archivio.stato.attivo ? "person.crop.circle.fill" : "person.crop.circle")
                            .foregroundStyle(.tint)
                        Text(nome).foregroundStyle(.primary)
                        Spacer()
                        if archivio.stato.preferito == id {
                            Image(systemName: "star.fill").foregroundStyle(.yellow)
                        }
                    }
                }
            }
            Button("Aggiungi profilo", systemImage: "person.badge.plus") {
                nomeProfilo = ""
                aggiungiProfilo = true
            }
        } header: {
            Text("Profili")
        } footer: {
            Text("★ si apre all'avvio. Il profilo si cambia dal menu in alto a destra.")
        }
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
            Text("Impostazioni di \(p.nome)")
        }
    }

    private var promemoria: some View {
        let pr = archivio.stato.promemoria ?? Promemoria()
        return Section {
            Toggle(isOn: Binding(get: { pr.acqua }, set: { v in Task { await cambiaPromemoria { $0.acqua = v } } })) {
                Label {
                    VStack(alignment: .leading) {
                        Text("Bevi acqua")
                        Text("alle " + Archivio.oreAcqua.map(String.init).joined(separator: ", ")).font(.caption).foregroundStyle(.secondary)
                    }
                } icon: { Image(systemName: "drop.fill") }
            }
            Toggle(isOn: Binding(get: { pr.pasti }, set: { v in Task { await cambiaPromemoria { $0.pasti = v } } })) {
                Label {
                    VStack(alignment: .leading) {
                        Text("Segna i pasti")
                        Text("ogni sera alle 21").font(.caption).foregroundStyle(.secondary)
                    }
                } icon: { Image(systemName: "checklist") }
            }
        } header: {
            Text("Promemoria")
        }
    }

    private func cambiaPromemoria(_ modifica: (inout Promemoria) -> Void) async {
        var p = archivio.stato.promemoria ?? Promemoria()
        modifica(&p)
        if (p.acqua || p.pasti), !(await Notifiche.permesso()) {
            errore = "Per i promemoria consenti le notifiche in Impostazioni → Notifiche → Dieta."
            return
        }
        archivio.stato.promemoria = p
        await archivio.programmaPromemoria()
    }

    private var backup: some View {
        Section {
            ShareLink(
                item: FileBackup(dati: archivio.backup(), nome: "dieta-backup-\(Giorni.oggi()).json"),
                preview: SharePreview("Backup Dieta")
            ) {
                Label("Esporta backup", systemImage: "square.and.arrow.up")
            }
            Button("Importa backup", systemImage: "square.and.arrow.down") { importa = .backup }
        } header: {
            Text("Backup")
        } footer: {
            Text("Il backup è lo stesso della web app: esportalo dalla web app e importalo qui per portare i dati nell'app.")
        }
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
    @State var piano: Piano
    @State private var dal = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome", text: $piano.nome)
                    DatePicker("Valido dal", selection: $dal, displayedComponents: .date)
                } footer: {
                    Text("Il piano precedente si chiude il giorno prima.")
                }
                Section("Anteprima: \(piano.giorni.first?.nome ?? "")") {
                    ForEach(Array((piano.giorni.first?.pasti ?? []).enumerated()), id: \.offset) { _, pasto in
                        LabeledContent(pasto.nome, value: pasto.opzioni.first?.alimenti.map(\.nome).joined(separator: ", ") ?? "")
                    }
                }
            }
            .navigationTitle("Nuovo piano")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla", role: .cancel) { chiudi() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", systemImage: "checkmark") {
                        piano.dal = Giorni.iso(dal)
                        archivio.aggiungiPiano(piano)
                        chiudi()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
