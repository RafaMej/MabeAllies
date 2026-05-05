// DashboardView.swift
// iPadOS: LazyVGrid adaptativo por horizontalSizeClass, toolbar nativa.
// Reemplaza: HStack header con botones flotantes → ToolbarItem

internal import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @Environment(\.horizontalSizeClass) private var hSizeClass

    private var twoColumns: [GridItem] {
        hSizeClass == .regular
            ? [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
            : [GridItem(.flexible())]
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {

                // KPI Cards — 2×2 en Regular, 1 col en Compact
                LazyVGrid(columns: twoColumns, spacing: 12) {
                    if viewModel.kpis.isEmpty {
                        ForEach(0..<4, id: \.self) { _ in skeletonCard }
                    } else {
                        ForEach(viewModel.kpis) { metric in KPICardView(metric: metric) }
                    }
                }

                // Charts — lado a lado en Regular, apilados en Compact
                LazyVGrid(columns: twoColumns, spacing: 16) {
                    ModelEfficiencyChart(
                        data: viewModel.modelEfficiency.isEmpty ? ModelEfficiency.mockData : viewModel.modelEfficiency,
                        totalConsultations: viewModel.totalConsultations == 0 ? ModelEfficiency.mockTotalConsultations : viewModel.totalConsultations
                    )
                    ConsultaHeatmapView(
                        cells: viewModel.heatmapCells.isEmpty ? HeatmapCell.mockData() : viewModel.heatmapCells
                    )
                }

                if !viewModel.sentimentPoints.isEmpty {
                    SentimentAreaChart(
                        dataPoints: viewModel.sentimentPoints,
                        annotations: SentimentAnnotation.mockAnnotations
                    )
                }

                if !viewModel.recentQueries.isEmpty {
                    QueryPipelineTable(queries: viewModel.recentQueries)
                }

                Spacer(minLength: 20)
            }
            .padding(16)
        }
        .background(Color.NexusHR.background)
        .navigationTitle("Dashboard de RRHH")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(DateRangeFilter.allCases) { filter in
                        Button(filter.rawValue) {
                            viewModel.selectedRange = filter
                            Task { await viewModel.loadAll() }
                        }
                    }
                } label: {
                    Label(viewModel.selectedRange.rawValue, systemImage: "calendar")
                        .font(.NexusHR.metricLabel)
                }
                Button { } label: { Image(systemName: "square.and.arrow.up") }
                    .accessibilityLabel("Exportar")
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Text(viewModel.lastUpdatedLabel)
                    .font(.NexusHR.caption)
                    .foregroundColor(Color.NexusHR.textSecondary)
            }
        }
        .overlay { if viewModel.isLoading && viewModel.kpis.isEmpty { loadingOverlay } }
        .task { await viewModel.loadAll() }
    }

    private var skeletonCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 8).fill(Color.NexusHR.divider).frame(width: 40, height: 40)
                RoundedRectangle(cornerRadius: 6).fill(Color.NexusHR.divider).frame(width: 80, height: 28)
                RoundedRectangle(cornerRadius: 4).fill(Color.NexusHR.divider).frame(width: 110, height: 14)
                RoundedRectangle(cornerRadius: 4).fill(Color.NexusHR.divider).frame(width: 60, height: 20)
            }
            .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        }
        .redacted(reason: .placeholder)
        .shimmering()
    }

    private var loadingOverlay: some View {
        Color.NexusHR.background.opacity(0.3).ignoresSafeArea()
            .overlay { ProgressView().scaleEffect(1.3).tint(Color.NexusHR.primaryBlue) }
    }
}

// MARK: — Shimmer

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    func body(content: Content) -> some View {
        content
            .overlay(LinearGradient(colors: [.clear, .white.opacity(0.4), .clear], startPoint: .leading, endPoint: .trailing)
                .rotationEffect(.degrees(30)).offset(x: phase * 300 - 100))
            .mask(content)
            .onAppear { withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) { phase = 1 } }
            .clipped()
    }
}
private extension View { func shimmering() -> some View { modifier(ShimmerModifier()) } }
