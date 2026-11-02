import SwiftUI

// Progressi: corpo (BIA), allenamenti (storico e record) e calendario
struct ProgressiView: View {
    @State private var vista = ["corpo", "allenamenti", "calendario"].firstIndex(of: Avvio.valore("-vista") ?? "") ?? 1

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Vista", selection: $vista) {
                        Text("Allenamenti").tag(1)
                        Text("Corpo").tag(0)
                        Text("Calendario").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                switch vista {
                case 0: AndamentoView()
                case 2: CalendarioContenuto()
                default: StoricoAllenamenti()
                }
            }
            .navigationTitle("Progressi")
            .toolbar {
                if vista == 0 { ToolbarItem(placement: .topBarTrailing) { MenuProfilo() } }
            }
            .navigationDestination(for: String.self) { EditorMisura(dataEsistente: $0) }
            .navigationDestination(for: UUID.self) { DettaglioAllenamentoView(id: $0) }
            .navigationDestination(for: Esercizio.self) { DettaglioEsercizioView(idEsercizio: $0.id) }
        }
    }
}

// Calendario del mese: allenamenti, cardio, giorni programmati e saltati
struct CalendarioContenuto: View {
    @Environment(Palestra.self) private var palestra
    @State private var mese = Giorni.data(String(Giorni.oggi().prefix(8)) + "01")
    @State private var scelto = Giorni.oggi()

    var body: some View {
        Section {
            HStack {
                Button("Mese precedente", systemImage: "chevron.left") { cambia(-1) }.labelStyle(.iconOnly)
                Spacer()
                Text(mese.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "it_IT"))).capitalized)
                    .font(.headline)
                Spacer()
                Button("Mese successivo", systemImage: "chevron.right") { cambia(1) }.labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            GrigliaMese(mese: mese, scelto: $scelto)
        } footer: {
            Text("Pallino arancione: pesi. Blu: cardio. Grigio: programmato. ✕: non andato.")
        }
        giorno
    }

    private func cambia(_ n: Int) {
        mese = Giorni.calendario.date(byAdding: .month, value: n, to: mese) ?? mese
    }

    @ViewBuilder private var giorno: some View {
        let t = palestra.programmato(scelto)
        let saltato = palestra.stato.saltati.contains(scelto)
        Section(Giorni.nomi[Giorni.indice(scelto)] + " " + Giorni.breve(scelto)) {
            LabeledContent("Programmato") {
                HStack(spacing: 6) {
                    Image(systemName: t.simbolo).foregroundStyle(.tint)
                    Text(t.nome)
                }
            }
            ForEach(palestra.allenamenti(del: scelto)) { a in
                NavigationLink(value: a.id) { RigaAllenamento(allenamento: a) }
            }
            ForEach(palestra.cardio(del: scelto)) { c in
                Label("\(c.tipo) · \(c.minuti) min" + (c.km > 0 ? " · \(num(c.km)) km" : ""), systemImage: Libreria.simboloCardio(c.tipo))
            }
            if scelto <= Giorni.oggi() && t != .riposo && palestra.allenamenti(del: scelto).isEmpty && palestra.cardio(del: scelto).isEmpty {
                Toggle("Non sono andato", isOn: Binding(
                    get: { saltato },
                    set: { v in
                        palestra.stato.saltati.removeAll { $0 == scelto }
                        if v { palestra.stato.saltati.append(scelto) }
                    }
                ))
            }
        }
    }
}

struct GrigliaMese: View {
    @Environment(Palestra.self) private var palestra
    let mese: Date
    @Binding var scelto: String

    var body: some View {
        let primo = Giorni.iso(mese)
        let vuoti = Giorni.indice(primo)
        let giorni = Giorni.calendario.range(of: .day, in: .month, for: mese)?.count ?? 30
        let oggi = Giorni.oggi()
        // Griglia non lazy: dentro una lista la griglia lazy viene misurata male e si taglia
        let celle: [Int?] = Array(repeating: nil, count: vuoti) + (0..<giorni).map { Optional($0) }
        let settimane = stride(from: 0, to: celle.count, by: 7).map { Array(celle[$0..<min($0 + 7, celle.count)]) }
        Grid(horizontalSpacing: 4, verticalSpacing: 4) {
            GridRow {
                ForEach(Array(["L", "M", "M", "G", "V", "S", "D"].enumerated()), id: \.offset) { _, l in
                    Text(l).font(.caption.weight(.semibold)).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
            }
            ForEach(settimane.indices, id: \.self) { w in
                GridRow {
                    ForEach(0..<7, id: \.self) { i in
                        if i < settimane[w].count, let d = settimane[w][i] {
                            cella(Giorni.aggiungi(primo, d), numero: d + 1, oggi: oggi)
                        } else {
                            Color.clear.frame(maxWidth: .infinity, minHeight: 42)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func cella(_ iso: String, numero: Int, oggi: String) -> some View {
        Button { scelto = iso } label: {
            VStack(spacing: 3) {
                Text("\(numero)")
                    .font(.callout.weight(iso == oggi ? .bold : .regular))
                    .foregroundStyle(iso == oggi ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                segno(iso)
            }
            .frame(maxWidth: .infinity, minHeight: 42)
            .background {
                if iso == scelto { RoundedRectangle(cornerRadius: 10).fill(.tint.opacity(0.18)) }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func segno(_ iso: String) -> some View {
        let pesi = !palestra.allenamenti(del: iso).isEmpty
        let cardio = !palestra.cardio(del: iso).isEmpty
        if pesi || cardio {
            HStack(spacing: 2) {
                if pesi { Circle().fill(.orange).frame(width: 6, height: 6) }
                if cardio { Circle().fill(.blue).frame(width: 6, height: 6) }
            }
        } else if palestra.stato.saltati.contains(iso) {
            Image(systemName: "xmark").font(.system(size: 8, weight: .heavy)).foregroundStyle(.red).frame(height: 6)
        } else {
            Circle().fill(palestra.programmato(iso) != .riposo ? AnyShapeStyle(.secondary.opacity(0.5)) : AnyShapeStyle(.clear))
                .frame(width: 6, height: 6)
        }
    }
}
