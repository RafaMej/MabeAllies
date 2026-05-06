// ConversationAnalysis.swift
// Computed (non-persistent) result of running SentimentAnalysisEngine over a ConversacionLog.
// These structs are derived on the fly from SwiftData and are never stored independently.

internal import Foundation

// MARK: — KeywordEntry

/// A single keyword extracted from conversation text, weighted by frequency and
/// colored by the dominant sentiment of the conversations it appeared in.
struct KeywordEntry: Identifiable, Equatable {
    let id: UUID
    let word: String
    let frequency: Int
    let dominantSentiment: SentimentScore

    init(id: UUID = UUID(), word: String, frequency: Int, dominantSentiment: SentimentScore) {
        self.id = id
        self.word = word
        self.frequency = frequency
        self.dominantSentiment = dominantSentiment
    }
}

// MARK: — ConversationAnalysis

/// Full NLP analysis result for one HR conversation.
/// Produced by SentimentAnalysisEngine.analyze(log:).
struct ConversationAnalysis: Identifiable {
    let id: UUID
    let timestamp: Date
    let colaboradorID: String
    /// Raw NLTagger sentimentScore in [-1.0, +1.0]. Negative = negative sentiment.
    let nlScore: Double
    let sentiment: SentimentScore
    let topic: QueryCategory
    /// Content-bearing keywords extracted from the employee's input message.
    let keywords: [String]
    /// Pipeline route: "simple" | "sensible" | "escalado"
    let ruta: String
    let resuelta: Bool
}

// MARK: — TopicCount

/// Aggregated count of conversations per HR topic, used by TopicDistributionChart.
struct TopicCount: Identifiable {
    let id: UUID
    let category: QueryCategory
    let count: Int

    init(category: QueryCategory, count: Int) {
        self.id = UUID()
        self.category = category
        self.count = count
    }
}

// MARK: — Seed mock data

extension ConversationAnalysis {

    /// 14 realistic Spanish HR conversations covering all topics and sentiments.
    /// Used as fallback when SwiftData contains no real ConversacionLog entries.
    /// nlScore values approximate what NLTagger.sentimentScore returns for each text.
    static let mockSeed: [ConversationAnalysis] = {
        let cal = Calendar.current
        let now = Date()
        func ago(_ h: Int) -> Date { cal.date(byAdding: .hour, value: -h, to: now) ?? now }

        return [
            // — Nómina ──────────────────────────────────────────────────────────
            ConversationAnalysis(
                id: UUID(), timestamp: ago(1), colaboradorID: "EMP-001423",
                nlScore: 0.45, sentiment: .positive, topic: .nomina,
                keywords: ["nómina", "depósito", "quincena", "viernes", "pago"],
                ruta: "simple", resuelta: true
            ),
            ConversationAnalysis(
                id: UUID(), timestamp: ago(3), colaboradorID: "EMP-003812",
                nlScore: -0.38, sentiment: .negative, topic: .nomina,
                keywords: ["descuento", "nómina", "diferencia", "error", "cobrar"],
                ruta: "sensible", resuelta: false
            ),
            ConversationAnalysis(
                id: UUID(), timestamp: ago(6), colaboradorID: "EMP-001423",
                nlScore: 0.22, sentiment: .positive, topic: .nomina,
                keywords: ["bono", "productividad", "pago", "monto", "extra"],
                ruta: "sensible", resuelta: true
            ),

            // — Vacaciones ──────────────────────────────────────────────────────
            ConversationAnalysis(
                id: UUID(), timestamp: ago(2), colaboradorID: "EMP-003812",
                nlScore: 0.55, sentiment: .positive, topic: .vacaciones,
                keywords: ["vacaciones", "días", "aprobadas", "descanso", "semana"],
                ruta: "sensible", resuelta: true
            ),
            ConversationAnalysis(
                id: UUID(), timestamp: ago(8), colaboradorID: "EMP-001423",
                nlScore: -0.25, sentiment: .negative, topic: .vacaciones,
                keywords: ["vacaciones", "negadas", "solicitud", "espera", "urgente"],
                ruta: "escalado", resuelta: false
            ),

            // — Legal ────────────────────────────────────────────────────────────
            ConversationAnalysis(
                id: UUID(), timestamp: ago(5), colaboradorID: "EMP-003812",
                nlScore: -0.52, sentiment: .negative, topic: .legal,
                keywords: ["contrato", "cláusula", "indefinido", "condiciones", "revisión"],
                ruta: "escalado", resuelta: false
            ),
            ConversationAnalysis(
                id: UUID(), timestamp: ago(12), colaboradorID: "EMP-001423",
                nlScore: 0.05, sentiment: .neutral, topic: .legal,
                keywords: ["contrato", "plazo", "renovación", "firma", "documento"],
                ruta: "sensible", resuelta: true
            ),

            // — Clima laboral ────────────────────────────────────────────────────
            ConversationAnalysis(
                id: UUID(), timestamp: ago(4), colaboradorID: "EMP-003812",
                nlScore: -0.61, sentiment: .negative, topic: .clima,
                keywords: ["ambiente", "equipo", "conflicto", "respeto", "queja"],
                ruta: "escalado", resuelta: false
            ),
            ConversationAnalysis(
                id: UUID(), timestamp: ago(10), colaboradorID: "EMP-001423",
                nlScore: 0.38, sentiment: .positive, topic: .clima,
                keywords: ["ambiente", "colaboración", "equipo", "proyecto", "bueno"],
                ruta: "simple", resuelta: true
            ),

            // — Beneficios ───────────────────────────────────────────────────────
            ConversationAnalysis(
                id: UUID(), timestamp: ago(7), colaboradorID: "EMP-001423",
                nlScore: 0.42, sentiment: .positive, topic: .beneficios,
                keywords: ["seguro", "médico", "familia", "inscripción", "beneficio"],
                ruta: "simple", resuelta: true
            ),
            ConversationAnalysis(
                id: UUID(), timestamp: ago(9), colaboradorID: "EMP-003812",
                nlScore: 0.08, sentiment: .neutral, topic: .beneficios,
                keywords: ["infonavit", "crédito", "descuento", "información", "saldo"],
                ruta: "sensible", resuelta: true
            ),

            // — Capacitación ─────────────────────────────────────────────────────
            ConversationAnalysis(
                id: UUID(), timestamp: ago(11), colaboradorID: "EMP-001423",
                nlScore: 0.60, sentiment: .positive, topic: .capacitacion,
                keywords: ["curso", "capacitación", "disponible", "inscribir", "aprender"],
                ruta: "simple", resuelta: true
            ),
            ConversationAnalysis(
                id: UUID(), timestamp: ago(13), colaboradorID: "EMP-003812",
                nlScore: 0.12, sentiment: .neutral, topic: .capacitacion,
                keywords: ["evaluación", "desempeño", "fecha", "resultado", "período"],
                ruta: "simple", resuelta: true
            ),
            ConversationAnalysis(
                id: UUID(), timestamp: ago(15), colaboradorID: "EMP-001423",
                nlScore: 0.35, sentiment: .positive, topic: .capacitacion,
                keywords: ["liderazgo", "programa", "talento", "desarrollo", "habilidad"],
                ruta: "simple", resuelta: true
            ),
        ]
    }()
}
