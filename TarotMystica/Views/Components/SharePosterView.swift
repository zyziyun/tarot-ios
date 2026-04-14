import SwiftUI

/// Generates a beautiful shareable long-form poster image from a tarot reading
struct SharePosterView: View {
    let question: String
    let spreadName: String
    let spreadKey: String?
    let drawnCards: [DrawnCard]
    let positions: [SpreadPosition]
    let aiReading: String
    let cardNameFn: (TarotCard) -> String
    let cardTextFn: (TarotCard, String) -> String

    private let posterWidth: CGFloat = 390

    private let cream = Color(red: 0.98, green: 0.965, blue: 0.94)
    private let cream2 = Color(red: 0.96, green: 0.94, blue: 0.90)
    private let dark = Color(red: 0.176, green: 0.161, blue: 0.149)
    private let muted = Color(red: 0.47, green: 0.443, blue: 0.424)
    private let gold = Color(red: 0.788, green: 0.659, blue: 0.298)
    private let accent = Color(red: 0.486, green: 0.227, blue: 0.929)

    var body: some View {
        VStack(spacing: 0) {
            // === Top section: branding + cards ===
            topSection

            // === Divider ===
            HStack(spacing: 12) {
                Rectangle().fill(gold.opacity(0.15)).frame(height: 0.5)
                Text("✦")
                    .font(.system(size: 8))
                    .foregroundColor(gold.opacity(0.4))
                Rectangle().fill(gold.opacity(0.15)).frame(height: 0.5)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)

            // === AI Reading section ===
            if !aiReading.isEmpty {
                aiReadingSection
            }

            // === Bottom branding ===
            bottomBranding
        }
        .frame(width: posterWidth)
        .background(
            LinearGradient(colors: [cream, cream2], startPoint: .top, endPoint: .bottom)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(gold.opacity(0.12), lineWidth: 1)
                .padding(8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Top Section

    private var topSection: some View {
        VStack(spacing: 0) {
            // Branding
            VStack(spacing: 6) {
                Text("✦")
                    .font(.system(size: 10))
                    .foregroundColor(gold.opacity(0.6))
                Text("Tarot Mystica")
                    .font(.system(size: 13, weight: .light, design: .serif))
                    .foregroundColor(muted.opacity(0.5))
                    .tracking(2)
            }
            .padding(.top, 28)

            // Spread name
            Text(spreadName)
                .font(.system(size: 22, weight: .light, design: .serif))
                .foregroundColor(dark)
                .multilineTextAlignment(.center)
                .padding(.top, 16)

            // Question
            if !question.isEmpty {
                Text("「\(question)」")
                    .font(.system(size: 11))
                    .foregroundColor(muted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
            }

            // Gold line
            Rectangle()
                .fill(gold.opacity(0.2))
                .frame(width: 32, height: 0.5)
                .padding(.top, 16)

            // Cards
            cardDisplay
                .padding(.top, 16)
                .padding(.bottom, 4)
        }
    }

    // MARK: - Card Display

    @ViewBuilder
    private var cardDisplay: some View {
        let count = drawnCards.count
        if count <= 3 {
            largeCardRow
        } else if count <= 7 {
            mediumCardGrid
        } else {
            smallCardGrid
        }
    }

    private var largeCardRow: some View {
        HStack(spacing: 12) {
            ForEach(Array(drawnCards.enumerated()), id: \.element.id) { idx, drawn in
                VStack(spacing: 8) {
                    cardImageView(drawn.card.image)
                        .frame(width: 90, height: 140)
                        .rotationEffect(drawn.reversed ? .degrees(180) : .zero)
                        .shadow(color: gold.opacity(0.15), radius: 8, y: 4)

                    VStack(spacing: 3) {
                        if idx < positions.count {
                            Text(positions[idx].label)
                                .font(.system(size: 8))
                                .foregroundColor(muted.opacity(0.6))
                        }
                        Text(cardNameFn(drawn.card))
                            .font(.system(size: 10, weight: .medium, design: .serif))
                            .foregroundColor(dark)
                            .lineLimit(1)
                        if drawn.reversed {
                            reversedBadge
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var mediumCardGrid: some View {
        VStack(spacing: 14) {
            let firstRowCount = min(drawnCards.count, drawnCards.count > 5 ? 4 : 3)
            HStack(spacing: 8) {
                ForEach(Array(drawnCards.prefix(firstRowCount).enumerated()), id: \.element.id) { idx, drawn in
                    mediumCardCell(drawn: drawn, idx: idx)
                }
            }
            if drawnCards.count > firstRowCount {
                HStack(spacing: 8) {
                    ForEach(Array(drawnCards.dropFirst(firstRowCount).enumerated()), id: \.element.id) { idx, drawn in
                        mediumCardCell(drawn: drawn, idx: idx + firstRowCount)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func mediumCardCell(drawn: DrawnCard, idx: Int) -> some View {
        VStack(spacing: 5) {
            cardImageView(drawn.card.image)
                .frame(width: 56, height: 87)
                .rotationEffect(drawn.reversed ? .degrees(180) : .zero)
                .shadow(color: gold.opacity(0.1), radius: 4, y: 2)

            VStack(spacing: 2) {
                if idx < positions.count {
                    Text(positions[idx].label)
                        .font(.system(size: 7))
                        .foregroundColor(muted.opacity(0.5))
                        .lineLimit(1)
                }
                Text(cardNameFn(drawn.card))
                    .font(.system(size: 8, weight: .medium, design: .serif))
                    .foregroundColor(dark)
                    .lineLimit(1)
                if drawn.reversed {
                    Text("R")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 12, height: 12)
                        .background(accent.opacity(0.7))
                        .cornerRadius(2)
                }
            }
        }
    }

    private var smallCardGrid: some View {
        VStack(spacing: 10) {
            let cols = drawnCards.count > 10 ? 5 : 4
            let rows = (drawnCards.count + cols - 1) / cols

            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<cols, id: \.self) { col in
                        let idx = row * cols + col
                        if idx < drawnCards.count {
                            smallCardCell(drawn: drawnCards[idx], idx: idx)
                        } else {
                            Color.clear.frame(width: 44, height: 80)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func smallCardCell(drawn: DrawnCard, idx: Int) -> some View {
        VStack(spacing: 3) {
            cardImageView(drawn.card.image)
                .frame(width: 44, height: 68)
                .rotationEffect(drawn.reversed ? .degrees(180) : .zero)
                .shadow(color: gold.opacity(0.08), radius: 3, y: 1)

            Text(cardNameFn(drawn.card))
                .font(.system(size: 6, weight: .medium))
                .foregroundColor(dark)
                .lineLimit(1)

            if drawn.reversed {
                Circle()
                    .fill(accent.opacity(0.6))
                    .frame(width: 4, height: 4)
            }
        }
    }

    private var reversedBadge: some View {
        Text("Reversed")
            .font(.system(size: 7, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(accent.opacity(0.7))
            .cornerRadius(3)
    }

    // MARK: - AI Reading Section

    private var aiReadingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                    .foregroundColor(accent)
                Text("AI Deep Reading")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(dark)
            }

            // Render truncated AI text — poster shows summary only
            posterMarkdown(truncatedReading)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
    }

    /// Truncate AI reading for poster — keep first ~400 chars (roughly first 2 sections)
    private var truncatedReading: String {
        let lines = aiReading.components(separatedBy: "\n")
        var result: [String] = []
        var charCount = 0
        var sectionCount = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") { sectionCount += 1 }
            if sectionCount > 2 && charCount > 300 { break }
            result.append(line)
            charCount += line.count
            if charCount > 500 { break }
        }

        let text = result.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if text.count < aiReading.count {
            return text + "\n\n✦ ..."
        }
        return text
    }

    /// Strip inline markdown: **bold**, *italic*, __bold__, _italic_
    private func stripInlineMarkdown(_ text: String) -> String {
        var s = text
        // Bold: **text** or __text__
        while let range = s.range(of: #"\*\*(.+?)\*\*"#, options: .regularExpression) {
            let inner = s[range].dropFirst(2).dropLast(2)
            s.replaceSubrange(range, with: inner)
        }
        while let range = s.range(of: #"__(.+?)__"#, options: .regularExpression) {
            let inner = s[range].dropFirst(2).dropLast(2)
            s.replaceSubrange(range, with: inner)
        }
        // Italic: *text* or _text_
        while let range = s.range(of: #"\*(.+?)\*"#, options: .regularExpression) {
            let inner = s[range].dropFirst(1).dropLast(1)
            s.replaceSubrange(range, with: inner)
        }
        while let range = s.range(of: #"\b_(.+?)_\b"#, options: .regularExpression) {
            let inner = s[range].dropFirst(1).dropLast(1)
            s.replaceSubrange(range, with: inner)
        }
        return s
    }

    /// Simple markdown rendering for the poster (no ThemeManager dependency)
    @ViewBuilder
    private func posterMarkdown(_ text: String) -> some View {
        let lines = text.components(separatedBy: "\n")
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty {
                    Spacer().frame(height: 4)
                } else if trimmed.hasPrefix("###") {
                    Text(stripInlineMarkdown(trimmed.replacingOccurrences(of: "### ", with: "").replacingOccurrences(of: "###", with: "")))
                        .font(.system(size: 11, weight: .semibold, design: .serif))
                        .foregroundColor(dark)
                        .padding(.top, 4)
                } else if trimmed.hasPrefix("##") {
                    Text(stripInlineMarkdown(trimmed.replacingOccurrences(of: "## ", with: "").replacingOccurrences(of: "##", with: "")))
                        .font(.system(size: 12, weight: .semibold, design: .serif))
                        .foregroundColor(dark)
                        .padding(.top, 6)
                } else if trimmed.hasPrefix("#") {
                    Text(stripInlineMarkdown(trimmed.replacingOccurrences(of: "# ", with: "").replacingOccurrences(of: "#", with: "")))
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundColor(dark)
                        .padding(.top, 8)
                } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                    HStack(alignment: .top, spacing: 6) {
                        Text("·")
                            .font(.system(size: 10))
                            .foregroundColor(gold)
                            .offset(y: 1)
                        Text(stripInlineMarkdown(String(trimmed.dropFirst(2))))
                            .font(.system(size: 10))
                            .foregroundColor(dark.opacity(0.85))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else if trimmed.hasPrefix("---") || trimmed.hasPrefix("***") {
                    Rectangle()
                        .fill(gold.opacity(0.15))
                        .frame(height: 0.5)
                        .padding(.vertical, 4)
                } else {
                    Text(stripInlineMarkdown(trimmed))
                        .font(.system(size: 10))
                        .foregroundColor(dark.opacity(0.85))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Bottom Branding

    private var bottomBranding: some View {
        VStack(spacing: 10) {
            Rectangle()
                .fill(gold.opacity(0.15))
                .frame(width: 24, height: 0.5)

            // App icon placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.15), gold.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(gold.opacity(0.2), lineWidth: 0.5)
                    )
                Text("✦")
                    .font(.system(size: 16))
                    .foregroundColor(accent.opacity(0.6))
            }

            Text("TAROT MYSTICA")
                .font(.system(size: 9, weight: .medium))
                .tracking(3)
                .foregroundColor(muted.opacity(0.5))

            Text("On-device AI · Private & Secure")
                .font(.system(size: 7))
                .foregroundColor(muted.opacity(0.3))
        }
        .padding(.bottom, 28)
    }

    // MARK: - Card Image

    private func cardImageView(_ filename: String) -> some View {
        let name = filename.replacingOccurrences(of: ".webp", with: "")
        if let path = Bundle.main.path(forResource: name, ofType: "webp"),
           let uiImage = UIImage(contentsOfFile: path) {
            return AnyView(
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(4)
            )
        }
        return AnyView(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - Poster Renderer

@MainActor
struct PosterRenderer {
    static func render(
        question: String,
        spreadName: String,
        spreadKey: String?,
        drawnCards: [DrawnCard],
        positions: [SpreadPosition],
        aiReading: String,
        cardNameFn: @escaping (TarotCard) -> String,
        cardTextFn: @escaping (TarotCard, String) -> String
    ) -> UIImage? {
        let poster = SharePosterView(
            question: question,
            spreadName: spreadName,
            spreadKey: spreadKey,
            drawnCards: drawnCards,
            positions: positions,
            aiReading: aiReading,
            cardNameFn: cardNameFn,
            cardTextFn: cardTextFn
        )

        let renderer = ImageRenderer(content: poster)
        renderer.scale = 3.0
        return renderer.uiImage
    }
}
