import Foundation

/// In-memory history of the last N converted clips (not persisted — privacy-first).
final class ClipboardHistory {
    static let shared = ClipboardHistory()
    private init() {}

    struct Entry: Identifiable {
        let id = UUID()
        let preview: String    // first ~60 chars of original
        let originalText: String
        let convertedHTML: String
        let date: Date
    }

    private(set) var entries: [Entry] = []
    private let maxEntries = 8

    func add(original: String, html: String) {
        let preview = original
            .components(separatedBy: "\n")
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }?
            .trimmingCharacters(in: .whitespaces) ?? original
        let truncated = preview.count > 60 ? String(preview.prefix(57)) + "…" : preview
        let entry = Entry(preview: truncated, originalText: original, convertedHTML: html, date: .now)
        entries.insert(entry, at: 0)
        if entries.count > maxEntries { entries = Array(entries.prefix(maxEntries)) }
    }

    func restore(_ entry: Entry) {
        guard let attributed = MarkdownConverter.htmlToAttributedString(entry.convertedHTML) else { return }
        PasteboardWriter.write(html: entry.convertedHTML, attributed: attributed, plain: entry.originalText)
    }
}
