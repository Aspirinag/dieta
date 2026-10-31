import SwiftUI

// La settimana in alto e i pasti del giorno scelto, ognuno su una riga con alimenti, calorie e spunta.
// Sotto acqua e olio; la lista della spesa si apre dal tasto in alto
struct DietaView: View {
    @Binding var giorno: String

    @Environment(Archivio.self) private var archivio
    @Environment(\.importa) private var importa
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var testo
    @State private var mostraSpesa = Avvio.valore("-vista") == "spesa"

    // Nei giorni che devono ancora venire si può scegliere l'alternativa (conta per la spesa), non segnare
    private var segnabile: Bool { giorno <= Giorni.oggi() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    intestazione
                    selettoreGiorni
                    if Giorni.lunedi(giorno) != Giorni.lunedi(Giorni.oggi()) {
                        Button { giorno = Giorni.oggi() } label: {
                            Text("Torna a oggi")
                                .font(.georgia(.subheadline, grassetto: true))
                                .foregroundStyle(palette.accento)
                                .frame(minHeight: 44)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                    if let piano = archivio.profilo.piano(per: giorno) {
                        pasti(piano)
                    } else {
                        senzaPiano
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .animation(.spring(duration: 0.35), value: archivio.registro(giorno))
            }
            .scorrimentoTema()
            .sfondoTema()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $mostraSpesa) { SpesaView() }
        }
        .seguiMezzanotte($giorno)
    }

    private var intestazione: some View {
        HStack {
            Text("Dieta")
                .font(.georgia(.largeTitle, grassetto: true))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            Button { mostraSpesa = true } label: {
                Text("Spesa")
                    .font(.georgia(.subheadline, grassetto: true))
                    .foregroundStyle(palette.testo)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 44)
                    .background(palette.riempimento, in: .capsule)
                    .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Lista della spesa")
        }
    }

    // ---------- Settimana ----------

