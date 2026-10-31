import SwiftUI

// Schermata di una nuova installazione, senza profili: si carica un backup oppure si crea il primo profilo.
// Sta dentro .importatore() (in Radice), così importa(.backup) e importa(.schema) funzionano da qui.
// Più avanti qui entrerà anche l'import del backup di Palestra.
struct PrimaApertura: View {
    @Environment(Archivio.self) private var archivio
    @Environment(\.importa) private var importa
    @Environment(\.palette) private var palette

    private enum Passo { case scelta, nome, piano }

    @State private var passo = Passo.scelta
    @State private var nome = ""
    @FocusState private var nomeAttivo: Bool

    private var nomePulito: String { nome.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("èffort")
                    .titoloApp(.largeTitle)
                    .foregroundStyle(palette.testo)
                    .accessibilityAddTraits(.isHeader)

                switch passo {
                case .scelta: scelta
                case .nome: richiestaNome
                case .piano: propostaPiano
                }
            }
            .frame(maxWidth: 520, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 48)
            .padding(.bottom, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .animation(.default, value: passo)
    }

    // ---------- Passi ----------

    private var scelta: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Benvenuto. Per cominciare serve un profilo.")
                .font(.title3)
                .foregroundStyle(palette.secondario)
            Spacer().frame(height: 8)
            tasto("Carica il tuo profilo", dettaglio: "Importa un backup", evidente: false) { importa(.backup) }
            tasto("Crea un profilo", dettaglio: "Scegli un nome e parti da zero", evidente: true) { passo = .nome }
        }
    }

    private var richiestaNome: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Come ti chiami?")
                .titoloApp(.title2)
                .foregroundStyle(palette.testo)
            TextField("Nome", text: $nome)
                .textContentType(.givenName)
                .submitLabel(.continue)
                .focused($nomeAttivo)
                .onSubmit { if !nomePulito.isEmpty { passo = .piano } }
                .padding(.horizontal, 16)
                .frame(minHeight: 52)
                .background(palette.riempimento, in: .rect(cornerRadius: 14))
                .foregroundStyle(palette.testo)
                .onAppear { nomeAttivo = true }
            if !nome.isEmpty && nomePulito.isEmpty {
                Text("Scrivi almeno una lettera.")
                    .font(.footnote)
                    .foregroundStyle(palette.caldo)
            }
            tasto("Continua", evidente: true) { passo = .piano }
                .disabled(nomePulito.isEmpty)
                .opacity(nomePulito.isEmpty ? 0.5 : 1)
            tasto("Indietro", evidente: false) { passo = .scelta }
        }
    }

    private var propostaPiano: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hai il piano alimentare in PDF?")
                .titoloApp(.title2)
                .foregroundStyle(palette.testo)
            Text("Puoi caricarlo ora, oppure farlo più tardi da Profilo.")
                .font(.body)
                .foregroundStyle(palette.secondario)
            tasto("Carica il piano (PDF)", evidente: true) { crea(poiCaricaPiano: true) }
            tasto("Salta", evidente: false) { crea(poiCaricaPiano: false) }
        }
    }

    private func crea(poiCaricaPiano: Bool) {
        guard archivio.creaPrimoProfilo(nome) else { passo = .nome; return }
        if poiCaricaPiano { importa(.schema) }
    }

    // ---------- Componenti ----------

    private func tasto(_ titolo: String, dettaglio: String? = nil, evidente: Bool, azione: @escaping () -> Void) -> some View {
        Button(action: azione) {
            VStack(spacing: 2) {
                Text(titolo).font(.headline)
                if let dettaglio {
                    Text(dettaglio).font(.subheadline)
                        .foregroundStyle(evidente ? palette.suTasto : palette.secondario)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.vertical, 6)
            .padding(.horizontal, 16)
            .foregroundStyle(evidente ? palette.suTasto : palette.testo)
            .background {
                if evidente {
                    RoundedRectangle(cornerRadius: 16).fill(palette.tasto)
                } else {
                    RoundedRectangle(cornerRadius: 16).fill(palette.scheda)
                    RoundedRectangle(cornerRadius: 16).strokeBorder(palette.secondario.opacity(0.35))
                }
            }
            .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
