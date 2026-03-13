import AppKit

/// Writes multiple clipboard representations simultaneously.
/// Apps pick the richest format they support:
///   - RTF       → Word, Pages, Mail, Apple Notes, Slack desktop, Outlook, TextEdit
///   - HTML      → Notion (web), Google Docs, Linear, any browser-based editor
///   - Plain     → VS Code, Terminal, Discord, any plain-text field (automatic fallback)
struct PasteboardWriter {

    static func write(html: String, attributed: NSAttributedString, plain: String) {
        let item = NSPasteboardItem()

        // 1. RTF — native macOS rich text
        if let rtf = try? attributed.data(
            from: NSRange(location: 0, length: attributed.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        ) {
            item.setData(rtf, forType: .rtf)
        }

        // 2. HTML — consumed by web apps (browsers map public.html ↔ text/html)
        if let htmlData = html.data(using: .utf8) {
            item.setData(htmlData, forType: .html)
        }

        // 3. Plain text — universal fallback
        item.setString(plain, forType: .string)

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([item])
    }
}
