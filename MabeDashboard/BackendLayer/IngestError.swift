internal import Foundation

enum IngestError: LocalizedError {
    case pdfNoLegible(String)
    case sinTexto(String)
    case embeddingFallido(String)
    case cifradoFallido

    var errorDescription: String? {
        switch self {
        case .pdfNoLegible(let n):     return "No se pudo leer el PDF: \(n)"
        case .sinTexto(let n):         return "El PDF no contiene texto extraíble: \(n)"
        case .embeddingFallido(let s): return "Embedding falló para chunk: \(s)"
        case .cifradoFallido:          return "Error en cifrado AES-GCM"
        }
    }
}

enum KeychainError: LocalizedError {
    case noSePudoGuardar(OSStatus)
    var errorDescription: String? {
        switch self {
        case .noSePudoGuardar(let s): return "Keychain error: \(s)"
        }
    }
}
