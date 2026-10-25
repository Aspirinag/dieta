import SwiftUI

// Pasti del giorno, olio e acqua; con le frecce si torna ai giorni passati.
// Schede invece di un elenco: riepilogo con tre anelli, un pasto per scheda (quelli fatti si richiudono)
struct OggiView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.scenePhase) private var fase
    @State private var giorno = Giorni.oggi()
    @State private var ultimoOggi = Giorni.oggi()

    private var titolo: String {
        let oggi = Giorni.oggi()
        let nome = Giorni.nomi[Giorni.indice(giorno)]
        if giorno == oggi { return "Oggi" }
        if giorno == Giorni.aggiungi(oggi, -1) { return "Ieri" }
        return nome
    }

    private var notaCalorie: String {
        var t = "Calorie stimate con valori medi (tabelle CREA), olio compreso: sono un ordine di grandezza."
        if let bmr = archivio.profilo.bia.max(by: { $0.data < $1.data })?.bmr {
            t += " Metabolismo basale dall'ultima BIA: \(numeroKcal(bmr)) kcal."
        }
        return t
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let piano = archivio.profilo.piano(per: giorno) {
                    let g = piano.giorni[Giorni.indice(giorno)]
                    // Il primo pasto non ancora segnato è quello «da fare»
                    let prossimo = g.pasti.indices.first { !archivio.slot(giorno, $0).fatto }
                    VStack(spacing: 14) {
                        RiepilogoGiorno(giorno: giorno, piano: piano)
                        ForEach(Array(g.pasti.enumerated()), id: \.offset) { i, pasto in
                            SchedaPasto(giorno: giorno, indice: i, pasto: pasto, prossimo: i == prossimo && giorno == Giorni.oggi())
                        }
                        SchedaAcquaOlio(giorno: giorno)
                        VStack(alignment: .leading, spacing: 8) {
                            if !archivio.profilo.testoNote.isEmpty {
                                Label(archivio.profilo.testoNote, systemImage: "lightbulb")
                            }
                            Text(notaCalorie)
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .animation(.spring(duration: 0.35), value: archivio.registro(giorno))
                } else {
                    let prossimo = archivio.profilo.prossimoPiano(dopo: giorno)
                    ContentUnavailableView(
                        "Nessun piano per questo giorno",
                        systemImage: "fork.knife",
                        description: Text(prossimo.map { "Il piano «\($0.nome)» inizia il \(Giorni.breve($0.dal))." }
                                          ?? "Carica lo schema dietetico in PDF dalla scheda Dati.")
                    )
                    .padding(.top, 80)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(titolo)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Giorno precedente", systemImage: "chevron.left") {
                        giorno = Giorni.aggiungi(giorno, -1)
                    }
                    Button("Giorno successivo", systemImage: "chevron.right") {
                        giorno = Giorni.aggiungi(giorno, 1)
                    }
                    .disabled(giorno >= Giorni.oggi())
                    if giorno != Giorni.oggi() {
                        Button("Oggi") { giorno = Giorni.oggi() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) { MenuProfilo() }
            }
            .animation(.default, value: giorno)
        }
        // Se l'app resta aperta oltre la mezzanotte, passa al nuovo giorno
        .onChange(of: fase) { _, nuova in
            guard nuova == .active else { return }
            if giorno == ultimoOggi { giorno = Giorni.oggi() }
            ultimoOggi = Giorni.oggi()
        }
    }
}

// Data, piano e tre anelli: pasti segnati, acqua bevuta, calorie dei pasti segnati
struct RiepilogoGiorno: View {
    @Environment(Archivio.self) private var archivio
    let giorno: String
    let piano: Piano

