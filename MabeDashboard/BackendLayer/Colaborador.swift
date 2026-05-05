internal import SwiftData
internal import Foundation

@Model
final class Colaborador {
    var id: UUID
    var numeroEmpleado: String
    var nombre: String
    var tipoContrato: TipoContrato
    var turno: Turno
    var departamento: String
    var fechaIngreso: Date
    var activo: Bool

    @Relationship(deleteRule: .cascade)
    var conversaciones: [ConversacionLog] = []

    @Relationship(deleteRule: .cascade)
    var tickets: [Ticket] = []

    init(numeroEmpleado: String, nombre: String, tipoContrato: TipoContrato,
         turno: Turno, departamento: String, fechaIngreso: Date) {
        self.id = UUID()
        self.numeroEmpleado = numeroEmpleado
        self.nombre = nombre
        self.tipoContrato = tipoContrato
        self.turno = turno
        self.departamento = departamento
        self.fechaIngreso = fechaIngreso
        self.activo = true
    }

    var documentoKeyID: String { "colaborador-\(numeroEmpleado)" }
}

enum TipoContrato: String, Codable, CaseIterable {
    case indefinido  = "Indefinido"
    case temporal    = "Temporal"
    case porObra     = "Por obra"
    case honorarios  = "Honorarios"
}

enum Turno: String, Codable, CaseIterable {
    case matutino   = "Matutino"
    case vespertino = "Vespertino"
    case nocturno   = "Nocturno"
    case mixto      = "Mixto"
}
