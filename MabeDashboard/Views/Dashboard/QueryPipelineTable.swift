// QueryPipelineTable.swift — iPadOS
// Reemplaza macOS Table (no disponible en iPadOS) con LazyVStack + sort chips horizontales

internal import SwiftUI

struct QueryPipelineTable: View {
    let queries: [QueryRecord]

    enum SortOption: String, CaseIterable {
        case timestamp = "Hora"; case category = "Categoría"
        case modelUsed = "Modelo"; case status = "Estado"
        var icon: String {
            switch self {
            case .timestamp: return "clock"; case .category: return "tag"
            case .modelUsed: return "cpu"; case .status: return "checkmark.circle"
            }
        }
    }

    @State private var sortBy: SortOption = .timestamp
    @State private var ascending = false

    private let fmt: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "es_MX"); f.dateFormat = "dd MMM, HH:mm"; return f
    }()

    private var sorted: [QueryRecord] {
        queries.sorted {
            let r: Bool
            switch sortBy {
            case .timestamp: r = $0.timestamp < $1.timestamp
            case .category:  r = $0.category.rawValue < $1.category.rawValue
            case .modelUsed: r = $0.modelUsed.rawValue < $1.modelUsed.rawValue
            case .status:    r = $0.status.rawValue < $1.status.rawValue
            }
            return ascending ? r : !r
        }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Pipeline de Consultas").font(.NexusHR.sectionTitle).foregroundColor(Color.NexusHR.textPrimary)
                        Text("Historial reciente de consultas procesadas").font(.NexusHR.caption).foregroundColor(Color.NexusHR.textSecondary)
                    }
                    Spacer()
                    HStack(spacing: 5) {
                        Circle().fill(Color.NexusHR.statusPositive).frame(width: 7, height: 7)
                        Text("\(queries.count) consultas").font(.NexusHR.caption).foregroundColor(Color.NexusHR.textSecondary)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 12)

                // Sort chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SortOption.allCases, id: \.self) { opt in
                            Button {
                                if sortBy == opt { ascending.toggle() } else { sortBy = opt; ascending = false }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: opt.icon).font(.system(size: 11, weight: .medium))
                                    Text(opt.rawValue).font(.NexusHR.tiny)
                                    if sortBy == opt {
                                        Image(systemName: ascending ? "chevron.up" : "chevron.down").font(.system(size: 9, weight: .bold))
                                    }
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(sortBy == opt ? Color.NexusHR.primaryBlue : Color.NexusHR.primaryBlue10,
                                            in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .foregroundColor(sortBy == opt ? .white : Color.NexusHR.primaryBlue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 8)

                Divider().foregroundColor(Color.NexusHR.divider)

                LazyVStack(spacing: 0) {
                    ForEach(sorted) { record in
                        row(record)
                        if record.id != sorted.last?.id {
                            Divider().foregroundColor(Color.NexusHR.divider).padding(.leading, 20)
                        }
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private func row(_ r: QueryRecord) -> some View {
        HStack(spacing: 12) {
            Text(fmt.string(from: r.timestamp))
                .font(.NexusHR.tableCell).foregroundColor(Color.NexusHR.textSecondary)
                .monospacedDigit().frame(width: 100, alignment: .leading)
            HStack(spacing: 5) {
                Image(systemName: r.category.icon).font(.system(size: 11))
                    .foregroundColor(Color.NexusHR.primaryBlue).accessibilityHidden(true)
                Text(r.category.rawValue).font(.NexusHR.tableCell).foregroundColor(Color.NexusHR.textPrimary)
            }
            .frame(minWidth: 90, alignment: .leading)
            Spacer()
            StatusBadge.forModel(r.modelUsed)
            StatusBadge.forStatus(r.status)
            StatusBadge.forSentiment(r.sentiment)
            Image(systemName: r.isAnonymized ? "lock.fill" : "lock.open")
                .font(.system(size: 12))
                .foregroundColor(r.isAnonymized ? Color.NexusHR.statusPositive : Color.NexusHR.statusNegative)
                .accessibilityLabel(r.isAnonymized ? "Anonimizado" : "Sin anonimizar")
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }
}
