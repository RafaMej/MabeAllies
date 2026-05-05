// StatusBadge.swift
// Colored rounded rectangle badge for query status and sentiment display.
// Color is never used as the sole differentiator — text label always present.

internal import SwiftUI

struct StatusBadge: View {
    let label: String
    let color: Color
    let textColor: Color

    init(label: String, color: Color, textColor: Color = .white) {
        self.label = label
        self.color = color
        self.textColor = textColor
    }

    // MARK: — Convenience Inits

    static func forStatus(_ status: QueryStatus) -> StatusBadge {
        switch status {
        case .resolved:
            return StatusBadge(label: status.rawValue, color: Color.NexusHR.statusPositive)
        case .escalated:
            return StatusBadge(label: status.rawValue, color: Color.NexusHR.statusNegative)
        case .inProgress:
            return StatusBadge(label: status.rawValue, color: Color.NexusHR.statusNeutral)
        }
    }

    static func forSentiment(_ sentiment: SentimentScore) -> StatusBadge {
        switch sentiment {
        case .positive:
            return StatusBadge(label: sentiment.rawValue, color: Color.NexusHR.statusPositive)
        case .neutral:
            return StatusBadge(label: sentiment.rawValue, color: Color.NexusHR.statusNeutral)
        case .negative:
            return StatusBadge(label: sentiment.rawValue, color: Color.NexusHR.statusNegative)
        }
    }

    static func forModel(_ tier: ModelTier) -> StatusBadge {
        switch tier {
        case .basic:
            return StatusBadge(label: tier.rawValue, color: Color.NexusHR.chartTeal)
        case .intermediate:
            return StatusBadge(label: tier.rawValue, color: Color.NexusHR.chartBlue)
        case .hrAgent:
            return StatusBadge(label: tier.rawValue, color: Color.NexusHR.chartSlate)
        }
    }

    var body: some View {
        Text(label)
            .font(.NexusHR.badge)
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .accessibilityLabel(label)
    }
}

// MARK: — Preview

#Preview {
    HStack(spacing: 8) {
        StatusBadge.forStatus(.resolved)
        StatusBadge.forStatus(.escalated)
        StatusBadge.forStatus(.inProgress)
        StatusBadge.forSentiment(.positive)
        StatusBadge.forSentiment(.negative)
        StatusBadge.forModel(.hrAgent)
    }
    .padding(20)
    .background(Color.NexusHR.background)
}
