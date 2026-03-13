import AppKit
import Foundation

/// Converts Markdown text to a styled NSAttributedString via HTML.
/// Handles: headers, bold, italic, code (inline + blocks), lists, links, horizontal rules.
struct MarkdownConverter {

    static func convert(_ markdown: String) -> NSAttributedString? {
        let html = markdownToHTML(markdown)
        return htmlToAttributedString(html)
    }

    // MARK: - Markdown → HTML

    static func markdownToHTML(_ input: String) -> String {
        var lines = input.components(separatedBy: "\n")
        var output: [String] = []
        var i = 0
        var inCodeBlock = false
        var inUL = false
        var inOL = false

        func closeList() {
            if inUL { output.append("</ul>"); inUL = false }
            if inOL { output.append("</ol>"); inOL = false }
        }

        while i < lines.count {
            var line = lines[i]

            // Code block (```)
            if line.hasPrefix("```") {
                closeList()
                if !inCodeBlock {
                    inCodeBlock = true
                    output.append("<pre><code>")
                } else {
                    inCodeBlock = false
                    output.append("</code></pre>")
                }
                i += 1
                continue
            }

            if inCodeBlock {
                output.append(escapeHTML(line))
                i += 1
                continue
            }

            // Horizontal rule
            if line.trimmingCharacters(in: .whitespaces) == "---" ||
               line.trimmingCharacters(in: .whitespaces) == "***" ||
               line.trimmingCharacters(in: .whitespaces) == "___" {
                closeList()
                output.append("<hr>")
                i += 1
                continue
            }

            // Headers
            if line.hasPrefix("### ") {
                closeList()
                output.append("<h3>\(applyInline(String(line.dropFirst(4))))</h3>")
                i += 1; continue
            }
            if line.hasPrefix("## ") {
                closeList()
                output.append("<h2>\(applyInline(String(line.dropFirst(3))))</h2>")
                i += 1; continue
            }
            if line.hasPrefix("# ") {
                closeList()
                output.append("<h1>\(applyInline(String(line.dropFirst(2))))</h1>")
                i += 1; continue
            }

            // Unordered list
            if line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") {
                if inOL { output.append("</ol>"); inOL = false }
                if !inUL { output.append("<ul>"); inUL = true }
                output.append("<li>\(applyInline(String(line.dropFirst(2))))</li>")
                i += 1; continue
            }

            // Ordered list (e.g. "1. ")
            let olPattern = #"^\d+\. (.+)$"#
            if let match = line.range(of: olPattern, options: .regularExpression) {
                let content = String(line[line.index(line.startIndex, offsetBy: line.distance(from: line.startIndex, to: match.lowerBound)):].dropFirst(line.prefix(while: { $0.isNumber }).count + 2))
                if inUL { output.append("</ul>"); inUL = false }
                if !inOL { output.append("<ol>"); inOL = true }
                output.append("<li>\(applyInline(content))</li>")
                i += 1; continue
            }

            // Blockquote
            if line.hasPrefix("> ") {
                closeList()
                output.append("<blockquote>\(applyInline(String(line.dropFirst(2))))</blockquote>")
                i += 1; continue
            }

            // Blank line → paragraph break
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                closeList()
                output.append("<br>")
                i += 1; continue
            }

            // Regular paragraph
            closeList()
            output.append("<p>\(applyInline(line))</p>")
            i += 1
        }

        if inUL { output.append("</ul>") }
        if inOL { output.append("</ol>") }
        if inCodeBlock { output.append("</code></pre>") }

        let body = output.joined(separator: "\n")
        return """
        <html><head><style>
        body { font-family: -apple-system, sans-serif; font-size: 13px; }
        h1 { font-size: 20px; font-weight: bold; }
        h2 { font-size: 17px; font-weight: bold; }
        h3 { font-size: 14px; font-weight: bold; }
        pre { background: #f5f5f5; padding: 8px; border-radius: 4px; }
        code { font-family: monospace; background: #f0f0f0; padding: 1px 4px; border-radius: 3px; }
        pre code { background: none; padding: 0; }
        blockquote { border-left: 3px solid #ccc; margin-left: 0; padding-left: 12px; color: #555; }
        hr { border: none; border-top: 1px solid #ccc; }
        </style></head><body>\(body)</body></html>
        """
    }

    // MARK: - Inline Markdown (bold, italic, code, links)

    static func applyInline(_ text: String) -> String {
        var s = text

        // Inline code (before bold/italic to avoid interference)
        s = s.replacingOccurrences(of: #"`([^`]+)`"#, with: "<code>$1</code>", options: .regularExpression)

        // Bold+Italic
        s = s.replacingOccurrences(of: #"\*\*\*(.+?)\*\*\*"#, with: "<strong><em>$1</em></strong>", options: .regularExpression)

        // Bold
        s = s.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)
        s = s.replacingOccurrences(of: #"__(.+?)__"#, with: "<strong>$1</strong>", options: .regularExpression)

        // Italic
        s = s.replacingOccurrences(of: #"\*(.+?)\*"#, with: "<em>$1</em>", options: .regularExpression)
        s = s.replacingOccurrences(of: #"_(.+?)_"#, with: "<em>$1</em>", options: .regularExpression)

        // Strikethrough
        s = s.replacingOccurrences(of: #"~~(.+?)~~"#, with: "<s>$1</s>", options: .regularExpression)

        // Links [text](url)
        s = s.replacingOccurrences(of: #"\[(.+?)\]\((.+?)\)"#, with: "<a href=\"$2\">$1</a>", options: .regularExpression)

        return s
    }

    static func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    // MARK: - HTML → NSAttributedString

    static func htmlToAttributedString(_ html: String) -> NSAttributedString? {
        guard let data = html.data(using: .utf8) else { return nil }
        return try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
    }
}
