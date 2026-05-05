internal import Foundation
internal import Combine
internal import SwiftData
internal import NaturalLanguage
internal import FoundationModels

@MainActor
final class PipelineOrchestrator: ObservableObject, @unchecked Sendable {

    @Published var procesando = false
    @Published var ultimaRuta: RutaAgente?

    private let container: ModelContainer
    private let sender: FirestoreMessageSender

    init(container: ModelContainer, agenteUID: String) {
        self.container = container
        self.sender = FirestoreMessageSender(agenteUID: agenteUID)
    }

    func procesar(
        mensaje: String,
        colaboradorID: String,   // numeroEmpleado — ej. "EMP-001423"
        historial: [TurnoConversacion]
    ) async throws -> RespuestaPipeline {

        let inicio = Date()
        procesando = true
        defer { procesando = false }

        let ruta = RouterMockup.clasificar(
            mensaje: mensaje,
            historial: historial.map(\.contenido)
        )
        ultimaRuta = ruta

        // RAG diferenciado — modo sensible usa docs del colaborador específico
        let contextoRAG = try await recuperarContexto(
            query: mensaje,
            modo: ruta,
            colaboradorID: colaboradorID
        )

        let respuestaRH = try await invocarModelo(
            mensaje: mensaje,
            historial: historial,
            contexto: contextoRAG,
            ruta: ruta,
            colaboradorID: colaboradorID
        )

        await sender.enviar(respuesta: respuestaRH.texto, a: colaboradorID)

        let duracion = Date().timeIntervalSince(inicio)

        if respuestaRH.requiereEscalado {
            try await crearTicket(
                colaboradorID: colaboradorID,
                mensajeOriginal: mensaje,
                motivo: respuestaRH.texto
            )
        }

        try await persistirLog(
            colaboradorID: colaboradorID,
            entrada: mensaje,
            respuesta: respuestaRH.texto,
            ruta: ruta,
            resuelta: !respuestaRH.requiereEscalado,
            duracion: duracion,
            confianza: respuestaRH.confianza
        )

        return RespuestaPipeline(
            texto: respuestaRH.texto,
            ruta: ruta,
            confianza: respuestaRH.confianza,
            requiereEscalado: respuestaRH.requiereEscalado,
            duracionSegundos: duracion,
            chunksUsados: contextoRAG.chunksUsados
        )
    }

    // MARK: - RAG diferenciado por colaborador

    private func recuperarContexto(
        query: String,
        modo: RutaAgente,
        colaboradorID: String
    ) async throws -> ContextoRAG {
        guard modo != .escalar else { return ContextoRAG(texto: "", chunksUsados: 0) }

        let retriever = RAGRetriever(modelContainer: container)

        if modo == .sensible {
            // Buscar SOLO en documentos del colaborador específico
            let idsPersonales = DocumentoRegistry
                .documentos(para: colaboradorID)
                .map(\.documentoID)

            let resultados = try await retriever.recuperar(
                query: query,
                topK: 5,
                filtrarPorDocumentos: idsPersonales
            )

            guard !resultados.isEmpty else {
                return ContextoRAG(
                    texto: "No se encontraron documentos personales del colaborador \(colaboradorID).",
                    chunksUsados: 0
                )
            }

            let texto = resultados
                .map { "[\($0.metadata) — relevancia: \(String(format: "%.2f", $0.score))]\n\($0.texto)" }
                .joined(separator: "\n\n---\n\n")

            return ContextoRAG(texto: texto, chunksUsados: resultados.count)

        } else {
            // Modo simple — busca en todos los documentos públicos
            let resultados = try await retriever.recuperar(query: query, topK: 3)
            guard !resultados.isEmpty else { return ContextoRAG(texto: "", chunksUsados: 0) }

            let texto = resultados
                .map { "[\($0.metadata) — relevancia: \(String(format: "%.2f", $0.score))]\n\($0.texto)" }
                .joined(separator: "\n\n---\n\n")

            return ContextoRAG(texto: texto, chunksUsados: resultados.count)
        }
    }

    // MARK: - FoundationModels

    private func invocarModelo(
        mensaje: String,
        historial: [TurnoConversacion],
        contexto: ContextoRAG,
        ruta: RutaAgente,
        colaboradorID: String
    ) async throws -> RespuestaRH {

        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            return fallbackRespuesta(ruta: ruta, contexto: contexto)
        }

        let instrucciones = systemPrompt(
            para: ruta,
            contexto: contexto.texto,
            colaboradorID: colaboradorID
        )
        let session = LanguageModelSession(instructions: instrucciones)

        var promptFinal = mensaje
        if !historial.isEmpty {
            let historialTexto = historial.suffix(6).map {
                "\($0.esUsuario ? "Colaborador" : "Agente"): \($0.contenido)"
            }.joined(separator: "\n")
            promptFinal = "\(historialTexto)\nColaborador: \(mensaje)"
        }

        let respuesta = try await session.respond(to: promptFinal)

