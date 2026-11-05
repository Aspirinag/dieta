import SwiftUI

// Oggi, la panoramica: pasti, allenamento, olio e acqua, peso. I pasti e le righe dell'allenamento sono
// liste (si spuntano o si aprono); il riquadro è solo per l'azione principale e per il numero del peso.
// Il dettaglio sta nelle schede Dieta, Palestra e Progressi
struct HomeView: View {
    @Environment(Archivio.self) private var archivio
    @Environment(Palestra.self) private var palestra
    @Environment(Navigazione.self) private var navigazione
    @State private var richiesta: TipoPDF?
    @State private var nuovaMisura = false
    @State private var pesoVeloce = false
    @State private var pesoPerModulo: Double?
    @State private var apriModulo = false
    // La misura di oggi, letta quando l'editor si apre: salvando non deve passare da «Nuova» a «Modifica» mentre il foglio si chiude
    @State private var misuraDiOggi: String?
    @State private var cardioAperto = false
    @State private var sceltaScheda = false
    @Environment(\.dynamicTypeSize) private var dimensione

    private var titolo: String {
        Testi.data(Date())
    }

    var body: some View {
        NavigationStack {
            List {
                pagamento
                pasti
                allenamento
                if archivio.profilo.piano(per: Giorni.oggi()) != nil {
                    olioEAcqua
                }
                peso
                note
            }
            .sfondoTema()
            .navigationTitle("Oggi")
            .navigationSubtitleSePossibile(titolo)
            .importaPDF($richiesta)
            .sheet(isPresented: $cardioAperto) { NuovoCardioView() }
            .confirmationDialog("Schede", isPresented: $sceltaScheda, titleVisibility: .visible) { schedeDaScegliere }
            .sheet(isPresented: $pesoVeloce, onDismiss: {
                if apriModulo {
                    apriModulo = false
                    misuraDiOggi = archivio.profilo.bia.contains { $0.data == Giorni.oggi() } ? Giorni.oggi() : nil
                    nuovaMisura = true
                }
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
                    EditorMisura(dataEsistente: misuraDiOggi,
                                 pesoIniziale: pesoPerModulo)
                        .toolbar {
                            if misuraDiOggi != nil {
                                ToolbarItem(placement: .cancellationAction) { AnnullaFoglio() }
                            }
                        }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    MenuProfilo()
                    PulsanteImpostazioni()
                }
            }
            .navigationDestination(for: UUID.self) { DettaglioAllenamentoView(id: $0) }
            .navigationDestination(for: Esercizio.self) { DettaglioEsercizioView(idEsercizio: $0.id) }
            .destinazioniDieta()
        }
    }

    // Un riquadro come riga di lista: senza sfondo di riga né margini, il riquadro fa da sé
    private func rigaRiquadro<C: View>(@ViewBuilder _ contenuto: () -> C) -> some View {
        contenuto()
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
    }

    // ---------- Note ----------

    // Le note del profilo (Impostazioni → Olio e acqua) stanno in fondo, piccole
    @ViewBuilder private var note: some View {
        let testo = archivio.profilo.testoNote
        if !testo.isEmpty {
            Section {
                Text(testo)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("riquadro-note")
            }
        }
    }

    // ---------- Pagamento ----------

