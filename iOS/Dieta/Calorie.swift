import Foundation

// Stima indicativa delle calorie degli alimenti dello schema, con valori medi per 100 g
// (tabelle di composizione CREA, arrotondati). Serve a dare un ordine di grandezza, non a pesare il piano.
enum Calorie {
    struct Voce {
        let parole: [String]     // basta che il nome ne contenga una
        let kcal: Double         // per 100 g (o 100 ml)
        var pezzo: Double = 100  // grammi di un pezzo, di una fetta o di un cucchiaino
        var qb: Double = 0       // grammi da contare quando la quantità è «q.b.»
    }

    // In ordine: le voci più specifiche prima di quelle generiche (es. «pasta integrale» prima di «pasta»)
    static let tabella: [Voce] = [
        // Cereali, pane e sostituti
        Voce(parole: ["pasta integrale", "riso o pasta integrale"], kcal: 330),
        Voce(parole: ["pasta"], kcal: 355),
        Voce(parole: ["riso"], kcal: 335),
        Voce(parole: ["farro", "orzo", "quinoa", "cous cous", "couscous"], kcal: 340),
        Voce(parole: ["avena", "muesli", "cereali", "corn flakes"], kcal: 375),
        Voce(parole: ["biscotti", "crackers", "gallette"], kcal: 420, pezzo: 8),
        Voce(parole: ["marmellata", "miele", "confettura"], kcal: 280, pezzo: 10),
        Voce(parole: ["fette biscottate"], kcal: 410, pezzo: 8),
        Voce(parole: ["pane integrale"], kcal: 245),
        Voce(parole: ["pane tostato"], kcal: 300),
        Voce(parole: ["toast"], kcal: 260, pezzo: 110),
        Voce(parole: ["pizza"], kcal: 270, pezzo: 300),
        Voce(parole: ["panino"], kcal: 285, pezzo: 80),
        Voce(parole: ["piadina"], kcal: 300, pezzo: 100),
        Voce(parole: ["pangrattato"], kcal: 350),
        Voce(parole: ["pane"], kcal: 280, pezzo: 50),
        Voce(parole: ["patate"], kcal: 85),
        // Legumi (la prima quantità è quella da secchi)
        Voce(parole: ["lenticchie"], kcal: 290),
        Voce(parole: ["fagioli"], kcal: 290),
        Voce(parole: ["legumi"], kcal: 300),
        Voce(parole: ["piselli"], kcal: 70),
        // Carne, pesce, uova
        Voce(parole: ["hamburger di pollo"], kcal: 150, pezzo: 100),
        Voce(parole: ["hamburger"], kcal: 220, pezzo: 100),
        Voce(parole: ["salsiccia di pollo"], kcal: 180),
        Voce(parole: ["spiedini di pollo"], kcal: 90, pezzo: 150),
        Voce(parole: ["pollo", "tacchino"], kcal: 105),
        Voce(parole: ["manzo", "vitello"], kcal: 120),
        Voce(parole: ["carne o pesce"], kcal: 115),
        Voce(parole: ["bresaola"], kcal: 150),
        Voce(parole: ["prosciutto cotto"], kcal: 180),
        Voce(parole: ["speck"], kcal: 300),
        Voce(parole: ["merluzzo", "orata", "branzino", "spigola", "sogliola", "nasello"], kcal: 85),
        Voce(parole: ["tonno"], kcal: 110, pezzo: 52),
        Voce(parole: ["salmone"], kcal: 185),
        Voce(parole: ["gamberi", "calamari", "seppie"], kcal: 75),
        Voce(parole: ["pesce spada"], kcal: 110),
        Voce(parole: ["polipi", "moscardini", "polpo"], kcal: 60),
        Voce(parole: ["albume"], kcal: 45, pezzo: 35),
        Voce(parole: ["uovo", "uova"], kcal: 130, pezzo: 55),
        // Latticini
        Voce(parole: ["yogurt greco"], kcal: 57),
        Voce(parole: ["yogurt proteico"], kcal: 60),
        Voce(parole: ["yogurt"], kcal: 65),
        Voce(parole: ["fiocchi di formaggio"], kcal: 100),
        Voce(parole: ["ricotta"], kcal: 140),
        Voce(parole: ["latte"], kcal: 50),
        Voce(parole: ["mozzarella"], kcal: 250),
        Voce(parole: ["stracchino", "robiola"], kcal: 300),
        Voce(parole: ["grana", "parmigiano"], kcal: 390),
        Voce(parole: ["provola"], kcal: 350),
        Voce(parole: ["formaggio"], kcal: 350, pezzo: 30),
        // Frutta
        Voce(parole: ["noci"], kcal: 690),
        Voce(parole: ["frutta secca", "mandorle", "nocciole"], kcal: 620),
        Voce(parole: ["burro di arachidi"], kcal: 590, pezzo: 7),
        Voce(parole: ["banana"], kcal: 65, pezzo: 120),
        Voce(parole: ["spremuta"], kcal: 35),
        Voce(parole: ["frutta", "mela", "pera", "arancia", "kiwi"], kcal: 50, pezzo: 150),
        // Verdure e condimenti (q.b. = una porzione di verdura, condimenti trascurabili)
        Voce(parole: ["minestrone"], kcal: 35),
        Voce(parole: ["vellutata"], kcal: 40, qb: 200),
        Voce(parole: ["passata"], kcal: 25, qb: 50),
        Voce(parole: ["verdur", "zucca", "zucchine", "spinaci", "insalata", "rucola", "pomodorini", "funghi", "peperoni"], kcal: 25, qb: 150),
    ]

