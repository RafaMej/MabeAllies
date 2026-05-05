// SentimentData.swift
// Model for sentiment trend area chart data points.

internal import Foundation

enum SentimentCategory: String, CaseIterable, Identifiable, Codable {
    case positive = "Positivo"
    case neutral  = "Neutral"
    case negative = "Negativo"

    var id: String { rawValue }

    var sortOrder: Int {
        switch self {
        case .positive: return 0
        case .neutral:  return 1
        case .negative: return 2
        }
    }
}

struct SentimentDataPoint: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let sentiment: SentimentCategory
    let percentage: Double

    init(id: UUID = UUID(), date: Date, sentiment: SentimentCategory, percentage: Double) {
        self.id = id
        self.date = date
        self.sentiment = sentiment
        self.percentage = percentage
    }
}

struct SentimentAnnotation: Identifiable {
    let id: UUID
    let date: Date
    let label: String

    init(id: UUID = UUID(), date: Date, label: String) {
        self.id = id
        self.date = date
        self.label = label
    }
}

// MARK: — Mock Data
extension SentimentDataPoint {
    static func mockData() -> [SentimentDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        func daysAgo(_ d: Int) -> Date { calendar.date(byAdding: .day, value: -d, to: now) ?? now }

        // Raw distribution per day — 30 days back
        let rawData: [(daysAgo: Int, positive: Double, neutral: Double, negative: Double)] = [
            (30, 55, 30, 15), (28, 57, 28, 15), (26, 52, 32, 16), (24, 48, 34, 18),
            (22, 45, 35, 20), (20, 50, 33, 17), (18, 60, 27, 13), (16, 63, 25, 12),
            (14, 58, 28, 14), (12, 55, 30, 15), (10, 62, 25, 13), (8,  65, 24, 11),
            (6,  61, 26, 13), (4,  64, 25, 11), (2,  68, 22, 10), (0,  70, 21,  9)
        ]

        var points: [SentimentDataPoint] = []
        for row in rawData {
            let date = daysAgo(row.daysAgo)
            points.append(SentimentDataPoint(date: date, sentiment: .positive, percentage: row.positive))
            points.append(SentimentDataPoint(date: date, sentiment: .neutral,  percentage: row.neutral))
            points.append(SentimentDataPoint(date: date, sentiment: .negative, percentage: row.negative))
        }
        return points
    }
}

extension SentimentAnnotation {
    static let mockAnnotations: [SentimentAnnotation] = {
        let calendar = Calendar.current
        let now = Date()
        func daysAgo(_ d: Int) -> Date { calendar.date(byAdding: .day, value: -d, to: now) ?? now }
        return [
            SentimentAnnotation(date: daysAgo(22), label: "Cierre Nómina"),
            SentimentAnnotation(date: daysAgo(10), label: "Inicio Vacaciones"),
        ]
    }()
}
