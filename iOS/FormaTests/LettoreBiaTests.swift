import Testing
import UIKit
@testable import Forma

// Lettura del referto BIA da PDF con il lettore dell'app (pdf.js in una pagina web invisibile)
@MainActor
struct LettoreBiaTests {
    // PDF con il testo nel formato del referto, una riga per voce
    static func pdf(_ righe: [String]) -> Data {
        let r = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
        return r.pdfData { ctx in
            ctx.beginPage()
            for (i, riga) in righe.enumerated() {
                (riga as NSString).draw(at: CGPoint(x: 40, y: 40 + CGFloat(i) * 22),
                                        withAttributes: [.font: UIFont.systemFont(ofSize: 12)])
            }
        }
    }

    @Test func leggeDataPesoEMassaGrassa() async throws {
        let dati = Self.pdf([
            "VISITA DEL 14/10/2026",
            "Peso: 82,4 kg",
            "FAT (Massa Grassa): 20,1 kg 24,4 %",
            "Circonferenza vita: 91 cm",
        ])
        let m = try await LettorePDF.condiviso.bia(dati)
        #expect(m.data == "2026-10-14")
        #expect(m.peso == 82.4)
        #expect(m.grassoKg == 20.1)
        #expect(m.vitaCm == 91)
    }
}
