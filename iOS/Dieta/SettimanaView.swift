import SwiftUI

// Pasti di ogni giorno del piano attivo e lista della spesa della settimana
struct SettimanaView: View {
    @Environment(Archivio.self) private var archivio
    @State private var vista = Avvio.valore("-vista") == "spesa" ? 1 : 0
    @State private var giorno = Giorni.indice(Giorni.oggi())

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Vista", selection: $vista) {
                        Text("Giorni").tag(0)
                        Text("Lista della spesa").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                if vista == 0 {
                    giorni
                } else {
                    spesa
                }
            }
            .navigationTitle("Settimana")
            .toolbar {
                if vista == 1 {
                    ToolbarItem(placement: .topBarLeading) {
                        ShareLink(item: testoSpesa, preview: SharePreview("Lista della spesa")) {
                            Label("Condividi", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) { MenuProfilo() }
            }
        }
    }

    // ---------- Giorni ----------

    @ViewBuilder private var giorni: some View {
        let oggi = Giorni.indice(Giorni.oggi())
        // Se oggi non c'è un piano si mostra quello che inizierà
        if let piano = archivio.profilo.piano(per: Giorni.oggi()) ?? archivio.profilo.prossimoPiano(dopo: Giorni.oggi()) {
            let g = piano.giorni[giorno]
            Section {
                selettoreGiorni(piano, oggi: oggi)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            } footer: {
                Text(piano.dal > Giorni.oggi() ? "\(piano.nome) · inizia il \(Giorni.breve(piano.dal))" : piano.nome)
            }
            Section {
                // Dal giorno del piano, non dalla data: il piano può iniziare a metà di questa settimana
                let previste = Double(archivio.profilo.olio) * Calorie.kcalCucchiainoOlio
                    + g.pasti.compactMap { $0.opzioni.first?.kcal }.reduce(0, +)
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Giorni.nomi[giorno] + (giorno == oggi ? " · oggi" : ""))
                            .font(.title3.weight(.semibold))
                            .fontDesign(.rounded)
                        Text("\(kcal(previste)) previste").font(.subheadline).foregroundStyle(.secondary).monospacedDigit()
                    }
                    Spacer()
                    if g.palestra {
                        Label("Palestra", systemImage: "dumbbell.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.accentColor.gradient, in: .capsule)
                    }
                }
                .padding(.vertical, 4)
            }
            ForEach(Array(g.pasti.enumerated()), id: \.offset) { _, pasto in
                let colore = colorePasto(pasto.nome)
                Section {
                    ForEach(Array(pasto.opzioni.enumerated()), id: \.offset) { j, o in
                        if pasto.opzioni.count > 1 {
                            HStack {
                                Text(o.titolo ?? "Opzione \(j + 1)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(colore)
                                Spacer()
                                if o.kcal > 0 { Text(kcal(o.kcal)).font(.caption).foregroundStyle(.secondary).monospacedDigit() }
                            }
                        }
                        ForEach(Array(o.alimenti.enumerated()), id: \.offset) { _, a in
                            HStack(alignment: .firstTextBaseline) {
                                Text(a.nome)
                                Spacer()
                                Text(a.quantita).foregroundStyle(.secondary).monospacedDigit()
                            }
                        }
                    }
                } header: {
                    HStack(spacing: 8) {
                        IconaPasto(nome: pasto.nome, lato: 24)
                        Text(pasto.nome)
                        Spacer()
                        if pasto.opzioni.count == 1, let o = pasto.opzioni.first, o.kcal > 0 {
                            Text(kcal(o.kcal)).monospacedDigit().textCase(nil)
                        }
                    }
                }
            }
        } else {
            ContentUnavailableView(
                "Nessun piano attivo",
                systemImage: "calendar",
                description: Text("Carica lo schema dietetico in PDF dalla scheda Profilo o da Oggi.")
            )
        }
    }

    // Giorni della settimana corrente: oggi evidenziato, manubrio per la palestra, spunta se tutti i pasti sono segnati
    private func selettoreGiorni(_ piano: Piano, oggi: Int) -> some View {
        let lun = Giorni.lunedi(Giorni.oggi())
        return HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { i in
                let data = Giorni.aggiungi(lun, i)
                let scelto = i == giorno
                Button {
                    giorno = i
                } label: {
                    VStack(spacing: 3) {
                        Text(String(Giorni.nomi[i].prefix(3)))
                            .font(.caption2.weight(.medium))
                            .textCase(.uppercase)
                        Text(String(Int(data.suffix(2)) ?? 0))
                            .font(.title3.weight(.semibold))
                            .fontDesign(.rounded)
                            .monospacedDigit()
                        Group {
                            if completo(data) {
                                Image(systemName: "checkmark.circle.fill")
                            } else if piano.giorni[i].palestra {
                                Image(systemName: "dumbbell.fill")
                            } else {
                                Image(systemName: "circle.fill").hidden()
                            }
                        }
                        .font(.caption2)
                        .frame(height: 12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(scelto ? AnyShapeStyle(.white) : i == oggi ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(scelto ? AnyShapeStyle(.tint) : AnyShapeStyle(Color(.secondarySystemGroupedBackground)))
                        if i == oggi && !scelto {
                            RoundedRectangle(cornerRadius: 14).strokeBorder(.tint, lineWidth: 1.5)
                        }
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Giorni.nomi[i] + (i == oggi ? ", oggi" : ""))
                .accessibilityAddTraits(scelto ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: giorno)
        .animation(.snappy(duration: 0.25), value: giorno)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)   // sette colonne: oltre non ci stanno
    }

    // Giorno passato (o oggi) con tutti i pasti segnati
    private func completo(_ data: String) -> Bool {
        guard data <= Giorni.oggi(), let p = archivio.profilo.piano(per: data) else { return false }
        let pasti = p.giorni[Giorni.indice(data)].pasti
        return !pasti.isEmpty && pasti.indices.allSatisfy { archivio.slot(data, $0).fatto }
    }

    // ---------- Spesa ----------
    // Divisa per reparto come al supermercato; quantità a destra in grassetto; ciò che è già preso scende in fondo

    @ViewBuilder private var spesa: some View {
        let voci = archivio.vociSpesa()
        let profili = archivio.profiliSpesa
        let presi = archivio.spunteSpesa()
        let giorni = Giorni.prossimi7()
        let daPrendere = voci.filter { presi[$0.chiave] != true }
        let nelCarrello = voci.filter { presi[$0.chiave] == true }
        if voci.isEmpty {
            ContentUnavailableView("Nessun piano nei prossimi 7 giorni", systemImage: "cart")
        } else {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(daPrendere.isEmpty ? "Tutto preso" : "Ancora \(daPrendere.count) da prendere")
                            .font(.headline)
                            .contentTransition(.numericText())
                        Spacer()
                        Text("\(nelCarrello.count)/\(voci.count)").foregroundStyle(.secondary).monospacedDigit()
                    }
                    ProgressView(value: Double(nelCarrello.count), total: Double(voci.count))
                    Text("Dal \(Giorni.breve(giorni[0])) al \(Giorni.breve(giorni[6]))"
                         + (profili.count > 1 ? " · per \(profili.map(\.nome).formatted(.list(type: .and)))" : ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            ForEach(Calorie.Reparto.allCases, id: \.self) { r in
                let righe = daPrendere.filter { $0.reparto == r }
                if !righe.isEmpty {
                    Section {
                        ForEach(righe) { v in rigaSpesa(v, preso: false) }
                    } header: {
                        HStack(spacing: 8) {
                            Image(systemName: r.icona)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(coloreReparto(r).gradient, in: .rect(cornerRadius: 7))
                            Text(r.nome)
                            Spacer()
                            Text("\(righe.count)").monospacedDigit()
                        }
                    }
                }
            }
            if !nelCarrello.isEmpty {
                Section {
                    ForEach(nelCarrello) { v in rigaSpesa(v, preso: true) }
                    Button("Togli tutte le spunte", systemImage: "arrow.counterclockwise") { archivio.azzeraSpesa() }
                } header: {
                    Label("Già nel carrello", systemImage: "cart.fill")
                }
            }
            Section {
            } footer: {
                Text((profili.count > 1 ? "Le quantità sono la somma di tutti i profili (sotto ogni voce la parte di ciascuno) e le spunte valgono per tutti. " : "")
                     + "×5 vuol dire 5 di quell'alimento (es. 5 banane). Comprende oggi e i 6 giorni successivi; per ogni pasto conta l'alternativa scelta in Oggi, altrimenti la prima. Ogni spunta dura 7 giorni.")
            }
        }
    }

    private func rigaSpesa(_ v: VoceSpesa, preso: Bool) -> some View {
        Button {
            withAnimation(.snappy) { archivio.spunta(v.chiave) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: preso ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(preso ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
                VStack(alignment: .leading, spacing: 2) {
                    Text(v.nome).strikethrough(preso)
                    if let d = v.dettaglio, !preso {
                        Text(d).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 12)
                Text(v.quanto)
                    .font(.body.weight(v.quanto == "q.b." ? .regular : .semibold))
                    .fontDesign(.rounded)
                    .monospacedDigit()
                    .foregroundStyle(v.quanto == "q.b." || preso ? .secondary : .primary)
                    .multilineTextAlignment(.trailing)
            }
            .opacity(preso ? 0.55 : 1)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: preso)
    }

    private func coloreReparto(_ r: Calorie.Reparto) -> Color {
        switch r {
        case .fruttaVerdura: Color(red: 0.20, green: 0.66, blue: 0.42)
        case .pane: Color(red: 0.95, green: 0.62, blue: 0.13)
        case .carne: Color(red: 0.88, green: 0.30, blue: 0.30)
        case .pesce: Color(red: 0.20, green: 0.52, blue: 0.90)
        case .latticini: Color(red: 0.36, green: 0.38, blue: 0.85)
        case .legumi: Color(red: 0.55, green: 0.58, blue: 0.16)
        case .dispensa: Color(red: 0.60, green: 0.43, blue: 0.30)
        case .altro: .gray
        }
    }

    // Da condividere (es. su WhatsApp): solo ciò che manca, per reparto
    private var testoSpesa: String {
        let presi = archivio.spunteSpesa()
        let mancano = archivio.vociSpesa().filter { presi[$0.chiave] != true }
        var righe = ["Lista della spesa"]
        for r in Calorie.Reparto.allCases {
            let voci = mancano.filter { $0.reparto == r }
            guard !voci.isEmpty else { continue }
            righe.append("\n" + r.nome.uppercased())
            righe += voci.map { "- \($0.nome)" + ($0.quanto.isEmpty ? "" : ": \($0.quanto)") }
        }
        return righe.joined(separator: "\n")
    }
}
