// TrendIndicator.swift
// Shows a percentage trend with directional arrow icon.
// Uses both color AND icon shape — never color alone — for accessibility.

internal import SwiftUI

struct TrendIndicator: View {
    let trend: Double

    private var isPositive: Bool { trend >= 0 }
    private var isNeutral: Bool { trend == 0 }

    private var color: Color {
        if isNeutral { return Color.NexusHR.textSecondary }
        return isPositive ? Color.NexusHR.statusPositive : Color.NexusHR.statusNegative
    }

    private var icon: String {
        if isNeutral { return "minus" }
        return isPositive ? "arrow.up.right" : "arrow.down.right"
    }

    private var accessibilityDescription: String {
        if isNeutral { return "sin cambio" }
        let direction = isPositive ? "incremento" : "decremento"
        let value = String(format: "%.0f", abs(trend))
        return "\(direction) del \(value)%"
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text("\(abs(trend), specifier: "%.0f")%")
                .font(.NexusHR.trendValue)
        }
        .foregroundColor(color)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .accessibilityLabel(accessibilityDescription)
        .accessibilityElement(children: .ignore)
    }
}

// MARK: — Preview

#Preview {
    HStack(spacing: 12) {
        TrendIndicator(trend: 12)
        TrendIndicator(trend: -5)
        TrendIndicator(trend: 0)
    }
    .padding(20)
    .background(Color.NexusHR.background)
}