    static let kcalCucchiainoOlio = 45.0   // 5 g di olio extra vergine

    static func voce(_ nome: String) -> Voce? {
        var n = nome.lowercased()
        for prefisso in ["contorno: ", "secondo: "] where n.hasPrefix(prefisso) { n.removeFirst(prefisso.count) }
        return tabella.first { v in v.parole.contains { n.contains($0) } }
    }

    // Grammi dalla quantità dello schema: vale la prima alternativa («40g/120g», «100ml o n°1»)
    static func grammi(_ quantita: String, _ v: Voce) -> Double? {
        let q = quantita.lowercased()
        let prima = q.split(separator: "/").first.map(String.init) ?? q
        let alternativa = prima.components(separatedBy: " o ").first ?? prima
        if let m = alternativa.firstMatch(of: #/(\d+(?:[.,]\d+)?)\s*(kg|g|gr|ml|l)\b/#) {
            let x = Double(m.1.replacingOccurrences(of: ",", with: ".")) ?? 0
            return switch m.2 { case "kg", "l": x * 1000; default: x }
        }
        if let m = alternativa.firstMatch(of: #/n°?\s*(\d+)/#) { return Double(m.1).map { $0 * v.pezzo } }
        if q.contains("q.b") || q.contains("libera") { return v.qb }
        // Senza quantità è un titolo («Toast con prosciutto cotto») e gli ingredienti seguono nelle righe sotto
        if q.trimmingCharacters(in: .whitespaces).isEmpty { return 0 }
        return nil
    }

    // nil: alimento o quantità non riconosciuti
    static func stima(nome: String, quantita: String) -> Double? {
        guard let v = voce(nome), let g = grammi(quantita, v) else { return nil }
        return g * v.kcal / 100
    }

    // Un'alternativa di un pasto: somma degli alimenti e nomi di quelli non riconosciuti.
    // Senza alimenti (es. «Pizza Margherita») si stima dal titolo, come un pezzo
    static func opzione(titolo: String?, alimenti: [(nome: String, quantita: String)]) -> (kcal: Double, ignoti: [String]) {
        if alimenti.isEmpty {
            guard let t = titolo else { return (0, []) }
            guard let v = voce(t) else { return (0, [t]) }
            return (v.pezzo * v.kcal / 100, [])
        }
        var kcal = 0.0
        var ignoti: [String] = []
        for a in alimenti {
            if let k = stima(nome: a.nome, quantita: a.quantita) { kcal += k } else { ignoti.append(a.nome) }
        }
        return (kcal, ignoti)
    }
}
