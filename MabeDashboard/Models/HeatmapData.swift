// HeatmapData.swift
// Model for the consultation heatmap grid (hour × day-of-week).

internal import Foundation

struct HeatmapCell: Identifiable, Equatable {
    let id: UUID
    /// Hour of day (6...22)
    let hour: Int
    /// Day of week: 0 = Monday, 6 = Sunday
    let dayOfWeek: Int
    let queryCount: Int

    init(id: UUID = UUID(), hour: Int, dayOfWeek: Int, queryCount: Int) {
        self.id = id
        self.hour = hour
        self.dayOfWeek = dayOfWeek
        self.queryCount = queryCount
    }

    var dayLabel: String {
        ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"][safe: dayOfWeek] ?? ""
    }

    var hourLabel: String {
        String(format: "%02d:00", hour)
    }
}

// MARK: — Collection safe subscript helper
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: — Mock Data
extension HeatmapCell {
    /// Generates realistic HR query volume for a standard work week.
    /// Peak hours are 9–11 am and 2–4 pm; weekends are low volume.
    static func mockData() -> [HeatmapCell] {
        var cells: [HeatmapCell] = []
        let hours = Array(6...22)
        let days = Array(0...6)

        // Weight matrix simulating typical office query patterns
        let peakHourWeight: (Int) -> Double = { hour in
            switch hour {
            case 9...11:  return 1.0
            case 14...16: return 0.85
            case 8:       return 0.5
            case 17:      return 0.4
            case 12...13: return 0.35
            case 7:       return 0.2
            case 18...19: return 0.15
            default:      return 0.05
            }
        }

        let dayWeight: (Int) -> Double = { day in
            switch day {
            case 0...4: return 1.0   // Mon–Fri
            case 5:     return 0.3   // Saturday
            case 6:     return 0.1   // Sunday
            default:    return 0
            }
        }

        for day in days {
            for hour in hours {
                let weight = peakHourWeight(hour) * dayWeight(day)
                let base = Int(weight * 40)
                // Add slight randomness for realism
                let noise = Int.random(in: -3...3)
                let count = max(0, base + noise)
                cells.append(HeatmapCell(hour: hour, dayOfWeek: day, queryCount: count))
            }
        }
        return cells
    }
}
