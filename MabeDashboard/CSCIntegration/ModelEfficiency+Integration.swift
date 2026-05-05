// ModelEfficiency+Integration.swift
// Extends ModelEfficiency to be constructible from backend data.
// Only needed if their ModelEfficiency.swift doesn't have this initializer.
// Check their Models/ModelEfficiency.swift — if it already has these fields, delete this file.

internal import Foundation

// If their ModelEfficiency looks different, adapt these field names to match.
// This is what LiveDashboardService expects:
//
// struct ModelEfficiency: Identifiable {
//     let id: UUID
//     let tier: ModelTier
//     let queryCount: Int
//     let averageResponseSeconds: Double
//     let resolutionRate: Double      // 0.0 – 1.0
//     let shareOfTotal: Double        // 0.0 – 1.0
// }
//
// If their fields are named differently, update LiveDashboardService accordingly.
