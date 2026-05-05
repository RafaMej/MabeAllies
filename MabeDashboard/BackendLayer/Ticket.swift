internal import SwiftData
internal import Foundation

@Model
final class Ticket {
    var id: UUID
    var folio: String
    var colaboradorID: String
    var motivo: String
    var mensajeOriginal: String
    var prioridad: PrioridadTicket
    var estado: EstadoTicket
    var creadoEn: Date
    var resueltaEn: Date?
    var notas: String

    init(colaboradorID: String, motivo: String, mensajeOriginal: String,
         prioridad: PrioridadTicket = .media) {
        self.id = UUID()
        self.folio = Ticket.generarFolio()
        self.colaboradorID = colaboradorID
        self.motivo = motivo
        self.mensajeOriginal = mensajeOriginal
        self.prioridad = prioridad
        self.estado = .abierto
        self.creadoEn = Date()
        self.resueltaEn = nil
        self.notas = ""
    }

    private static func generarFolio() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let fecha = formatter.string(from: Date())
        let sufijo = String(UUID().uuidString.prefix(4).uppercased())
        return "TKT-\(fecha)-\(sufijo)"
    }
}

enum PrioridadTicket: String, Codable, CaseIterable {
    case alta  = "Alta"
    case media = "Media"
    case baja  = "Baja"
}

enum EstadoTicket: String, Codable, CaseIterable {
    case abierto    = "Abierto"
    case enRevision = "En revisión"
    case resuelto   = "Resuelto"
    case cerrado    = "Cerrado"
}
