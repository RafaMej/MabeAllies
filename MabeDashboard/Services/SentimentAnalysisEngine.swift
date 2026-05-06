// SentimentAnalysisEngine.swift
// On-device NLP pipeline for HR conversation analysis.
//
// Two capabilities:
//   1. Sentiment scoring   — NLTagger(.sentimentScore), returns -1.0…+1.0
//   2. Keyword extraction  — NLTagger(.lexicalClass + .lemma), filters content words
//
// No network required. Works fully offline on any device with NaturalLanguage support.
// Language hint is set to Spanish (.spanish) to improve accuracy for MABE's corpus.

internal import Foundation
internal import NaturalLanguage

final class SentimentAnalysisEngine {

    // MARK: — Sentiment scoring

    /// Scores a block of text on the range [-1.0, +1.0].
    /// Positive values indicate positive sentiment; negative values indicate negative sentiment.
    /// Uses Apple's on-device NLTagger with the .sentimentScore scheme.
    func sentimentScore(for text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        tagger.setLanguage(.spanish, range: text.startIndex..<text.endIndex)
        let (tag, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        return Double(tag?.rawValue ?? "0") ?? 0.0
    }

    /// Maps a raw NLTagger score to a discrete SentimentScore bucket.
    ///
    /// Thresholds chosen empirically for Spanish HR text:
    ///   > +0.10 → positive  (clear satisfaction / resolution)
    ///   < -0.10 → negative  (frustration / complaint)
    ///   otherwise → neutral
    func sentimentCategory(from score: Double) -> SentimentScore {
        if score >  0.10 { return .positive }
        if score < -0.10 { return .negative }
        return .neutral
    }

    // MARK: — Keyword extraction

    /// Spanish stopwords filtered out before keyword aggregation.
    /// Keeps the cloud focused on domain-relevant HR terms.
    private static let stopwords: Set<String> = [
        "para", "como", "este", "esta", "esto", "esos", "esas", "ellos", "ellas",
        "pero", "porque", "aunque", "cuando", "donde", "quién", "cuál", "cuáles",
        "más", "también", "solo", "cada", "todo", "toda", "todos", "todas",
        "puede", "poder", "tener", "hacer", "decir", "haber", "estar", "deber",
        "algo", "mucho", "poco", "bien", "mal", "aquí", "allí", "ahora", "antes",
        "favor", "gracias", "buenas", "hola", "sobre", "desde", "hasta", "entre",
        "mediante", "respecto", "dicho", "mismo", "misma", "otros", "otras",
        "quiero", "necesito", "quisiera", "saber", "información", "pregunta",
        "ayuda", "podría", "puedes", "tiene", "tiene", "tengo", "tenía",
    ]

    /// Extracts content-bearing words (nouns, verbs, adjectives) from a text string.
    /// Uses NLTagger lemmatization to normalize inflected Spanish forms
    /// (e.g. "vacaciones" and "vacacionar" → "vacacion").
    ///
    /// - Returns: Lowercase lemmas/tokens, filtered to content words ≥ 4 characters.
    func extractKeywords(from text: String) -> [String] {
        var keywords: [String] = []

        let tagger = NLTagger(tagSchemes: [.lexicalClass, .lemma])
        tagger.string = text
        tagger.setLanguage(.spanish, range: text.startIndex..<text.endIndex)

        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther]

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: options
        ) { lexTag, tokenRange in
            guard let lexTag,
                  [NLTag.noun, .verb, .adjective].contains(lexTag)
            else { return true }

            let token = String(text[tokenRange])
            guard token.count >= 4 else { return true }

            // Prefer the lemma form; fall back to the raw token
            let (lemmaTag, _) = tagger.tag(at: tokenRange.lowerBound, unit: .word, scheme: .lemma)
            let keyword = (lemmaTag?.rawValue ?? token).lowercased()

            guard !Self.stopwords.contains(keyword) else { return true }
            keywords.append(keyword)
            return true
        }

