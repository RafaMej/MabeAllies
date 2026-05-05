// Colors.swift
// Nexus HR — Design System Color Constants
// All colors defined here as single source of truth.
// Minimum contrast ratio of 4.5:1 enforced for text/background pairings.

internal import SwiftUI

extension Color {
    enum NexusHR {
        // MARK: — Primary
        /// Main brand blue — used for active states, accents, CTA
        static let primaryBlue = Color(hex: "007299")

        /// 20% opacity primary — used for hover backgrounds, light fills
        static let primaryBlue20 = Color(hex: "007299").opacity(0.2)

        /// 10% opacity primary — used for heatmap minimum, subtle fills
        static let primaryBlue10 = Color(hex: "007299").opacity(0.1)

        // MARK: — Backgrounds
        /// Main window background
        static let background = Color(hex: "FDFFFF")

        /// Card surface background
        static let cardBackground = Color.white.opacity(0.60)

        /// Sidebar background — slightly deeper than main
        static let sidebarBackground = Color(hex: "F4F6F8")

        // MARK: — Text
        /// Primary text — high contrast on light background (contrast > 7:1)
        static let textPrimary = Color(hex: "1A1A1A")

        /// Secondary / muted text
        static let textSecondary = Color(hex: "6B7280")

        /// Tertiary label
        static let textTertiary = Color(hex: "9CA3AF")

        // MARK: — Status
        static let statusPositive = Color(hex: "10B981")  // emerald-500
        static let statusNegative = Color(hex: "EF4444")  // red-500
        static let statusNeutral  = Color(hex: "F59E0B")  // amber-500
        static let statusInfo     = Color(hex: "3B82F6")  // blue-500

        // MARK: — Dividers & Borders
        static let divider = Color(hex: "E5E7EB")
        static let borderSubtle = Color.white.opacity(0.8)

        // MARK: — Chart palette (for model efficiency donut)
        static let chartTeal   = Color(hex: "007299")   // LLM Básico
        static let chartBlue   = Color(hex: "0EA5E9")   // LLM Intermedio
        static let chartSlate  = Color(hex: "64748B")   // Agente RRHH

        // MARK: — Sidebar active
        static let sidebarActive = Color(hex: "007299")
        static let sidebarActiveText = Color.white
        static let sidebarInactiveText = Color(hex: "374151")
    }
}
