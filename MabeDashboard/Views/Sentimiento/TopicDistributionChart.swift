// TopicDistributionChart.swift
// Horizontal bar chart showing conversation count per HR topic category.
// Style matches SentimentAreaChart — GlassCard wrapper + Swift Charts BarMark.

internal import SwiftUI
internal import Charts

struct TopicDistributionChart: View {
    let distribution: [TopicCount]

    private let categoryColors: [QueryCategory: Color] = [
        .nomina:       Color.NexusHR.chartTeal,
        .vacaciones:   Color.NexusHR.statusPositive,
        .legal:        Color.NexusHR.statusNegative,
        .clima:        Color.NexusHR.chartBlue,
        .beneficios:   Color.NexusHR.statusNeutral,
        .capacitacion: Color.NexusHR.chartSlate,
    ]

    private var totalCount: Int { distribution.reduce(0) { $0 + $1.count } }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {

                // Header — mirrors SentimentAreaChart layout
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Distribución por Tema")
                            .font(.NexusHR.sectionTitle)
                            .foregroundColor(Color.NexusHR.textPrimary)
                        Text("Consultas agrupadas por categoría HR")
                            .font(.NexusHR.caption)
                            .foregroundColor(Color.NexusHR.textSecondary)
                    }
                    Spacer()
                    Text("\(totalCount) total")
                        .font(.NexusHR.caption)
                        .foregroundColor(Color.NexusHR.textSecondary)
                }

                if distribution.isEmpty {
                    emptyState
                } else {
                    chart
                }
            }
            .padding(20)
        }
    }

    // MARK: — Chart

    private var chart: some View {
        Chart(distribution) { item in
            BarMark(
                x: .value("Consultas", item.count),
                y: .value("Tema", item.category.rawValue)
            )
            .foregroundStyle(categoryColors[item.category] ?? Color.NexusHR.primaryBlue)
            .cornerRadius(5)
            .annotation(position: .trailing, alignment: .leading) {
                Text("\(item.count)")
                    .font(.NexusHR.tiny)
                    .foregroundColor(Color.NexusHR.textSecondary)
                    .monospacedDigit()
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.NexusHR.divider)
                AxisValueLabel()
                    .font(.NexusHR.tiny)
                    .foregroundStyle(Color.NexusHR.textTertiary)
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.NexusHR.tiny)
                    .foregroundStyle(Color.NexusHR.textSecondary)
            }
        }
        // Height scales with the number of bars so no bar is ever truncated
        .frame(height: CGFloat(distribution.count) * 38 + 16)
        .accessibilityLabel("Gráfica de distribución por tema")
    }

    // MARK: — Empty state

    private var emptyState: some View {
        Text("Sin datos para el rango seleccionado.")
            .font(.NexusHR.body)
            .foregroundColor(Color.NexusHR.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)
    }
}

// MARK: — Preview

#Preview {
    TopicDistributionChart(distribution: [
        TopicCount(category: .nomina,       count: 5),
        TopicCount(category: .vacaciones,   count: 3),
        TopicCount(category: .legal,        count: 2),
        TopicCount(category: .beneficios,   count: 2),
        TopicCount(category: .capacitacion, count: 1),
        TopicCount(category: .clima,        count: 1),
    ])
    .frame(width: 360)
    .padding(40)
    .background(Color.NexusHR.background)
}