    // Oggi con un bordo, manubrio nei giorni di allenamento, spunta se tutti i pasti sono segnati
    private var selettoreGiorni: some View {
        let lun = Giorni.lunedi(giorno)
        let oggi = Giorni.oggi()
        return HStack(spacing: 5) {
            ForEach(0..<7, id: \.self) { i in
                let data = Giorni.aggiungi(lun, i)
                let scelto = data == giorno
                Button {
                    giorno = data
                } label: {
                    VStack(spacing: 2) {
                        Text(String(Giorni.nomi[i].prefix(1))).font(.georgia(.caption, grassetto: true))
                        Text(String(Int(data.suffix(2)) ?? 0)).font(.georgia(.title3, grassetto: true))
                        Group {
                            if completo(data) {
                                Image(systemName: "checkmark")
                            } else if archivio.profilo.piano(per: data)?.giorni[i].palestra == true {
                                Image(systemName: "dumbbell.fill")
                            } else {
                                Image(systemName: "circle.fill").hidden()
                            }
                        }
                        .font(.georgia(.caption2))
                        .imageScale(.small)
                        .frame(height: 10)
                    }
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .padding(.vertical, 4)
                    .foregroundStyle(scelto ? palette.suTasto : palette.testo)
                    .background {
                        if scelto {
                            RoundedRectangle(cornerRadius: 14).fill(palette.tasto)
                        } else {
                            RoundedRectangle(cornerRadius: 14).fill(palette.scheda)
                        }
                        if data == oggi && !scelto {
                            RoundedRectangle(cornerRadius: 14).strokeBorder(palette.accento, lineWidth: 1.5)
                        }
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Giorni.estesa(data) + (data == oggi ? ", oggi" : ""))
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

    // ---------- Pasti ----------

    @ViewBuilder private func pasti(_ piano: Piano) -> some View {
        let g = piano.giorni[Giorni.indice(giorno)]
        VStack(spacing: 0) {
            ForEach(Array(g.pasti.enumerated()), id: \.offset) { i, pasto in
                if i > 0 { Rectangle().fill(palette.traccia).frame(height: 1) }
                RigaPasto(giorno: giorno, indice: i, pasto: pasto, segnabile: segnabile)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(palette.scheda, in: .rect(cornerRadius: 22))

        if segnabile { acquaEOlio }

        Text(pieDiPagina(piano, g))
            .font(.georgia(.footnote))
            .foregroundStyle(palette.secondario)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
    }

    private func pieDiPagina(_ piano: Piano, _ g: GiornoPiano) -> String {
        var parti = [piano.nome]
        if let previste = archivio.profilo.calorie(giorno)?.previste { parti.append("\(kcal(previste)) previste") }
        if g.palestra { parti.append("giorno di allenamento") }
        return parti.joined(separator: " · ")
    }

    @ViewBuilder private var acquaEOlio: some View {
        let r = archivio.registro(giorno)
        let p = archivio.profilo
        let acqua = SchedaDose(titolo: "Acqua", valore: num(r.acqua), obiettivo: "di \(num(p.acqua)) L",
                               aggiungi: "+ \(num(Archivio.passoAcqua)) L", togli: "Togli \(num(Archivio.passoAcqua)) litri d'acqua",
                               vuoto: r.acqua <= 0) {
            archivio.aggiungiAcqua(giorno)
        } azioneTogli: {
            archivio.togliAcqua(giorno)
        }
        let olio = SchedaDose(titolo: "Olio", valore: "\(r.olio)", obiettivo: "di \(p.olio) cucchiaini",
                              aggiungi: "+ 1 cucchiaino", togli: "Togli un cucchiaino d'olio", vuoto: r.olio <= 0) {
            archivio.aggiungiOlio(giorno)
        } azioneTogli: {
            archivio.togliOlio(giorno)
        }
        Group {
            if testo.isAccessibilitySize {
                VStack(spacing: 10) {
                    acqua
                    olio
                }
            } else {
                HStack(alignment: .top, spacing: 10) {
                    acqua
                    olio
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .sensoryFeedback(.selection, trigger: r)
    }

    @ViewBuilder private var senzaPiano: some View {
        let prossimo = archivio.profilo.prossimoPiano(dopo: giorno)
        StatoVuoto(titolo: "Nessun piano per questo giorno", icona: "calendar",
                   descrizione: prossimo.map { "Il piano «\($0.nome)» inizia il \(Giorni.breve($0.dal))." }
                       ?? "Carica il piano alimentare in PDF da Profilo o da qui.") {
            if prossimo == nil {
                Button("Carica piano alimentare") { importa(.schema) }
                    .buttonStyle(TastoTema())
            }
        }
    }
}

// Un pasto su una riga: il tocco apre alternative e fuori piano, la spunta lo segna
private struct RigaPasto: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.palette) private var palette
    @Environment(\.dynamicTypeSize) private var testo
    let giorno: String
    let indice: Int
    let pasto: Pasto
    let segnabile: Bool
    @State private var foglio = false

    var body: some View {
        let s = archivio.slot(giorno, indice)
        Group {
            // Con il testo molto grande il nome ha tutta la riga: accanto a calorie e spunta si spezzerebbe
            if testo.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    Button { foglio = true } label: {
                        descrizione(s)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    HStack {
                        calorie(s)
                        Spacer(minLength: 8)
                        if segnabile { spunta(s) }
                    }
                }
            } else {
                HStack(spacing: 10) {
                    Button { foglio = true } label: {
                        HStack(spacing: 10) {
                            descrizione(s)
                            Spacer(minLength: 0)
                            calorie(s).fixedSize()
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    if segnabile { spunta(s) }
                }
            }
        }
        .padding(.vertical, 11)
        .frame(minHeight: 74)
        .sheet(isPresented: $foglio) {
            FoglioPasto(giorno: giorno, indice: indice, pasto: pasto)
        }
    }

    private func descrizione(_ s: Slot) -> some View {
        let opz = pasto.opzione(s)
        return VStack(alignment: .leading, spacing: 2) {
            TestoIntero(testo: pasto.nome)
                .font(.georgia(.headline))
            if let nota = s.altro {
                Text(nota.isEmpty ? "Fuori piano" : "Fuori piano: \(nota)")
                    .font(.georgia(.subheadline, grassetto: true))
                    .foregroundStyle(palette.caldo)
            } else if let opz {
                Text(opz.descrizione)
                    .font(.georgia(.subheadline))
                    .foregroundStyle(palette.secondario)
            }
            if pasto.opzioni.count > 1 {
                Text("\(pasto.opzioni.count) alternative")
                    .font(.georgia(.footnote))
                    .foregroundStyle(palette.accento)
            }
        }
        .multilineTextAlignment(.leading)
    }

    @ViewBuilder private func calorie(_ s: Slot) -> some View {
        if s.altro == nil, let c = pasto.opzione(s)?.calorie, c.kcal > 0 {
            Text(numeroKcal(c.kcal) + (c.ignoti.isEmpty ? "" : "+"))
                .font(.georgia(.subheadline))
                .foregroundStyle(palette.secondario)
                .lineLimit(1)
                .accessibilityLabel("circa \(numeroKcal(c.kcal)) kcal")
        }
    }

    private func spunta(_ s: Slot) -> some View {
        let fuori = s.altro != nil
        return Button {
            if fuori {
                foglio = true   // si annulla da lì, con il testo che spiega cosa succede
            } else {
                archivio.cambiaSlot(giorno, indice) { $0.fatto.toggle() }
            }
        } label: {
            Image(systemName: fuori ? "arrow.triangle.swap" : "checkmark")
                .font(.georgiaFissa(18, grassetto: true))
                .foregroundStyle(s.fatto ? palette.suTasto : fuori ? palette.caldo : palette.secondario)
                .frame(width: 44, height: 44)
                .background(s.fatto ? palette.tasto : palette.riempimento, in: .rect(cornerRadius: 12))
                .contentShape(.rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(fuori ? "\(pasto.nome), fuori piano" : "Segna \(pasto.nome)")
        .accessibilityAddTraits(s.fatto ? .isSelected : [])
        .sensoryFeedback(trigger: s.fatto) { _, nuovo in nuovo ? .success : .selection }
    }
}

// Acqua od olio: un tasto per aggiungere, anche oltre l'obiettivo. Toccando il valore si toglie un tocco di troppo
private struct SchedaDose: View {
    let titolo, valore, obiettivo, aggiungi, togli: String
    let vuoto: Bool
    let azioneAggiungi: () -> Void
    let azioneTogli: () -> Void
    @Environment(\.palette) private var palette

    init(titolo: String, valore: String, obiettivo: String, aggiungi: String, togli: String, vuoto: Bool,
         azioneAggiungi: @escaping () -> Void, azioneTogli: @escaping () -> Void) {
        self.titolo = titolo
        self.valore = valore
        self.obiettivo = obiettivo
        self.aggiungi = aggiungi
        self.togli = togli
        self.vuoto = vuoto
        self.azioneAggiungi = azioneAggiungi
        self.azioneTogli = azioneTogli
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titolo)
                .font(.georgia(.subheadline, grassetto: true))
                .foregroundStyle(palette.secondario)
            Button(action: azioneTogli) {
                HStack(alignment: .center, spacing: 6) {
                    (Text(valore).font(.georgia(.title2, grassetto: true)).foregroundStyle(palette.testo)
                     + Text(" " + obiettivo).font(.georgia(.subheadline)).foregroundStyle(palette.secondario))
                    Spacer(minLength: 0)
                    if !vuoto {
                        Image(systemName: "minus.circle")
                            .font(.georgiaFissa(20))
                            .foregroundStyle(palette.secondario)
                    }
                }
                .frame(minHeight: 44)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .allowsHitTesting(!vuoto)
            .accessibilityLabel("\(titolo): \(valore) \(obiettivo)")
            .accessibilityHint(vuoto ? "" : togli)
            Spacer(minLength: 4)
            Button(aggiungi, action: azioneAggiungi)
                .buttonStyle(TastoTema(principale: false))
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(palette.scheda, in: .rect(cornerRadius: 22))
    }
}

// Un pasto aperto: alternative, «Mangiato» e «Ho mangiato altro». Vale da Dieta e dal tasto «Altro» di Oggi
struct FoglioPasto: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var chiudi
    let giorno: String
    let indice: Int
    let pasto: Pasto
    @State private var chiediAltro = false
    @State private var notaAltro = ""

    var body: some View {
        let s = archivio.slot(giorno, indice)
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(pasto.opzioni.enumerated()), id: \.offset) { j, o in
                        alternativa(o, indice: j, scelta: pasto.opzioni.indices.contains(s.opt) ? s.opt : 0)
                    }
                    if giorno <= Giorni.oggi() {
                        azioni(s)
                    }
                }
                .padding(16)
            }
            .navigationTitle(pasto.nome)
            .navigationBarTitleDisplayMode(.inline)
            .sfondoTema()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { chiudi() }
                        .font(.georgia())
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(palette.fondo)
        .sensoryFeedback(trigger: s.fatto) { _, nuovo in nuovo ? .success : .selection }
        .alert("Ho mangiato altro", isPresented: $chiediAltro) {
            TextField("Cosa? (facoltativo)", text: $notaAltro)
            Button("Salva") {
                let nota = notaAltro.trimmingCharacters(in: .whitespaces)
                archivio.cambiaSlot(giorno, indice) { $0.altro = nota; $0.fatto = false }
                chiudi()
            }
            Button("Annulla", role: .cancel) {}
        } message: {
            Text("Il pasto resta segnato come fuori piano: non conta nella costanza né nelle calorie.")
        }
    }

    // Una scheda per alternativa, con i suoi alimenti; con più di una si sceglie toccandola
    @ViewBuilder private func alternativa(_ o: Opzione, indice j: Int, scelta: Int) -> some View {
        let piu = pasto.opzioni.count > 1
        Button {
            archivio.cambiaSlot(giorno, indice) { $0.opt = j }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if piu {
                        Image(systemName: j == scelta ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(j == scelta ? palette.accento : palette.secondario)
                    }
                    if let t = o.titolo ?? (piu ? "Opzione \(j + 1)" : nil) {
                        TestoIntero(testo: t).font(.georgia(.headline))
                    }
                    Spacer(minLength: 8)
                    if o.kcal > 0 {
                        Text(kcal(o.kcal, incompleto: !o.calorie.ignoti.isEmpty))
                            .font(.georgia(.subheadline))
                            .foregroundStyle(palette.secondario)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
                ForEach(Array(o.alimenti.enumerated()), id: \.offset) { _, a in
                    HStack(alignment: .firstTextBaseline) {
                        Text(a.nome)
                        Spacer(minLength: 12)
                        Text(a.quantita)
                            .foregroundStyle(palette.secondario)
                            .multilineTextAlignment(.trailing)
                    }
                    .font(.georgia(.callout))
                }
                if !o.calorie.ignoti.isEmpty {
                    Text("Calorie non stimate per: \(o.calorie.ignoti.joined(separator: ", ")).")
                        .font(.georgia(.caption))
                        .foregroundStyle(palette.secondario)
                }
            }
            .multilineTextAlignment(.leading)
            .scheda()
            .overlay {
                if piu && j == scelta {
                    RoundedRectangle(cornerRadius: 22).strokeBorder(palette.accento, lineWidth: 2)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .allowsHitTesting(piu)
        .accessibilityAddTraits(piu && j == scelta ? .isSelected : [])
    }

    @ViewBuilder private func azioni(_ s: Slot) -> some View {
        if let nota = s.altro {
            Text(nota.isEmpty ? "Fuori piano" : "Fuori piano: \(nota)")
                .font(.georgia(.subheadline, grassetto: true))
                .foregroundStyle(palette.caldo)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                archivio.cambiaSlot(giorno, indice) { $0.altro = nil }
                chiudi()
            } label: {
                Label("Annulla «fuori piano»", systemImage: "arrow.uturn.backward")
            }
            .buttonStyle(TastoTema(principale: false))
        } else if s.fatto {
            Button {
                archivio.cambiaSlot(giorno, indice) { $0.fatto = false }
                chiudi()
            } label: {
                Label("Segnato come fatto · annulla", systemImage: "arrow.uturn.backward")
            }
            .buttonStyle(TastoTema(principale: false))
        } else {
            Button("Mangiato") {
                archivio.cambiaSlot(giorno, indice) { $0.fatto = true }
                chiudi()
            }
            .buttonStyle(TastoTema())
            Button("Ho mangiato altro") {
                notaAltro = ""
                chiediAltro = true
            }
            .buttonStyle(TastoTema(principale: false))
        }
    }
}