        return keywords
    }

    // MARK: — Full conversation analysis

    /// Produces a ConversationAnalysis from a persisted ConversacionLog entry.
    /// Runs NLTagger on the combined employee input + agent response for a richer signal,
    /// but extracts keywords only from the employee's message to reflect intent.
    func analyze(log: ConversacionLog) -> ConversationAnalysis {
        let combinedText = "\(log.mensajeEntrada) \(log.respuestaAgente)"
        let score       = sentimentScore(for: combinedText)
        let sentiment   = sentimentCategory(from: score)
        let keywords    = extractKeywords(from: log.mensajeEntrada)
        let topic       = inferTopic(from: keywords, ruta: log.modo)

        return ConversationAnalysis(
            id: log.id,
            timestamp: log.timestamp,
            colaboradorID: log.colaboradorID,
            nlScore: score,
            sentiment: sentiment,
            topic: topic,
            keywords: keywords,
            ruta: log.modo,
            resuelta: log.resuelta
        )
    }

    // MARK: — Aggregation helpers

    /// Aggregates per-conversation keywords into a frequency-sorted list capped at 40 entries.
    /// Each entry carries the dominant sentiment of conversations the word appeared in.
    func aggregateKeywords(from analyses: [ConversationAnalysis]) -> [KeywordEntry] {
        var frequency: [String: Int] = [:]
        var sentimentVotes: [String: [SentimentScore]] = [:]

        for analysis in analyses {
            for word in analysis.keywords {
                frequency[word, default: 0] += 1
                sentimentVotes[word, default: []].append(analysis.sentiment)
            }
        }

        return frequency
            .map { word, count -> KeywordEntry in
                let dominant = dominantSentiment(sentimentVotes[word] ?? [])
                return KeywordEntry(word: word, frequency: count, dominantSentiment: dominant)
            }
            .sorted { $0.frequency > $1.frequency }
            .prefix(40)
            .map { $0 }
    }

    /// Returns sorted topic counts across all analyses, omitting topics with 0 conversations.
    func topicDistribution(from analyses: [ConversationAnalysis]) -> [TopicCount] {
        var counts: [QueryCategory: Int] = [:]
        for analysis in analyses { counts[analysis.topic, default: 0] += 1 }
        return QueryCategory.allCases
            .compactMap { cat -> TopicCount? in
                guard let count = counts[cat], count > 0 else { return nil }
                return TopicCount(category: cat, count: count)
            }
            .sorted { $0.count > $1.count }
    }

    // MARK: — Private helpers

    /// Maps extracted keywords + pipeline route to a QueryCategory.
    /// Escalated conversations default to .legal as the most common escalation driver.
    private func inferTopic(from keywords: [String], ruta: String) -> QueryCategory {
        if ruta == RutaAgente.escalar.rawValue { return .legal }

        let joined = keywords.joined(separator: " ")
        let rules: [(words: [String], category: QueryCategory)] = [
            (["nómin", "sueldo", "salario", "bono", "pago", "depósito", "descuento", "quincena"], .nomina),
            (["vacacion", "descanso", "permiso", "libre"],                                        .vacaciones),
            (["contrato", "legal", "demanda", "sindicat", "cláusula", "denuncia"],                .legal),
            (["seguro", "infonavit", "beneficio", "médico", "crédito"],                           .beneficios),
            (["capaci", "curso", "formación", "evaluación", "desempeño", "talento"],              .capacitacion),
            (["ambiente", "equipo", "clima", "conflicto", "respeto"],                             .clima),
        ]

        for rule in rules {
            if rule.words.contains(where: { joined.contains($0) }) { return rule.category }
        }
        return .capacitacion
    }

    /// Returns the most frequently occurring SentimentScore in a list of votes.
    private func dominantSentiment(_ votes: [SentimentScore]) -> SentimentScore {
        guard !votes.isEmpty else { return .neutral }
        let counts = Dictionary(grouping: votes, by: { $0 }).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key ?? .neutral
    }
}
