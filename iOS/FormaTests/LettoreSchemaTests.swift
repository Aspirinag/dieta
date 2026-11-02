import Testing
import UIKit
@testable import Forma

// Lettura dello schema dietetico da PDF: anche colazione e merenda, e pagine di altre dimensioni
@MainActor
struct LettoreSchemaTests {
    // Righe (sinistra, destra) disegnate in due colonne, con più pagine se servono
    static func pdf(_ righe: [(String, String)], larghezza: CGFloat = 595, altezza: CGFloat = 842,
                    xSinistra: CGFloat = 40, xDestra: CGFloat = 380) -> Data {
        let r = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: larghezza, height: altezza))
        let perPagina = Int((altezza - 80) / 18)
        return r.pdfData { ctx in
            for (i, riga) in righe.enumerated() {
                if i % perPagina == 0 { ctx.beginPage() }
                let y = 40 + CGFloat(i % perPagina) * 18
                let a: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11)]
                (riga.0 as NSString).draw(at: CGPoint(x: xSinistra, y: y), withAttributes: a)
                if !riga.1.isEmpty { (riga.1 as NSString).draw(at: CGPoint(x: xDestra, y: y), withAttributes: a) }
            }
        }
    }

    static func settimana(_ pasti: [String]) -> [(String, String)] {
        Giorni.nomi.flatMap { g in [(g, "")] + pasti.flatMap { [($0, ""), ("Yogurt greco", "(150 g)")] } }
    }

    @Test func colazioneEMerenda() async throws {
        let pasti = ["Colazione", "Spuntino", "Pranzo", "Merenda", "Cena"]
        let giorni = try await LettorePDF.condiviso.schema(Self.pdf(Self.settimana(pasti)))
        #expect(giorni.count == 7)
        #expect(giorni.first?.pasti.map(\.nome) == pasti)
        #expect(giorni.first?.pasti.first?.opzioni.first?.alimenti.first?.quantita == "150 g")
    }

    @Test func paginaOrizzontaleConColonneSpostate() async throws {
        let dati = Self.pdf(Self.settimana(["Pranzo", "Cena"]), larghezza: 842, altezza: 595, xSinistra: 300, xDestra: 600)
        let giorni = try await LettorePDF.condiviso.schema(dati)
        #expect(giorni.count == 7)
        #expect(giorni.first?.pasti.first?.opzioni.first?.alimenti.first?.nome == "Yogurt greco")
    }
}
