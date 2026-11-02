import Foundation
import Testing
@testable import Forma

// Un file dati illeggibile non va mai perso: se ne tiene una copia
@MainActor
struct FileDatiTests {
    private struct Prova: Codable, Equatable { var n: Int }

    private func cartella() throws -> URL {
        let u = FileManager.default.temporaryDirectory.appending(path: "filedati-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    @Test func fileAssente() throws {
        let u = try cartella().appending(path: "dati.json")
        guard case .assente = FileDati.leggi(u, come: Prova.self) else { Issue.record("atteso .assente"); return }
    }

    @Test func fileValido() throws {
        let u = try cartella().appending(path: "dati.json")
        try Data(#"{"n":3}"#.utf8).write(to: u)
        guard case .ok(let p) = FileDati.leggi(u, come: Prova.self) else { Issue.record("atteso .ok"); return }
        #expect(p == Prova(n: 3))
    }

    @Test func fileRottoVieneMessoDaParte() throws {
        let u = try cartella().appending(path: "dati.json")
        let rotto = Data(#"{"n": tre"#.utf8)
        try rotto.write(to: u)
        guard case .illeggibile(let copia) = FileDati.leggi(u, come: Prova.self) else { Issue.record("atteso .illeggibile"); return }
        #expect(copia.lastPathComponent.hasPrefix("dati.illeggibile-"))
        #expect(copia.pathExtension == "json")
        #expect(try Data(contentsOf: copia) == rotto)
    }
}
