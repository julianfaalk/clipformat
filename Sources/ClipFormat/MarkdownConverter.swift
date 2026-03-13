import AppKit
import Foundation

// MARK: - Public API

struct MarkdownConverter {

    /// Returns true if the string contains Markdown syntax worth converting.
    static func looksLikeMarkdown(_ text: String) -> Bool {
        let patterns: [String] = [
            #"^#{1,6} "#,                   // ATX headers
            #"^={3,}$"#,                    // Setext h1
            #"^-{3,}$"#,                    // Setext h2 or HR
            #"\*\*[^*\n]+\*\*"#,           // Bold
            #"\*[^*\n]+\*"#,               // Italic
            #"__[^_\n]+__"#,               // Bold underscore
            #"_[^_\n]+_"#,                 // Italic underscore
            #"`[^`\n]+`"#,                 // Inline code
            #"^```"#,                       // Code block
            #"^\s*[-*+] "#,                // Unordered list
            #"^\s*\d+\. "#,               // Ordered list
            #"^\s*- \[[ xX]\]"#,          // Task list
            #"^\|.+\|"#,                   // Table
            #"^> "#,                        // Blockquote
            #"~~[^~\n]+~~"#,               // Strikethrough
            #"\[[^\]]+\]\([^)]+\)"#,       // Link
        ]
        for line in text.components(separatedBy: "\n") {
            for pattern in patterns {
                if line.range(of: pattern, options: .regularExpression) != nil { return true }
            }
        }
        return false
    }

