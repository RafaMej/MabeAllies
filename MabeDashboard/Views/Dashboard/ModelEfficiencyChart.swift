// ModelEfficiencyChart.swift
// Donut chart using Swift Charts SectorMark showing query distribution across ML model tiers.

internal import SwiftUI
internal import Charts

// chartAngleSelection requires the selection type to be Plottable.
// We use the model's String name as the selection value instead of the full struct.
struct ModelEfficiencyChart: View {
    let data: [ModelEfficiency]
    let totalConsultations: Int

    @State private var selectedModelName: String? = nil

    private var selectedSlice: ModelEfficiency? {
        guard let name = selectedModelName else { return nil }
        return data.first { $0.modelName == name }
    }

    // INTEGRATION POINT: Call this method to update chart with real ML pipeline data
    func updateWithRealData(_ newData: [ModelEfficiency]) {
        // In a real app, this would update via ViewModel binding
        // This hook exists for direct imperative integration if needed
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Eficiencia del Modelo")
                    .font(.NexusHR.sectionTitle)
                    .foregroundColor(Color.NexusHR.textPrimary)

                HStack(alignment: .top, spacing: 24) {
                    // Donut chart
                    ZStack {
                        Chart(data) { item in
                            SectorMark(
                                angle: .value("Consultas", item.percentage),
                                innerRadius: .ratio(0.62),
                                outerRadius: selectedSlice?.id == item.id ? .ratio(1.0) : .ratio(0.95),
                                angularInset: 2
                            )
                            .foregroundStyle(item.color)
                            .cornerRadius(4)
                        }
                        .chartAngleSelection(value: $selectedModelName)
                        .frame(width: 180, height: 180)
                        // Accessibility for chart
                        .accessibilityLabel("Gráfica de eficiencia del modelo")
                        .accessibilityValue(
                            data.map { "\($0.modelName): \(String(format: "%.0f", $0.percentage))%" }
                                .joined(separator: ", ")
                        )

                        // Center label
                        VStack(spacing: 2) {
                            Text("\(totalConsultations)")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(Color.NexusHR.textPrimary)
                            Text("consultas")
                                .font(.NexusHR.tiny)
                                .foregroundColor(Color.NexusHR.textSecondary)
                        }
                        .accessibilityHidden(true)   // Read by parent chart accessibilityValue
                    }

                    // Legend
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(data) { item in
                            legendRow(for: item)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(20)
        }
    }

    // MARK: — Legend Row

    @ViewBuilder
    private func legendRow(for item: ModelEfficiency) -> some View {
        HStack(spacing: 8) {
            // Color chip + shape for accessibility
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(item.color)
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.modelName)
                    .font(.NexusHR.metricLabel)
                    .foregroundColor(Color.NexusHR.textPrimary)
                Text("\(String(format: "%.0f", item.percentage))% · \(item.consultationCount) consultas")
                    .font(.NexusHR.caption)
                    .foregroundColor(Color.NexusHR.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.modelName): \(String(format: "%.0f", item.percentage)) por ciento, \(item.consultationCount) consultas")
    }
}

// MARK: — Preview

#Preview {
    ModelEfficiencyChart(
        data: ModelEfficiency.mockData,
        totalConsultations: ModelEfficiency.mockTotalConsultations
    )
    .frame(width: 420)
    .padding(40)
    .background(Color.NexusHR.background)
}
