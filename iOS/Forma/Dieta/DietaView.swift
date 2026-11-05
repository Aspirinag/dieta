import SwiftUI

// Scheda Dieta: la settimana del piano. In alto i sette giorni, sotto i pasti del giorno scelto in una lista.
// La spesa si apre dal carrello nella barra. I pasti di oggi si segnano anche in Oggi: è la stessa spunta
struct DietaView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.scenePhase) private var fase
    @State private var giorno = Giorni.oggi()
    @State private var ultimoOggi = Giorni.oggi()
    @State private var percorso: [PaginaDieta] = Avvio.valore("-vista") == "spesa" ? [.spesa] : []
    @State private var richiesta: TipoPDF?
    @State private var aMano = false

    private var sottotitolo: String {
        guard let p = archivio.profilo.piano(per: giorno) ?? archivio.profilo.piano(per: ultimoOggi) else { return "" }
        let dal = Giorni.data(p.dal).formatted(.dateTime.day().month(.wide))
        return String(localized: "\(p.nome) · dal \(dal)")
    }

    var body: some View {
        NavigationStack(path: $percorso) {
            List {
                Section {
                    StrisciaGiorni(lunedi: Giorni.lunedi(ultimoOggi), selezionato: $giorno)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                if let piano = archivio.profilo.piano(per: giorno) {
                    let pasti = piano.giorni[Giorni.indice(giorno)].pasti
                    if pasti.isEmpty {
                        Section {
                            Riga("Nessun pasto per questo giorno").righeTema()
                        }
                    } else {
                        let fatti = pasti.indices.filter { archivio.slot(giorno, $0).fatto }.count
                        Section {
                            ForEach(pasti.indices, id: \.self) { i in
                                RigaPasto(giorno: giorno, indice: i, pasto: pasti[i])
                            }
                        } header: {
                            Text("Pasti · \(fatti) di \(pasti.count)").textCase(nil)
                        }
                    }
                } else {
                    vuoto
                }
            }
            .sfondoTema()
            .navigationTitle("Dieta")
            .navigationSubtitleSePossibile(sottotitolo)
            .importaPDF($richiesta)
            .toolbar {
                // Il carrello c'è solo se la settimana ha una spesa; è l'unica porta della Spesa
                ToolbarItemGroup(placement: .topBarTrailing) {
                    carrello
                    PulsanteImpostazioni()
                }
            }
            .sheet(isPresented: $aMano) { EditorPianoView(originale: nil) }
            .destinazioniDieta()
        }
        .tint(.primary)
        // Se l'app resta aperta oltre la mezzanotte, passa al nuovo giorno
        .onChange(of: fase) { _, nuova in
            guard nuova == .active else { return }
            let oggi = Giorni.oggi()
            giorno = Giorni.giornoScelto(giorno, ultimoOggi: ultimoOggi, oggi: oggi)
            ultimoOggi = oggi
        }
    }

    // ---------- Giorno senza piano ----------

    private var vuoto: some View {
        Section {
            VStack(alignment: .leading, spacing: Spazio.xs) {
                Text("Nessun piano per questo giorno").font(.headline)
                Text("Carica il PDF del piano alimentare che ti ha dato il nutrizionista.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Spazio.l) { azioniVuoto }
                    VStack(alignment: .leading, spacing: Spazio.m) { azioniVuoto }
                }
                .padding(.top, Spazio.m)
            }
            .padding(.vertical, Spazio.xs)
            .righeTema()
        }
    }

    @ViewBuilder private var azioniVuoto: some View {
        Button("Carica il PDF") { richiesta = .schema }
            .buttonStyle(PulsanteAccento())
        Button("Scrivilo a mano") { aMano = true }
            .font(.subheadline)
            .frame(minHeight: Misure.tocco)
    }

    // ---------- Spesa ----------

    // Nascosto se la settimana non ha nessun piano. È la stessa settimana che la Spesa apre di base.
    // Il conteggio sta nel valore di accessibilità («3 di 11 presi»)
    @ViewBuilder private var carrello: some View {
        let lun = Profilo.lunediSpesa(oggi: ultimoOggi)
        let voci = archivio.profilo.vociSpesa(lunedi: lun)
        if !voci.isEmpty {
            let presi = archivio.spunteSpesa(lunedi: lun)
            let quanti = voci.filter { presi[$0.chiave] == true }.count
            Button("Spesa", systemImage: "cart") { percorso.append(.spesa) }
                .accessibilityValue(Text("\(quanti) di \(voci.count) presi"))
        }
    }
}

// ---------- Striscia dei giorni ----------

