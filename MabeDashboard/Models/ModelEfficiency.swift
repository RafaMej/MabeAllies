// ModelEfficiency.swift
// Model for the donut chart showing query distribution across ML model tiers.

internal import Foundation
internal import SwiftUI

struct ModelEfficiency: Identifiable, Equatable {
    let id: UUID
    let modelName: String
    let percentage: Double
    let color: Color
    /// Absolute number of consultations (for center label)
    let consultationCount: Int

    init(id: UUID = UUID(), modelName: String, percentage: Double, color: Color, consultationCount: Int) {
        self.id = id
        self.modelName = modelName
        self.percentage = percentage
        self.color = color
        self.consultationCount = consultationCount
    }
}

// MARK: — Mock Data
extension ModelEfficiency {
    static let mockData: [ModelEfficiency] = [
        ModelEfficiency(
            modelName: "LLM Básico",
            percentage: 58,
            color: Color.NexusHR.chartTeal,
            consultationCount: 897
        ),
        ModelEfficiency(
            modelName: "LLM Intermedio",
            percentage: 32,
            color: Color.NexusHR.chartBlue,
            consultationCount: 495
        ),
        ModelEfficiency(
            modelName: "Agente RRHH",
            percentage: 10,
            color: Color.NexusHR.chartSlate,
            consultationCount: 155
        )
    ]

    /// Total consultation count across all tiers
    static var mockTotalConsultations: Int {
        mockData.reduce(0) { $0 + $1.consultationCount }
    }
}
