internal import SwiftData
internal import Foundation

/// Inserta colaboradores de prueba y registra qué documentos
/// pertenecen a cada uno. Se llama una sola vez al arrancar la app.
@MainActor
struct ColaboradorSeeder {

    static func sembrarSiNecesario(context: ModelContext) throws {
        // Si ya hay colaboradores no volvemos a sembrar
        let existentes = try context.fetch(FetchDescriptor<Colaborador>())
        guard existentes.isEmpty else { return }

        let calendar = Calendar.current

        // ── Colaborador 1: Carlos Mendoza Ríos ──────────────────────────────
        let carlos = Colaborador(
            numeroEmpleado: "EMP-001423",
            nombre: "Carlos Mendoza Ríos",
            tipoContrato: .indefinido,
            turno: .matutino,
            departamento: "Dirección de Finanzas",
            fechaIngreso: calendar.date(from: DateComponents(year: 2019, month: 3, day: 15))!
        )
        context.insert(carlos)

        // ── Colaborador 2: Sofía Ramírez Castillo ───────────────────────────
        let sofia = Colaborador(
            numeroEmpleado: "EMP-003812",
            nombre: "Sofía Ramírez Castillo",
            tipoContrato: .indefinido,
            turno: .nocturno,
            departamento: "Planta de Manufactura — Línea 4",
            fechaIngreso: calendar.date(from: DateComponents(year: 2021, month: 7, day: 3))!
        )
        context.insert(sofia)

        try context.save()
        print("[Seeder] Colaboradores insertados correctamente.")
    }
}
