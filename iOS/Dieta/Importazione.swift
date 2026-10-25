import SwiftUI
import UniformTypeIdentifiers

// Caricamento di schema dietetico, referti BIA (PDF) e backup, da qualsiasi scheda:
// la radice applica .importatore() e le schermate chiamano @Environment(\.importa) — es. importa(.bia)
enum TipoImportazione { case schema, bia, backup }

struct AzioneImporta {
    let esegui: (TipoImportazione) -> Void
    func callAsFunction(_ tipo: TipoImportazione) { esegui(tipo) }
}

extension EnvironmentValues {
    @Entry var importa = AzioneImporta { _ in }
}

extension View {
    func importatore() -> some View { modifier(Importatore()) }
}

struct Importatore: ViewModifier {
    @Environment(Archivio.self) private var archivio

    private typealias Importa = TipoImportazione

    // PDF cifrato in attesa della password
    private struct PdfProtetto {
        let tipo: Importa
        let dati: Data
        let nome: String
    }

    // Il tipo resta salvato a parte: alla chiusura del selettore SwiftUI azzera la presentazione
    // prima di consegnare il file, e il tipo andava perso (il PDF scelto veniva ignorato)
    @State private var importa = Importa.schema
    @State private var mostraImporta = false
    @State private var conferma: String?
    @State private var nuovoPiano: Piano?
    // BIA lette e in attesa di conferma, e PDF che non si sono letti (più PDF insieme)
    @State private var nuoveBia: [Misura] = []
    @State private var nonLetti: [String] = []
    @State private var backupLetto: Data?
    @State private var errore: String?
    @State private var protetto: PdfProtetto?
    @State private var codaProtetti: [PdfProtetto] = []
    @State private var password = ""
    @State private var lettura = false

