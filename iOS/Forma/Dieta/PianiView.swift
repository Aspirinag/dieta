import SwiftUI
import UniformTypeIdentifiers

// PDF che si possono caricare per la dieta
enum TipoPDF { case schema, bia }

// Selettore dei PDF della dieta (schema dietetico o referto BIA) con lettura, anteprima ed errori.
// Si apre mettendo un valore in `richiesta`. Il tipo scelto resta in uno stato a parte: SwiftUI chiude
// il selettore (azzerando il suo isPresented) prima di consegnare il file, quindi non va ricavato da lì.
struct ImportaPDF: ViewModifier {
    @Environment(Archivio.self) private var archivio
    @Binding var richiesta: TipoPDF?
    @State private var tipo: TipoPDF = .schema
    @State private var aperto = false
    @State private var lettura = false
    @State private var nuovoPiano: Piano?
    @State private var nuovaBia: Misura?
    @State private var errore: String?

    func body(content: Content) -> some View {
        content
            .onChange(of: richiesta) { _, r in
                guard let r else { return }
                tipo = r
                richiesta = nil
                aperto = true
            }
            .fileImporter(isPresented: $aperto, allowedContentTypes: [.pdf]) { risultato in
                switch risultato {
                case .failure:
                    errore = "Non riesco ad aprire il file. Riprova o scegline un altro."
                case .success(let url):
                    let accesso = url.startAccessingSecurityScopedResource()
                    defer { if accesso { url.stopAccessingSecurityScopedResource() } }
                    guard let dati = try? Data(contentsOf: url) else {
                        errore = "Non riesco ad aprire il file. Riprova o scegline un altro."
                        return
                    }
                    let scelto = tipo
                    Task { await leggi(scelto, dati, nome: url.deletingPathExtension().lastPathComponent) }
                }
            }
            .overlay {
                if lettura {
                    ProgressView("Lettura del PDF…")
                        .padding(24)
                        .background(.regularMaterial, in: .rect(cornerRadius: 20))
                }
            }
            .sheet(item: $nuovoPiano) { FoglioNuovoPiano(piano: $0) }
            .alert("Aggiungere la BIA del \(Giorni.breve(nuovaBia?.data ?? ""))?", isPresented: Binding(
                get: { nuovaBia != nil }, set: { if !$0 { nuovaBia = nil } }
            ), presenting: nuovaBia) { m in
                Button("Aggiungi") { archivio.salvaMisura(m) }
                Button("Annulla", role: .cancel) {}
            } message: { m in
                Text(riassuntoBia(m))
            }
            .alert("Non riesco a leggere il PDF", isPresented: Binding(get: { errore != nil }, set: { if !$0 { errore = nil } })) {
                Button("OK") {}
            } message: {
                Text(errore ?? "")
            }
    }

    private func riassuntoBia(_ m: Misura) -> String {
        var t = "Peso \(num(m.peso)) kg · massa grassa \(num(m.grassoKg)) kg · vita \(num(m.vitaCm)) cm"
        if archivio.profilo.bia.contains(where: { $0.data == m.data }) { t += "\nSostituisce la misurazione della stessa data." }
        return t
    }

    enum EsitoLettura {
        case piano([GiornoPiano])
        case bia(Misura)
        case errore(String)
    }

    // Decide cosa fare con quello che il lettore ha trovato nel PDF
    static func valuta(_ tipo: TipoPDF, giorni: [GiornoPiano]?, misura: Misura?) -> EsitoLettura {
        switch tipo {
        case .schema:
            let g = giorni ?? []
            guard g.count == 7, g.allSatisfy({ !$0.pasti.isEmpty }) else {
                return .errore("Non riesco a leggere il piano da questo PDF (\(g.count == 1 ? "trovato 1 giorno" : "trovati \(g.count) giorni") su 7). Controlla che sia il piano alimentare del nutrizionista, oppure crealo a mano da Dieta → Piani e misure.")
            }
            return .piano(g)
        case .bia:
            guard let m = misura, !m.data.isEmpty, m.peso != nil else {
                return .errore("Non riesco a leggere i valori da questo PDF. Controlla che sia la BIA, oppure aggiungi la misurazione a mano.")
            }
            return .bia(m)
        }
    }

