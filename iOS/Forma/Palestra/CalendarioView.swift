import SwiftUI

// Calendario del mese: allenamenti, cardio, giorni programmati e saltati
struct CalendarioContenuto: View {
    @Environment(Palestra.self) private var palestra
    @State private var mese = Giorni.data(String(Giorni.oggi().prefix(8)) + "01")
    @State private var scelto = Giorni.oggi()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Riquadro {
                    HStack {
                        Button("Mese precedente", systemImage: "chevron.left") { cambia(-1) }
                            .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                        Spacer()
                        Text(mese.formatted(.dateTime.month(.wide).year()).capitalized)
                            .font(.headline)
                        Spacer()
                        Button("Mese successivo", systemImage: "chevron.right") { cambia(1) }
                            .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.borderless)
                    GrigliaMese(mese: mese, scelto: $scelto)
                    Text("Pallino pieno: pesi o cardio fatti. Grigio: in programma. ✕: saltato.")
                        .font(.footnote).foregroundStyle(.secondary).padding(.top, 8)
                }
                giorno
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .sfondoTema()
        .navigationTitle("Calendario")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func cambia(_ n: Int) {
        mese = Giorni.calendario.date(byAdding: .month, value: n, to: mese) ?? mese
    }

    @ViewBuilder private var giorno: some View {
        let t = palestra.programmato(scelto)
        let saltato = palestra.stato.saltati.contains(scelto)
        let pesi = palestra.allenamenti(del: scelto), cardio = palestra.cardio(del: scelto)
        VStack(alignment: .leading, spacing: 4) {
            Text(Giorni.nomeGiorno(Giorni.indice(scelto)) + " " + Giorni.breve(scelto)).font(.headline).padding(.horizontal, 4)
            Riquadro {
                HStack {
                    Text("In programma")
                    Spacer()
                    Image(systemName: t.simbolo).foregroundStyle(Colori.accento)
                    Text(t.nome).foregroundStyle(.secondary)
                }
                .frame(minHeight: 44)
                ForEach(pesi) { a in
                    Divider()
                    RigaRecente(allenamento: a)
                }
                ForEach(cardio) { c in
                    Divider()
                    RigaCardio(cardio: c)
                }
                if scelto <= Giorni.oggi() && t != .riposo && pesi.isEmpty && cardio.isEmpty {
                    Divider()
                    Toggle("Saltato", isOn: Binding(
                        get: { saltato },
                        set: { v in
                            palestra.stato.saltati.removeAll { $0 == scelto }
                            if v { palestra.stato.saltati.append(scelto) }
                        }
                    ))
                    .frame(minHeight: 44)
                }
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
                ForEach(Array(Giorni.iniziali.enumerated()), id: \.offset) { _, l in
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
        .accessibilityLabel(etichetta(iso))
        .accessibilityAddTraits(iso == scelto ? .isSelected : [])
    }

    // Per VoiceOver: data e cosa è successo (o cosa era previsto) quel giorno
    private func etichetta(_ iso: String) -> String {
        let data = Giorni.data(iso).formatted(.dateTime.weekday(.wide).day().month(.wide))
        var parti = [data]
        if !palestra.allenamenti(del: iso).isEmpty { parti.append(String(localized: "pesi fatti")) }
        if !palestra.cardio(del: iso).isEmpty { parti.append(String(localized: "cardio fatto")) }
        if parti.count == 1 {
            if palestra.stato.saltati.contains(iso) { parti.append(String(localized: "saltato")) }
            else if palestra.programmato(iso) != .riposo { parti.append(String(localized: "in programma: \(palestra.programmato(iso).nome.lowercased())")) }
        }
        return parti.joined(separator: ", ")
    }

    @ViewBuilder private func segno(_ iso: String) -> some View {
        let pesi = !palestra.allenamenti(del: iso).isEmpty
        let cardio = !palestra.cardio(del: iso).isEmpty
        if pesi || cardio {
            HStack(spacing: 2) {
                if pesi { Circle().fill(.tint).frame(width: 6, height: 6) }
                if cardio { Circle().fill(Colori.accento.opacity(0.45)).frame(width: 6, height: 6) }
            }
        } else if palestra.stato.saltati.contains(iso) {
            Image(systemName: "xmark").font(.system(size: 8, weight: .heavy)).foregroundStyle(.red).frame(height: 6)
        } else {
            Circle().fill(palestra.programmato(iso) != .riposo ? AnyShapeStyle(.secondary.opacity(0.5)) : AnyShapeStyle(.clear))
                .frame(width: 6, height: 6)
        }
    }
}
