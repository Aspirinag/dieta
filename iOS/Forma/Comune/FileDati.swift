import Foundation

// Lettura dei file dati: se un file c'è ma non si decodifica, se ne tiene una copia accanto
// (così ripartire da zero non lo sovrascrive e i dati si possono recuperare).
// Se il file c'è ma non si riesce nemmeno a leggerlo (es. telefono bloccato), non va mai sovrascritto
enum FileDati {
    enum Esito<T> {
        case ok(T)
        case assente
        case illeggibile(copia: URL)
        case bloccato               // esiste ma non si legge, o non si è potuta salvare la copia: non salvare
    }

    static let marcaCopia = ".illeggibile-"

    static func leggi<T: Decodable>(_ url: URL, come: T.Type) -> Esito<T> {
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return .assente }
        guard let dati = try? Data(contentsOf: url) else { return .bloccato }
        if let valore = try? JSONDecoder().decode(T.self, from: dati) { return .ok(valore) }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd-HHmmss"
        let nome = url.deletingPathExtension().lastPathComponent
        let copia = url.deletingLastPathComponent().appending(path: "\(nome)\(marcaCopia)\(f.string(from: Date())).json")
        do { try dati.write(to: copia, options: .atomic) } catch { return .bloccato }
        return .illeggibile(copia: copia)
    }

    // Copie dei file non letti in una cartella, dalla più recente
    static func copie(in cartella: URL) -> [URL] {
        let tutti = (try? FileManager.default.contentsOfDirectory(at: cartella, includingPropertiesForKeys: nil)) ?? []
        return tutti.filter { $0.lastPathComponent.contains(marcaCopia) }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }
}
