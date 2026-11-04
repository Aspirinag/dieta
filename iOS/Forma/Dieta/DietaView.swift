import SwiftUI

// Scheda Dieta: la settimana del piano. In alto i sette giorni, sotto i pasti del giorno scelto,
// in fondo la spesa. I pasti di oggi si segnano anche in Oggi: è la stessa spunta
struct DietaView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.scenePhase) private var fase
    @Environment(\.dynamicTypeSize) private var dimensione
    @State private var giorno = Giorni.oggi()
    @State private var ultimoOggi = Giorni.oggi()
    @State private var percorso: [PaginaDieta] = Avvio.valore("-vista") == "spesa" ? [.spesa] : []
    @State private var richiesta: TipoPDF?
    @State private var aMano = false

    private var sottotitolo: String {
        guard let p = archivio.profilo.piano(per: giorno) ?? archivio.profilo.piano(per: ultimoOggi) else { return "" }
        let dal = Giorni.data(p.dal).formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "it_IT")))
        return "\(p.nome) · dal \(dal)"
    }

    var body: some View {
        NavigationStack(path: $percorso) {
            ScrollView {
                VStack(spacing: 12) {
                    StrisciaGiorni(lunedi: Giorni.lunedi(ultimoOggi), selezionato: $giorno)
                    if let piano = archivio.profilo.piano(per: giorno) {
                        let pasti = piano.giorni[Giorni.indice(giorno)].pasti
                        ForEach(pasti.indices, id: \.self) { i in
                            RiquadroPasto(giorno: giorno, indice: i, pasto: pasti[i])
                        }
                    } else {
                        vuoto
                    }
                    rigaSpesa
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .sfondoTema()
            .navigationTitle("Dieta")
            .navigationSubtitleSePossibile(sottotitolo)
            .importaPDF($richiesta)
            .sheet(isPresented: $aMano) { EditorPianoView(originale: nil) }
            .destinazioniDieta()
        }
        // Se l'app resta aperta oltre la mezzanotte, passa al nuovo giorno
        .onChange(of: fase) { _, nuova in
            guard nuova == .active else { return }
            let oggi = Giorni.oggi()
            if giorno == ultimoOggi { giorno = oggi }
            ultimoOggi = oggi
        }
    }

    // ---------- Giorno senza piano ----------

    private var vuoto: some View {
        Riquadro {
            Text("Nessun piano per questo giorno").font(.headline)
            Text("Carica il PDF del piano alimentare che ti ha dato il nutrizionista.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) { azioniVuoto }
                VStack(alignment: .leading, spacing: 12) { azioniVuoto }
            }
            .padding(.top, 12)
        }
    }

    @ViewBuilder private var azioniVuoto: some View {
        Button("Carica il PDF") { richiesta = .schema }
            .buttonStyle(PulsanteAccento())
        Button("Scrivilo a mano") { aMano = true }
            .font(.subheadline)
            .frame(minHeight: 44)
    }

    // ---------- Spesa ----------

    // Nascosta se la settimana non ha nessun piano. È la stessa settimana che la Spesa apre di base
    @ViewBuilder private var rigaSpesa: some View {
        let lun = Profilo.lunediSpesa(oggi: ultimoOggi)
        let voci = archivio.profilo.vociSpesa(lunedi: lun)
        if !voci.isEmpty {
            let presi = archivio.spunteSpesa(lunedi: lun)
            let quanti = voci.filter { presi[$0.chiave] == true }.count
            let testo = "\(voci.count) \(voci.count == 1 ? "prodotto" : "prodotti") · \(quanti) \(quanti == 1 ? "preso" : "presi")"
            NavigationLink(value: PaginaDieta.spesa) {
                Riquadro {
                    HStack(spacing: 12) {
                        Image(systemName: "cart")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Colori.accento)
                            .frame(width: 34, height: 34)
                            .background(Colori.accento.opacity(0.14), in: .rect(cornerRadius: 10, style: .continuous))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Spesa della settimana").foregroundStyle(.primary)
                            Text(testo).font(.footnote).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color(.tertiaryLabel))
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, 2)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Spesa della settimana")
            .accessibilityValue(testo)
            .accessibilityAddTraits(.isButton)
        }
    }
}

// ---------- Striscia dei giorni ----------

// I sette giorni della settimana: oggi ha il numero verde, il giorno scelto è pieno verde.
// Sotto ogni giorno un puntino per pasto, pieno se segnato
struct StrisciaGiorni: View {
    @Environment(Archivio.self) private var archivio
    let lunedi: String
    @Binding var selezionato: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                giorno(Giorni.aggiungi(lunedi, i), i)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16, style: .continuous))
        // Sette colonne strette: con il testo molto grande le sigle non devono andare a capo
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private func giorno(_ iso: String, _ i: Int) -> some View {
        let scelto = iso == selezionato
        let oggi = iso == Giorni.oggi()
        let pasti = archivio.profilo.piano(per: iso)?.giorni[i].pasti.count ?? 0
        let fatti = (0..<pasti).filter { archivio.slot(iso, $0).fatto }.count
        let numero = Giorni.calendario.component(.day, from: Giorni.data(iso))
        return Button { selezionato = iso } label: {
            VStack(spacing: 4) {
                Text(String(Giorni.nomi[i].prefix(3)).lowercased()).font(.caption)
                Text("\(numero)").font(.headline).monospacedDigit()
                HStack(spacing: 2) {
                    ForEach(0..<pasti, id: \.self) { p in
                        Circle()
                            .fill(puntino(pieno: p < fatti, scelto: scelto))
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 4)
            }
            .foregroundStyle(scelto ? Colori.sulAccento : (oggi ? Colori.accento : Color.primary))
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.vertical, 6)
            .background(scelto ? Colori.accento : Color.clear, in: .rect(cornerRadius: 12, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Giorni.nomi[i]) \(numero)")
        .accessibilityValue((oggi ? "oggi, " : "") + (pasti > 0 ? "\(fatti) di \(pasti) pasti segnati" : "nessun piano"))
        .accessibilityAddTraits(scelto ? [.isButton, .isSelected] : .isButton)
    }

    private func puntino(pieno: Bool, scelto: Bool) -> Color {
        if scelto { return Colori.sulAccento.opacity(pieno ? 1 : 0.4) }
        return pieno ? Colori.accento : Color(.systemGray4)
    }
}

// ---------- Pasto ----------

// Un pasto del giorno: nome, cibi di seguito con le quantità, «oppure …» per le alternative
private struct RiquadroPasto: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.dynamicTypeSize) private var dimensione
    let giorno: String
    let indice: Int
    let pasto: Pasto

    var body: some View {
        let s = archivio.slot(giorno, indice)
        let scelta = pasto.opzioni.indices.contains(s.opt) ? s.opt : 0
        let cibi = pasto.opzioni.indices.contains(scelta) ? pasto.opzioni[scelta].riassunto : ""
        let alternative = pasto.opzioni.indices.filter { $0 != scelta }.map { pasto.opzioni[$0].principale }.filter { !$0.isEmpty }
        let oppure = alternative.isEmpty ? "" : "oppure " + alternative.joined(separator: ", ")
        NavigationLink(value: PaginaDieta.pasto(giorno, indice)) {
            Riquadro {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(pasto.nome).font(.headline).foregroundStyle(.primary)
                        if !cibi.isEmpty {
                            Text(cibi).font(.subheadline).foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        if !oppure.isEmpty {
                            Text(oppure).font(.footnote).foregroundStyle(Colori.accento)
                                .multilineTextAlignment(.leading)
                                .padding(.top, 3)
                        }
                    }
                    Spacer(minLength: 8)
                    // Con il testo molto grande il nome ha bisogno di tutta la riga: restano solo i segni piccoli
                    if s.fatto {
                        Image(systemName: "checkmark.circle.fill").font(.body).foregroundStyle(Colori.accento)
                    }
                    if !dimensione.isAccessibilitySize {
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }
                .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(pasto.nome)
        .accessibilityValue([cibi, oppure, s.fatto ? "fatto" : ""].filter { !$0.isEmpty }.joined(separator: ". "))
        .accessibilityAddTraits(.isButton)
    }
}

extension Opzione {
    // I cibi di seguito: «Yogurt greco 150 g, fiocchi d'avena 30 g». Senza i prefissi «Contorno:» e «Secondo:»
    var riassunto: String {
        alimenti.enumerated().map { i, a in
            var nome = a.nome
            for prefisso in ["Contorno: ", "Secondo: "] where nome.hasPrefix(prefisso) { nome.removeFirst(prefisso.count) }
            nome = nome.trimmingCharacters(in: .whitespaces)
            if i > 0 { nome = nome.prefix(1).lowercased() + nome.dropFirst() }
            return a.quantita.isEmpty ? nome : "\(nome) \(a.quantita)"
        }
        .joined(separator: ", ")
    }

    // Il cibo che dà il nome all'opzione, per «oppure riso basmati»: il primo, in minuscolo
    var principale: String {
        guard let a = alimenti.first else { return titolo?.lowercased() ?? "" }
        let nome = a.nome.trimmingCharacters(in: .whitespaces)
        return nome.prefix(1).lowercased() + nome.dropFirst()
    }
}
