import SwiftUI
import UniformTypeIdentifiers

// Impostazioni: profili, olio e acqua, promemoria, tema e backup.
// Piani e referti stanno in Dieta, le impostazioni della palestra in Palestra
struct ProfiloView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(Palestra.self) private var palestra

    @State private var importaBackup = false
    @State private var backupLetto: Data?
    @State private var errore: String?
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
            Group {
                profili
                impostazioni
                promemoria
                SezioneTema()
                backup
            }
            .righeTema()
        }
        .sfondoTema()
        .navigationTitle("Impostazioni")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { MenuProfilo() } }
    }

    private var conAvvisi: some View {
        lista
            .fileImporter(isPresented: $importaBackup, allowedContentTypes: [.json]) { risultato in
                guard case .success(let url) = risultato else {
                    errore = "Non riesco ad aprire il file."
                    return
                }
                let accesso = url.startAccessingSecurityScopedResource()
                defer { if accesso { url.stopAccessingSecurityScopedResource() } }
                guard let dati = try? Data(contentsOf: url) else {
                    errore = "Non riesco ad aprire il file."
                    return
                }
                backupLetto = dati
            }
            .alert("Importare il backup?", isPresented: Binding(
                get: { backupLetto != nil }, set: { if !$0 { backupLetto = nil } }
            ), presenting: backupLetto) { dati in
                Button("Importa", role: .destructive) {
                    do {
                        try Backup.importa(dati, archivio: archivio, palestra: palestra)
                        Task {
                            await archivio.programmaPromemoria()
                            await palestra.programmaPagamento()
                        }
                    } catch { errore = "File non valido: scegli un backup di Forma, Dieta o Palestra." }
                }
                Button("Annulla", role: .cancel) {}
            } message: { _ in
                Text("Un backup di Forma sostituisce tutti i dati, dieta e palestra. Un backup di Dieta sostituisce la dieta. Gli allenamenti di un backup di Palestra si aggiungono a quelli che ci sono.")
            }
            .alert("Errore", isPresented: Binding(get: { errore != nil }, set: { if !$0 { errore = nil } })) {
                Button("OK") {}
            } message: {
                Text(errore ?? "")
            }
    }

    private var conDialoghi: some View {
        conAvvisi
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
                .tint(.primary)
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
            Toggle(isOn: Binding(get: { pr.mattino }, set: { v in cambiaPromemoria { $0.mattino = v } })) {
                Label("Controlla la dieta odierna", systemImage: "sun.horizon")
            }
            if pr.mattino {
                SceltaOrario(titolo: "Ogni mattina alle", minuti: pr.oraMattino) { m in cambiaPromemoria { $0.oraMattino = m } }
            }
            Toggle(isOn: Binding(get: { pr.pasti }, set: { v in cambiaPromemoria { $0.pasti = v } })) {
                Label("Segna i pasti", systemImage: "checklist")
            }
            if pr.pasti {
                SceltaOrario(titolo: "Ogni sera alle", minuti: pr.oraPasti) { m in cambiaPromemoria { $0.oraPasti = m } }
            }
            Toggle(isOn: Binding(get: { pr.acqua }, set: { v in cambiaPromemoria { $0.acqua = v } })) {
                Label("Bevi acqua", systemImage: "drop.fill")
            }
            if pr.acqua {
                SceltaOrario(titolo: "Dalle", minuti: pr.acquaDalle) { m in cambiaPromemoria { $0.acquaDalle = m; $0.acquaAlle = max($0.acquaAlle, m) } }
                SceltaOrario(titolo: "Alle", minuti: pr.acquaAlle) { m in cambiaPromemoria { $0.acquaAlle = m; $0.acquaDalle = min($0.acquaDalle, m) } }
                Stepper(pr.acquaOgni == 1 ? "Ogni ora" : "Ogni \(pr.acquaOgni) ore", value: Binding(
                    get: { pr.acquaOgni }, set: { v in cambiaPromemoria { $0.acquaOgni = v } }
                ), in: 1...6)
            }
        } header: {
            Text("Promemoria")
        } footer: {
            if pr.acqua {
                Text("Acqua alle " + pr.orariAcqua.map(Self.orario).joined(separator: ", ") + ".")
            }
        }
    }

    static func orario(_ minuti: Int) -> String { String(format: "%d:%02d", minuti / 60, minuti % 60) }

    // Salva subito la modifica (così due tocchi veloci non si sovrascrivono), poi riprogramma
    private func cambiaPromemoria(_ modifica: (inout Promemoria) -> Void) {
        let prima = archivio.stato.promemoria ?? Promemoria()
        var p = prima
        modifica(&p)
        archivio.stato.promemoria = p
        let acceso = (p.mattino && !prima.mattino) || (p.pasti && !prima.pasti) || (p.acqua && !prima.acqua)
        Task {
            if acceso, !(await Notifiche.permesso()) {
                var q = archivio.stato.promemoria ?? Promemoria()
                if !prima.mattino { q.mattino = false }
                if !prima.pasti { q.pasti = false }
                if !prima.acqua { q.acqua = false }
                archivio.stato.promemoria = q
                errore = "Per i promemoria consenti le notifiche in Impostazioni → Notifiche → Forma."
            }
            await archivio.programmaPromemoria()
        }
    }

    private var backup: some View {
        Section {
            ShareLink(
                item: FileBackup(dati: Backup.esporta(archivio: archivio, palestra: palestra), nome: "forma-backup-\(Giorni.oggi()).json"),
                preview: SharePreview("Backup Forma")
            ) {
                Label("Esporta backup", systemImage: "square.and.arrow.up")
            }
            Button("Importa backup", systemImage: "square.and.arrow.down") { importaBackup = true }
        } header: {
            Text("Backup")
        } footer: {
            Text("Importa qui i backup delle web app o delle app Dieta e Palestra per portare tutti i dati in Forma.")
        }
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
                Group {
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
                .righeTema()
            }
            .sfondoTema()
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
