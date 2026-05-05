// DashboardViewModel.swift
// Primary ViewModel driving the Dashboard tab.
// Uses Combine Timer for periodic refresh and async/await for data fetching.

internal import Foundation
internal import Combine
internal import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {

    // MARK: — Published State

    @Published var kpis: [KPIMetric] = []
    @Published var heatmapCells: [HeatmapCell] = []
    @Published var sentimentPoints: [SentimentDataPoint] = []
    @Published var recentQueries: [QueryRecord] = []
    @Published var modelEfficiency: [ModelEfficiency] = []
    @Published var totalConsultations: Int = 0

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var lastUpdated: Date = Date()

    /// Selected date range filter — "Últimos 30 días" by default
    @Published var selectedRange: DateRangeFilter = .last30Days

    // MARK: — Private

    private let service: DashboardServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let refreshInterval: TimeInterval = 30

    // MARK: — Init

    init(service: DashboardServiceProtocol) {
        self.service = service
        setupAutoRefresh()
    }

    // MARK: — Setup

    private func setupAutoRefresh() {
        // INTEGRATION POINT: Replace Timer.publish with WebSocket or SSE publisher
        // for true real-time updates when backend supports it.
        Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.loadAll() }
            }
            .store(in: &cancellables)

        // Initial load
        Task { await loadAll() }
    }

    // MARK: — Data Loading

    func loadAll() async {
        isLoading = true
        errorMessage = nil

        let range = selectedRange.dateInterval

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadKPIs() }
            group.addTask { await self.loadHeatmap(range: range) }
            group.addTask { await self.loadSentiment(range: range) }
            group.addTask { await self.loadQueries() }
            group.addTask { await self.loadModelEfficiency() }
        }

        isLoading = false
        lastUpdated = Date()
    }

    private func loadKPIs() async {
        do {
            kpis = try await service.fetchKPIs()
        } catch {
            handleError(error, context: "KPIs")
        }
    }

    private func loadHeatmap(range: DateInterval) async {
        do {
            heatmapCells = try await service.fetchHeatmapData(range: range)
        } catch {
            handleError(error, context: "Heatmap")
        }
    }

    private func loadSentiment(range: DateInterval) async {
        do {
            sentimentPoints = try await service.fetchSentimentTrend(range: range)
        } catch {
            handleError(error, context: "Sentimiento")
        }
    }

    private func loadQueries() async {
        do {
            let raw = try await service.fetchRecentQueries(limit: 50)
            // INTEGRATION POINT: DataAnonymizer runs on every record before display
            recentQueries = raw.map { DataAnonymizer.anonymize($0) }
        } catch {
            handleError(error, context: "Consultas")
        }
    }

    private func loadModelEfficiency() async {
        do {
            let data = try await service.fetchModelEfficiency()
            modelEfficiency = data
            totalConsultations = data.reduce(0) { $0 + $1.consultationCount }
        } catch {
            handleError(error, context: "Eficiencia del Modelo")
        }
    }

    private func handleError(_ error: Error, context: String) {
        // Only surface error if not a cancellation
        if !(error is CancellationError) {
            errorMessage = "Error al cargar \(context): \(error.localizedDescription)"
        }
    }

    // MARK: — Formatted Last Updated

    var lastUpdatedLabel: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.unitsStyle = .full
        return "Actualizado \(formatter.localizedString(for: lastUpdated, relativeTo: Date()))"
    }
}

// MARK: — Date Range Filter

enum DateRangeFilter: String, CaseIterable, Identifiable {
    case last7Days  = "Últimos 7 días"
    case last30Days = "Últimos 30 días"
    case last90Days = "Últimos 90 días"

    var id: String { rawValue }

    var dateInterval: DateInterval {
        let now = Date()
        let calendar = Calendar.current
        switch self {
        case .last7Days:
            return DateInterval(start: calendar.date(byAdding: .day, value: -7, to: now)!, end: now)
        case .last30Days:
            return DateInterval(start: calendar.date(byAdding: .day, value: -30, to: now)!, end: now)
        case .last90Days:
            return DateInterval(start: calendar.date(byAdding: .day, value: -90, to: now)!, end: now)
        }
    }
}
