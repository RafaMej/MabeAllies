internal import SwiftData
internal import NaturalLanguage
import CryptoKit
import Accelerate
internal import Foundation

@ModelActor
actor RAGRetriever {
    private let embedding = NLEmbedding.sentenceEmbedding(for: .spanish)!

    /// Búsqueda general sobre todos los documentos
    func recuperar(query: String, topK: Int = 4) throws -> [ResultadoRAG] {
        try recuperar(query: query, topK: topK, filtrarPorDocumentos: nil)
    }

    /// Búsqueda filtrada por IDs de documento específicos (modo sensible)
    func recuperar(
        query: String,
        topK: Int = 4,
        filtrarPorDocumentos documentIDs: [String]?
    ) throws -> [ResultadoRAG] {
        guard let vectorRaw = embedding.vector(for: query) else { return [] }
        let queryVec = vectorRaw.map { Float($0) }

        var descriptor = FetchDescriptor<DocumentChunk>()
        if let ids = documentIDs, !ids.isEmpty {
            descriptor = FetchDescriptor<DocumentChunk>(
                predicate: #Predicate { ids.contains($0.documentID) }
            )
        }

        let chunks = try modelContext.fetch(descriptor)
        guard !chunks.isEmpty else { return [] }

        let scored: [(DocumentChunk, Float)] = chunks.map { chunk in
            (chunk, cosineSimilarity(queryVec, chunk.vector))
        }.sorted { $0.1 > $1.1 }

        return Array(scored.prefix(topK)).compactMap { (chunk, score) in
            guard
                let nonceObj  = try? AES.GCM.Nonce(data: chunk.nonce),
                let box       = try? AES.GCM.SealedBox(nonce: nonceObj,
                                                        ciphertext: chunk.ciphertext,
                                                        tag: chunk.tag),
                let llave     = try? KeychainManager.dek(paraDocumento: chunk.documentID),
                let plainData = try? AES.GCM.open(box, using: llave),
                let texto     = String(data: plainData, encoding: .utf8)
            else { return nil }

            return ResultadoRAG(documentoID: chunk.documentID, metadata: chunk.metadata,
                               texto: texto, score: score)
        }
    }

    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot: Float = 0; var normA: Float = 0; var normB: Float = 0
        vDSP_dotpr(a, 1, b, 1, &dot, vDSP_Length(a.count))
        vDSP_svesq(a, 1, &normA, vDSP_Length(a.count))
        vDSP_svesq(b, 1, &normB, vDSP_Length(b.count))
        let denom = sqrt(normA) * sqrt(normB)
        return denom > 0 ? dot / denom : 0
    }
}

struct ResultadoRAG: Identifiable {
    let id = UUID()
    let documentoID: String
    let metadata: String
    let texto: String
    let score: Float
}
