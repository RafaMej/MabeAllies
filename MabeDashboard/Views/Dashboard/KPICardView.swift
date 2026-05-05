// KPICardView.swift — iPadOS
// Reemplaza .onHover con feedback táctil de escala

internal import SwiftUI

struct KPICardView: View {
    let metric: KPIMetric
    @State private var isPressed = false
    @State private var livePulse = false

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.NexusHR.primaryBlue10).frame(width: 40, height: 40)
                        Image(systemName: metric.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.NexusHR.primaryBlue)
                            .accessibilityHidden(true)
                    }
                    Spacer()
                }
                Text(metric.value).font(.NexusHR.kpiValue).foregroundColor(Color.NexusHR.textPrimary)
                Text(metric.title).font(.NexusHR.metricLabel).foregroundColor(Color.NexusHR.textSecondary)
                if metric.isLive { liveDot } else { TrendIndicator(trend: metric.trend) }
            }
            .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            withAnimation { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { withAnimation { isPressed = false } }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var liveDot: some View {
        HStack(spacing: 6) {
            Circle().fill(Color.NexusHR.statusPositive).frame(width: 8, height: 8)
                .scaleEffect(livePulse ? 1.4 : 1.0).opacity(livePulse ? 0.6 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: livePulse)
            Text("en tiempo real").font(.NexusHR.caption).foregroundColor(Color.NexusHR.textSecondary)
        }
        .onAppear { livePulse = true }
    }

    private var accessibilityLabel: String {
        var label = "\(metric.title): \(metric.value)"
        if metric.isLive { label += ", actualización en tiempo real" }
        else if metric.trend != 0 {
            let dir = metric.trend > 0 ? "incremento" : "decremento"
            label += ", \(dir) del \(String(format: "%.0f", abs(metric.trend)))%"
        }
        return label
    }
}