    var body: some View {
        let g = piano.giorni[Giorni.indice(giorno)]
        let fatti = g.pasti.indices.filter { archivio.slot(giorno, $0).fatto }.count
        let r = archivio.registro(giorno)
        let p = archivio.profilo
        let kcal = p.calorie(giorno)
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Giorni.nomi[Giorni.indice(giorno)] + " " + Giorni.breve(giorno))
                        .font(.title3.weight(.semibold))
                        .fontDesign(.rounded)
                    Text(piano.nome).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                if g.palestra {
                    Label("Palestra", systemImage: "dumbbell.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.accentColor.gradient, in: .capsule)
                }
            }
            HStack(alignment: .top) {
                misura(Anello(valore: g.pasti.isEmpty ? 0 : Double(fatti) / Double(g.pasti.count),
                              testo: "\(fatti)/\(g.pasti.count)", lato: 64,
                              descrizione: "Pasti segnati: \(fatti) su \(g.pasti.count)"),
                       titolo: fatti == g.pasti.count && fatti > 0 ? "Tutti fatti" : "Pasti")
                misura(Anello(valore: p.acqua > 0 ? r.acqua / p.acqua : 0, testo: num(r.acqua), lato: 64,
                              descrizione: "Acqua: \(num(r.acqua)) litri su \(num(p.acqua))", colore: .blue),
                       titolo: "di \(num(p.acqua)) L")
                if let kcal {
                    misura(Anello(valore: kcal.previste > 0 ? kcal.segnate / kcal.previste : 0,
                                  testo: numeroKcal(kcal.segnate), lato: 64,
                                  descrizione: "Calorie dei pasti segnati: circa \(numeroKcal(kcal.segnate)) su \(numeroKcal(kcal.previste))",
                                  colore: .orange),
                           titolo: "di ≈ \(numeroKcal(kcal.previste)) kcal")
                }
            }
        }
        .scheda()
    }

    private func misura(_ anello: Anello, titolo: String) -> some View {
        VStack(spacing: 6) {
            anello
            Text(titolo)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// Un pasto: alternative, alimenti e pulsante per segnarlo. Fatto, si richiude in una riga (toccandola si riapre)
struct SchedaPasto: View {
    @Environment(Archivio.self) private var archivio
    let giorno: String
    let indice: Int
    let pasto: Pasto
    let prossimo: Bool
    @State private var aperto = false

    var body: some View {
        let s = archivio.slot(giorno, indice)
        let scelta = pasto.opzioni.indices.contains(s.opt) ? s.opt : 0
        let opz = pasto.opzioni.indices.contains(scelta) ? pasto.opzioni[scelta] : nil
        let calorie = opz?.calorie
        let colore = colorePasto(pasto.nome)
        let chiuso = s.fatto && !aperto
        VStack(alignment: .leading, spacing: 14) {
            Button {
                if s.fatto { aperto.toggle() }
            } label: {
                HStack(spacing: 12) {
                    IconaPasto(nome: pasto.nome)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(pasto.nome).font(.headline)
                        if let t = opz?.titolo, chiuso || pasto.opzioni.count == 1 {
                            Text(t).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                        } else if prossimo {
                            Text("Prossimo pasto").font(.subheadline.weight(.medium)).foregroundStyle(colore)
                        }
                    }
                    Spacer(minLength: 8)
                    if let calorie, calorie.kcal > 0 {
                        Text(kcal(calorie.kcal, incompleto: !calorie.ignoti.isEmpty))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    if s.fatto {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(colore)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .allowsHitTesting(s.fatto)   // non .disabled: renderebbe l'intestazione grigia

            if !chiuso {
                if pasto.opzioni.count > 1 {
                    let scelte = Picker("Alternativa", selection: Binding(
                        get: { scelta },
                        set: { nuova in archivio.cambiaSlot(giorno, indice) { $0.opt = nuova } }
                    )) {
                        ForEach(pasto.opzioni.indices, id: \.self) { j in
                            Text(pasto.opzioni[j].titolo ?? "Opzione \(j + 1)").tag(j)
                        }
                    }
                    if pasto.opzioni.count <= 3 && pasto.opzioni.allSatisfy({ ($0.titolo ?? "").count <= 14 }) {
                        scelte.pickerStyle(.segmented)
                    } else {
                        // Titoli lunghi: menu a tendina con il titolo scelto ben visibile
                        Menu {
                            scelte
                        } label: {
                            HStack {
                                Text(opz?.titolo ?? "Opzione \(scelta + 1)").fontWeight(.medium).lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down").font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(colore.opacity(0.12), in: .rect(cornerRadius: 10))
                            .foregroundStyle(colore)
                        }
                    }
                }
                VStack(spacing: 0) {
                    ForEach(Array((opz?.alimenti ?? []).enumerated()), id: \.offset) { j, a in
                        if j > 0 { Divider() }
                        HStack(alignment: .firstTextBaseline) {
                            Text(a.nome).strikethrough(s.fatto)
                            Spacer(minLength: 12)
                            Text(a.quantita).foregroundStyle(.secondary).monospacedDigit()
                        }
                        .padding(.vertical, 8)
                        .opacity(s.fatto ? 0.5 : 1)
                    }
                }
                if let calorie, !calorie.ignoti.isEmpty {
                    Text("Calorie non stimate per: \(calorie.ignoti.joined(separator: ", ")).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button {
                    archivio.cambiaSlot(giorno, indice) { $0.fatto.toggle() }
                    aperto = false
                } label: {
                    Label(s.fatto ? "Segnato come fatto · annulla" : "Segna come fatto",
                          systemImage: s.fatto ? "arrow.uturn.backward" : "checkmark")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(s.fatto ? .secondary : colore)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
            }
        }
        .scheda()
        .overlay {
            if prossimo {
                RoundedRectangle(cornerRadius: 22).strokeBorder(colore.opacity(0.7), lineWidth: 2)
            }
        }
        .sensoryFeedback(trigger: s.fatto) { _, nuovo in nuovo ? .success : .selection }
    }
}

// Acqua a bicchieri da 0,25 L e olio a cucchiaini: si tocca l'ultimo da riempire (o l'ultimo pieno per toglierlo)
struct SchedaAcquaOlio: View {
    @Environment(Archivio.self) private var archivio
    let giorno: String

    var body: some View {
        let r = archivio.registro(giorno)
        let p = archivio.profilo
        VStack(alignment: .leading, spacing: 16) {
            riga(titolo: "Acqua", valore: "\(num(r.acqua)) / \(num(p.acqua)) L", icona: "drop.fill", colore: .blue,
                 pieni: Int((r.acqua / 0.25).rounded()), totale: Int((p.acqua / 0.25).rounded()),
                 unita: "bicchiere") { n in archivio.cambiaRegistro(giorno) { $0.acqua = Double(n) * 0.25 } }
            Divider()
            riga(titolo: "Olio extra vergine", valore: "\(r.olio) / \(p.olio) cucchiaini", icona: "drop.halffull",
                 colore: Color(red: 0.62, green: 0.62, blue: 0.13),
                 pieni: r.olio, totale: p.olio, unita: "cucchiaino") { n in archivio.cambiaRegistro(giorno) { $0.olio = n } }
            Text("Un bicchiere è circa 0,25 L.").font(.caption).foregroundStyle(.secondary)
        }
        .scheda()
        .sensoryFeedback(.selection, trigger: r)
    }

    private func riga(titolo: String, valore: String, icona: String, colore: Color,
                      pieni: Int, totale: Int, unita: String, cambia: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(titolo).font(.headline)
                Spacer()
                Text(valore).foregroundStyle(.secondary).monospacedDigit().contentTransition(.numericText())
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: min(max(totale, 1), 8)), spacing: 8) {
                ForEach(0..<max(totale, 1), id: \.self) { i in
                    Button {
                        // Toccare l'ultimo pieno lo svuota, altrimenti si riempie fino a quello toccato
                        cambia(i + 1 == pieni ? i : i + 1)
                    } label: {
                        Image(systemName: icona)
                            .font(.title2)
                            .foregroundStyle(i < pieni ? AnyShapeStyle(colore.gradient) : AnyShapeStyle(colore.opacity(0.22)))
                            .symbolEffect(.bounce, value: i < pieni)
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(unita.capitalized) \(i + 1)")
                    .accessibilityAddTraits(i < pieni ? .isSelected : [])
                }
            }
        }
    }
}
