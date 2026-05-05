// SentimentAreaChart.swift
// Stacked area chart showing sentiment distribution over time using Swift Charts AreaMark.

internal import SwiftUI
internal import Charts
internal import Combine

struct SentimentAreaChart: View {
    let dataPoints: [SentimentDataPoint]
    let annotations: [SentimentAnnotation]

    // INTEGRATION POINT: Subscribe to this publisher for real-time sentiment updates.
    // Bind to SentimentViewModel.dataPublisher in the parent view.
    var dataPublisher: AnyPublisher<[SentimentDataPoint], Never>?

    private let sentimentColors: [SentimentCategory: Color] = [
        .positive: Color.NexusHR.statusPositive,
        .neutral:  Color.NexusHR.statusNeutral,
        .negative: Color.NexusHR.statusNegative
    ]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tendencia de Sentimiento")
                            .font(.NexusHR.sectionTitle)
                            .foregroundColor(Color.NexusHR.textPrimary)
                        Text("Distribución porcentual de respuestas")
                            .font(.NexusHR.caption)
                            .foregroundColor(Color.NexusHR.textSecondary)
                    }
                    Spacer()
                    legendRow
                }

                // Chart
                Chart {
                    ForEach(SentimentCategory.allCases.sorted(by: { $0.sortOrder > $1.sortOrder }), id: \.self) { category in
                        ForEach(dataPoints.filter { $0.sentiment == category }) { point in
                            AreaMark(
                                x: .value("Fecha", point.date),
                                y: .value("Porcentaje", point.percentage),
                                stacking: .normalized
                            )
                            .foregroundStyle(
                                (sentimentColors[category] ?? Color.gray).opacity(0.75)
                            )
                            .interpolationMethod(.monotone)
                        }
                        .foregroundStyle(by: .value("Sentimiento", category.rawValue))
                    }

                    // Annotation markers for key events
                    ForEach(annotations) { annotation in
                        RuleMark(x: .value("Evento", annotation.date))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                            .foregroundStyle(Color.NexusHR.primaryBlue.opacity(0.6))
                            .annotation(position: .top, alignment: .leading) {
                                Text(annotation.label)
                                    .font(.NexusHR.tiny)
                                    .foregroundColor(Color.NexusHR.primaryBlue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.NexusHR.primaryBlue10, in: RoundedRectangle(cornerRadius: 4))
                            }
                    }
                }
                .chartForegroundStyleScale([
                    SentimentCategory.positive.rawValue: Color.NexusHR.statusPositive.opacity(0.75),
                    SentimentCategory.neutral.rawValue:  Color.NexusHR.statusNeutral.opacity(0.75),
                    SentimentCategory.negative.rawValue: Color.NexusHR.statusNegative.opacity(0.75)
                ])
                .chartLegend(.hidden)
                .chartYAxis {
                    AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.NexusHR.divider)
                        AxisValueLabel {
                            if let pct = value.as(Double.self) {
                                Text("\(Int(pct * 100))%")
                                    .font(.NexusHR.tiny)
                                    .foregroundColor(Color.NexusHR.textTertiary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.NexusHR.divider)
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: false)
                            .font(.NexusHR.tiny)
                            .foregroundStyle(Color.NexusHR.textTertiary)
                    }
                }
                .frame(height: 160)
                .accessibilityLabel("Gráfica de área de tendencia de sentimiento")
                .accessibilityValue("Sentimiento positivo predominante, con tendencia al alza en los últimos 30 días")
            }
            .padding(20)
        }
    }

    // MARK: — Legend

    private var legendRow: some View {
        HStack(spacing: 12) {
            ForEach(SentimentCategory.allCases, id: \.self) { category in
                HStack(spacing: 4) {
                    // Shape + color for accessibility
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(sentimentColors[category] ?? .gray)
                        .frame(width: 10, height: 10)
                        .accessibilityHidden(true)
                    Text(category.rawValue)
                        .font(.NexusHR.tiny)
                        .foregroundColor(Color.NexusHR.textSecondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(category.rawValue)
            }
        }
    }
}

// MARK: — Preview

#Preview {
    SentimentAreaChart(
        dataPoints: SentimentDataPoint.mockData(),
        annotations: SentimentAnnotation.mockAnnotations
    )
    .frame(width: 600)
    .padding(40)
    .background(Color.NexusHR.background)
}
