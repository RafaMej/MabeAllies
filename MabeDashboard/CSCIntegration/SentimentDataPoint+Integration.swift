// SentimentDataPoint+Integration.swift
// Extends SentimentDataPoint to be constructible from backend data.
// Only needed if their SentimentData.swift doesn't have this initializer.
// Check their Models/SentimentData.swift — if it already has these fields, delete this file.

internal import Foundation

// If their SentimentDataPoint looks different, adapt these field names to match.
// This is what LiveDashboardService expects:
//
// struct SentimentDataPoint: Identifiable {
//     let id: UUID
//     let date: Date
//     let sentiment: SentimentScore
//     let count: Int
// }
//
// If their fields are named differently, update LiveDashboardService accordingly.
