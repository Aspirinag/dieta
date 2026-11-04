import Foundation

// Reparto del supermercato in cui si trova un alimento
enum Reparto: String, CaseIterable, Codable {
    case fruttaVerdura, carnePesceUova, latticini, panePastaCereali, dispensa, altro

    var nome: String {
        switch self {
        case .fruttaVerdura: String(localized: "Frutta e verdura")
        case .carnePesceUova: String(localized: "Carne, pesce, uova")
        case .latticini: String(localized: "Latticini")
        case .panePastaCereali: String(localized: "Pane, pasta, cereali")
        case .dispensa: String(localized: "Dispensa")
        case .altro: String(localized: "Altro")
        }
    }

    // Parole chiave senza accenti e in minuscolo. Dalle 4 lettere in su vale anche l'inizio della parola
    // (così "mele" e "mela" valgono entrambe); le parole più corte devono coincidere
    private static let paroleChiave: [(Reparto, [String])] = [
        (.fruttaVerdura, ["mela", "mele", "pera", "pere", "banana", "banane", "arancia", "arance", "mandarino", "mandarini", "kiwi",
                          "fragola", "fragole", "pesca", "pesche", "albicocca", "uva", "ananas", "melone", "anguria", "limone", "frutta",
                          "insalata", "lattuga", "rucola", "spinaci", "zucchina", "zucchine", "zucchini", "carota", "carote", "pomodoro", "pomodori",
                          "cetriolo", "cetrioli", "peperone", "peperoni", "melanzana", "melanzane", "broccoli", "cavolfiore", "cavolo",
                          "verdura", "verdure", "finocchio", "finocchi", "radicchio", "bieta", "biete", "funghi", "cipolla", "patata", "patate",
                          "asparagi", "fagiolini", "sedano", "zucca", "carciofi", "ortaggi", "minestrone", "prezzemolo", "basilico"]),
        (.carnePesceUova, ["pollo", "petto", "tacchino", "manzo", "vitello", "maiale", "agnello", "bresaola", "prosciutto", "fesa", "carne",
                           "bistecca", "hamburger", "macinato", "salsiccia", "speck", "affettato", "affettati", "coniglio",
                           "pesce", "merluzzo", "salmone", "tonno", "orata", "branzino", "spigola", "sogliola", "platessa", "nasello",
                           "gamberi", "gamberetti", "calamari", "polpo", "cozze", "vongole", "sgombro", "acciughe", "sardine", "trota",
                           "uovo", "uova", "albume", "albumi", "frittata"]),
        (.latticini, ["latte", "yogurt", "kefir", "formaggio", "formaggi", "parmigiano", "grana", "mozzarella", "ricotta", "burro",
                      "panna", "skyr", "stracchino", "crescenza", "provola", "scamorza", "feta", "primosale", "pecorino", "asiago",
                      "philadelphia", "latticini", "caciotta", "gorgonzola", "fontina", "quark"]),
        (.panePastaCereali, ["pane", "pasta", "riso", "farro", "orzo", "avena", "cereali", "grissini", "cracker", "crackers",
                             "fette", "biscotti", "biscotto", "gallette", "pancarre", "piadina", "focaccia", "pizza", "gnocchi",
                             "cous", "couscous", "polenta", "farina", "muesli", "corn", "bulgur", "tagliatelle", "spaghetti", "penne",
                             "fusilli", "risotto", "tortellini", "pangrattato", "wasa", "friselle", "taralli"]),
        (.dispensa, ["olio", "aceto", "sale", "zucchero", "miele", "marmellata", "confettura", "cacao", "caffe", "te", "tisana", "tisane",
                     "noci", "mandorle", "nocciole", "pistacchi", "anacardi", "arachidi", "semi", "legumi", "fagioli", "ceci", "lenticchie",
                     "piselli", "passata", "pelati", "spezie", "salsa", "senape", "maionese", "ketchup", "dado", "brodo",
                     "olive", "capperi", "hummus", "tahini", "crema", "cioccolato", "cioccolata", "proteine", "integratore", "lievito"]),
    ]

    // Parole che valgono solo se intere (come prefisso darebbero «semi» → «semintegrale»)
    private static let soloEsatte: Set<String> = ["semi"]
    // Espressioni di più parole, controllate prima delle singole parole («frutta secca» non è frutta fresca)
    private static let espressioni: [(Reparto, [String])] = [
        (.dispensa, ["frutta secca", "frutta a guscio", "frutta oleosa", "frutta disidratata"]),
    ]

    // Il primo termine del nome che corrisponde decide il reparto; senza corrispondenze è "altro"
    static func indovina(_ nome: String) -> Reparto {
        let pulito = nome.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).lowercased()
        let spaziato = " " + pulito.split(whereSeparator: { !$0.isLetter }).joined(separator: " ") + " "
        for (reparto, frasi) in espressioni where frasi.contains(where: { spaziato.contains(" \($0) ") }) { return reparto }
        let parole = pulito.split(whereSeparator: { !$0.isLetter }).map(String.init)
        for parola in parole {
            for (reparto, chiavi) in paroleChiave {
                for k in chiavi where parola == k || (k.count >= 4 && !soloEsatte.contains(k) && parola.hasPrefix(k)) {
                    return reparto
                }
            }
        }
        return .altro
    }
}
