// GlassCard.swift
// Reusable card container with macOS glass material aesthetic.

internal import SwiftUI

struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(
                ZStack {
                    // Glass base material
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                    // White overlay at 60% for a clean bright card feel
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.60))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.NexusHR.borderSubtle, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: — Preview

#Preview {
    GlassCard {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ejemplo de Tarjeta")
                .font(.NexusHR.sectionTitle)
            Text("Contenido de muestra")
                .font(.NexusHR.body)
                .foregroundColor(.NexusHR.textSecondary)
        }
        .padding(20)
    }
    .frame(width: 280)
    .padding(40)
    .background(Color.NexusHR.background)
}
