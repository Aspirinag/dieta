import Foundation

// Dati di prova per le schermate nel simulatore (avvio con -demo): non vengono salvati
extension StatoPalestra {
    static var demo: StatoPalestra {
        var s = StatoPalestra()
        s.routine += [Libreria.modelli[1], Libreria.modelli[2], Libreria.modelli[3]]
        let scheda = s.routine[0]
        let base: [String: Double] = ["Leg press": 70, "Chest press": 30, "Lat machine": 35, "Leg curl": 25,
                                      "Shoulder press": 15, "Seated row": 30, "Addominali": 0]
        for (n, giorni) in [-27, -24, -20, -17, -13, -10, -6, -3].enumerated() {
            let d = Giorni.data(Giorni.aggiungi(Giorni.oggi(), giorni)).addingTimeInterval(18.5 * 3600)
            var a = Allenamento(nome: scheda.nome, inizio: d, routine: scheda.id)
            a.fine = d.addingTimeInterval(TimeInterval(3000 + n * 60))
            a.esercizi = scheda.voci.map { v in
                let kg = (base[v.esercizio] ?? 20) + Double(n / 2) * 2.5
                return EsercizioFatto(esercizio: v.esercizio, recupero: v.recupero,
                                      serie: (0..<v.serie).map { k in SerieFatta(kg: kg, rip: v.ripMax - k, fatta: true) })
            }
            s.allenamenti.append(a)
        }
        for k in [-26, -19, -12, -5, -1] {
            s.cardio.append(SessioneCardio(data: Giorni.aggiungi(Giorni.oggi(), k), tipo: k == -12 ? "Bici" : "Corsa",
                                           minuti: 30, km: k == -12 ? 12 : 4.5))
        }
        // `-pagamento-tra N`: il pagamento cade tra N giorni (per vedere il riquadro in Oggi)
        if let n = Avvio.valore("-pagamento-tra").flatMap(Int.init) {
            let giorno = Giorni.aggiungi(Giorni.oggi(), n)
            s.giornoPagamento = min(Int(giorno.suffix(2)) ?? 1, 28)
        }
        // `-oggi-cardio`: oggi è giorno di cardio (per vedere il riquadro in Oggi)
        // `-oggi-riposo`: oggi è giorno di riposo (per «Allenati lo stesso»)
        for (argomento, tipo) in [("-oggi-cardio", TipoGiorno.cardio), ("-oggi-riposo", TipoGiorno.riposo)] where Avvio.argomenti.contains(argomento) {
            var p = s.piani[s.settimana(Giorni.oggi())] ?? []
            while p.count < 7 { p.append(.riposo) }
            p[Giorni.indice(Giorni.oggi())] = tipo
            s.piani[s.settimana(Giorni.oggi())] = p
        }
        s.saltati = [Giorni.aggiungi(Giorni.oggi(), -8)]
        // Dal Watch: una camminata e una sessione di palestra ancora senza esercizi
        s.cardio.append(SessioneCardio(data: Giorni.aggiungi(Giorni.oggi(), -4), tipo: "Camminata", minuti: 52, km: 4.6,
                                       watch: DatiWatch(uuid: "demo-camminata", calorie: 214, battito: 102)))
        var w = Allenamento(nome: Palestra.nomeWatch, inizio: Giorni.data(Giorni.aggiungi(Giorni.oggi(), -2)).addingTimeInterval(18 * 3600))
        w.fine = w.inizio.addingTimeInterval(55 * 60)
        w.watch = DatiWatch(uuid: "demo-palestra", calorie: 318, battito: 118)
        s.allenamenti.append(w)
        // `-allenato-oggi`: oggi un allenamento libero e uno registrato dal Watch (per i nomi di sistema)
        if Avvio.argomenti.contains("-allenato-oggi") {
            for (nome, watch) in [(Allenamento.nomeLibero, nil), (Allenamento.nomeWatch, DatiWatch(uuid: "demo-oggi", calorie: 200, battito: 110))] {
                var a = Allenamento(nome: nome, inizio: Giorni.data(Giorni.oggi()).addingTimeInterval(3600))
                a.fine = a.inizio.addingTimeInterval(40 * 60)
                a.watch = watch
                s.allenamenti.append(a)
            }
        }
        if Avvio.valore("-tab") == "inCorso" {
            var a = Allenamento(nome: scheda.nome, inizio: Date().addingTimeInterval(-1460), routine: scheda.id)
            a.esercizi = scheda.voci.prefix(3).enumerated().map { i, v in
                let kg = (base[v.esercizio] ?? 20) + 10
                return EsercizioFatto(esercizio: v.esercizio, recupero: v.recupero, serie: (0..<v.serie).map { k in
                    i == 0 || (i == 1 && k == 0) ? SerieFatta(kg: kg, rip: 10, fatta: true) : SerieFatta()
                })
            }
            a.riscaldamento = ["0": true, "1": true, "2": true]
            s.inCorso = a
        }
        return s
    }
}
