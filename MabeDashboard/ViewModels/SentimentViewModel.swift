// SentimentViewModel.swift
// ViewModel for the Sentimiento tab (future expansion).
// INTEGRATION POINT: Connect to real-time sentiment stream from backend.

internal import Foundation
internal import Combine
internal import SwiftUI

@MainActor
final class SentimentViewModel: ObservableObject {

    // MARK: — Published State

    @Published var dataPoints: [SentimentDataPoint] = []
    @Published var annotations: [SentimentAnnotation] = SentimentAnnotation.mockAnnotations
    @Published var overallSentimentScore: Double = 0.70   // 0..1, 1 = fully positive
    @Published var isLoading: Bool = false

    // MARK: — Combine

    // INTEGRATION POINT: Replace with AnyPublisher<[SentimentDataPoint], Never> from your
    // WebSocket / SSE stream for real-time sentiment updates.
    var dataPublisher: AnyPublisher<[SentimentDataPoint], Never> {
        Just(SentimentDataPoint.mockData()).eraseToAnyPublisher()
    }

    private var cancellables = Set<AnyCancellable>()

    init() {
        dataPublisher
            .receive(on: RunLoop.main)
            .assign(to: \.dataPoints, on: self)
            .store(in: &cancellables)
    }

    // MARK: — Derived

    var positivePercentage: Double {
        latestSentiment(for: .positive)
    }

    var negativePercentage: Double {
        latestSentiment(for: .negative)
    }

    var neutralPercentage: Double {
        latestSentiment(for: .neutral)
    }

    private func latestSentiment(for category: SentimentCategory) -> Double {
        dataPoints
            .filter { $0.sentiment == category }
            .max(by: { $0.date < $1.date })?
            .percentage ?? 0
    }
}
