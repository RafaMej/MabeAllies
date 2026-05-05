// DashboardService.swift
// Protocol defining the dashboard data contract.
// Provides MockDashboardService (preview/development) and LiveDashboardService stub (production).

internal import Foundation
internal import Combine

// MARK: — Protocol

protocol DashboardServiceProtocol {
    func fetchKPIs() async throws -> [KPIMetric]
    func fetchHeatmapData(range: DateInterval) async throws -> [HeatmapCell]
    func fetchSentimentTrend(range: DateInterval) async throws -> [SentimentDataPoint]
    func fetchRecentQueries(limit: Int) async throws -> [QueryRecord]
    func fetchModelEfficiency() async throws -> [ModelEfficiency]
}

// MARK: — Mock Service (Development / Previews)

final class MockDashboardService: DashboardServiceProtocol {

    private let simulatedLatency: TimeInterval

    init(simulatedLatency: TimeInterval = 0.3) {
        self.simulatedLatency = simulatedLatency
    }

    func fetchKPIs() async throws -> [KPIMetric] {
        try await Task.sleep(nanoseconds: UInt64(simulatedLatency * 1_000_000_000))
        return KPIMetric.mockData
    }

    func fetchHeatmapData(range: DateInterval) async throws -> [HeatmapCell] {
        try await Task.sleep(nanoseconds: UInt64(simulatedLatency * 1_000_000_000))
        return HeatmapCell.mockData()
    }

    func fetchSentimentTrend(range: DateInterval) async throws -> [SentimentDataPoint] {
        try await Task.sleep(nanoseconds: UInt64(simulatedLatency * 1_000_000_000))
        return SentimentDataPoint.mockData()
    }

    func fetchRecentQueries(limit: Int) async throws -> [QueryRecord] {
        try await Task.sleep(nanoseconds: UInt64(simulatedLatency * 1_000_000_000))
        return Array(QueryRecord.mockData.prefix(limit))
    }

    func fetchModelEfficiency() async throws -> [ModelEfficiency] {
        try await Task.sleep(nanoseconds: UInt64(simulatedLatency * 1_000_000_000))
        return ModelEfficiency.mockData
    }
}

