import AppKit

/// Reads the richest available format from the clipboard and reports the source type.
struct ClipboardReader {

    enum Source {
        case html(String)           // copied from browser / web app
        case rtf(Data)             // copied from Word, Pages, etc.
        case markdown(String)      // plain text with Markdown syntax
        case plainText(String)     // plain text, no detectable formatting
        case empty
    }

    static func read() -> Source {
        let pb = NSPasteboard.general

        // 1. RTF (highest fidelity native format)
        if let data = pb.data(forType: .rtf) {
            return .rtf(data)
        }

        // 2. HTML (browser copies, Notion, Google Docs, web editors)
        if let html = pb.string(forType: .html), !html.isEmpty {
            return .html(html)
        }

        // 3. Plain text — distinguish Markdown from regular text
        if let text = pb.string(forType: .string), !text.isEmpty {
            return MarkdownConverter.looksLikeMarkdown(text) ? .markdown(text) : .plainText(text)
        }

        return .empty
    }
}
