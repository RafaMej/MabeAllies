// BusquedaRAGView.swift — iPadOS
// Basado en BusquedaView.swift del original.
// Añade navigationTitle y navigationBarTitleDisplayMode para la barra nativa de iPadOS.
// El resto de la lógica (RAGRetriever, ResultadoRAG, ResultadoCard) es idéntica.

internal import SwiftUI
internal import SwiftData

struct BusquedaRAGView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var chunks: [DocumentChunk]

    @State private var query      = ""
    @State private var topK       = 4
    @State private var resultados: [ResultadoRAG] = []
    @State private var buscando   = false
    @State private var tiempoMs: Double?
    @State private var errorMsg: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Search controls
            HStack(spacing: 12) {
                TextField("ej. ¿Cuántos días de vacaciones me corresponden?", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { buscar() }

                Stepper("Top \(topK)", value: $topK, in: 1...10).fixedSize()

                Button("Buscar") { buscar() }
                    .buttonStyle(.borderedProminent)
                    .disabled(query.isEmpty || chunks.isEmpty || buscando)
            }

            if chunks.isEmpty {
                ContentUnavailableView(
                    "Sin documentos indexados", systemImage: "doc.questionmark",
                    description: Text("Ve a Indexación y agrega un PDF primero.")
                )
            }

            if buscando {
                HStack { ProgressView(); Text("Buscando…").foregroundStyle(.secondary) }
            }

            if let ms = tiempoMs {
                Text("Recuperado en \(String(format: "%.1f", ms)) ms · \(resultados.count) resultados")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if let err = errorMsg {
                Label(err, systemImage: "xmark.circle.fill").foregroundStyle(.red)
            }

            if !resultados.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(resultados.enumerated()), id: \.element.id) { i, r in
                            ResultadoCard(rank: i + 1, resultado: r)
                        }
                    }
                }
            } else if !buscando && tiempoMs != nil {
                Text("Sin resultados para esa query.").foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(24)
        .navigationTitle("Búsqueda RAG")
        .navigationBarTitleDisplayMode(.large)
    }

    private func buscar() {
        guard !query.isEmpty else { return }
        buscando = true; resultados = []; errorMsg = nil; tiempoMs = nil
        Task {
            let inicio = Date()
            do {
                let retriever = RAGRetriever(modelContainer: modelContext.container)
                let encontrados = try await retriever.recuperar(query: query, topK: topK)
                let ms = Date().timeIntervalSince(inicio) * 1000
                await MainActor.run { resultados = encontrados; tiempoMs = ms; buscando = false }
            } catch {
                await MainActor.run { errorMsg = error.localizedDescription; buscando = false }
            }
        }
    }
}

// MARK: — ResultadoCard (idéntica al original)

struct ResultadoCard: View {
    let rank: Int
    let resultado: ResultadoRAG
    @State private var expandido = false

    var scoreColor: Color {
        switch resultado.score {
        case 0.75...: return .green
        case 0.5...:  return .orange
        default:      return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                Text("#\(rank)").font(.caption.bold()).foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 3).background(.secondary, in: Capsule())
                VStack(alignment: .leading, spacing: 2) {
                    Text(resultado.documentoID).fontWeight(.semibold)
                    Text(resultado.metadata).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(String(format: "%.3f", resultado.score))
                    .font(.system(.body, design: .monospaced).bold()).foregroundStyle(scoreColor)
                Button { withAnimation(.easeInOut(duration: 0.2)) { expandido.toggle() } } label: {
                    Image(systemName: expandido ? "chevron.up" : "chevron.down").foregroundStyle(.secondary)
                }.buttonStyle(.borderless)
            }
            if expandido {
                Text(resultado.texto).font(.system(.callout, design: .serif)).foregroundStyle(.primary)
                    .padding(10).background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Text(resultado.texto).lineLimit(2).font(.callout).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(scoreColor.opacity(0.3), lineWidth: 1))
    }
}
