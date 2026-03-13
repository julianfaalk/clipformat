# ClipFormat

> Copy from ChatGPT / Claude / Gemini → press **⌥⌘C** → paste beautifully formatted text anywhere.

## What it does

AI chat tools copy Markdown (`**bold**`, `# headers`, `- lists`) which looks broken when pasted into Word, Notes, Mail, Slack, Notion, etc.

ClipFormat sits in your menu bar and converts the Markdown on your clipboard to rich text (RTF) — so when you paste, it looks correct in every app.

## Usage

1. Copy text from any AI chat (ChatGPT, Claude, Gemini, ...)
2. Press **⌥⌘C** (Option + Command + C)
3. Menu bar briefly shows **✅ Formatted!**
4. Paste normally with **⌘V** — formatted!

Apps that don't support rich text (terminal, code editors) will automatically fall back to plain text.

## Build & Install

### Requirements
- macOS 13 (Ventura) or later
- Xcode 15+

### Steps

1. Clone the repo
2. Open `Package.swift` in Xcode (File → Open)
3. Set scheme target to **My Mac**
4. Product → **Archive**, then Distribute as a direct install
5. Or just hit **Run** (⌘R) to use it immediately from Xcode

### Run at Login

After building: right-click the `.app` → Open, then add it to **System Settings → General → Login Items**.

## Supported Markdown

| Syntax | Result |
|---|---|
| `# H1` `## H2` `### H3` | Headers |
| `**bold**` | **Bold** |
| `*italic*` | *Italic* |
| `` `code` `` | Inline code |
| ` ``` ` blocks | Code blocks |
| `- item` / `1. item` | Lists |
| `[text](url)` | Links |
| `> quote` | Blockquotes |
| `---` | Horizontal rule |
| `~~strike~~` | Strikethrough |

## License

MIT
