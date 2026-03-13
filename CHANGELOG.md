# Changelog

## v1.0 — Initial Release

### Core
- **Multi-format clipboard**: RTF + HTML + plain text written simultaneously — every app gets what it supports
- **Global hotkey ⌥⌘C** via Carbon `RegisterEventHotKey` (reliable across all apps and spaces)
- **Strip to plain text ⌥⌘X** — removes all Markdown syntax, outputs clean readable text
- **Menu bar only** — no Dock icon, zero clutter

### Markdown Parser
- ATX and Setext headers (`#`, `==`, `--`)
- Bold, italic, bold+italic (both `*` and `_` variants)
- Inline code and fenced code blocks (with language tag)
- Tables with header detection and alternate row shading
- Nested unordered and ordered lists (indent-aware)
- Task lists (`- [ ]` / `- [x]`) with ☐/☑ symbols
- Blockquotes
- Horizontal rules
- Strikethrough (`~~text~~`)
- Hyperlinks and auto-linked bare URLs

### Features
- **Onboarding** — step-by-step welcome window on first launch
- **Clipboard history** — last 8 conversions accessible from menu with one-click restore
- **Preview window** — WKWebView preview with source toggle, confirm before clipboard is replaced (optional)
- **Launch at Login** — SMAppService toggle in Settings
- **Auto-detect Markdown** — skips conversion if clipboard doesn't look like Markdown
- **Sound feedback** — system sound on convert/strip
- **macOS Notifications** — brief notification after successful convert
- **Settings window** — all options in one place (⌘,)

### Performance
- Fast markdown detection with early-exit character scan before regex
- Consecutive blank lines collapsed to single `<br>`