    private func leggi(_ tipo: TipoPDF, _ dati: Data, nome: String) async {
        lettura = true
        defer { lettura = false }
        let esito: EsitoLettura
        do {
            switch tipo {
            case .schema: esito = Self.valuta(tipo, giorni: try await LettorePDF.condiviso.schema(dati), misura: nil)
            case .bia: esito = Self.valuta(tipo, giorni: nil, misura: try await LettorePDF.condiviso.bia(dati))
            }
        } catch {
            errore = "Il file non è leggibile. Scegli un altro PDF."
            return
        }
        switch esito {
        case .piano(let g): nuovoPiano = Piano(nome: nome, dal: Giorni.oggi(), al: "", giorni: g)
        case .bia(let m): nuovaBia = m
        case .errore(let t): errore = t
        }
    }
}

extension View {
    func importaPDF(_ richiesta: Binding<TipoPDF?>) -> some View {
        modifier(ImportaPDF(richiesta: richiesta))
    }
}

// Dieta → Piani e misure: piani alimentari dai PDF e misurazioni BIA
struct PianiDietaView: View {
    @Environment(Archivio.self) private var archivio
    @State private var richiesta: TipoPDF?
    @State private var nuovaMisura = false
    @State private var pianoDaEliminare: Piano?
    @State private var pianoDaModificare: Piano?
    @State private var nuovoVuoto = false

    var body: some View {
        List {
            Group {
                Section {
                    ForEach(archivio.profilo.piani.sorted { $0.dal > $1.dal }) { p in
                        Button { pianoDaModificare = p } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.nome).font(.headline).foregroundStyle(.primary)
                                Text("\(Giorni.breve(p.dal)) → \(p.al.isEmpty ? "in corso" : Giorni.breve(p.al))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .accessibilityHint("Apre il piano per modificarlo")
                        .swipeActions {
                            Button("Elimina", systemImage: "trash", role: .destructive) { pianoDaEliminare = p }
                        }
                    }
                    Button("Carica il piano alimentare (PDF)", systemImage: "doc.badge.plus") { richiesta = .schema }
                    Button("Nuovo piano a mano", systemImage: "square.and.pencil") { nuovoVuoto = true }
                } header: {
                    Text("Piani alimentari")
                } footer: {
                    Text("Forma legge il PDF e ricava i pasti di ogni giorno. Tocca un piano per correggerlo, scorri a sinistra per eliminarlo.")
                }
                Section {
                    Button("Carica la BIA (PDF)", systemImage: "doc.text.magnifyingglass") { richiesta = .bia }
                    Button("Aggiungi misurazione a mano", systemImage: "square.and.pencil") { nuovaMisura = true }
                } header: {
                    Text("Misurazioni BIA")
                } footer: {
                    Text("Le misurazioni si vedono, modificano ed eliminano in Progressi.")
                }
            }
            .righeTema()
        }
        .sfondoTema()
        .navigationTitle("Piani e misure")
        .navigationBarTitleDisplayMode(.inline)
        .importaPDF($richiesta)
        .sheet(item: $pianoDaModificare) { EditorPianoView(originale: $0) }
        .sheet(isPresented: $nuovoVuoto) { EditorPianoView(originale: nil) }
        .sheet(isPresented: $nuovaMisura) {
            NavigationStack { EditorMisura(dataEsistente: nil) }
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
    }
}

// Pagine della dieta aperte dentro una scheda. Le destinazioni stanno sulla radice della scheda:
// registrate su una pagina aperta con un collegamento diretto, si perdevano al primo collegamento per valore
enum PaginaDieta: Hashable {
    case misure, piani, spesa
    case misura(String)
    case pasto(String, Int)   // giorno (aaaa-mm-gg) e posizione del pasto
}

extension View {
    func destinazioniDieta() -> some View {
        navigationDestination(for: PaginaDieta.self) { pagina in
            switch pagina {
            case .misure: MisurazioniView()
            case .piani: PianiDietaView()
            case .spesa: SpesaView()
            case .pasto(let giorno, let indice): DettaglioPastoView(giorno: giorno, indice: indice)
            case .misura(let data): EditorMisura(dataEsistente: data)
            }
        }
    }
}
