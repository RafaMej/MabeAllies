// RootNavigationView.swift
// Reemplaza MainWindowView.swift (macOS HStack sidebar fijo) con NavigationSplitView nativo iPadOS.
// Navegación: Dashboard, Sentimiento, Simulador, Indexación, Configuración.

internal import SwiftUI
internal import SwiftData

struct RootNavigationView: View {
    @EnvironmentObject var dashboardVM: DashboardViewModel
    @StateObject private var sentimentVM  = SentimentViewModel()
    @StateObject private var pipelineVM   = QueryPipelineViewModel()

    @State private var selectedDestination: NavDestination? = .dashboard
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView(selectedDestination: $selectedDestination)
        } detail: {
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: dashboardVM.recentQueries) { _, newQueries in
            pipelineVM.loadQueries(from: newQueries)
        }
    }

    // MARK: — Router

    @ViewBuilder
    private var contentView: some View {
        switch selectedDestination ?? .dashboard {

        case .dashboard:
            DashboardView()
                .environmentObject(dashboardVM)

        case .sentimiento:
            placeholder(icon: "heart", title: "Sentimiento",
                        subtitle: "Análisis profundo de sentimiento organizacional en desarrollo")

        case .simulador:
            SimuladorView(container: modelContext.container)

        case .indexacion:
            IndexacionView()

        case .configuracion:
            placeholder(icon: "gearshape", title: "Configuración",
                        subtitle: "Gestión de modelos, conexiones y preferencias en desarrollo")
        }
    }

    private func placeholder(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 52, weight: .light))
                .foregroundColor(Color.NexusHR.primaryBlue.opacity(0.4))
                .accessibilityHidden(true)
            Text(title)
                .font(.NexusHR.sectionTitle)
                .foregroundColor(Color.NexusHR.textPrimary)
            Text(subtitle)
                .font(.NexusHR.body)
                .foregroundColor(Color.NexusHR.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.NexusHR.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
