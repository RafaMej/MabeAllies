// KeywordCloudView.swift
// Frequency-weighted keyword cloud extracted from HR conversations.
//
// Visual encoding:
//   Font size  — proportional to keyword frequency (11 pt min → 22 pt max)
//   Chip color — reflects the dominant sentiment of conversations containing the word
//                 green = positive · amber = neutral · red = negative
//
// WrappingHStack is a custom SwiftUI Layout (iOS 16+) that flows chips left-to-right
// and wraps to the next line when the available width is exhausted.

internal import SwiftUI

// MARK: — Public view

struct KeywordCloudView: View {
    let keywords: [KeywordEntry]

    /// Maximum number of chips rendered to avoid overwhelming the layout engine.
    private static let maxDisplay = 30

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Palabras Clave")
                            .font(.NexusHR.sectionTitle)
                            .foregroundColor(Color.NexusHR.textPrimary)
                        Text("Términos más frecuentes extraídos de las conversaciones")
                            .font(.NexusHR.caption)
                            .foregroundColor(Color.NexusHR.textSecondary)
                    }
                    Spacer()
                    if !keywords.isEmpty {
                        Text("\(min(keywords.count, Self.maxDisplay)) términos")
                            .font(.NexusHR.caption)
                            .foregroundColor(Color.NexusHR.textSecondary)
                    }
                }

                if keywords.isEmpty {
                    Text("Sin palabras clave extraídas aún.")
                        .font(.NexusHR.body)
                        .foregroundColor(Color.NexusHR.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else {
                    let topKeywords = Array(keywords.prefix(Self.maxDisplay))
                    let maxFreq     = topKeywords.first?.frequency ?? 1

                    WrappingHStack(spacing: 8) {
                        ForEach(topKeywords) { entry in
                            KeywordChip(entry: entry, maxFrequency: maxFreq)
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: — Keyword chip

private struct KeywordChip: View {
    let entry: KeywordEntry
    let maxFrequency: Int

    /// Font size scales linearly from 11 pt (frequency = 1) to 22 pt (frequency = max).
    private var fontSize: CGFloat {
        let minSize: CGFloat = 11
        let maxSize: CGFloat = 22
        guard maxFrequency > 1 else { return minSize }
        let ratio = CGFloat(entry.frequency - 1) / CGFloat(maxFrequency - 1)
        return (minSize + (maxSize - minSize) * ratio).rounded()
    }

    private var chipColor: Color {
        switch entry.dominantSentiment {
        case .positive: return Color.NexusHR.statusPositive
        case .negative: return Color.NexusHR.statusNegative
        case .neutral:  return Color.NexusHR.primaryBlue
        }
    }

    var body: some View {
        Text(entry.word)
            .font(.system(size: fontSize, weight: .medium))
            .foregroundColor(chipColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                chipColor.opacity(0.12),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .accessibilityLabel(
                "\(entry.word), mencionado \(entry.frequency) \(entry.frequency == 1 ? "vez" : "veces")"
            )
    }
}

// MARK: — WrappingHStack custom Layout

/// Lays out children left-to-right and wraps to the next line when the
/// combined width would exceed the container's available width.
/// Available from iPadOS 16+ (this project targets iPadOS 17+).
struct WrappingHStack: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let containerWidth = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > containerWidth, x > 0 {
                y += lineHeight + spacing
                x = 0
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: containerWidth, height: y + lineHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += lineHeight + spacing
                x = bounds.minX
                lineHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: — Preview

#Preview {
    KeywordCloudView(keywords: [
        KeywordEntry(word: "nómina",       frequency: 5, dominantSentiment: .positive),
        KeywordEntry(word: "vacaciones",   frequency: 4, dominantSentiment: .positive),
        KeywordEntry(word: "contrato",     frequency: 3, dominantSentiment: .neutral),
        KeywordEntry(word: "descuento",    frequency: 3, dominantSentiment: .negative),
        KeywordEntry(word: "seguro",       frequency: 2, dominantSentiment: .positive),
        KeywordEntry(word: "conflicto",    frequency: 2, dominantSentiment: .negative),
        KeywordEntry(word: "capacitación", frequency: 2, dominantSentiment: .positive),
        KeywordEntry(word: "evaluación",   frequency: 1, dominantSentiment: .neutral),
        KeywordEntry(word: "infonavit",    frequency: 1, dominantSentiment: .neutral),
        KeywordEntry(word: "liderazgo",    frequency: 1, dominantSentiment: .positive),
    ])
    .frame(width: 500)
    .padding(40)
    .background(Color.NexusHR.background)
}
