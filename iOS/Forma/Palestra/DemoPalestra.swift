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
        s.saltati = [Giorni.aggiungi(Giorni.oggi(), -8)]
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