// I sette giorni della settimana: il giorno scelto è pieno (scuro), oggi ha un contorno.
// Sotto ogni giorno un puntino per pasto: pieno verde = segnato, contorno = da fare
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
        .padding(.horizontal, Spazio.xs)
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
            VStack(spacing: Spazio.xs) {
                Text(Giorni.sigla(i)).font(.caption)
                Text("\(numero)").font(.numero(.headline))
                HStack(spacing: 3) {
                    ForEach(0..<pasti, id: \.self) { p in
                        puntino(pieno: p < fatti, scelto: scelto)
                    }
                }
                .frame(height: 6)
            }
            .foregroundStyle(scelto ? Color(.systemBackground) : Color.primary)
            .frame(maxWidth: .infinity, minHeight: Misure.tocco)
            .padding(.vertical, Spazio.xs)
            .background {
                if scelto {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary)
                } else if oggi {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Colori.vuoto, lineWidth: Misure.contorno)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Giorni.nomeGiorno(i)) \(numero)")
        .accessibilityValue(Text(verbatim: (oggi ? String(localized: "oggi") + ", " : "") + (pasti > 0 ? String(localized: "\(fatti) di \(pasti) pasti segnati") : String(localized: "nessun piano"))))
        .accessibilityAddTraits(scelto ? [.isButton, .isSelected] : .isButton)
    }

    // Pieno = segnato (verde, o chiaro sul giorno scelto); contorno = da fare: si distinguono anche senza colore
    @ViewBuilder private func puntino(pieno: Bool, scelto: Bool) -> some View {
        if pieno {
            Circle().fill(scelto ? Color(.systemBackground) : Colori.accento).frame(width: 6, height: 6)
        } else {
            Circle().strokeBorder(scelto ? Color(.systemBackground) : Colori.vuoto, lineWidth: 1).frame(width: 6, height: 6)
        }
    }
}

// ---------- Pasto ----------

// Una riga per pasto: cerchio a sinistra (segna il pasto), nome, cibi con le quantità, alternativa in grigio.
// Il resto della riga apre il dettaglio
private struct RigaPasto: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.dynamicTypeSize) private var dimensione
    let giorno: String
    let indice: Int
    let pasto: Pasto

    var body: some View {
        let s = archivio.slot(giorno, indice)
        let scelta = pasto.opzioni.indices.contains(s.opt) ? s.opt : 0
        let cibi = pasto.opzioni.indices.contains(scelta) ? pasto.opzioni[scelta].riassunto : ""
        let alternativa = pasto.opzioni.count > 1
            ? String(localized: "Alternativa: \(pasto.nomeAlternativa(scelta)) (\(scelta + 1) di \(pasto.opzioni.count))")
            : ""
        let dettaglio = [cibi, alternativa].filter { !$0.isEmpty }.joined(separator: "\n")
        let spunta = CerchioSpunta(fatta: s.fatto, etichetta: Text("Segna \(pasto.nome)")) {
            // Segna il pasto del giorno scelto, anche se non è oggi
            archivio.cambiaSlot(giorno, indice) { $0.fatto.toggle() }
        }
        .disabled(giorno > Giorni.oggi())   // un pasto futuro non si segna; la riga apre comunque il dettaglio
        let titolo = Text(pasto.nome)
        let testo = dettaglio.isEmpty ? nil : Text(verbatim: dettaglio)
        NavigationLink(value: PaginaDieta.pasto(giorno, indice)) {
            if dimensione.isAccessibilitySize {
                // A testo molto grande il cerchio sta sopra: il nome e i cibi hanno tutta la larghezza
                VStack(alignment: .leading, spacing: 0) {
                    spunta
                    Riga(titolo, dettaglio: testo, evidente: true, fatta: s.fatto)
                }
            } else {
                Riga(titolo, dettaglio: testo, evidente: true, fatta: s.fatto, inizio: spunta)
            }
        }
        .righeTema()
    }
}

extension Pasto {
    // Il nome di un'alternativa, uguale in lista e nel selettore del dettaglio: il titolo se c'è
    // («Pasta»), altrimenti il primo cibo («Riso basmati»), altrimenti «Alternativa 2»
    func nomeAlternativa(_ j: Int) -> String {
        guard opzioni.indices.contains(j) else { return "" }
        if let titolo = opzioni[j].titolo?.trimmingCharacters(in: .whitespaces), !titolo.isEmpty { return titolo }
        let primo = opzioni[j].principale
        if !primo.isEmpty { return primo.prefix(1).uppercased() + primo.dropFirst() }
        return String(localized: "Alternativa \(j + 1)")
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
