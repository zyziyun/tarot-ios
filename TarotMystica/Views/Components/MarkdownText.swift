import SwiftUI

struct MarkdownText: View {
    let text: String
    let theme: ThemeManager

    init(_ text: String, theme: ThemeManager) {
        self.text = text
        self.theme = theme
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(parseBlocks().enumerated()), id: \.offset) { idx, block in
                blockView(block, isFirst: idx == 0)
            }
        }
    }

    private enum Block {
        case heading(String, Int)      // text, level (1-3)
        case paragraph(String)
        case bullet(String)
        case divider
    }

    private func parseBlocks() -> [Block] {
        var blocks: [Block] = []
        let lines = text.components(separatedBy: "\n")
        var paragraphBuffer = ""

        func flushParagraph() {
            let trimmed = paragraphBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                blocks.append(.paragraph(trimmed))
            }
            paragraphBuffer = ""
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                flushParagraph()
                continue
            }

            if trimmed.hasPrefix("###") {
                flushParagraph()
                let content = trimmed.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(content, 3))
            } else if trimmed.hasPrefix("##") {
                flushParagraph()
                let content = trimmed.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(content, 2))
            } else if trimmed.hasPrefix("#") {
                flushParagraph()
                let content = trimmed.drop(while: { $0 == "#" }).trimmingCharacters(in: .whitespaces)
                blocks.append(.heading(content, 1))
            }
            else if trimmed.allSatisfy({ $0 == "-" || $0 == "*" || $0 == " " }) && trimmed.count >= 3 {
                flushParagraph()
                blocks.append(.divider)
            }
            else if (trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ")) {
                flushParagraph()
                let content = String(trimmed.dropFirst(2))
                blocks.append(.bullet(content))
            }
            else {
                if !paragraphBuffer.isEmpty {
                    paragraphBuffer += " "
                }
                paragraphBuffer += trimmed
            }
        }
        flushParagraph()
        return blocks
    }

    @ViewBuilder
    private func blockView(_ block: Block, isFirst: Bool = false) -> some View {
        switch block {
        case .heading(let text, let level):
            VStack(alignment: .leading, spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(theme.colors.border.opacity(0.3))
                        .frame(height: 0.5)
                        .padding(.bottom, 8)
                }
                styledInlineText(text)
                    .font(.system(size: headingSize(level), weight: .semibold, design: .serif))
                    .foregroundColor(theme.colors.foreground)
            }
            .padding(.top, isFirst ? 0 : 6)

        case .paragraph(let text):
            styledInlineText(text)
                .font(.system(size: 14))
                .foregroundColor(theme.colors.foreground.opacity(0.88))
                .lineSpacing(6)

        case .bullet(let text):
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.accent)
                    .padding(.top, 1)
                styledInlineText(text)
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.foreground.opacity(0.88))
                    .lineSpacing(6)
            }

        case .divider:
            HStack(spacing: 10) {
                Rectangle().fill(theme.colors.border.opacity(0.4)).frame(height: 0.5)
                Text("✦")
                    .font(.system(size: 6))
                    .foregroundColor(theme.colors.gold.opacity(0.4))
                Rectangle().fill(theme.colors.border.opacity(0.4)).frame(height: 0.5)
            }
            .padding(.vertical, 6)
        }
    }

    private func headingSize(_ level: Int) -> CGFloat {
        switch level {
        case 1: return 18
        case 2: return 16
        default: return 15
        }
    }

    private func styledInlineText(_ input: String) -> Text {
        var result = Text("")
        var remaining = input[input.startIndex...]

        while !remaining.isEmpty {
            // Bold: **text**
            if remaining.hasPrefix("**") {
                let after = remaining.index(remaining.startIndex, offsetBy: 2)
                if let endRange = remaining[after...].range(of: "**") {
                    let boldContent = String(remaining[after..<endRange.lowerBound])
                    result = result + Text(boldContent).bold()
                    remaining = remaining[endRange.upperBound...]
                    continue
                }
            }

            // Italic: *text* (single asterisk, not double)
            if remaining.hasPrefix("*") && !remaining.hasPrefix("**") {
                let after = remaining.index(remaining.startIndex, offsetBy: 1)
                if let endIdx = remaining[after...].firstIndex(of: "*") {
                    let italicContent = String(remaining[after..<endIdx])
                    result = result + Text(italicContent).italic()
                    remaining = remaining[remaining.index(after: endIdx)...]
                    continue
                }
            }

            // Find next special character
            let nextStar = remaining.dropFirst().firstIndex(of: "*")
            let end = nextStar ?? remaining.endIndex
            let plainText = String(remaining[remaining.startIndex..<end])
            result = result + Text(plainText)
            remaining = remaining[end...]
        }

        return result
    }
}