    func body(content: Content) -> some View {
        content
            .environment(\.importa, AzioneImporta { apri($0) })
    .overlay {
        if lettura {
            ProgressView("Lettura del PDF…")
                .padding(24)
                .background(.regularMaterial, in: .rect(cornerRadius: 20))
        }
    }
    .overlay(alignment: .bottom) {
        if let conferma {
            Label(conferma, systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.medium))
                .symbolRenderingMode(.multicolor)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: .capsule)
                .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
                .padding(.horizontal, 16)
                .padding(.bottom, 64)   // sopra la barra delle schede
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onTapGesture { self.conferma = nil }
        }
    }
    .animation(.spring(duration: 0.35), value: conferma)
    .sensoryFeedback(.success, trigger: conferma) { _, nuovo in nuovo != nil }
    .task(id: conferma) {
        guard conferma != nil else { return }
        try? await Task.sleep(for: .seconds(3))
        conferma = nil
    }
        .fileImporter(
            isPresented: $mostraImporta,
            allowedContentTypes: importa == .backup ? [.json] : [.pdf],
            allowsMultipleSelection: importa == .bia
        ) { risultato in
            guard case .success(let urls) = risultato, !urls.isEmpty else {
                if case .failure = risultato { errore = "Non riesco ad aprire il file." }
                return
            }
            let tipo = importa
            var file: [PdfProtetto] = []
            for url in urls {
                let accesso = url.startAccessingSecurityScopedResource()
                defer { if accesso { url.stopAccessingSecurityScopedResource() } }
                let nome = url.deletingPathExtension().lastPathComponent
                if let dati = try? Data(contentsOf: url) {
                    file.append(PdfProtetto(tipo: tipo, dati: dati, nome: nome))
                } else {
                    nonLetti.append(nome)
                }
            }
            // I PDF con password si aprono dopo, uno alla volta
            let liberi = file.filter { tipo == .backup || !LettorePDF.protetto($0.dati) }
            codaProtetti = file.filter { tipo != .backup && LettorePDF.protetto($0.dati) }
            if liberi.isEmpty && codaProtetti.isEmpty {
                nonLetti = []
                errore = "Non riesco ad aprire il file."
                return
            }
            lettura = !liberi.isEmpty
            Task {
                for f in liberi { await leggi(f.tipo, f.dati, nome: f.nome) }
                lettura = false
                prossimoProtetto()
            }
        }
        .sheet(item: $nuovoPiano) { p in
            FoglioNuovoPiano(piano: p) { conferma = "PDF caricato correttamente: piano «\($0)» salvato" }
        }
        .alert(titoloBia, isPresented: Binding(
            get: { !nuoveBia.isEmpty && !lettura && protetto == nil && codaProtetti.isEmpty },
            set: { if !$0 { nuoveBia = []; nonLetti = [] } }
        )) {
            Button("Aggiungi") {
                nuoveBia.forEach { archivio.salvaMisura($0) }
                conferma = nuoveBia.count == 1
                    ? "PDF caricato correttamente: BIA del \(Giorni.breve(nuoveBia[0].data)) aggiunta"
                    : "\(nuoveBia.count) PDF caricati correttamente"
            }
            Button("Annulla", role: .cancel) {}
        } message: {
            Text(riassuntoBia())
        }
        .alert("Importare il backup?", isPresented: Binding(
            get: { backupLetto != nil }, set: { if !$0 { backupLetto = nil } }
        ), presenting: backupLetto) { dati in
            Button("Importa", role: .destructive) {
                do { try archivio.importa(dati); conferma = "Backup importato" } catch { errore = "File non valido: scegli un backup esportato dall'app Dieta." }
            }
            Button("Annulla", role: .cancel) {}
        } message: { _ in
            Text("Il backup sostituisce tutti i dati attuali.")
        }
        .alert("PDF protetto", isPresented: Binding(
            get: { protetto != nil }, set: { if !$0 { protetto = nil } }
        ), presenting: protetto) { p in
            SecureField("Password", text: $password)
            Button("Apri") {
                let pwd = password
                protetto = nil
                lettura = true
                Task {
                    await leggi(p.tipo, p.dati, nome: p.nome, password: pwd)
                    lettura = false
                    prossimoProtetto()
                }
            }
            Button("Annulla", role: .cancel) {
                nonLetti.append(p.nome)
                protetto = nil
                prossimoProtetto()
            }
        } message: { p in
            Text("«\(p.nome)» si apre solo con la password. Spesso è indicata nell'email o nel messaggio con cui ti è arrivato il referto.")
        }
        .alert("Errore", isPresented: Binding(get: { errore != nil }, set: { if !$0 { errore = nil } })) {
            Button("OK") {}
        } message: {
            Text(errore ?? "")
        }
    }

    private var titoloBia: String {
        nuoveBia.count == 1 ? "Aggiungo la BIA del \(Giorni.breve(nuoveBia[0].data))?" : "Aggiungo \(nuoveBia.count) misurazioni?"
    }

    private func riassuntoBia() -> String {
        var righe: [String]
        if let m = nuoveBia.first, nuoveBia.count == 1 {
            righe = ["Peso \(num(m.peso)) kg · massa grassa \(num(m.grassoKg)) kg · vita \(num(m.vitaCm)) cm"]
            if archivio.profilo.bia.contains(where: { $0.data == m.data }) { righe.append("Sostituisce la misurazione della stessa data.") }
        } else {
            righe = nuoveBia.sorted { $0.data < $1.data }.map { m in
                "\(Giorni.breve(m.data)) · \(num(m.peso)) kg" + (archivio.profilo.bia.contains { $0.data == m.data } ? " (sostituisce)" : "")
            }
        }
        if !nonLetti.isEmpty { righe.append("\nNon letti: " + nonLetti.joined(separator: ", ")) }
        return righe.joined(separator: "\n")
    }

    // Mostra la richiesta di password per il prossimo PDF protetto, dopo che si è chiuso l'avviso precedente
    private func prossimoProtetto() {
        guard protetto == nil else { return }
        guard !codaProtetti.isEmpty else {
            // Finito: se nessuna BIA si è letta non c'è niente da confermare, quindi si spiega l'errore
            if nuoveBia.isEmpty && !nonLetti.isEmpty {
                errore = "Non riesco a leggere i valori da: \(nonLetti.joined(separator: ", ")). Controlla che siano referti BIA."
                nonLetti = []
            }
            return
        }
        password = ""
        let prossimo = codaProtetti.removeFirst()
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            protetto = prossimo
        }
    }

    private func leggi(_ tipo: Importa, _ dati: Data, nome: String, password: String = "") async {
        if !password.isEmpty && !LettorePDF.passwordGiusta(dati, password) {
            if tipo == .bia { nonLetti.append(nome + " (password errata)") } else { errore = "La password non è corretta." }
            return
        }
        switch tipo {
        case .backup:
            backupLetto = dati
        case .schema:
            lettura = true
            defer { lettura = false }
            do {
                let giorni = try await LettorePDF.condiviso.schema(dati, password: password)
                guard giorni.count == 7, giorni.allSatisfy({ !$0.pasti.isEmpty }) else {
                    errore = "Non riesco a leggere lo schema da questo PDF. Controlla che sia lo schema dietetico."
                    return
                }
                nuovoPiano = Piano(nome: nome, dal: Giorni.oggi(), al: "", giorni: giorni)
            } catch {
                errore = messaggio(error)
            }
        case .bia:
            // Il caricamento in corso lo segnala chi chiama: con più PDF la rotellina resta fino all'ultimo
            do {
                let m = try await LettorePDF.condiviso.bia(dati, password: password)
                guard !m.data.isEmpty, m.peso != nil else {
                    nonLetti.append(nome)
                    return
                }
                nuoveBia.removeAll { $0.data == m.data }
                nuoveBia.append(m)
            } catch {
                nonLetti.append(nome)
            }
        }
    }

    private func apri(_ tipo: Importa) {
        importa = tipo
        mostraImporta = true
    }

    private func messaggio(_ errore: Error) -> String {
        switch errore {
        case LettorePDF.Errore.password: "Il PDF è protetto da password e non si riesce ad aprire."
        case is DecodingError: "Ho letto il PDF ma non ne ricavo i dati: forse non è nel formato atteso."
        default: "Non riesco a leggere questo PDF. Riprova; se succede ancora, chiudi e riapri l'app."
        }
    }
}
