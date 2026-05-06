// SentimientoView.swift
// Full sentiment analysis dashboard for the Sentimiento tab.
//
// Sections (top to bottom):
//   1. Mock-data banner  — shown only when no real logs exist yet
//   2. Sentiment KPI row — % Positivo / Neutral / Negativo
//   3. Charts row        — SentimentAreaChart (reused) + TopicDistributionChart (new)
//   4. KeywordCloudView  — frequency-weighted keyword chips
//   5. Analysis list     — per-conversation NL score bar + sentiment badge
//
// Layout follows DashboardView: ScrollView > VStack > LazyVGrid, padding(16),
// .background(Color.NexusHR.background), toolbar date filter menu.

internal import SwiftUI
internal import SwiftData

struct SentimientoView: View {
    @StateObject private var vm = SentimentViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var hSizeClass

    private var twoColumns: [GridItem] {
        hSizeClass == .regular
            ? [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
            : [GridItem(.flexible())]
    }

    /// Capped list used in the analysis table — avoids layout thrash with many records.
    private var recentAnalyses: [ConversationAnalysis] {
        Array(vm.analyses.prefix(20))
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {

                // 1 — Mock data banner
                if vm.isMockData { mockDataBanner }

                // 2 — Sentiment KPI row (3 equal columns)
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ], spacing: 12) {
                    sentimentKPICard(
                        label: "Positivo",
                        pct: vm.positivePercentage,
                        color: Color.NexusHR.statusPositive,
                        icon: "face.smiling"
                    )
                    sentimentKPICard(
                        label: "Neutral",
                        pct: vm.neutralPercentage,
                        color: Color.NexusHR.statusNeutral,
                        icon: "minus.circle"
                    )
                    sentimentKPICard(
                        label: "Negativo",
                        pct: vm.negativePercentage,
                        color: Color.NexusHR.statusNegative,
                        icon: "exclamationmark.triangle"
                    )
                }

                // 3 — Charts: trend area + topic distribution
                LazyVGrid(columns: twoColumns, spacing: 16) {
                    if !vm.dataPoints.isEmpty {
                        SentimentAreaChart(
                            dataPoints: vm.dataPoints,
                            annotations: vm.annotations
                        )
                    }
                    TopicDistributionChart(distribution: vm.topicDistribution)
                }

                // 4 — Keyword cloud
                KeywordCloudView(keywords: vm.aggregatedKeywords)

                // 5 — Per-conversation analysis list
                if !vm.analyses.isEmpty {
                    conversationList
                }

                Spacer(minLength: 20)
            }
            .padding(16)
        }
        .background(Color.NexusHR.background)
        .navigationTitle("Sentimiento")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(DateRangeFilter.allCases) { filter in
                        Button(filter.rawValue) {
                            vm.selectedRange = filter
                            Task { await vm.load(container: modelContext.container) }
                        }
                    }
                } label: {
                    Label(vm.selectedRange.rawValue, systemImage: "calendar")
                        .font(.NexusHR.metricLabel)
                }
            }
        }
        .overlay { if vm.isLoading { loadingOverlay } }
        .task { await vm.load(container: modelContext.container) }
    }

    // MARK: — Sentiment KPI card

    /// Matches KPICardView structure: icon tile · large metric · label.
    private func sentimentKPICard(
        label: String,
        pct: Double,
        color: Color,
        icon: String
    ) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(color)
                        .accessibilityHidden(true)
                }
                Text(String(format: "%.0f%%", pct))
                    .font(.NexusHR.kpiValue)
                    .foregroundColor(Color.NexusHR.textPrimary)
                Text(label)
                    .font(.NexusHR.metricLabel)
                    .foregroundColor(Color.NexusHR.textSecondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(String(format: "%.0f", pct)) por ciento")
    }

    // MARK: — Conversation analysis list

    private var conversationList: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 0) {

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Conversaciones Analizadas")
                            .font(.NexusHR.sectionTitle)
                            .foregroundColor(Color.NexusHR.textPrimary)
                        Text("Puntaje NL y sentimiento por interacción")
                            .font(.NexusHR.caption)
                            .foregroundColor(Color.NexusHR.textSecondary)
                    }
                    Spacer()
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.NexusHR.statusPositive)
                            .frame(width: 7, height: 7)
                        Text("\(vm.analyses.count) registros")
                            .font(.NexusHR.caption)
                            .foregroundColor(Color.NexusHR.textSecondary)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 12)

                Divider().foregroundColor(Color.NexusHR.divider)

                LazyVStack(spacing: 0) {
                    ForEach(recentAnalyses) { analysis in
                        analysisRow(analysis)
                        if analysis.id != recentAnalyses.last?.id {
                            Divider()
                                .foregroundColor(Color.NexusHR.divider)
                                .padding(.leading, 20)
                        }
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }

    private let fmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "dd MMM, HH:mm"
        return f
    }()

    @ViewBuilder
    private func analysisRow(_ a: ConversationAnalysis) -> some View {
        HStack(spacing: 12) {

            // Timestamp
            Text(fmt.string(from: a.timestamp))
                .font(.NexusHR.tableCell)
                .foregroundColor(Color.NexusHR.textSecondary)
                .monospacedDigit()
                .frame(width: 100, alignment: .leading)

            // Topic
            HStack(spacing: 5) {
                Image(systemName: a.topic.icon)
                    .font(.system(size: 11))
                    .foregroundColor(Color.NexusHR.primaryBlue)
                    .accessibilityHidden(true)
                Text(a.topic.rawValue)
                    .font(.NexusHR.tableCell)
                    .foregroundColor(Color.NexusHR.textPrimary)
            }
            .frame(minWidth: 90, alignment: .leading)

            Spacer()

            // Raw NL score bar — compact [-1…+1] visual
            nlScoreBar(score: a.nlScore)

            // Discrete sentiment badge
            StatusBadge.forSentiment(a.sentiment)
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    /// Mini horizontal bar that fills proportionally from the center for negative scores
    /// and from the left edge (as a plain fill) for a simple [-1, +1] encoding.
    ///
    /// Implementation: map score to [0, 1] fill ratio: ratio = (score + 1) / 2
    private func nlScoreBar(score: Double) -> some View {
        let clamped = max(-1.0, min(1.0, score))
        let ratio   = (clamped + 1.0) / 2.0
        let color: Color = clamped >  0.10 ? Color.NexusHR.statusPositive
                         : clamped < -0.10 ? Color.NexusHR.statusNegative
                         :                   Color.NexusHR.statusNeutral

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.NexusHR.divider)
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(ratio))
            }
        }
        .frame(width: 60, height: 6)
        .accessibilityLabel("Puntaje NL: \(String(format: "%.2f", score))")
    }

    // MARK: — Supporting views

    /// Shown when the VM is using seed data instead of real SwiftData records.
    private var mockDataBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(Color.NexusHR.primaryBlue)
                .accessibilityHidden(true)
            Text("Mostrando datos de demostración. Los datos reales aparecerán al procesar conversaciones en el Simulador.")
                .font(.NexusHR.caption)
                .foregroundColor(Color.NexusHR.textSecondary)
            Spacer()
        }
        .padding(12)
        .background(
            Color.NexusHR.primaryBlue10,
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.NexusHR.primaryBlue.opacity(0.2), lineWidth: 1)
        )
    }

    private var loadingOverlay: some View {
        Color.NexusHR.background.opacity(0.3).ignoresSafeArea()
            .overlay {
                ProgressView()
                    .scaleEffect(1.3)
                    .tint(Color.NexusHR.primaryBlue)
            }
    }
}
