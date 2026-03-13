# ClipFormat

**Copy from ChatGPT / Claude / Gemini → press ⌥⌘C → paste beautifully formatted text in any app.**

---

## The Problem

AI tools output Markdown. When you paste into Word, Notion, Google Docs, Notes, Mail — you get raw symbols like `**bold**` instead of **bold**, `# Header` instead of a real header.

## The Fix

ClipFormat lives in your menu bar. One shortcut converts the Markdown on your clipboard to rich text. Then you paste normally.

## How It Works

1. Copy any AI response (ChatGPT, Claude, Gemini, Perplexity, ...)
2. Press **⌥⌘C** (Option + Command + C)
3. Menu bar briefly flashes ✅
4. Press **⌘V** anywhere — fully formatted

## App Compatibility

ClipFormat writes three formats to the clipboard simultaneously. Every app gets what it supports:

| Format | Apps |
|--------|------|
| **Rich Text (RTF)** | Word, Pages, Apple Notes, Mail, Outlook, Slack, TextEdit |
| **HTML** | Notion, Google Docs, Linear, Confluence, Coda, any web editor |
| **Plain text** | VS Code, Terminal, Discord, any plain-text input |

No configuration needed. It just works.

## Markdown Support

| Syntax | Renders as |
|--------|-----------|
| `# H1` `## H2` `### H3` | Headers (with underline style support) |
| `**bold**` / `__bold__` | **Bold** |
| `*italic*` / `_italic_` | *Italic* |
| `***bold italic***` | ***Bold italic*** |
| `` `inline code` `` | Inline code |
| ```` ```lang ```` blocks | Syntax-highlighted code blocks |
| `- item` / `* item` / `+ item` | Unordered lists (nested!) |
| `1. item` | Ordered lists (nested!) |
| `- [ ]` / `- [x]` | Task lists with ☐/☑ |
| `\| col \| col \|` tables | Full HTML tables with header |
| `> quote` | Blockquotes |
| `---` | Horizontal rule |
| `~~strikethrough~~` | ~~Strikethrough~~ |
| `[text](url)` | Hyperlinks |
| bare `https://` URLs | Auto-linked |

## Build

### Requirements
- macOS 13 (Ventura) or later
- Xcode 15+

### Steps

```bash
git clone https://github.com/julianfaalk/clipformat
```

1. Open `Package.swift` in Xcode (File → Open)
2. Set scheme to **My Mac**
3. **⌘R** to run immediately, or **Product → Archive** to build a standalone `.app`

### Run at Login

1. Archive → Distribute → Copy App
2. Move `ClipFormat.app` to `/Applications`
3. System Settings → General → Login Items → add ClipFormat

## Settings

Click the menu bar icon → **Settings…** to configure:

- Toggle auto-detect (skips conversion if no Markdown found)
- Toggle sound feedback
- Toggle macOS notifications

## License

MIT
