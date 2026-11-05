import SwiftUI

// Calendario del mese: allenamenti e cardio fatti (pallino pieno), giorni in programma (contorno)
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
                        Text(mese.formatted(.dateTime.month(.wide).year()))
                            .font(.headline)
                        Spacer()
                        Button("Mese successivo", systemImage: "chevron.right") { cambia(1) }
                            .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.borderless)
                    GrigliaMese(mese: mese, scelto: $scelto)
                    Text("Pallino pieno: pesi o cardio fatti. Pallino vuoto: in programma.")
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
        let pesi = palestra.allenamenti(del: scelto), cardio = palestra.cardio(del: scelto)
        VStack(alignment: .leading, spacing: 4) {
            Text(Testi.data(Giorni.data(scelto))).font(.headline).padding(.horizontal, 4)
            Riquadro {
                HStack {
                    Text("In programma")
                    Spacer()
                    Image(systemName: t.simbolo).foregroundStyle(.secondary)
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
                            Color.clear.frame(maxWidth: .infinity, minHeight: 44)
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
                    .foregroundStyle(.primary)
                segno(iso)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background {
                if iso == scelto { RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.18)) }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(etichetta(iso))
        .accessibilityAddTraits(iso == scelto ? .isSelected : [])
    }

    // Per VoiceOver: data e cosa è successo (o cosa era previsto) quel giorno
    private func etichetta(_ iso: String) -> String {
        var parti = [Testi.data(Giorni.data(iso))]
        if !palestra.allenamenti(del: iso).isEmpty { parti.append(String(localized: "pesi fatti")) }
        if !palestra.cardio(del: iso).isEmpty { parti.append(String(localized: "cardio fatto")) }
        if parti.count == 1 {
            if palestra.programmato(iso) != .riposo { parti.append(String(localized: "in programma: \(palestra.programmato(iso).nome.lowercased())")) }
        }
        return parti.joined(separator: ", ")
    }

    // Pieno = fatto (pesi o cardio), contorno = in programma. Oggi è in grassetto: non solo il colore
    @ViewBuilder private func segno(_ iso: String) -> some View {
        let fatto = !palestra.allenamenti(del: iso).isEmpty || !palestra.cardio(del: iso).isEmpty
        if fatto {
            Circle().fill(Colori.accento).frame(width: 8, height: 8)
        } else if palestra.programmato(iso) != .riposo {
            Circle().strokeBorder(Colori.vuoto, lineWidth: Misure.contorno).frame(width: 8, height: 8)
        } else {
            Color.clear.frame(width: 8, height: 8)
        }
    }
}
