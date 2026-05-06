// SentimentViewModel.swift
// Drives the Sentimiento tab.
//
// Data flow:
//   SwiftData (ConversacionLog) → SentimentAnalysisEngine → published state → SentimientoView
//
// When no real logs exist yet (e.g. fresh install before using the Simulator),
// the VM falls back to ConversationAnalysis.mockSeed so the view always renders.
//
// INTEGRATION POINT: Replace load(container:) with a WebSocket/SSE publisher when
// the backend supports real-time sentiment streaming.

internal import Foundation
internal import Combine
internal import SwiftUI
internal import SwiftData

@MainActor
final class SentimentViewModel: ObservableObject {

    // MARK: — Published State

    /// Time-series data points consumed by SentimentAreaChart.
    @Published var dataPoints: [SentimentDataPoint] = []
    /// Annotation markers (cierre de nómina, inicio de vacaciones, etc.) for SentimentAreaChart.
    @Published var annotations: [SentimentAnnotation] = SentimentAnnotation.mockAnnotations
    /// Per-conversation analysis results, sorted newest first.
    @Published var analyses: [ConversationAnalysis] = []
    /// Top-40 keywords aggregated across all analyses, sorted by frequency descending.
    @Published var aggregatedKeywords: [KeywordEntry] = []
    /// Conversation count per QueryCategory, sorted by count descending.
    @Published var topicDistribution: [TopicCount] = []
    /// Currently selected date window; changing it triggers a reload.
    @Published var selectedRange: DateRangeFilter = .last30Days
    @Published var isLoading = false
    /// True when mock seed data is shown instead of real SwiftData records.
    @Published var isMockData = false

    // MARK: — Derived metrics

    /// Weighted average NL score across all analyses. Falls back to a realistic default.
    var overallSentimentScore: Double {
        guard !analyses.isEmpty else { return 0.70 }
        return analyses.map(\.nlScore).reduce(0, +) / Double(analyses.count)
    }

    var positivePercentage: Double { sentimentPct(for: .positive) }
    var negativePercentage: Double { sentimentPct(for: .negative) }
    var neutralPercentage:  Double { sentimentPct(for: .neutral)  }

    // MARK: — Private

    private let engine = SentimentAnalysisEngine()

    // MARK: — Data loading

    /// Fetches ConversacionLog records for the selected date range, runs NLP analysis,
    /// and populates all published properties.
    /// Call this from a .task modifier, passing modelContext.container.
    func load(container: ModelContainer) async {
        isLoading = true
        defer { isLoading = false }

        let context = ModelContext(container)
        let range   = selectedRange.dateInterval

        do {
            let descriptor = FetchDescriptor<ConversacionLog>(
                predicate: #Predicate {
                    $0.timestamp >= range.start && $0.timestamp <= range.end
                },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            let logs = try context.fetch(descriptor)

            if logs.isEmpty {
                isMockData = true
                analyses   = ConversationAnalysis.mockSeed
            } else {
                isMockData = false
                // NLTagger is CPU-bound; offload to avoid blocking the main thread.
                let engine = self.engine
                analyses = await Task.detached(priority: .userInitiated) {
                    logs.map { engine.analyze(log: $0) }
                }.value
            }
        } catch {
            // Silent fallback — surface error only in debug builds.
            assert(false, "[SentimentViewModel] Fetch failed: \(error)")
            isMockData = true
            analyses   = ConversationAnalysis.mockSeed
        }

        aggregatedKeywords = engine.aggregateKeywords(from: analyses)
        topicDistribution  = engine.topicDistribution(from: analyses)
        dataPoints         = buildTrendPoints(from: analyses)
    }

    // MARK: — Private helpers

    private func sentimentPct(for score: SentimentScore) -> Double {
        guard !analyses.isEmpty else {
            // Matches the mock seed distribution
            switch score {
            case .positive: return 71.4
            case .neutral:  return 14.3
            case .negative: return 14.3
            }
        }
        let count = analyses.filter { $0.sentiment == score }.count
        return (Double(count) / Double(analyses.count)) * 100
    }

    /// Converts per-analysis NL results into [SentimentDataPoint] grouped by calendar day.
    /// This feeds the existing SentimentAreaChart without any changes to that component.
    private func buildTrendPoints(from analyses: [ConversationAnalysis]) -> [SentimentDataPoint] {
        guard !analyses.isEmpty else { return SentimentDataPoint.mockData() }

        let calendar = Calendar.current
        var byDay: [Date: [ConversationAnalysis]] = [:]
        for a in analyses {
            let day = calendar.startOfDay(for: a.timestamp)
            byDay[day, default: []].append(a)
        }

        return byDay.keys.sorted().flatMap { day -> [SentimentDataPoint] in
            let group = byDay[day]!
            let total = Double(group.count)
            func pct(_ s: SentimentScore) -> Double {
                (Double(group.filter { $0.sentiment == s }.count) / total) * 100
            }
            return [
                SentimentDataPoint(date: day, sentiment: .positive, percentage: pct(.positive)),
                SentimentDataPoint(date: day, sentiment: .neutral,  percentage: pct(.neutral)),
                SentimentDataPoint(date: day, sentiment: .negative, percentage: pct(.negative)),
            ]
        }
    }
}
