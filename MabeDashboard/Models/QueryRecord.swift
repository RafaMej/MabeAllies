// QueryRecord.swift
// Model representing a single employee HR query processed by the pipeline.

internal import Foundation

// MARK: — Supporting Enums

enum QueryCategory: String, CaseIterable, Identifiable, Codable {
    case nomina     = "Nómina"
    case vacaciones = "Vacaciones"
    case legal      = "Legal"
    case clima      = "Clima Laboral"
    case beneficios = "Beneficios"
    case capacitacion = "Capacitación"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .nomina:       return "banknote"
        case .vacaciones:   return "sun.max"
        case .legal:        return "doc.text"
        case .clima:        return "person.3"
        case .beneficios:   return "heart"
        case .capacitacion: return "book"
        }
    }
}

enum ModelTier: String, CaseIterable, Identifiable, Codable {
    case basic        = "LLM Básico"
    case intermediate = "LLM Intermedio"
    case hrAgent      = "Agente RRHH"

    var id: String { rawValue }
}

enum QueryStatus: String, CaseIterable, Identifiable, Codable {
    case resolved   = "Resuelto"
    case escalated  = "Escalado"
    case inProgress = "En Proceso"

    var id: String { rawValue }
}

enum SentimentScore: String, CaseIterable, Identifiable, Codable {
    case positive = "Positivo"
    case neutral  = "Neutral"
    case negative = "Negativo"

    var id: String { rawValue }
}

// MARK: — Main Model

struct QueryRecord: Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let category: QueryCategory
    let modelUsed: ModelTier
    let status: QueryStatus
    let sentiment: SentimentScore
    /// Whether PII has been stripped by DataAnonymizer
    let isAnonymized: Bool

    init(
        id: UUID = UUID(),
        timestamp: Date,
        category: QueryCategory,
        modelUsed: ModelTier,
        status: QueryStatus,
        sentiment: SentimentScore,
        isAnonymized: Bool = true
    ) {
        self.id = id
        self.timestamp = timestamp
        self.category = category
        self.modelUsed = modelUsed
        self.status = status
        self.sentiment = sentiment
        self.isAnonymized = isAnonymized
    }
}

// MARK: — Mock Data
extension QueryRecord {
    static let mockData: [QueryRecord] = {
        let calendar = Calendar.current
        let now = Date()
        func hoursAgo(_ h: Int) -> Date { calendar.date(byAdding: .hour, value: -h, to: now) ?? now }

        return [
            QueryRecord(timestamp: hoursAgo(0),  category: .nomina,      modelUsed: .basic,        status: .resolved,   sentiment: .positive),
            QueryRecord(timestamp: hoursAgo(1),  category: .vacaciones,  modelUsed: .intermediate, status: .resolved,   sentiment: .neutral),
            QueryRecord(timestamp: hoursAgo(1),  category: .legal,       modelUsed: .hrAgent,      status: .escalated,  sentiment: .negative),
            QueryRecord(timestamp: hoursAgo(2),  category: .clima,       modelUsed: .basic,        status: .resolved,   sentiment: .positive),
            QueryRecord(timestamp: hoursAgo(2),  category: .beneficios,  modelUsed: .intermediate, status: .inProgress, sentiment: .neutral),
            QueryRecord(timestamp: hoursAgo(3),  category: .nomina,      modelUsed: .basic,        status: .resolved,   sentiment: .positive),
            QueryRecord(timestamp: hoursAgo(4),  category: .capacitacion,modelUsed: .basic,        status: .resolved,   sentiment: .positive),
            QueryRecord(timestamp: hoursAgo(5),  category: .vacaciones,  modelUsed: .intermediate, status: .escalated,  sentiment: .negative),
            QueryRecord(timestamp: hoursAgo(6),  category: .legal,       modelUsed: .hrAgent,      status: .resolved,   sentiment: .neutral),
            QueryRecord(timestamp: hoursAgo(8),  category: .nomina,      modelUsed: .basic,        status: .resolved,   sentiment: .positive),
            QueryRecord(timestamp: hoursAgo(10), category: .clima,       modelUsed: .intermediate, status: .inProgress, sentiment: .neutral),
            QueryRecord(timestamp: hoursAgo(12), category: .beneficios,  modelUsed: .hrAgent,      status: .resolved,   sentiment: .positive),
        ]
    }()
}
