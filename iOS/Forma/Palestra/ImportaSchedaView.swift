import SwiftUI
import UniformTypeIdentifiers

// Importa una o più schede da un PDF: si sceglie il file, si guarda l'anteprima, poi si aggiungono alle schede.
// Si apre mettendo `true` in `richiesta`. Con l'argomento di avvio `-importaPDFProva <percorso>` (solo per i test)
// si salta il selettore e si legge quel file.
struct ImportaSchedaPDF: ViewModifier {
    @Environment(Palestra.self) private var palestra
    @Binding var richiesta: Bool
    @State private var aperto = false
    @State private var lettura = false
    @State private var trovate: AnteprimaSchede?
    @State private var errore: String?

    func body(content: Content) -> some View {
        content
            .onChange(of: richiesta) { _, r in
                guard r else { return }
                richiesta = false
                if let prova = Avvio.valore("-importaPDFProva") {
                    leggi(URL(fileURLWithPath: prova))
                } else {
                    aperto = true
                }
            }
            .fileImporter(isPresented: $aperto, allowedContentTypes: [.pdf]) { risultato in
                switch risultato {
                case .failure: errore = Self.erroreApertura
                case .success(let url): leggi(url)
                }
            }
            .overlay {
                if lettura {
                    ProgressView("Lettura del PDF…")
                        .padding(24)
                        .background(.regularMaterial, in: .rect(cornerRadius: 20))
                }
            }
            .sheet(item: $trovate) { anteprima in
                AnteprimaSchedeView(schede: anteprima.schede) { palestra.importa($0) }
            }
            .alert("Nessun esercizio trovato", isPresented: Binding(get: { errore != nil }, set: { if !$0 { errore = nil } })) {
                Button("OK") {}
            } message: {
                Text(errore ?? "")
            }
    }

    private static var erroreApertura: String { String(localized: "Non riesco ad aprire il file. Riprova o scegline un altro.") }

    private func leggi(_ url: URL) {
        let accesso = url.startAccessingSecurityScopedResource()
        defer { if accesso { url.stopAccessingSecurityScopedResource() } }
        guard let dati = try? Data(contentsOf: url), let testo = LettoreScheda.testo(pdf: dati) else {
            errore = Self.erroreApertura
            return
        }
        let schede = LettoreScheda.leggi(testo: testo, libreria: palestra.stato.esercizi)
        if schede.isEmpty {
            errore = String(localized: "Non ho trovato esercizi in questo PDF. Controlla che sia una scheda di allenamento, con serie e ripetizioni su ogni riga.")
        } else {
            trovate = AnteprimaSchede(schede: schede)
        }
    }
}

struct AnteprimaSchede: Identifiable {
    let id = UUID()
    let schede: [SchedaLetta]
}

extension View {
    func importaSchedaPDF(_ richiesta: Binding<Bool>) -> some View {
        modifier(ImportaSchedaPDF(richiesta: richiesta))
    }
}

// Elenco delle schede trovate, con «Importa» per aggiungerle
struct AnteprimaSchedeView: View {
    @Environment(\.dismiss) private var chiudi
    let schede: [SchedaLetta]
    let importa: ([SchedaLetta]) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(schede.indices, id: \.self) { i in
                    Section {
                        ForEach(schede[i].voci.indices, id: \.self) { j in
                            riga(schede[i].voci[j])
                        }
                    } header: {
                        Text(schede[i].nome)
                    }
                    .righeTema()
                }
            }
            .tint(.primary)
            .sfondoTema()
            .navigationTitle("Importa da PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { chiudi() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Importa") {
                        importa(schede)
                        chiudi()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func riga(_ v: VoceLetta) -> some View {
        VStack(alignment: .leading, spacing: Spazio.xs) {
            HStack(spacing: Spazio.s) {
                Text(v.esercizio.titolo)
                if v.nuovo {
                    Text("nuovo")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, Spazio.s)
                        .padding(.vertical, 2)
                        .background(Colori.accento.opacity(0.15), in: .capsule)
                }
            }
            Text("\(v.obiettivo) · \(Self.recupero(v.recupero))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    // «Recupero 1 min 30 s»
    static func recupero(_ secondi: Int) -> String {
        let durata: String
        if secondi < 60 { durata = String(localized: "\(secondi) s") }
        else if secondi % 60 == 0 { durata = String(localized: "\(secondi / 60) min") }
        else { durata = String(localized: "\(secondi / 60) min \(secondi % 60) s") }
        return String(localized: "Recupero \(durata)")
    }
}

extension Palestra {
    func importa(_ schede: [SchedaLetta]) { stato.importa(schede) }
}

extension StatoPalestra {
    // Aggiunge le schede lette: nome già usato → « (2)», esercizi nuovi nella libreria (come quelli creati a mano:
    // id = nome, oppure un identificativo univoco se è già preso). Le schede esistenti non cambiano
    mutating func importa(_ schede: [SchedaLetta]) {
        var create: [String: String] = [:]   // id provvisorio → id nella libreria
        for scheda in schede {
            var voci: [VoceRoutine] = []
            for v in scheda.voci {
                var id = v.esercizio.id
                if v.nuovo {
                    if let gia = create[id] {
                        id = gia
                    } else {
                        let e = Esercizio(id: esercizi.contains { $0.id == v.esercizio.nome } ? UUID().uuidString : v.esercizio.nome,
                                          nome: v.esercizio.nome, muscolo: v.esercizio.muscolo, attrezzo: v.esercizio.attrezzo)
                        esercizi.append(e)
                        create[v.esercizio.id] = e.id
                        id = e.id
                    }
                }
                voci.append(VoceRoutine(esercizio: id, serie: v.serie, ripMin: v.ripMin, ripMax: v.ripMax, recupero: v.recupero))
            }
            routine.append(Routine(nome: nomeLibero(scheda.nome), voci: voci))
        }
    }

    private func nomeLibero(_ nome: String) -> String {
        let usati = Set(routine.map { LettoreScheda.normalizza($0.nome) })
        if !usati.contains(LettoreScheda.normalizza(nome)) { return nome }
        var n = 2
        while usati.contains(LettoreScheda.normalizza("\(nome) (\(n))")) { n += 1 }
        return "\(nome) (\(n))"
    }
}
