import PDFKit
internal import Foundation

struct PDFExtractor {
    static func extraer(url: URL) throws -> [(pagina: Int, texto: String)] {
        guard let documento = PDFDocument(url: url) else {
            throw IngestError.pdfNoLegible(url.lastPathComponent)
        }
        var paginas: [(Int, String)] = []
        for i in 0..<documento.pageCount {
            guard let pagina = documento.page(at: i),
                  let texto = pagina.string, !texto.isEmpty else { continue }
            paginas.append((i + 1, texto))
        }
        guard !paginas.isEmpty else {
            throw IngestError.sinTexto(url.lastPathComponent)
        }
        return paginas
    }
}
