// SidebarView.swift
// iPadOS: List sidebar nativa. Añade .indexacion vs macOS que lo tenía en AppRootView separado.
// Reemplaza: NSImage → Image("AppIcon"), VStack manual → List(.sidebar)

internal import SwiftUI

enum NavDestination: String, CaseIterable, Hashable {
    case dashboard      = "Dashboard"
    case consultas      = "Búsqueda RAG"
    case sentimiento    = "Sentimiento"
    case eficiencia     = "Eficiencia"
    case simulador      = "Simulador"
    case indexacion     = "Indexación"
    case configuracion  = "Configuración"

    var icon: String {
        switch self {
        case .dashboard:    return "square.grid.2x2.fill"
        case .consultas:    return "magnifyingglass.circle"
        case .sentimiento:  return "heart"
        case .eficiencia:   return "waveform.path.ecg"
        case .simulador:    return "bubble.left.and.bubble.right"
        case .indexacion:   return "doc.badge.plus"
        case .configuracion:return "gearshape"
        }
    }
}

struct SidebarView: View {
    @Binding var selectedDestination: NavDestination?

    var body: some View {
        List(NavDestination.allCases, id: \.self, selection: $selectedDestination) { dest in
            Label(dest.rawValue, systemImage: dest.icon)
                .font(.NexusHR.sidebarItem)
        }
        .listStyle(.sidebar)
        .navigationTitle("Allies")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            userProfile
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.NexusHR.sidebarBackground)
        }
    }

    private var userProfile: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.NexusHR.primaryBlue20)
                    .frame(width: 36, height: 36)
                Text("AM")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.NexusHR.primaryBlue)
            }
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.NexusHR.statusPositive)
                    .frame(width: 9, height: 9)
                    .overlay(Circle().stroke(Color.NexusHR.sidebarBackground, lineWidth: 1.5))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("Ana Martínez")
                    .font(.NexusHR.metricLabel)
                    .foregroundColor(Color.NexusHR.textPrimary)
                Text("HR Admin")
                    .font(.NexusHR.caption)
                    .foregroundColor(Color.NexusHR.textSecondary)
            }
            Spacer()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sesión activa: Ana Martínez, Administradora de RRHH")
    }
}
