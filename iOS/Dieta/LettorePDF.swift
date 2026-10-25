import UIKit
import WebKit
import PDFKit

// Legge lo schema dietetico e la BIA dai PDF con lo stesso codice della web app (Risorse/lettore.html),
// eseguito in una pagina web invisibile: così i PDF vengono letti esattamente come nella web app
final class LettorePDF: NSObject, WKNavigationDelegate {
    static let condiviso = LettorePDF()

    enum Errore: LocalizedError {
        case lettura, password
        var errorDescription: String? {
            switch self {
            case .lettura: "Non riesco a leggere questo PDF."
            case .password: "Il PDF è protetto da password."
            }
        }
    }

    // Cifrato con una password di apertura (non basta aprirlo per leggerlo)
    static func protetto(_ pdf: Data) -> Bool { PDFDocument(data: pdf)?.isLocked == true }

    static func passwordGiusta(_ pdf: Data, _ password: String) -> Bool {
        guard let doc = PDFDocument(data: pdf) else { return false }
        return !doc.isLocked || doc.unlock(withPassword: password)
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

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { scarta() }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { scarta() }

    // Se iOS chiude la pagina invisibile, la si ricarica alla lettura successiva
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { scarta() }

    // Pagina non caricata: la si butta, così la prossima lettura riprova invece di restare in attesa
    private func scarta() {
        web?.removeFromSuperview()
        web = nil
        pronto = false
        sblocca()
    }

    private func sblocca() {
        attesa.forEach { $0.resume() }
        attesa.removeAll()
    }

    private func esegui(_ funzione: String, _ pdf: Data, _ password: String) async throws -> Data {
        await prepara()
        guard let web, pronto else { throw Errore.lettura }
        let risultato: Any?
        do {
            risultato = try await web.callAsyncJavaScript(
                "return await \(funzione)(b64, pwd)",
                arguments: ["b64": pdf.base64EncodedString(), "pwd": password],
                contentWorld: .page
            )
        } catch {
            let messaggio = (error as NSError).userInfo["WKJavaScriptExceptionMessage"] as? String ?? ""
            throw messaggio.contains("PasswordException") ? Errore.password : Errore.lettura
        }
        guard let testo = risultato as? String else { throw Errore.lettura }
        return Data(testo.utf8)
    }

    func schema(_ pdf: Data, password: String = "") async throws -> [GiornoPiano] {
        try JSONDecoder().decode([GiornoPiano].self, from: await esegui("schema", pdf, password))
    }

    func bia(_ pdf: Data, password: String = "") async throws -> Misura {
        try JSONDecoder().decode(Misura.self, from: await esegui("bia", pdf, password))
    }
}
