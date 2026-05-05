internal import Foundation

enum RutaAgente: String, CaseIterable, Sendable {
    case simple   = "simple"
    case sensible = "sensible"
    case escalar  = "escalado"
}

struct RouterMockup {
    static func clasificar(mensaje: String, historial: [String]) -> RutaAgente {
        let texto = mensaje.lowercased()

        let triggerEscalar = ["despido", "demanda", "sindicato", "acoso",
                              "discriminacion", "accidente", "auditoria",
                              "juridico", "legal", "denuncia", "renuncia"]
        if triggerEscalar.contains(where: { texto.contains($0) }) { return .escalar }
        if historial.count > 6 { return .escalar }

        let triggerSensible = ["nomina", "sueldo", "salario", "contrato",
                               "imss", "infonavit", "bono", "descuento",
                               "recibo", "expediente", "mi contrato",
                               "mi sueldo", "me descuentan", "me pagaron"]
        if triggerSensible.contains(where: { texto.contains($0) }) { return .sensible }

        return .simple
    }
}
