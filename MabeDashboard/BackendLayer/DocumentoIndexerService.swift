internal import SwiftData
internal import Foundation

/// Indexa automáticamente los PDFs del bundle para cada colaborador.
/// Detecta si un documento ya está indexado para no repetir el trabajo.
@ModelActor
actor DocumentoIndexerService {

    /// Indexa todos los documentos de todos los colaboradores registrados.
    func indexarTodosLosDocumentos() async throws -> [String: IndexResult] {
        var resultados: [String: IndexResult] = [:]

        for (numeroEmpleado, docs) in DocumentoRegistry.documentos {
            for entrada in docs {
                // Saltar si ya está indexado
                if try yaIndexado(documentoID: entrada.documentoID) {
                    print("[IndexerService] Ya indexado: \(entrada.documentoID)")
                    continue
                }

                guard let url = Bundle.main.url(
                    forResource: entrada.nombreArchivo,
                    withExtension: "pdf"
                ) else {
                    print("[IndexerService] ⚠️ PDF no encontrado en bundle: \(entrada.nombreArchivo)")
                    continue
                }

                do {
                    let indexer = DocumentIndexer(modelContainer: modelContext.container)
                    let result = try await indexer.indexar(
                        url: url,
                        documentoID: entrada.documentoID
                    )
                    resultados[entrada.documentoID] = result
                    print("[IndexerService] ✓ \(entrada.documentoID): \(result.resumen)")
                } catch {
                    print("[IndexerService] ✗ \(entrada.documentoID): \(error.localizedDescription)")
                }
            }
        }

        return resultados
    }

    /// Indexa solo los documentos de un colaborador específico.
    func indexar(numeroEmpleado: String) async throws -> [IndexResult] {
        let docs = DocumentoRegistry.documentos(para: numeroEmpleado)
        var resultados: [IndexResult] = []

        for entrada in docs {
            guard let url = Bundle.main.url(
                forResource: entrada.nombreArchivo,
                withExtension: "pdf"
            ) else { continue }

            let indexer = DocumentIndexer(modelContainer: modelContext.container)
            let result = try await indexer.indexar(url: url, documentoID: entrada.documentoID)
            resultados.append(result)
        }

        return resultados
    }

    private func yaIndexado(documentoID: String) throws -> Bool {
        let descriptor = FetchDescriptor<DocumentChunk>(
            predicate: #Predicate { $0.documentID == documentoID }
        )
        return try modelContext.fetchCount(descriptor) > 0
    }
}
