# ClipFormat

**Copy from app A → press ⌥⌘C → paste perfectly formatted in app B. Every time.**

---

## The Problem

Copying between apps breaks formatting. AI tools give you raw Markdown. Browser copies lose their styling in Word. RTF from Pages won't paste into Notion. Every app speaks a different clipboard dialect.

## The Fix

ClipFormat is a universal clipboard format merger. It reads whatever's on your clipboard, normalizes it, and writes RTF + HTML + plain text simultaneously — so every target app gets the richest format it supports.

## How It Works

1. Copy from **anywhere** — browser, Word, AI chat, PDF, anything
2. Press **⌥⌘C** (Option + Command + C)
3. ClipFormat auto-detects the source format and normalizes it
4. Press **⌘V** anywhere — looks identical to the source

### Source detection (automatic)

| What you copied | What ClipFormat does |
|---|---|
| Browser (ChatGPT, Claude, Notion...) | Reads HTML, strips noise, converts to RTF |
| Word / Pages / Mail | Reads RTF, generates HTML |
| Plain text with Markdown | Parses Markdown → HTML + RTF |
| Plain text | Normalizes to all formats |

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
