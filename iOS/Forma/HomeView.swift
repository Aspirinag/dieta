import SwiftUI

// Oggi, la panoramica: pasti, allenamento, olio e acqua, peso. Ogni cosa in un riquadro;
// il dettaglio sta nelle schede Dieta, Palestra e Progressi
struct HomeView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(Palestra.self) private var palestra
    @Environment(Navigazione.self) private var navigazione
    @State private var richiesta: TipoPDF?
    @State private var nuovaMisura = false
    @State private var pesoVeloce = false
    @State private var pesoPerModulo: Double?
    @State private var apriModulo = false
    @State private var cardioAperto = false
    @Environment(\.dynamicTypeSize) private var dimensione

    private var titolo: String {
        Date().formatted(.dateTime.weekday(.wide).day().month(.wide)).capitalized
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    pagamento
                    pasti
                    allenamento
                    if archivio.profilo.piano(per: Giorni.oggi()) != nil {
                        olioEAcqua
                    }
                    peso
                    note
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .sfondoTema()
            .navigationTitle("Oggi")
            .navigationSubtitleSePossibile(titolo)
            .importaPDF($richiesta)
            .sheet(isPresented: $cardioAperto) { NuovoCardioView() }
            .sheet(isPresented: $pesoVeloce, onDismiss: {
                if apriModulo { apriModulo = false; nuovaMisura = true }
            }) {
                PesoVeloceView { kg in
                    pesoPerModulo = kg
                    apriModulo = true
                }
                .presentationDetents([.height(dimensione.isAccessibilitySize ? 420 : 260)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $nuovaMisura) {
                NavigationStack {
                    EditorMisura(dataEsistente: archivio.profilo.bia.contains { $0.data == Giorni.oggi() } ? Giorni.oggi() : nil,
                                 pesoIniziale: pesoPerModulo)
                        .toolbar {
                            if archivio.profilo.bia.contains(where: { $0.data == Giorni.oggi() }) {
                                ToolbarItem(placement: .cancellationAction) { AnnullaFoglio() }
                            }
                        }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    MenuProfilo()
                    Button("Impostazioni", systemImage: "gearshape") { navigazione.impostazioniAperte = true }
                }
            }
            .navigationDestination(for: UUID.self) { DettaglioAllenamentoView(id: $0) }
            .navigationDestination(for: Esercizio.self) { DettaglioEsercizioView(idEsercizio: $0.id) }
            .destinazioniDieta()
        }
    }

    // ---------- Note ----------

    // Le note del profilo (Impostazioni → Olio e acqua) stanno in fondo, piccole
    @ViewBuilder private var note: some View {
        let testo = archivio.profilo.testoNote
        if !testo.isEmpty {
            Riquadro {
                Text(testo)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .accessibilityIdentifier("riquadro-note")
        }
    }

    // ---------- Pagamento ----------

    // Solo da una settimana prima del giorno di pagamento al giorno dopo, finché non è segnato pagato
    @ViewBuilder private var pagamento: some View {
        if let p = palestra.promemoriaPagamento() {
            Riquadro {
                Text(p.testo).font(.subheadline)
                Button("Segna come pagato") { withAnimation { palestra.segnaPagato(p.mese) } }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(Colori.accento)
                    .padding(.top, 8)
            }
            .accessibilityIdentifier("riquadro-pagamento")
        }
    }

    // ---------- Pasti ----------

    @ViewBuilder private var pasti: some View {
        let oggi = Giorni.oggi()
        if let piano = archivio.profilo.piano(per: oggi) {
            let elenco = piano.giorni[Giorni.indice(oggi)].pasti
            let fatti = elenco.indices.filter { archivio.slot(oggi, $0).fatto }.count
            Riquadro {
                if elenco.isEmpty {
                    Text("Pasti").font(.headline)
                    Text("Nessun pasto per questo giorno")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                } else {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Pasti").font(.headline)
                        Spacer()
                        Text("\(fatti) di \(elenco.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .padding(.bottom, 10)
                    BarraSegmenti(fatti: fatti, totale: elenco.count)
                        .padding(.bottom, 4)
                }
                ForEach(elenco.indices, id: \.self) { i in
                    if i > 0 { Divider() }
                    let fatto = archivio.slot(oggi, i).fatto
                    let opzioni = elenco[i].opzioni
                    let scelta = opzioni.indices.contains(archivio.slot(oggi, i).opt) ? archivio.slot(oggi, i).opt : 0
                    let alimenti = opzioni.indices.contains(scelta) ? Pasto.riga(opzioni[scelta]) : nil
                    HStack(spacing: 0) {
                        NavigationLink(value: PaginaDieta.pasto(oggi, i)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(elenco[i].nome)
                                    .foregroundStyle(fatto ? Color.secondary : Color.primary)
                                if let alimenti {
                                    Text(alimenti)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("pasto-\(elenco[i].nome)")
                        Button { archivio.cambiaSlot(oggi, i) { $0.fatto.toggle() } } label: {
                            Spunta(fatta: fatto)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .sensoryFeedback(.selection, trigger: fatto)
                        .accessibilityIdentifier("riga-pasto")
                        .accessibilityLabel("Segna \(elenco[i].nome)")
                        .accessibilityValue(fatto ? Text("fatto") : Text("da fare"))
                        .accessibilityAddTraits(fatto ? .isSelected : [])
                    }
                }
            }
        } else {
            Riquadro {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Nessun piano per oggi").font(.headline)
                    Button("Carica il piano alimentare (PDF)") { richiesta = .schema }
                        .buttonStyle(PulsanteAccento())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // ---------- Allenamento ----------

    @ViewBuilder private var allenamento: some View {
        let oggi = Giorni.oggi()
        let tipo = palestra.programmato(oggi)
        let fatti = palestra.allenamenti(del: oggi)
        let cardio = palestra.cardio(del: oggi)
        Riquadro {
            if let a = palestra.stato.inCorso {
                disposizione {
                    sottotitolato(a.titolo, Text("In corso"))
                    Spacer(minLength: 8)
                    Button("Riprendi") { navigazione.allenamentoAperto = true }
                        .buttonStyle(PulsanteAccento())
                }
            } else if tipo == .pesi && fatti.isEmpty {
                if let r = palestra.stato.prossimaRoutine() {
                    disposizione {
                        sottotitolato(r.nome, Text("\(Self.esercizi(r.voci.count)) · circa \(minutiStimati(r)) min"))
                        Spacer(minLength: 8)
                        Button("Inizia") {
                            palestra.inizia(r)
                            navigazione.allenamentoAperto = true
                        }
                        .buttonStyle(PulsanteAccento())
                    }
                } else {
                    disposizione {
                        Text("Nessuna scheda").font(.headline)
                        Spacer(minLength: 8)
                        Button("Crea la prima scheda") { navigazione.scheda = .allenamento }
                            .buttonStyle(PulsanteAccento())
                    }
                }
            } else if fatti.isEmpty && cardio.isEmpty {
                if tipo == .cardio {
                    disposizione {
                        Text("Oggi cardio").font(.headline)
                        Spacer(minLength: 8)
                        Button("Registra cardio") { cardioAperto = true }
                            .font(.subheadline)
                    }
                } else {
                    disposizione {
                        Text("Oggi riposo").font(.headline)
                        Spacer(minLength: 8)
                        Button("Allenati lo stesso") { navigazione.scheda = .allenamento }
                            .font(.subheadline)
                    }
                }
            }
            ForEach(fatti) { a in
                NavigationLink(value: a.id) {
                    HStack(spacing: 12) {
                        sottotitolato(a.titolo, Text(durataTesto(a.durata)))
                        Spacer(minLength: 8)
                        Spunta(fatta: true)
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            ForEach(cardio) { c in
                HStack(spacing: 12) {
                    Text("\(Libreria.nomeCardio(c.tipo)) · \(c.minuti) min" + (c.km > 0 ? " · \(num(c.km)) km" : ""))
                    Spacer(minLength: 8)
                    Spunta(fatta: true)
                }
                .padding(.vertical, 2)
                .accessibilityElement(children: .combine)
            }
            if Self.mostraAltraScheda(inCorso: palestra.stato.inCorso != nil, pesiFatti: fatti.count, cardioFatto: cardio.count) {
                Button("Un'altra scheda") { navigazione.scheda = .allenamento }
                    .font(.subheadline)
                    .frame(minHeight: 44, alignment: .leading)
            }
        }
    }

    // Il link a Palestra compare a fine allenamento (pesi o cardio fatti), mai con un allenamento in corso
    static func mostraAltraScheda(inCorso: Bool, pesiFatti: Int, cardioFatto: Int) -> Bool {
        !inCorso && (pesiFatti > 0 || cardioFatto > 0)
    }

    // Durata indicativa: 40 secondi a serie più il recupero, a multipli di 5 minuti
    private func minutiStimati(_ r: Routine) -> Int {
        let secondi = r.voci.reduce(0) { $0 + $1.serie * (40 + $1.recupero) }
        return max(5, Int((Double(secondi) / 300).rounded()) * 5)
    }

    // ---------- Olio e acqua ----------

    @ViewBuilder private var olioEAcqua: some View {
        let oggi = Giorni.oggi()
        let r = archivio.registro(oggi)
        let p = archivio.profilo
        Riquadro {
            if p.olio > 0 {
                Dosaggio(
                    nome: "Olio", unita: "cucchiaini",
                    valore: Binding(get: { r.olio }, set: { v in archivio.cambiaRegistro(oggi) { $0.olio = v } }),
                    dose: p.olio, colore: Colori.olio, simbolo: .cucchiaino)
                    .padding(.vertical, 6)
            }
            if p.olio > 0 && p.acqua > 0 { Divider() }
            if p.acqua > 0 {
                Dosaggio(
                    nome: "Acqua", unita: "L",
                    valore: Binding(
                        get: { Int((r.acqua / Dosi.litriPerGoccia).rounded()) },
                        set: { v in archivio.cambiaRegistro(oggi) { $0.acqua = Double(v) * Dosi.litriPerGoccia } }),
                    dose: Dosi.gocce(dose: p.acqua), colore: Colori.acqua, simbolo: .goccia,
                    quantitaPerElemento: Dosi.litriPerGoccia, doseTesto: num(p.acqua))
                    .padding(.vertical, 6)
            }
        }
    }

    // ---------- Peso ----------

    @ViewBuilder private var peso: some View {
        let bia = archivio.profilo.bia.filter { $0.peso != nil }.sorted { $0.data < $1.data }
        if let ultimo = PesoVeloce.ultimo(bia), let kg = ultimo.peso {
            let quando = PesoVeloce.etichetta(ultimo.data, oggi: Giorni.oggi())
            let variazione = bia.first.flatMap { $0.data != ultimo.data ? $0.peso : nil }.map { kg - $0 }
            let testoVariazione = variazione.map { v in
                let r = (v * 10).rounded() / 10
                return "\(r > 0 ? "+" : r < 0 ? "−" : "")\(kgTesto(abs(r)))"
            }
            Button { pesoVeloce = true } label: {
                Riquadro {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Peso").font(.headline)
                        Spacer()
                        if let t = testoVariazione {
                            Text(t)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle((variazione ?? 0) < 0 ? AnyShapeStyle(Colori.accento) : AnyShapeStyle(.secondary))
                                .monospacedDigit()
                        }
                    }
                    disposizione(allineamento: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(num(kg)).font(.system(size: 34, weight: .bold)).monospacedDigit()
                                Text("kg").font(.subheadline).foregroundStyle(.secondary)
                            }
                            Text(quando).font(.footnote).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        if bia.count > 1 {
                            Tendenza(valori: bia.suffix(8).compactMap(\.peso))
                                .frame(width: 120, height: 40)
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Peso")
            .accessibilityValue(kgTesto(kg) + ", " + quando + (testoVariazione.map { ", " + String(localized: "\($0) dall'inizio") } ?? ""))
            .accessibilityHint("Scrivi il peso di oggi")
        } else {
            Button { pesoVeloce = true } label: {
                Riquadro {
                    HStack {
                        Text("Peso").font(.headline)
                        Spacer()
                        Text("Aggiungi il primo peso").font(.subheadline).foregroundStyle(Colori.accento)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Peso")
            .accessibilityValue("Aggiungi il primo peso")
        }
    }

    // ---------- Pezzi ----------

    // Riga che con il testo molto grande va su due righe
    private func disposizione<C: View>(allineamento: VerticalAlignment = .center, @ViewBuilder _ contenuto: () -> C) -> some View {
        let layout = dimensione.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(alignment: allineamento))
        return layout { contenuto() }
    }

    // «1 esercizio» · «5 esercizi»: il plurale sta nel catalogo delle stringhe
    private static func esercizi(_ n: Int) -> String { String(localized: "\(n) esercizi") }

    private func sottotitolato(_ titolo: String, _ sotto: Text) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: titolo).font(.headline)
            sotto.font(.footnote).foregroundStyle(.secondary)
        }
    }
}

// Cerchio dei pasti: pieno con il segno quando è fatto
private struct Spunta: View {
    let fatta: Bool

    var body: some View {
        ZStack {
            if fatta {
                Circle().fill(Colori.accento)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Colori.sulAccento)
            } else {
                Circle().strokeBorder(Color(.systemGray3), lineWidth: 2)
            }
        }
        .frame(width: 24, height: 24)
        .accessibilityHidden(true)
    }
}

// Un segmento per pasto, pieno se segnato
private struct BarraSegmenti: View {
    let fatti: Int
    let totale: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<max(totale, 1), id: \.self) { i in
                Capsule().fill(i < fatti ? Colori.accento : Color(.systemFill)).frame(height: 5)
            }
        }
        .accessibilityHidden(true)
    }
}

// Mini-linea dell'andamento, con un punto sull'ultimo valore
private struct Tendenza: View {
    let valori: [Double]

    var body: some View {
        Canvas { ctx, size in
            guard valori.count > 1, let basso = valori.min(), let alto = valori.max() else { return }
            let margine: CGFloat = 4
            let intervallo = max(alto - basso, 0.1)
            let punti = valori.enumerated().map { i, v in
                CGPoint(x: margine + (size.width - 2 * margine) * CGFloat(i) / CGFloat(valori.count - 1),
                        y: margine + (size.height - 2 * margine) * CGFloat((alto - v) / intervallo))
            }
            var linea = Path()
            linea.addLines(punti)
            ctx.stroke(linea, with: .color(Colori.accento), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            if let u = punti.last {
                ctx.fill(Path(ellipseIn: CGRect(x: u.x - 3.5, y: u.y - 3.5, width: 7, height: 7)), with: .color(Colori.accento))
            }
        }
    }
}

extension View {
    // Sottotitolo con la data sotto "Oggi" (iOS 26 in poi)
    @ViewBuilder
    func navigationSubtitleSePossibile(_ testo: String) -> some View {
        if #available(iOS 26.0, *) { navigationSubtitle(testo) } else { self }
    }
}

// «Annulla» di un foglio il cui contenuto non ha il proprio
private struct AnnullaFoglio: View {
    @Environment(\.dismiss) private var chiudi
    var body: some View { Button("Annulla", role: .cancel) { chiudi() } }
}
