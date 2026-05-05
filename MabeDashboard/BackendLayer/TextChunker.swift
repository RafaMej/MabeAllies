internal import NaturalLanguage
internal import Foundation

struct TextChunker {
    static let maxPalabras = 300

    static func chunkear(texto: String, pagina: Int, documentoID: String) -> [Chunk] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = texto
        var chunks: [Chunk] = []
        var buffer = ""
        var contadorPalabras = 0
        var indice = 0

        tokenizer.enumerateTokens(in: texto.startIndex..<texto.endIndex) { rango, _ in
            let oracion = String(texto[rango]).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !oracion.isEmpty else { return true }
            let palabras = oracion.split(separator: " ").count
            if contadorPalabras + palabras > Self.maxPalabras && !buffer.isEmpty {
                chunks.append(Chunk(texto: buffer.trimmingCharacters(in: .whitespaces),
                                    indice: indice,
                                    metadata: "doc:\(documentoID) p.\(pagina) chunk:\(indice)"))
                indice += 1
                buffer = oracion
                contadorPalabras = palabras
            } else {
                buffer += (buffer.isEmpty ? "" : " ") + oracion
                contadorPalabras += palabras
            }
            return true
        }
        if !buffer.isEmpty {
            chunks.append(Chunk(texto: buffer.trimmingCharacters(in: .whitespaces),
                                indice: indice,
                                metadata: "doc:\(documentoID) p.\(pagina) chunk:\(indice)"))
        }
        return chunks
    }
}

struct Chunk {
    let texto: String
    let indice: Int
    let metadata: String
}
