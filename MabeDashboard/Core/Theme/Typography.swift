// Typography.swift
// Nexus HR — Design System Typography
// Uses SF Pro system fonts via .system() for HIG compliance and Dynamic Type support.

internal import SwiftUI

extension Font {
    enum NexusHR {
        // MARK: — Display / KPI values
        /// Large numeric KPI value — 34pt rounded bold
        static let kpiValue = Font.system(size: 34, weight: .bold, design: .rounded)

        /// Section title — 20pt semibold
        static let sectionTitle = Font.system(size: 20, weight: .semibold, design: .default)

        /// Card title / metric label — 13pt medium
        static let metricLabel = Font.system(size: 13, weight: .medium, design: .default)

        // MARK: — Body
        /// Standard body copy — 14pt regular
        static let body = Font.system(size: 14, weight: .regular, design: .default)

        /// Small caption / subtitles — 12pt regular
        static let caption = Font.system(size: 12, weight: .regular, design: .default)

        /// Tiny label — 11pt medium
        static let tiny = Font.system(size: 11, weight: .medium, design: .default)

        // MARK: — Navigation
        /// Sidebar item label — 13pt medium
        static let sidebarItem = Font.system(size: 13, weight: .medium, design: .default)

        /// Sidebar header / app name — 15pt semibold
        static let appName = Font.system(size: 15, weight: .semibold, design: .default)

        // MARK: — Table
        /// Table column header — 12pt semibold
        static let tableHeader = Font.system(size: 12, weight: .semibold, design: .default)

        /// Table cell — 13pt regular
        static let tableCell = Font.system(size: 13, weight: .regular, design: .default)

        // MARK: — Trend / Badge
        /// Trend percentage — 12pt semibold
        static let trendValue = Font.system(size: 12, weight: .semibold, design: .rounded)

        /// Status badge label — 11pt semibold
        static let badge = Font.system(size: 11, weight: .semibold, design: .default)
    }
}
