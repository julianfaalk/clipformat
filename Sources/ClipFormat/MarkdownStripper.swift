import Foundation

/// Strips Markdown syntax from text, leaving clean readable plain text.
/// Useful for pasting into apps that don't need formatting (code editors, forms, etc.)
struct MarkdownStripper {

    static func strip(_ input: String) -> String {
        var lines = input.components(separatedBy: "\n")
        var out: [String] = []
        var inCodeBlock = false

        for raw in lines {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)

            // Toggle code blocks — preserve content, strip fences
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                inCodeBlock.toggle()
                continue
            }
            if inCodeBlock { out.append(raw); continue }

            // HR → blank line
            if trimmed == "---" || trimmed == "***" || trimmed == "___" { out.append(""); continue }

            // Headers → just the text
            var line = trimmed
            while line.hasPrefix("#") { line = String(line.dropFirst()) }
            line = line.trimmingCharacters(in: .whitespaces)

            // Strip table pipes
            if line.hasPrefix("|") && line.hasSuffix("|") {
                if line.contains("---") { continue } // separator row
                line = line.dropFirst().dropLast()
                    .components(separatedBy: "|")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .joined(separator: "  |  ")
            }

            // Blockquote
            if line.hasPrefix("> ") { line = String(line.dropFirst(2)) }

            // List bullets
            if line.hasPrefix("- [ ] ") || line.hasPrefix("* [ ] ") { line = "☐ " + String(line.dropFirst(6)) }
            else if line.hasPrefix("- [x] ") || line.hasPrefix("- [X] ") { line = "☑ " + String(line.dropFirst(6)) }
            else if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") { line = "• " + String(line.dropFirst(2)) }
            else if let stripped = stripOrderedBullet(line) { line = stripped }

            // Inline styles
            line = stripInline(line)

            out.append(line)
        }

        return out.joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func stripInline(_ s: String) -> String {
        var t = s
        // Bold+Italic
        t = regex(t, #"\*\*\*(.+?)\*\*\*"#, "$1")
        t = regex(t, #"___(.+?)___"#, "$1")
        // Bold
        t = regex(t, #"\*\*(.+?)\*\*"#, "$1")
        t = regex(t, #"__(.+?)__"#, "$1")
        // Italic
        t = regex(t, #"\*([^*\n]+)\*"#, "$1")
        t = regex(t, #"_([^_\n]+)_"#, "$1")
        // Strikethrough
        t = regex(t, #"~~(.+?)~~"#, "$1")
        // Inline code
        t = regex(t, #"`([^`\n]+)`"#, "$1")
        // Links [text](url) → text (url)
        t = regex(t, #"\[([^\]]+)\]\(([^)]+)\)"#, "$1 ($2)")
        return t
    }

    private static func stripOrderedBullet(_ line: String) -> String? {
        var i = line.startIndex
        while i < line.endIndex && line[i].isNumber { i = line.index(after: i) }
        guard i > line.startIndex, i < line.endIndex, line[i] == "." else { return nil }
        let after = line.index(after: i)
        guard after < line.endIndex, line[after] == " " else { return nil }
        return "  " + String(line[line.index(after: after)...])
    }

    private static func regex(_ s: String, _ pattern: String, _ template: String) -> String {
        guard let rx = try? NSRegularExpression(pattern: pattern) else { return s }
        return rx.stringByReplacingMatches(
            in: s, range: NSRange(s.startIndex..., in: s), withTemplate: template
        )
    }
}