    /// Full markdown → NSAttributedString pipeline.
    static func htmlToAttributedString(_ html: String) -> NSAttributedString? {
        guard let data = html.data(using: .utf8) else { return nil }
        return try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue,
            ],
            documentAttributes: nil
        )
    }

    // MARK: - Markdown → HTML

    static func toHTML(_ input: String) -> String {
        var lines = input.components(separatedBy: "\n")
        var out: [String] = []
        var i = 0

        // List stack: (tag, indentSpaces)
        var listStack: [(tag: String, indent: Int)] = []
        var inCodeBlock = false
        var codeLang = ""
        var codeLines: [String] = []

        // Flush open lists down to a target indent level
        func closeLists(toIndent target: Int = -1) {
            while let last = listStack.last, last.indent > target {
                out.append("</\(listStack.removeLast().tag)>")
            }
        }

        func openList(tag: String, indent: Int) {
            closeLists(toIndent: indent - 1)
            if let last = listStack.last {
                if last.indent == indent && last.tag != tag {
                    out.append("</\(listStack.removeLast().tag)>")
                    out.append("<\(tag)>")
                    listStack.append((tag, indent))
                    return
                }
                if last.indent == indent { return } // already open
            }
            out.append("<\(tag)>")
            listStack.append((tag, indent))
        }

        func flush() { closeLists() }

        // ── Main loop ──────────────────────────────────────────────────
        while i < lines.count {
            let raw = lines[i]
            let trimmed = raw.trimmingCharacters(in: .whitespaces)

            // ── Fenced code blocks ──
            if raw.hasPrefix("```") || raw.hasPrefix("~~~") {
                let fence = raw.hasPrefix("```") ? "```" : "~~~"
                if !inCodeBlock {
                    flush()
                    inCodeBlock = true
                    codeLang = String(raw.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    codeLines = []
                } else {
                    inCodeBlock = false
                    let code = codeLines.map { escapeHTML($0) }.joined(separator: "\n")
                    let cls = codeLang.isEmpty ? "" : " class=\"language-\(codeLang)\""
                    out.append("<pre><code\(cls)>\(code)</code></pre>")
                    codeLines = []; codeLang = ""
                }
                i += 1; continue
            }

            if inCodeBlock { codeLines.append(raw); i += 1; continue }

            // ── Horizontal rule ──
            let isHR = (trimmed == "---" || trimmed == "***" || trimmed == "___" ||
                        trimmed == "- - -" || trimmed == "* * *")
            if isHR { flush(); out.append("<hr>"); i += 1; continue }

            // ── Setext headers (must peek ahead) ──
            if i + 1 < lines.count && !trimmed.isEmpty {
                let next = lines[i + 1].trimmingCharacters(in: .whitespaces)
                if next.count >= 2 && next.allSatisfy({ $0 == "=" }) {
                    flush(); out.append("<h1>\(inline(trimmed))</h1>"); i += 2; continue
                }
                if next.count >= 2 && next.allSatisfy({ $0 == "-" }) && !trimmed.hasPrefix("-") {
                    flush(); out.append("<h2>\(inline(trimmed))</h2>"); i += 2; continue
                }
            }

            // ── ATX Headers ──
            if trimmed.hasPrefix("#") {
                var level = 0
                var rest = trimmed
                while rest.hasPrefix("#") && level < 6 { rest = String(rest.dropFirst()); level += 1 }
                if rest.hasPrefix(" ") || rest.isEmpty {
                    flush()
                    let content = rest.hasPrefix(" ") ? String(rest.dropFirst()) : ""
                    out.append("<h\(level)>\(inline(content))</h\(level)>")
                    i += 1; continue
                }
            }

            // ── Tables (look ahead for separator row) ──
            if isTableRow(trimmed) && i + 1 < lines.count && isTableSeparator(lines[i + 1]) {
                flush()
                let headers = parseCells(trimmed)
                var html = "<table><thead><tr>"
                html += headers.map { "<th>\(inline($0))</th>" }.joined()
                html += "</tr></thead><tbody>"
                i += 2 // skip header + separator
                while i < lines.count && isTableRow(lines[i]) {
                    let cells = parseCells(lines[i])
                    html += "<tr>" + cells.map { "<td>\(inline($0))</td>" }.joined() + "</tr>"
                    i += 1
                }
                html += "</tbody></table>"
                out.append(html); continue
            }

            // ── Blockquote ──
            if trimmed.hasPrefix("> ") {
                flush()
                out.append("<blockquote>\(inline(String(trimmed.dropFirst(2))))</blockquote>")
                i += 1; continue
            }

            // ── Lists ──
            let indent = raw.prefix(while: { $0 == " " || $0 == "\t" }).count

            // Task list items
            if let taskHTML = parseTaskItem(trimmed) {
                openList(tag: "ul", indent: indent)
                out.append(taskHTML); i += 1; continue
            }

            // Unordered list
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                openList(tag: "ul", indent: indent)
                out.append("<li>\(inline(String(trimmed.dropFirst(2))))</li>")
                i += 1; continue
            }

            // Ordered list
            if let olContent = parseOrderedItem(trimmed) {
                openList(tag: "ol", indent: indent)
                out.append("<li>\(inline(olContent))</li>")
                i += 1; continue
            }

            // ── Blank line ──
            if trimmed.isEmpty { flush(); out.append("<br>"); i += 1; continue }

            // ── Paragraph ──
            flush()
            out.append("<p>\(inline(trimmed))</p>")
            i += 1
        }

        flush()
        if inCodeBlock {
            let code = codeLines.map { escapeHTML($0) }.joined(separator: "\n")
            out.append("<pre><code>\(code)</code></pre>")
        }

        return wrapHTML(out.joined(separator: "\n"))
    }

    // MARK: - Inline Formatting

    static func inline(_ text: String) -> String {
        var s = text

        // Inline code (first, to protect contents)
        s = regex(s, #"`([^`\n]+)`"#, "<code>$1</code>")

        // Bold + Italic combinations
        s = regex(s, #"\*\*\*(.+?)\*\*\*"#, "<strong><em>$1</em></strong>")
        s = regex(s, #"___(.+?)___"#, "<strong><em>$1</em></strong>")

        // Bold
        s = regex(s, #"\*\*(.+?)\*\*"#, "<strong>$1</strong>")
        s = regex(s, #"__(.+?)__"#, "<strong>$1</strong>")

        // Italic
        s = regex(s, #"(?<![*])\*([^*\n]+)\*(?![*])"#, "<em>$1</em>")
        s = regex(s, #"(?<![_])_([^_\n]+)_(?![_])"#, "<em>$1</em>")

        // Strikethrough
        s = regex(s, #"~~(.+?)~~"#, "<s>$1</s>")

        // Links [text](url)
        s = regex(s, #"\[([^\]]+)\]\(([^)]+)\)"#, "<a href=\"$2\">$1</a>")

        // Bare URLs (not already inside an href)
        s = regex(s, #"(?<!href=\")(https?://[^\s<>\"']+)"#, "<a href=\"$1\">$1</a>")

        return s
    }

    // MARK: - Helpers

    static func parseTaskItem(_ line: String) -> String? {
        if line.hasPrefix("- [ ] ") || line.hasPrefix("* [ ] ") {
            return "<li>☐ \(inline(String(line.dropFirst(6))))</li>"
        }
        if line.hasPrefix("- [x] ") || line.hasPrefix("- [X] ") ||
           line.hasPrefix("* [x] ") || line.hasPrefix("* [X] ") {
            return "<li><s>☑ \(inline(String(line.dropFirst(6))))</s></li>"
        }
        return nil
    }

    static func parseOrderedItem(_ line: String) -> String? {
        var idx = line.startIndex
        while idx < line.endIndex && line[idx].isNumber { idx = line.index(after: idx) }
        guard idx > line.startIndex, idx < line.endIndex, line[idx] == "." else { return nil }
        let after = line.index(after: idx)
        guard after < line.endIndex, line[after] == " " else { return nil }
        return String(line[line.index(after: after)...])
    }

    static func isTableRow(_ s: String) -> Bool {
        let t = s.trimmingCharacters(in: .whitespaces)
        return t.hasPrefix("|") && t.hasSuffix("|") && !isTableSeparator(t)
    }

    static func isTableSeparator(_ s: String) -> Bool {
        let t = s.trimmingCharacters(in: .whitespaces)
        guard t.hasPrefix("|") && t.hasSuffix("|") else { return false }
        return t.contains("---") || t.contains("===")
    }

    static func parseCells(_ row: String) -> [String] {
        let t = row.trimmingCharacters(in: .whitespaces)
        let inner = t.hasPrefix("|") ? String(t.dropFirst()) : t
        let stripped = inner.hasSuffix("|") ? String(inner.dropLast()) : inner
        return stripped.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    static func escapeHTML(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }

    static func regex(_ s: String, _ pattern: String, _ template: String) -> String {
        guard let rx = try? NSRegularExpression(pattern: pattern) else { return s }
        return rx.stringByReplacingMatches(
            in: s, range: NSRange(s.startIndex..., in: s), withTemplate: template
        )
    }

    // MARK: - HTML Wrapper

    static func wrapHTML(_ body: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="UTF-8">
        <style>
        body {
            font-family: -apple-system, 'Helvetica Neue', Arial, sans-serif;
            font-size: 14px;
            line-height: 1.65;
            color: #1a1a1a;
            margin: 0;
            padding: 0;
        }
        h1 { font-size: 22px; font-weight: 700; margin: 20px 0 8px; border-bottom: 2px solid #e5e5e5; padding-bottom: 6px; }
        h2 { font-size: 18px; font-weight: 700; margin: 16px 0 6px; }
        h3 { font-size: 15px; font-weight: 600; margin: 14px 0 4px; }
        h4 { font-size: 13px; font-weight: 600; margin: 12px 0 4px; }
        p  { margin: 8px 0; }
        strong { font-weight: 700; }
        em { font-style: italic; }
        s  { color: #999; }
        a  { color: #0071e3; text-decoration: none; }
        code {
            font-family: 'SF Mono', 'Menlo', 'Consolas', monospace;
            font-size: 12.5px;
            background: #f0f0f0;
            padding: 2px 5px;
            border-radius: 4px;
        }
        pre {
            background: #f7f7f7;
            border: 1px solid #e0e0e0;
            border-radius: 8px;
            padding: 14px 18px;
            overflow-x: auto;
            margin: 12px 0;
        }
        pre code { background: none; padding: 0; font-size: 12.5px; }
        ul, ol { margin: 8px 0; padding-left: 28px; }
        li { margin: 4px 0; line-height: 1.55; }
        blockquote {
            border-left: 4px solid #d0d0d0;
            margin: 10px 0;
            padding: 4px 0 4px 18px;
            color: #555;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 14px 0;
            font-size: 13.5px;
        }
        th, td { border: 1px solid #d0d0d0; padding: 9px 14px; text-align: left; }
        th { background: #f2f2f2; font-weight: 600; }
        tr:nth-child(even) td { background: #fafafa; }
        hr { border: none; border-top: 2px solid #ebebeb; margin: 18px 0; }
        </style>
        </head>
        <body>\(body)</body>
        </html>
        """
    }
}
