internal import SwiftData
internal import NaturalLanguage
import CryptoKit
internal import Foundation

@ModelActor
actor DocumentIndexer {
    private let embedding = NLEmbedding.sentenceEmbedding(for: .spanish)!

    func indexar(url: URL, documentoID: String) async throws -> IndexResult {
        var chunksGuardados = 0
        var errores: [String] = []
        let llave = try KeychainManager.dek(paraDocumento: documentoID)
        let paginas = try PDFExtractor.extraer(url: url)
        try borrarChunksExistentes(documentoID: documentoID)

        for (numeroPagina, textoPagina) in paginas {
            let chunks = TextChunker.chunkear(texto: textoPagina, pagina: numeroPagina, documentoID: documentoID)
            for chunk in chunks {
                do {
                    guard let vectorRaw = embedding.vector(for: chunk.texto) else {
                        errores.append("Embedding falló: \(chunk.metadata)"); continue
                    }
                    let vector = vectorRaw.map { Float($0) }
                    let datos = Data(chunk.texto.utf8)
                    let sealed = try AES.GCM.seal(datos, using: llave)
                    let nonceData = sealed.nonce.withUnsafeBytes { Data($0) }
                    let record = DocumentChunk(documentID: documentoID, chunkIndex: chunk.indice,
                                              metadata: chunk.metadata, ciphertext: sealed.ciphertext,
                                              nonce: nonceData, tag: sealed.tag, vector: vector)
                    modelContext.insert(record)
                    chunksGuardados += 1
                } catch {
                    errores.append("Error en chunk \(chunk.indice): \(error.localizedDescription)")
                }
            }
        }
        try modelContext.save()
        return IndexResult(documentoID: documentoID, chunksIndexados: chunksGuardados,
                          paginas: paginas.count, errores: errores)
    }

    private func borrarChunksExistentes(documentoID: String) throws {
        let descriptor = FetchDescriptor<DocumentChunk>(
            predicate: #Predicate { $0.documentID == documentoID })
        let existentes = try modelContext.fetch(descriptor)
        existentes.forEach { modelContext.delete($0) }
    }
}

struct IndexResult {
    let documentoID: String
    let chunksIndexados: Int
    let paginas: Int
    let errores: [String]
    var exitoso: Bool { errores.isEmpty }
    var resumen: String {
        "\(chunksIndexados) chunks de \(paginas) páginas" +
        (errores.isEmpty ? "" : " (\(errores.count) errores)")
    }
}
