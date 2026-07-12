# Claude Usage Widget

A macOS menu bar app that tracks your [Claude.ai](https://claude.ai) usage in real time — see your 5-hour session and weekly limits at a glance, with per-model breakdowns.

![Claude Usage Widget screenshot](https://github.com/MertDemirok/ClaudeUsageWidget/assets/screenshot.png)

---

## Features

- **Menu bar icon** — shows your current usage percentage at all times
- **Popup panel** — 5-hour session ring, weekly bar, per-model rows (Opus, Sonnet, Haiku, Fable…)
- **Floating orb widget** — draggable, always-on-top 3D glass orb with live usage color
- **Auto-refresh** — configurable every 5, 10, or 15 minutes
- **5 languages** — English, Turkish, German, French, Italian

---

## Installation

### Download (Recommended)

1. Download the latest `ClaudeUsageWidget.zip` from [Releases](https://github.com/MertDemirok/ClaudeUsageWidget/releases)
2. Unzip and drag `ClaudeUsageWidget.app` to `/Applications`
3. On first launch, macOS may block the app — run this once in Terminal:

```bash
xattr -cr /Applications/ClaudeUsageWidget.app
```

Then open normally.

### Homebrew

```bash
brew tap MertDemirok/claude-usage
brew install --cask claude-usage-widget
```

---

## Setup

1. Launch the app — it appears in your menu bar
2. Click the icon → **Settings**
3. Click **Sign in with Claude** to log in via the built-in browser
4. Your usage data loads automatically

---

## How it works

The app reads your Claude.ai session cookie (stored securely in macOS Keychain) and fetches usage data from the Claude API. No data leaves your machine except to Claude's own servers.

---

## Requirements

- macOS 13 Ventura or later
- A Claude.ai account (Free, Pro, Team, or Enterprise)

---

## Build from source

```bash
git clone https://github.com/MertDemirok/ClaudeUsageWidget.git
cd ClaudeUsageWidget
open ClaudeUsageWidget.xcodeproj
```

Requires Xcode 15+ and Swift Package Manager (PhosphorSwift is resolved automatically).

---

## License

MIT
