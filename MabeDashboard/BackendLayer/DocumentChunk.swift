internal import SwiftData
internal import Foundation

@Model
final class DocumentChunk {
    var id: UUID
    var documentID: String
    var chunkIndex: Int
    var metadata: String
    var ciphertext: Data
    var nonce: Data
    var tag: Data
    var vector: [Float]

    init(documentID: String, chunkIndex: Int, metadata: String,
         ciphertext: Data, nonce: Data, tag: Data, vector: [Float]) {
        self.id = UUID()
        self.documentID = documentID
        self.chunkIndex = chunkIndex
        self.metadata = metadata
        self.ciphertext = ciphertext
        self.nonce = nonce
        self.tag = tag
        self.vector = vector
    }
}
