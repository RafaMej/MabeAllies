// MLOrchestrator.swift
// ML Pipeline Coordinator — integration-ready stub.
// Wire your CoreML models or LLM API clients in the marked INTEGRATION POINT sections.

internal import Foundation

// MARK: — Supporting Context Type

struct QueryContext {
    let previousInteractions: Int
    let employeeRiskLevel: RiskLevel
    let category: QueryCategory

    enum RiskLevel: String {
        case low, medium, high
    }
}

// MARK: — Protocol

protocol MLOrchestratorProtocol {
    /// Classify an incoming query into an HR category.
    func classify(query: String) async throws -> QueryCategory

    /// Route classified query to the appropriate model tier.
    func routeToModel(query: String, category: QueryCategory) async throws -> ModelTier

    /// Analyze the sentiment of a piece of text.
    func analyzeSentiment(text: String) async throws -> SentimentScore

    /// Determine if a query should be escalated to a human HR agent.
    func shouldEscalateToHuman(query: String, context: QueryContext) async throws -> Bool
}

// MARK: — Concrete Implementation

final class MLOrchestrator: MLOrchestratorProtocol {

    // INTEGRATION POINT: Inject your small/fast CoreML classification model
    private var basicLLM: Any?

    // INTEGRATION POINT: Inject your RAG-capable intermediate LLM (e.g. via API or CoreML)
    private var intermediateLLM: Any?

    // INTEGRATION POINT: Inject your intent clustering / classification model
    private var classifier: Any?

    // INTEGRATION POINT: Inject your sentiment analysis model (CoreML or API-backed)
    private var sentimentModel: Any?

    // INTEGRATION POINT: Configure confidence thresholds per environment
    private let escalationThreshold: Double = 0.75
    private let basicLLMConfidenceThreshold: Double = 0.85

    // MARK: — Classify

    func classify(query: String) async throws -> QueryCategory {
        // INTEGRATION POINT: Run query through `classifier` CoreML model.
        // Expected output: predicted label matching QueryCategory.rawValue
        // Example CoreML usage:
        //   let input = MyClassifierInput(text: query)
        //   let output = try classifier.prediction(input: input)
        //   return QueryCategory(rawValue: output.label) ?? .clima

        // Mock: keyword-based routing for development
        let lowercased = query.lowercased()
        if lowercased.contains("pago") || lowercased.contains("sueldo") || lowercased.contains("nómina") {
            return .nomina
        } else if lowercased.contains("vacacion") || lowercased.contains("descanso") {
            return .vacaciones
        } else if lowercased.contains("contrato") || lowercased.contains("legal") {
            return .legal
        } else if lowercased.contains("equipo") || lowercased.contains("ambiente") {
            return .clima
        } else if lowercased.contains("beneficio") || lowercased.contains("seguro") {
            return .beneficios
        } else {
            return .capacitacion
        }
    }

    // MARK: — Route

    func routeToModel(query: String, category: QueryCategory) async throws -> ModelTier {
        // INTEGRATION POINT: Use a routing policy (rule-based or learned) to select model tier.
        // Consider: query complexity, category criticality, current model load.

        switch category {
        case .legal:
            return .hrAgent         // Legal queries always go to full agent
        case .nomina, .beneficios:
            return .intermediate    // Financial topics need RAG context
        default:
            return .basic           // General queries served by fast LLM
        }
    }

    // MARK: — Sentiment

    func analyzeSentiment(text: String) async throws -> SentimentScore {
        // INTEGRATION POINT: Run text through `sentimentModel` CoreML NLModel.
        // Example:
        //   let tagger = NLTagger(tagSchemes: [.sentimentScore])
        //   tagger.string = text
        //   let (tag, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        //   let score = Double(tag?.rawValue ?? "0") ?? 0
        //   return score > 0.2 ? .positive : score < -0.2 ? .negative : .neutral

        // Mock: random with realistic distribution
        let roll = Double.random(in: 0...1)
        if roll < 0.60 { return .positive }
        else if roll < 0.85 { return .neutral }
        else { return .negative }
    }

    // MARK: — Escalation

    func shouldEscalateToHuman(query: String, context: QueryContext) async throws -> Bool {
        // INTEGRATION POINT: Implement escalation logic combining:
        //   - Model confidence score (if below threshold → escalate)
        //   - Employee risk level from context
        //   - Category (legal / alta-sensibilidad → always offer escalation)
        //   - Negative sentiment detected

        if context.category == .legal { return true }
        if context.employeeRiskLevel == .high { return true }
        return false
    }
}
