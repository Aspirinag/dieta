import SwiftUI

// «Annulla» per qualche secondo dopo una spunta o dopo «Mangiato»
struct BannerAnnulla: View {
    let tipo: TipoAnnulla
    @Environment(Archivio.self) private var archivio
    @Environment(\.palette) private var palette

    var body: some View {
        if let r = archivio.richiestaAnnulla, r.tipo == tipo {
            HStack {
                Text(r.testo)
                    .font(.georgia(.subheadline))
                Spacer()
                Button {
                    if tipo == .spunta { archivio.annullaSpunta() } else { archivio.annullaUltimoPasto() }
                } label: {
                    Text("Annulla")
                        .font(.georgia(.subheadline, grassetto: true))
                        .foregroundStyle(palette.accento)
                        .padding(.horizontal, 12)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 14)
            .padding(.trailing, 4)
            .background(palette.barra, in: .capsule)
            .overlay { Capsule().strokeBorder(palette.traccia) }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

