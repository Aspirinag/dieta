import Foundation

// Lettura dei file dati: se un file c'è ma non si legge, se ne tiene una copia accanto
// (così ripartire da zero non lo sovrascrive e i dati si possono recuperare)
enum FileDati {
    enum Esito<T> {
        case ok(T)
        case assente
        case illeggibile(copia: URL)
    }

    static func leggi<T: Decodable>(_ url: URL, come: T.Type) -> Esito<T> {
        guard let dati = try? Data(contentsOf: url) else { return .assente }
        if let valore = try? JSONDecoder().decode(T.self, from: dati) { return .ok(valore) }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd-HHmmss"
        let nome = url.deletingPathExtension().lastPathComponent
        let copia = url.deletingLastPathComponent().appending(path: "\(nome).illeggibile-\(f.string(from: Date())).json")
        try? dati.write(to: copia, options: .atomic)
        return .illeggibile(copia: copia)
    }
}
