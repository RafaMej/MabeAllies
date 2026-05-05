// KPIMetric.swift
// Model representing a single KPI card metric shown in the dashboard header row.

internal import Foundation

struct KPIMetric: Identifiable, Equatable {
    let id: UUID
    let title: String
    let value: String
    /// Percentage change — positive values indicate growth, negative indicate decline
    let trend: Double
    /// When true, renders a pulsing live indicator instead of trend badge
    let isLive: Bool
    /// SF Symbol name for the card icon
    let icon: String

    init(
        id: UUID = UUID(),
        title: String,
        value: String,
        trend: Double,
        isLive: Bool = false,
        icon: String
    ) {
        self.id = id
        self.title = title
        self.value = value
        self.trend = trend
        self.isLive = isLive
        self.icon = icon
    }
}

// MARK: — Mock Data
extension KPIMetric {
    static let mockData: [KPIMetric] = [
        KPIMetric(
            title: "Tickets Evitados",
            value: "1,284",
            trend: 12.0,
            icon: "ticket.fill"
        ),
        KPIMetric(
            title: "Horas Ahorradas",
            value: "342 hrs",
            trend: 8.0,
            icon: "clock.fill"
        ),
        KPIMetric(
            title: "Resolución Automática",
            value: "87%",
            trend: 3.0,
            icon: "cpu.fill"
        ),
        KPIMetric(
            title: "Consultas Activas",
            value: "23",
            trend: 0.0,
            isLive: true,
            icon: "message.fill"
        )
    ]
}
