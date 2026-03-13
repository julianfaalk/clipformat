import AppKit
import Foundation

/// Converts between rich text formats.
/// All paths ultimately produce the three-format tuple that PasteboardWriter needs.
struct FormatBridge {

    struct Result {
        let html: String
        let attributed: NSAttributedString
        let plain: String
        let sourceLabel: String   // shown in menu bar flash, e.g. "HTML→RTF"
    }

    // MARK: - Entry point

    static func convert(source: ClipboardReader.Source) -> Result? {
        switch source {
        case .html(let html):
            return fromHTML(html)
        case .rtf(let data):
            return fromRTF(data)
        case .markdown(let text):
            return fromMarkdown(text)
        case .plainText(let text):
            return fromPlain(text)
        case .empty:
            return nil
        }
    }

    // MARK: - HTML → RTF + plain

    /// Browser copies (ChatGPT, Claude.ai, Notion web, Google Docs, etc.)
    static func fromHTML(_ html: String) -> Result? {
        // Clean up browser-injected meta cruft before converting
        let cleaned = sanitizeBrowserHTML(html)

        guard let data = cleaned.data(using: .utf8),
              let attributed = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue,
                ],
                documentAttributes: nil
              )
        else { return nil }

        let plain = attributed.string
        return Result(html: cleaned, attributed: attributed, plain: plain, sourceLabel: "HTML→RTF")
    }

    // MARK: - RTF → HTML + plain

    /// Copies from Word, Pages, TextEdit, Mail, etc.
    static func fromRTF(_ data: Data) -> Result? {
        guard let attributed = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        ) else { return nil }

        // Export to HTML
        let htmlData = try? attributed.data(
            from: NSRange(location: 0, length: attributed.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.html]
        )
        let html = htmlData.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        let plain = attributed.string

        return Result(html: html, attributed: attributed, plain: plain, sourceLabel: "RTF→HTML")
    }

    // MARK: - Markdown → HTML + RTF

    static func fromMarkdown(_ text: String) -> Result? {
        let html = MarkdownConverter.toHTML(text)
        guard let attributed = MarkdownConverter.htmlToAttributedString(html) else { return nil }
        return Result(html: html, attributed: attributed, plain: text, sourceLabel: "MD→RTF")
    }

    // MARK: - Plain text (no Markdown)

    static func fromPlain(_ text: String) -> Result? {
        // Wrap in a simple paragraph so apps get a consistent attributed string
        let attributed = NSAttributedString(
            string: text,
            attributes: [.font: NSFont.systemFont(ofSize: 13)]
        )
        let html = "<p>\(text.replacingOccurrences(of: "\n", with: "<br>"))</p>"
        return Result(html: html, attributed: attributed, plain: text, sourceLabel: "Plain✓")
    }

    // MARK: - HTML Sanitizer

    /// Strips browser-injected noise (Google Docs wrapper divs, ChatGPT class names, etc.)
    /// while preserving semantic structure.
    private static func sanitizeBrowserHTML(_ html: String) -> String {
        var s = html

        // Remove inline styles (keep structure, lose colors/fonts — let target app decide)
        s = MarkdownConverter.regex(s, #" style=\"[^\"]*\""#, "")

        // Remove class attributes
        s = MarkdownConverter.regex(s, #" class=\"[^\"]*\""#, "")

        // Remove data-* attributes
        s = MarkdownConverter.regex(s, #" data-[a-z-]+=\"[^\"]*\""#, "")

        // Remove span tags but keep contents (they're usually just styling wrappers)
        s = MarkdownConverter.regex(s, #"<span[^>]*>"#, "")
        s = s.replacingOccurrences(of: "</span>", with: "")

        // Remove empty tags
        s = MarkdownConverter.regex(s, #"<(?:div|p|span)[^>]*>\s*</(?:div|p|span)>"#, "")

        return s
    }
}
