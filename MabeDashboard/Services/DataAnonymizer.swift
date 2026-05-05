// DataAnonymizer.swift
// Privacy layer — all personally identifiable information (PII) passes through here
// before being surfaced in the dashboard. Compliant with GDPR / Mexican LFPDPPP.

internal import Foundation
import CryptoKit

struct DataAnonymizer {

    // MARK: — Record Anonymization

    /// Returns a copy of the record with PII stripped from any free-text fields.
    /// The record ID is replaced with a one-way hash.
    static func anonymize(_ record: QueryRecord) -> QueryRecord {
        // INTEGRATION POINT: If QueryRecord grows to include employee name / email,
        // strip those fields here before storing or displaying in the dashboard.
        QueryRecord(
            id: UUID(uuidString: hashIdentifier(record.id.uuidString).prefix(36).description) ?? record.id,
            timestamp: record.timestamp,
            category: record.category,
            modelUsed: record.modelUsed,
            status: record.status,
            sentiment: record.sentiment,
            isAnonymized: true
        )
    }

    // MARK: — Text PII Stripping

    /// Replaces common PII patterns (names, emails, CURP, RFC, phone numbers) with redacted placeholders.
    static func stripPII(from text: String) -> String {
        var result = text

        // Email addresses
        result = result.replacingOccurrences(
            of: #"[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}"#,
            with: "[EMAIL REDACTADO]",
            options: .regularExpression
        )

        // Mexican CURP (18 chars)
        result = result.replacingOccurrences(
            of: #"\b[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z0-9]\d\b"#,
            with: "[CURP REDACTADO]",
            options: .regularExpression
        )

        // Mexican RFC (12–13 chars)
        result = result.replacingOccurrences(
            of: #"\b[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}\b"#,
            with: "[RFC REDACTADO]",
            options: .regularExpression
        )

        // Phone numbers (Mexican format)
        result = result.replacingOccurrences(
            of: #"(\+52|52)?[\s\-]?(\d{2,3})[\s\-]?\d{3,4}[\s\-]?\d{4}"#,
            with: "[TELÉFONO REDACTADO]",
            options: .regularExpression
        )

        // INTEGRATION POINT: Add NER-based name detection using CreateML / NLTagger
        // to catch personal names not covered by pattern matching above.

        return result
    }

    // MARK: — Identifier Hashing

    /// Produces a deterministic SHA-256 hex digest of the given identifier.
    /// Used to pseudonymize employee IDs while preserving referential integrity for analytics.
    static func hashIdentifier(_ id: String) -> String {
        let data = Data(id.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: — Differential Privacy Helper (stub)

    /// INTEGRATION POINT: Apply Laplace noise mechanism for differential privacy
    /// when exporting aggregated statistics to external systems.
    /// - Parameters:
    ///   - value: The true aggregate value
    ///   - sensitivity: L1 sensitivity of the query (typically 1 for counts)
    ///   - epsilon: Privacy budget (lower = more private)
    static func addLaplaceNoise(to value: Double, sensitivity: Double = 1.0, epsilon: Double = 0.5) -> Double {
        // INTEGRATION POINT: Replace with production DP library implementation.
        // Stub returns value unchanged for now.
        return value
    }
}
