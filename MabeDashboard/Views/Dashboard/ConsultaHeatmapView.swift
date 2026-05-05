// ConsultaHeatmapView.swift — iPadOS
// Reemplaza .onHover tooltip → .popover activado por tap

internal import SwiftUI
internal import Charts
import UniformTypeIdentifiers

struct ConsultaHeatmapView: View {
    let cells: [HeatmapCell]
    @State private var selectedCell: HeatmapCell? = nil
    @State private var showPopover = false

    private let hours = Array(6...22)
    private let days = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]
    private var maxCount: Int { cells.map(\.queryCount).max() ?? 1 }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Heatmap de Consultas")
                    .font(.NexusHR.sectionTitle).foregroundColor(Color.NexusHR.textPrimary)

                HStack(spacing: 0) {
                    Text("00:00").font(.NexusHR.tiny).hidden().frame(width: 36)
                    ForEach(days, id: \.self) { day in
                        Text(day).font(.NexusHR.tiny).foregroundColor(Color.NexusHR.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                VStack(spacing: 2) {
                    ForEach(hours, id: \.self) { hour in
                        HStack(spacing: 2) {
                            Text(String(format: "%02d:00", hour))
                                .font(.NexusHR.tiny).foregroundColor(Color.NexusHR.textSecondary)
                                .frame(width: 36, alignment: .trailing).accessibilityHidden(true)
                            ForEach(0..<7, id: \.self) { dayIndex in
                                if let c = cell(hour: hour, day: dayIndex) { heatCell(c) }
                            }
                        }
                    }
                }

                colorScaleLegend
            }
            .padding(16)
        }
        .accessibilityLabel("Heatmap de consultas por hora y día de la semana")
    }

    @ViewBuilder
    private func heatCell(_ c: HeatmapCell) -> some View {
        let intensity = maxCount > 0 ? Double(c.queryCount) / Double(maxCount) : 0
        let fill = Color.NexusHR.primaryBlue.opacity(max(0.08, intensity))
        let selected = selectedCell?.id == c.id

        RoundedRectangle(cornerRadius: 3, style: .continuous).fill(fill)
            .frame(maxWidth: .infinity).aspectRatio(1.1, contentMode: .fit)
            .overlay(RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(selected ? Color.NexusHR.primaryBlue : Color.clear, lineWidth: 1.5))
            .onTapGesture { selectedCell = c; showPopover = true }
            .popover(isPresented: Binding(
                get: { showPopover && selectedCell?.id == c.id },
                set: { if !$0 { showPopover = false } }
            ), arrowEdge: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(c.dayLabel) \(c.hourLabel)").font(.NexusHR.tiny).foregroundColor(Color.NexusHR.textSecondary)
                    Text("\(c.queryCount) consultas").font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.NexusHR.textPrimary)
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .presentationCompactAdaptation(.popover)
            }
            .accessibilityElement()
            .accessibilityLabel("\(c.dayLabel), \(c.hourLabel)")
            .accessibilityValue("\(c.queryCount) consultas")
            .accessibilityAddTraits(.isButton)
    }

    private var colorScaleLegend: some View {
        HStack(spacing: 6) {
            Text("Menos").font(.NexusHR.tiny).foregroundColor(Color.NexusHR.textTertiary)
            HStack(spacing: 2) {
                ForEach([0.08, 0.25, 0.5, 0.75, 1.0], id: \.self) { op in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.NexusHR.primaryBlue.opacity(op)).frame(width: 14, height: 9)
                }
            }
            Text("Más").font(.NexusHR.tiny).foregroundColor(Color.NexusHR.textTertiary)
        }
    }

    private func cell(hour: Int, day: Int) -> HeatmapCell? {
        cells.first { $0.hour == hour && $0.dayOfWeek == day }
    }
}

protocol HeatmapDataSource {
    func heatmapCells(for range: DateInterval) async throws -> [HeatmapCell]
}
