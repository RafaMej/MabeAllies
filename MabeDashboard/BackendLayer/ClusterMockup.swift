internal import Foundation

struct ClusterData: Identifiable {
    let id: Int
    let etiqueta: String
    let descripcion: String
    var porcentaje: Int
    var resueltosPorAgente: Int
    var tiempoPromedioMin: Double
    var tono: String
}

struct ClusterMockup {
    static let clusters: [ClusterData] = [
        ClusterData(id: 0, etiqueta: "Consultas de nómina fuera de horario",
                    descripcion: "Colaboradores operativos consultando recibos en turno nocturno",
                    porcentaje: 34, resueltosPorAgente: 78, tiempoPromedioMin: 4, tono: "neutral"),
        ClusterData(id: 1, etiqueta: "Dudas sobre prestaciones IMSS",
                    descripcion: "Preguntas sobre incapacidades, guardería y crédito Infonavit",
                    porcentaje: 28, resueltosPorAgente: 65, tiempoPromedioMin: 7, tono: "ansioso"),
        ClusterData(id: 2, etiqueta: "Trámites de vacaciones y permisos",
                    descripcion: "Solicitudes y seguimiento de días de descanso",
                    porcentaje: 24, resueltosPorAgente: 91, tiempoPromedioMin: 3, tono: "neutral"),
        ClusterData(id: 3, etiqueta: "Conflictos contractuales escalados",
                    descripcion: "Casos que requirieron intervención humana por complejidad legal",
                    porcentaje: 14, resueltosPorAgente: 12, tiempoPromedioMin: 18, tono: "frustrado")
    ]

    static func asignar(modo: String, duracionMin: Double) -> ClusterData {
        switch (modo, duracionMin) {
        case ("escalado", _):    return clusters[3]
        case ("sensible", 5...): return clusters[1]
        case ("sensible", _):    return clusters[0]
        default:                 return clusters[2]
        }
    }
}
