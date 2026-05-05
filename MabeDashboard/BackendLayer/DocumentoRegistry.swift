internal import Foundation

/// Mapea cada colaborador a sus documentos cifrados.
/// En producción esto vendría de una base de datos de RRHH.
/// En hackathon es un diccionario estático que apunta a los PDFs de prueba.
struct DocumentoRegistry {

    struct EntradaDocumento {
        let documentoID: String   // clave usada en KeychainManager y SwiftData
        let nombreArchivo: String // nombre del PDF en el bundle
        let tipo: TipoDocumento
        let descripcion: String
    }

    enum TipoDocumento: String {
        case nomina      = "Nómina"
        case contrato    = "Contrato"
        case vacaciones  = "Vacaciones"
        case imss        = "Alta IMSS"
        case constancia  = "Constancia de empleo"
    }

    /// Documentos indexados por número de empleado
    static let documentos: [String: [EntradaDocumento]] = [
        "EMP-001423": [
            EntradaDocumento(
                documentoID: "EMP001423-nomina-q1-may2025",
                nombreArchivo: "EMP001423_nomina_q1_mayo2025",
                tipo: .nomina,
                descripcion: "Recibo de nómina Quincena 1 Mayo 2025"
            ),
            EntradaDocumento(
                documentoID: "EMP001423-contrato",
                nombreArchivo: "EMP001423_contrato",
                tipo: .contrato,
                descripcion: "Contrato individual de trabajo"
            ),
            EntradaDocumento(
                documentoID: "EMP001423-vacaciones-2024",
                nombreArchivo: "EMP001423_vacaciones_2024",
                tipo: .vacaciones,
                descripcion: "Estado de vacaciones y permisos 2024"
            ),
            EntradaDocumento(
                documentoID: "EMP001423-imss",
                nombreArchivo: "EMP001423_alta_imss",
                tipo: .imss,
                descripcion: "Comprobante de alta IMSS"
            ),
            EntradaDocumento(
                documentoID: "EMP001423-constancia",
                nombreArchivo: "EMP001423_constancia",
                tipo: .constancia,
                descripcion: "Constancia de empleo"
            ),
        ],
        "EMP-003812": [
            EntradaDocumento(
                documentoID: "EMP003812-nomina-q1-may2025",
                nombreArchivo: "EMP003812_nomina_q1_mayo2025",
                tipo: .nomina,
                descripcion: "Recibo de nómina Quincena 1 Mayo 2025"
            ),
            EntradaDocumento(
                documentoID: "EMP003812-contrato",
                nombreArchivo: "EMP003812_contrato",
                tipo: .contrato,
                descripcion: "Contrato individual de trabajo"
            ),
            EntradaDocumento(
                documentoID: "EMP003812-vacaciones-2024",
                nombreArchivo: "EMP003812_vacaciones_2024",
                tipo: .vacaciones,
                descripcion: "Estado de vacaciones y permisos 2024"
            ),
            EntradaDocumento(
                documentoID: "EMP003812-imss",
                nombreArchivo: "EMP003812_alta_imss",
                tipo: .imss,
                descripcion: "Comprobante de alta IMSS"
            ),
            EntradaDocumento(
                documentoID: "EMP003812-constancia",
                nombreArchivo: "EMP003812_constancia",
                tipo: .constancia,
                descripcion: "Constancia de empleo"
            ),
        ]
    ]

    static func documentos(para numeroEmpleado: String) -> [EntradaDocumento] {
        documentos[numeroEmpleado] ?? []
    }
}
