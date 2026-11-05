import SwiftUI

// Libreria esercizi: ricerca, filtri per muscolo e attrezzo, esercizi nuovi.
// In modalità scelta si selezionano più esercizi da aggiungere a una scheda o all'allenamento
struct LibreriaView: View {
    enum Modo {
        case sfoglia
        case scelta(([String]) -> Void)
    }

    @Environment(Palestra.self) private var palestra
    @Environment(\.dismiss) private var chiudi
    let modo: Modo

    @State private var cerca = ""
    @State private var muscolo: Muscolo?
    @State private var attrezzo: Attrezzo?
    @State private var scelti: [String] = []
    @State private var nuovo = false

    private var inScelta: Bool { if case .scelta = modo { true } else { false } }

    private var filtrati: [Esercizio] {
        palestra.stato.esercizi
            .filter { muscolo == nil || $0.muscolo == muscolo }
            .filter { attrezzo == nil || $0.attrezzo == attrezzo }
            .filter { cerca.isEmpty || $0.titolo.localizedCaseInsensitiveContains(cerca) }
            .sorted { $0.titolo.localizedCompare($1.titolo) == .orderedAscending }
    }

    var body: some View {
        if inScelta {
            // In scelta la libreria ha una navigazione sua; sfogliando usa quella della scheda Palestra
            NavigationStack {
                contenuto.navigationDestination(for: Esercizio.self) { DettaglioEsercizioView(idEsercizio: $0.id) }
            }
        } else {
            contenuto
        }
    }

    private var contenuto: some View {
        List {
            Group {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filtro(titolo: muscolo?.nome ?? String(localized: "Muscolo"), attivo: muscolo != nil) {
                                Picker("Muscolo", selection: $muscolo) {
                                    Text("Tutti").tag(Muscolo?.none)
                                    ForEach(Muscolo.allCases) { Text($0.nome).tag(Muscolo?.some($0)) }
                                }
                            }
                            filtro(titolo: attrezzo?.nome ?? String(localized: "Attrezzo"), attivo: attrezzo != nil) {
                                Picker("Attrezzo", selection: $attrezzo) {
                                    Text("Tutti").tag(Attrezzo?.none)
                                    ForEach(Attrezzo.allCases) { Text($0.nome).tag(Attrezzo?.some($0)) }
                                }
                            }
                            if muscolo != nil || attrezzo != nil {
                                Button("Togli i filtri", systemImage: "xmark.circle.fill") {
                                    muscolo = nil
                                    attrezzo = nil
                                }
                                .labelStyle(.iconOnly)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                } footer: {
                    Text("\(filtrati.count) esercizi")
                }
                let gruppi = Dictionary(grouping: filtrati, by: \.muscolo)
                ForEach(Muscolo.allCases.filter { gruppi[$0] != nil }) { m in
                    Section(m.nome) {
                        ForEach(gruppi[m] ?? []) { e in riga(e) }
                    }
                }
            }
            .righeTema()
        }
        .tint(.primary)
        .sfondoTema()
        .navigationTitle(inScelta ? LocalizedStringKey("Aggiungi esercizi") : LocalizedStringKey("Libreria esercizi"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $cerca, placement: .navigationBarDrawer(displayMode: .always), prompt: "Cerca esercizio")
        .toolbar {
            if case .scelta(let fatto) = modo {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla", role: .cancel) { chiudi() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(scelti.isEmpty ? LocalizedStringKey("Aggiungi") : LocalizedStringKey("Aggiungi (\(scelti.count))")) {
                        fatto(scelti)
                        chiudi()
                    }
                    .disabled(scelti.isEmpty)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Nuovo esercizio", systemImage: "plus") { nuovo = true }
            }
        }
        .sheet(isPresented: $nuovo) {
            NuovoEsercizioView { e in if inScelta { scelti.append(e.id) } }
        }
    }

    private func filtro<C: View>(titolo: String, attivo: Bool, @ViewBuilder _ contenuto: () -> C) -> some View {
        Menu {
            contenuto()
        } label: {
            HStack(spacing: 4) {
                Text(titolo)
                Image(systemName: "chevron.down").font(.caption2.weight(.bold))
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(minHeight: Misure.tocco - 16)
            .foregroundStyle(attivo ? AnyShapeStyle(Color(.systemBackground)) : AnyShapeStyle(.primary))
            .background(attivo ? AnyShapeStyle(.primary) : AnyShapeStyle(.fill.secondary), in: .capsule)
        }
    }

    @ViewBuilder
    private func riga(_ e: Esercizio) -> some View {
        let etichetta = HStack(spacing: 12) {
            // L'omino solo se c'è il disegno della macchina
            if Figura.esercizi[e.id] != nil { IconaEsercizio(esercizio: e) }
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: e.titolo).foregroundStyle(.primary)
                Text(e.attrezzo.nome).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
        }
        if inScelta {
            let n = scelti.firstIndex(of: e.id)
            Button {
                if let n { scelti.remove(at: n) } else { scelti.append(e.id) }
            } label: {
                HStack {
                    etichetta
                    if let n {
                        Text("\(n + 1)")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(Color(.systemBackground))
                            .frame(minWidth: 28, minHeight: 28)
                            .background(.primary, in: .circle)
                    } else {
                        Image(systemName: "circle").font(.title3).foregroundStyle(.tertiary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: e) { etichetta }
        }
    }
}

struct NuovoEsercizioView: View {
    @Environment(Palestra.self) private var palestra
    @Environment(\.dismiss) private var chiudi
    var creato: (Esercizio) -> Void = { _ in }
    @State private var nome = ""
    @State private var muscolo: Muscolo = .petto
    @State private var attrezzo: Attrezzo = .macchina

    var body: some View {
        NavigationStack {
            Form {
                Group {
                    TextField("Nome", text: $nome)
                    Picker("Muscolo principale", selection: $muscolo) {
                        ForEach(Muscolo.allCases) { Text($0.nome).tag($0) }
                    }
                    Picker("Attrezzo", selection: $attrezzo) {
                        ForEach(Attrezzo.allCases) { Text($0.nome).tag($0) }
                    }
                }
                .righeTema()
            }
            .sfondoTema()
            .navigationTitle("Nuovo esercizio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla", role: .cancel) { chiudi() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva", systemImage: "checkmark") {
                        creato(palestra.nuovoEsercizio(nome: nome.trimmingCharacters(in: .whitespaces), muscolo: muscolo, attrezzo: attrezzo))
                        chiudi()
                    }
                    .disabled(nome.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
