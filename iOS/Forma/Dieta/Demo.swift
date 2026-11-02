import Foundation

// Dati di prova per le schermate nel simulatore (avvio con -demo): non vengono salvati
extension Stato {
    static var demo: Stato {
        let oggi = Giorni.oggi()
        let giorni = Giorni.nomi.enumerated().map { i, nome in
            GiornoPiano(nome: nome, palestra: i == 0 || i == 3, pasti: [
                Pasto(nome: "Colazione", opzioni: [Opzione(alimenti: [
                    Alimento(nome: "Yogurt greco", quantita: "150 g"),
                    Alimento(nome: "Fiocchi d'avena", quantita: "30 g"),
                ])]),
                Pasto(nome: "Pranzo", opzioni: [
                    Opzione(titolo: "Pasta", alimenti: [
                        Alimento(nome: "Pasta integrale", quantita: "70 g"),
                        Alimento(nome: "Contorno: zucchine", quantita: "200 g"),
                    ]),
                    Opzione(titolo: "Riso", alimenti: [
                        Alimento(nome: "Riso basmati", quantita: "70 g"),
                        Alimento(nome: "Contorno: spinaci", quantita: "200 g"),
                    ]),
                ]),
                Pasto(nome: "Spuntino", opzioni: [Opzione(alimenti: [
                    Alimento(nome: "Mela", quantita: "150 g"),
                    Alimento(nome: "Noci", quantita: "15 g"),
                ])]),
                Pasto(nome: "Cena", opzioni: [Opzione(alimenti: [
                    Alimento(nome: "Petto di pollo", quantita: "150 g"),
                    Alimento(nome: "Insalata", quantita: "libera"),
                    Alimento(nome: "Pane integrale", quantita: "50 g"),
                ])]),
            ])
        }
        var p = Profilo(nome: "Raffaele")
        p.piani = [Piano(nome: "Schema ottobre", dal: Giorni.aggiungi(oggi, -20), al: "", giorni: giorni)]
        let misure: [(Int, Double, Double, Double, Double)] = [(-60, 84.2, 24.1, 60.1, 96), (-30, 82.5, 22.8, 59.7, 93), (-2, 81.1, 21.5, 59.6, 91)]
        p.bia = misure.map { k, peso, grasso, magra, vita in
            var m = Misura(data: Giorni.aggiungi(oggi, k))
            m.peso = peso
            m.grassoKg = grasso
            m.magraKg = magra
            m.vitaCm = vita
            m.addomeCm = vita + 4
            m.fianchiCm = 102
            m.obiettivoPeso = 76
            return m
        }
        for k in 1...6 {
            var r = Registro()
            for i in 0..<4 where (i + k) % 4 != 0 { r.slot[String(i)] = Slot(fatto: true) }
            r.olio = 5
            r.acqua = 1.75
            p.dieta[Giorni.aggiungi(oggi, -k)] = r
        }
        var oggiR = Registro()
        oggiR.slot["0"] = Slot(fatto: true)
        oggiR.slot["1"] = Slot(opt: 1)
        oggiR.olio = 2
        oggiR.acqua = 0.75
        p.dieta[oggi] = oggiR
        return Stato(profili: ["raffaele": p, "alessandra": Profilo(nome: "Alessandra")], attivo: "raffaele")
    }
}
