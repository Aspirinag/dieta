import UIKit
import WebKit

// Legge lo schema dietetico e la BIA dai PDF con lo stesso codice della web app (Risorse/lettore.html),
// eseguito in una pagina web invisibile: così i PDF vengono letti esattamente come nella web app
final class LettorePDF: NSObject, WKNavigationDelegate {
    static let condiviso = LettorePDF()

    enum Errore: LocalizedError {
        case lettura
        var errorDescription: String? { "Non riesco a leggere questo PDF." }
    }

    private var web: WKWebView?
    private var attesa: [CheckedContinuation<Void, Never>] = []
    private var pronto = false

    private func prepara() async {
        if pronto { return }
        if web == nil {
            let w = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            w.alpha = 0.01
            w.isUserInteractionEnabled = false
            w.navigationDelegate = self
            // Agganciata alla finestra, altrimenti iOS può sospendere la pagina
            let finestra = UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first
            finestra?.addSubview(w)
            web = w
            if let url = Bundle.main.url(forResource: "lettore", withExtension: "html") {
                w.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
            }
        }
        await withCheckedContinuation { attesa.append($0) }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        pronto = true
        sblocca()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { sblocca() }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { sblocca() }

    private func sblocca() {
        attesa.forEach { $0.resume() }
        attesa.removeAll()
    }

    private func esegui(_ funzione: String, _ pdf: Data) async throws -> Data {
        await prepara()
        guard let web else { throw Errore.lettura }
        let risultato = try await web.callAsyncJavaScript(
            "return await \(funzione)(b64)",
            arguments: ["b64": pdf.base64EncodedString()],
            contentWorld: .page
        )
        guard let testo = risultato as? String else { throw Errore.lettura }
        return Data(testo.utf8)
    }

    func schema(_ pdf: Data) async throws -> [GiornoPiano] {
        try JSONDecoder().decode([GiornoPiano].self, from: await esegui("schema", pdf))
    }

    func bia(_ pdf: Data) async throws -> Misura {
        try JSONDecoder().decode(Misura.self, from: await esegui("bia", pdf))
    }
}