    // Solo da una settimana prima del giorno di pagamento al giorno dopo, finché non è segnato pagato
    @ViewBuilder private var pagamento: some View {
        if let p = palestra.promemoriaPagamento() {
            Section {
                Riga(Text(p.testo)) {
                    Button("Segna come pagato") { withAnimation { palestra.segnaPagato(p.mese) } }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.primary)
                        .buttonBorderShape(.capsule)
                }
                .accessibilityIdentifier("riquadro-pagamento")
            }
        }
    }

    // ---------- Pasti ----------

    @ViewBuilder private var pasti: some View {
        let oggi = Giorni.oggi()
        if let piano = archivio.profilo.piano(per: oggi) {
            let elenco = piano.giorni[Giorni.indice(oggi)].pasti
            if elenco.isEmpty {
                Section {
                    Riga("Nessun pasto per questo giorno")
                } header: {
                    Text("Pasti").textCase(nil)
                }
            } else {
                let fatti = elenco.indices.filter { archivio.slot(oggi, $0).fatto }.count
                Section {
                    ForEach(elenco.indices, id: \.self) { i in
                        RigaPasto(giorno: oggi, indice: i, pasto: elenco[i])
                    }
                } header: {
                    Text("Pasti · \(fatti) di \(elenco.count)").textCase(nil)
                }
            }
        } else {
            Section {
                rigaRiquadro {
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
        }
    }

    // ---------- Allenamento ----------

    @ViewBuilder private var allenamento: some View {
        let oggi = Giorni.oggi()
        let tipo = palestra.programmato(oggi)
        let fatti = palestra.allenamenti(del: oggi)
        let cardio = palestra.cardio(del: oggi)
        let inCorso = palestra.stato.inCorso
        let proxima = palestra.stato.prossimaRoutine()
        // L'azione principale (riprendere o iniziare la scheda) è un riquadro
        if let a = inCorso {
            Section {
                rigaRiquadro {
                    Riquadro {
                        disposizione {
                            sottotitolato(a.titolo, Text("In corso"))
                            Spacer(minLength: 8)
                            Button("Riprendi") { navigazione.allenamentoAperto = true }
                                .buttonStyle(PulsanteAccento())
                        }
                    }
                }
            }
        } else if tipo == .pesi && fatti.isEmpty {
            Section {
                rigaRiquadro {
                    Riquadro {
                        if let r = proxima {
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
                    }
                }
            }
        }
        // Il resto sono righe: riposo, cardio, allenamenti fatti
        let senzaPrincipale = !(inCorso == nil && tipo == .pesi && fatti.isEmpty)
        let altraScheda = Self.mostraAltraScheda(inCorso: inCorso != nil, pesiFatti: fatti.count, cardioFatto: cardio.count)
        let giornoLibero = senzaPrincipale && inCorso == nil && fatti.isEmpty && cardio.isEmpty
        if giornoLibero || !fatti.isEmpty || !cardio.isEmpty || altraScheda {
            Section {
                if giornoLibero {
                    if tipo == .cardio {
                        Riga(Text("Cardio"), evidente: true) {
                            Button("Registra cardio") { cardioAperto = true }
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.capsule)
                                .tint(.primary)
                        }
                    } else {
                        Riga(Text("Riposo"), evidente: true) {
                            Button("Allenati lo stesso") { sceltaScheda = true }
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.capsule)
                                .tint(.primary)
                                .accessibilityIdentifier("allenati-lo-stesso")
                        }
                    }
                }
                ForEach(fatti) { a in
                    NavigationLink(value: a.id) {
                        Riga(Text(verbatim: a.titolo), dettaglio: Text(durataTesto(a.durata)), evidente: true,
                             inizio: CerchioSpunta(fatta: true))
                    }
                }
                ForEach(cardio) { c in
                    Riga(Text("\(Libreria.nomeCardio(c.tipo)) · \(c.minuti) min" + (c.km > 0 ? " · \(num(c.km)) km" : "")),
                         inizio: CerchioSpunta(fatta: true))
                }
                if altraScheda {
                    Button("Un'altra scheda") { navigazione.scheda = .allenamento }
                        .tint(.primary)
                        .frame(minHeight: Misure.tocco, alignment: .leading)
                }
            }
        }
    }

    // La scelta della scheda per «Allenati lo stesso»: le schede e l'allenamento libero, e si parte
    @ViewBuilder private var schedeDaScegliere: some View {
        ForEach(palestra.stato.routine) { r in
            Button(r.nome) { avvia(r) }
        }
        Button("Allenamento libero") { avvia(nil) }
    }

    private func avvia(_ r: Routine?) {
        palestra.inizia(r)
        navigazione.allenamentoAperto = true
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
        Section { rigaRiquadro { Riquadro {
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
        } } }
    }

    // ---------- Peso ----------

    @ViewBuilder private var peso: some View {
        let bia = archivio.profilo.bia.filter { $0.peso != nil }.sorted { $0.data < $1.data }
        if let ultimo = PesoVeloce.ultimo(bia), let kg = ultimo.peso {
            let quando = PesoVeloce.etichetta(ultimo.data, oggi: Giorni.oggi())
            let variazione = PesoVeloce.variazione(bia, ultimo: ultimo)
            let testoVariazione = variazione.map { String(localized: "\(Testi.conSegno($0, unita: "kg")) in 30 giorni") }
            Section { rigaRiquadro { Button { pesoVeloce = true } label: {
                Riquadro {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Peso").font(.headline)
                        Spacer()
                        if let t = testoVariazione {
                            Text(t)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                    disposizione(allineamento: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(num(kg)).numero(.largeTitle)
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
            .accessibilityValue(kgTesto(kg) + ", " + quando + (testoVariazione.map { ", " + $0 } ?? ""))
            .accessibilityHint("Scrivi il peso di oggi") } }
        } else {
            Section { rigaRiquadro { Button { pesoVeloce = true } label: {
                Riquadro {
                    HStack {
                        Text("Peso").font(.headline)
                        Spacer()
                        Text("Aggiungi il primo peso").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Peso")
            .accessibilityValue("Aggiungi il primo peso") } }
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
            ctx.stroke(linea, with: .color(.secondary), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            if let u = punti.last {
                ctx.fill(Path(ellipseIn: CGRect(x: u.x - 3.5, y: u.y - 3.5, width: 7, height: 7)), with: .color(.secondary))
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