        let confianza: Double
        let requiereEscalado: Bool
        switch ruta {
        case .escalar:
            confianza = 0.1; requiereEscalado = true
        case .sensible:
            confianza = contexto.chunksUsados > 0 ? 0.82 : 0.45
            requiereEscalado = contexto.chunksUsados == 0
        case .simple:
            confianza = contexto.chunksUsados > 0 ? 0.91 : 0.60
            requiereEscalado = false
        }

        return RespuestaRH(texto: respuesta.content,
                           confianza: confianza,
                           requiereEscalado: requiereEscalado)
    }

    private func fallbackRespuesta(ruta: RutaAgente, contexto: ContextoRAG) -> RespuestaRH {
        switch ruta {
        case .simple:
            let texto = contexto.chunksUsados > 0
                ? "[Sin IA] Encontré información relevante, pero el modelo aún se descarga."
                : "[Sin IA] El modelo de IA aún se está descargando. Intenta en unos minutos."
            return RespuestaRH(texto: texto, confianza: 0.0, requiereEscalado: false)
        case .sensible:
            return RespuestaRH(
                texto: "[Sin IA] Esta consulta requiere el modelo de IA que aún se descarga.",
                confianza: 0.0, requiereEscalado: false)
        case .escalar:
            return RespuestaRH(
                texto: "Tu consulta ha sido registrada. Un especialista de RRHH te contactará en máximo 24 horas hábiles.",
                confianza: 0.1, requiereEscalado: true)
        }
    }

    private func systemPrompt(
        para ruta: RutaAgente,
        contexto: String,
        colaboradorID: String
    ) -> String {
        switch ruta {
        case .simple:
            return """
            Eres el asistente de RRHH de Mabe. Respondes preguntas generales sobre
            la Ley Federal del Trabajo, prestaciones y políticas internas de la empresa.
            Sé claro, conciso y amable. Responde siempre en español.
            Si no encuentras la respuesta en el contexto, dilo honestamente.

            Contexto disponible:
            \(contexto.isEmpty ? "Sin contexto adicional disponible." : contexto)
            """
        case .sensible:
            return """
            Eres el asistente confidencial de RRHH de Mabe. Tienes acceso al expediente
            personal del colaborador \(colaboradorID). REGLAS ESTRICTAS:
            - Solo responde con información EXPLÍCITA en el expediente proporcionado.
            - Nunca infieras ni estimes datos de nómina, fechas o montos.
            - Si no tienes certeza absoluta, indica que escalará la consulta a RRHH.
            - No confirmes información que no esté textualmente en el expediente.
            Responde siempre en español.
            - No muestres, digas o cites bajo ningunga circumstancia ningun dato que corresponda a otro colaborador que no sea \(colaboradorID).

            Expediente del colaborador \(colaboradorID):
            \(contexto.isEmpty ? "Sin expediente disponible. Escalar a RRHH." : contexto)
            """
        case .escalar:
            return """
            Eres el asistente de RRHH de Mabe. Esta consulta requiere atención
            personalizada de un especialista. Tu tarea es:
            1. Informar al colaborador que su caso será atendido por un especialista.
            2. Dar un tiempo estimado de respuesta (máximo 24 horas hábiles).
            3. Pedirle que esté disponible en su número registrado.
            Sé empático y tranquilizador. Responde en español.
            """
        }
    }

    // MARK: - Persistencia

    private func crearTicket(
        colaboradorID: String,
        mensajeOriginal: String,
        motivo: String
    ) async throws {
        let context = ModelContext(container)
        let textoLower = mensajeOriginal.lowercased()
        let prioridad: PrioridadTicket
        if ["acoso", "discriminación", "accidente", "demanda"].contains(where: textoLower.contains) {
            prioridad = .alta
        } else if ["despido", "sindicato", "auditoría"].contains(where: textoLower.contains) {
            prioridad = .media
        } else {
            prioridad = .baja
        }
        let ticket = Ticket(colaboradorID: colaboradorID, motivo: motivo,
                           mensajeOriginal: mensajeOriginal, prioridad: prioridad)
        context.insert(ticket)
        try context.save()
    }

    private func persistirLog(
        colaboradorID: String, entrada: String, respuesta: String,
        ruta: RutaAgente, resuelta: Bool, duracion: TimeInterval, confianza: Double
    ) async throws {
        let context = ModelContext(container)
        let log = ConversacionLog(
            colaboradorID: colaboradorID, mensajeEntrada: entrada,
            respuestaAgente: respuesta, modo: ruta.rawValue,
            resuelta: resuelta, duracionSegundos: duracion, scoreConfianza: confianza
        )
        log.clusterID = ClusterMockup.asignar(modo: ruta.rawValue, duracionMin: duracion / 60).id
        context.insert(log)
        try context.save()
    }
}

// MARK: - Tipos

struct TurnoConversacion: Identifiable {
    let id = UUID()
    let contenido: String
    let esUsuario: Bool
    let timestamp: Date
}

struct RespuestaPipeline {
    let texto: String
    let ruta: RutaAgente
    let confianza: Double
    let requiereEscalado: Bool
    let duracionSegundos: Double
    let chunksUsados: Int
}

struct RespuestaRH {
    let texto: String
    let confianza: Double
    let requiereEscalado: Bool
}

struct ContextoRAG {
    let texto: String
    let chunksUsados: Int
}
