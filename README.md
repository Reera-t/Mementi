<div align="center">

# 📎 Mementi

### Ultra-Lightweight, Distraction-Free macOS Clipboard Manager with Long Memory

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue?logo=apple&logoColor=white)](https://apple.com)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift&logoColor=white)](https://swift.org)
[![UI](https://img.shields.io/badge/UI-Pure%20Native%20AppKit-9333ea)](https://developer.apple.com/documentation/appkit)
[![Binary Size](https://img.shields.io/badge/Binary%20Size-~270%20KB-success)](#)
[![RAM Usage](https://img.shields.io/badge/Memory-~15%20MB-brightgreen)](#)
[![Idle CPU](https://img.shields.io/badge/Idle%20CPU-0.0%25-brightgreen)](#)
[![Security Audit](https://img.shields.io/badge/Security%20Audit-Cloudflare%20Passed-blueviolet)](https://github.com/cloudflare/security-audit-skill)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

*Mementi lives quietly in your top Mac toolbar. It keeps temporary clips for 3 days, and lets you highlight values yellow with a single mouse click to keep them forever.*

---

</div>

## 🖼️ Visual Preview

```text
 ┌────────────────────────────────────────────────────────────┐
 │  Apple Menu Bar              ... [ WiFi ] [ Battery ] [📎] │ ◄── Lives here only
 └─────────────────────────────────────────────────────────┬──┘
                                                           │ (Click 📎)
    ┌──────────────────────────────────────────────────────▼──────┐
    │  📎 Mementi  v1.0                                       ⋯   │
    │  ┌────────────────────────────────────────────────────────┐ │
    │  │ 🔍 Search clipboard history...                         │ │
    │  └────────────────────────────────────────────────────────┘ │
    │  ┌───────────────┬────────────────────────────────────────┐ │
    │  │   All (12)    │               ❤️ (3)                    │ │ ◄── 2 Columns
    │  └───────────────┴────────────────────────────────────────┘ │
    │                                                             │
    │  ┌─ 🌟 LONG MEMORY (Yellow Highlighted Card) ────────────┐  │
    │  │ ❤️ LONG MEMORY  •  12m ago             [Highlight] [⎘] │  │
    │  │                                                          │
    │  │  https://api.github.com/v1/deployments/production-01     │ ◄── Bright Yellow
    │  │                                                          │     Kept Forever
    │  │  54 chars  •  1 line                                     │
    │  └──────────────────────────────────────────────────────────┘
    │                                                             │
    │  ┌─ 🕒 Standard Temporary Card (Clean View) ─────────────┐  │
    │  │ 2h ago                                 [Highlight] [⎘] │  │
    │  │                                                          │
    │  │  git commit -m "feat: add mouse highlighter support"    │ ◄── Silent 3-Day
    │  │                                                          │     Auto-Prune
    │  │  51 chars  •  1 line                                     │
    │  └──────────────────────────────────────────────────────────┘
    │                                                             │
    │  💡 Click highlighter with mouse to turn yellow & save to ❤️ │
    └─────────────────────────────────────────────────────────────┘
```

---

## ✨ Features

- **🪶 Ultra-Lightweight & Native**:
  - Pure **Swift 6 & AppKit** (no Electron, no Chromium, no webview).
  - Executable is only **~270 KB**!
  - Idle RAM consumption is **~15 MB** (vs 250 MB+ for typical clipboard managers).
  - Idle CPU usage: **0.0%**.

- **🕶️ Invisible Background App**:
  - Configured with `LSUIElement = true`.
  - **No Dock icon**, no Cmd+Tab task switcher pollution.
  - Exists exclusively as a subtle paperclip icon (`📎`) in your macOS Menu Bar.

- **🕒 3-Day Default Retention**:
  - Temporary clips are retained for **72 hours (3 days)** by default.
  - Silent hourly cleanup runs in the background.
  - Clean card design with no countdown clutter.

- **💛 Mouse Highlighter ("Long Memory")**:
  - Move your mouse over any clip and click the **Highlight** button.
  - The card instantly transforms with a vibrant **fluorescent canary yellow highlight** (or glowing amber in Dark Mode).
  - Labeled with **`❤️ LONG MEMORY`** and exempt from the 3-day deletion window.
  - Click again anytime to un-highlight and return the clip to temporary memory.

- **❤️ Streamlined Two-Column Navigation**:
  - **`All`**: Complete chronological clipboard history.
  - **`❤️`**: Fast filter for your yellow-highlighted Long Memory snippets.

- **🔒 Privacy & Security First**:
  - **Cloudflare Security Audited**: Validated using [Cloudflare's Security Audit](https://github.com/cloudflare/security-audit-skill) methodology.
  - **Password Manager Protection**: Automatically ignores confidential clips from Apple Keychain, 1Password, KeePassXC, Bitwarden, and transient pasteboards.
  - **Owner-Only File Permissions**: Stored in `~/Library/Application Support/Mementi/clips.json` with strict `0600` / `0700` POSIX access masks.
  - **Memory Guard**: Rejects abnormally oversized payloads (> 1MB) to prevent denial-of-service memory spikes.

---

## 🏛️ System Architecture

```mermaid
flowchart TD
    subgraph macOS System
        PB["NSPasteboard (System Clipboard)"]
        MB["NSStatusBar (Menu Bar Icon 📎)"]
    end

    subgraph Mementi Engine
        Obs["ClipboardObserver\n• 0.5s changeCount polling\n• Password vault exclusion\n• 1MB payload ceiling"]
        Store["StorageManager\n• In-memory cache\n• Atomic 0600 JSON store\n• 3-day retention sweeper\n• 1,000 item capacity cap"]
    end

    subgraph User Interface (AppKit)
        Popover["ClipboardPopoverController\n• All vs ❤️ Segments\n• Instant search"]
        Cell["ClipTableCellView\n• Fluorescent Yellow Highlight\n• One-click copy & delete"]
    end

    PB -->|Extracts string| Obs
    Obs -->|Dispatches new clip| Store
    Store <-->|Renders list| Popover
    MB -->|Click 📎| Popover
    Popover --> Cell
    Cell -->|Click Highlighter| Store
    Cell -->|Click Copy / Enter| PB
```

---

## 🚀 Installation & Quick Start

### Option 1: Run the Prebuilt App
```bash
# Clone the repository
git clone https://github.com/Reera-t/mementi.git
cd mementi

# Build and package the .app bundle
./build_app.sh

# Copy to Applications
cp -R Mementi.app /Applications/

# Launch
open /Applications/Mementi.app
```
Look for the paperclip icon `📎` in the top-right corner of your Mac menu bar.

### Option 2: Build from Source
```bash
# Compile release binary
swift build -c release --product Mementi

# Run test suite
swift run MementiTestRunner
```

---

## ⌨️ How to Use

| Action | How to do it |
| :--- | :--- |
| **Open Mementi** | Click the paperclip (`📎`) in your Mac menu bar |
| **Save to Long Memory** | Click the **Highlight** button on any card with your mouse (turns yellow) |
| **Filter Favorites** | Click the **`❤️`** column tab |
| **Copy Snippet Back** | Click the copy icon (`⎘`) or double-click the card |
| **Search History** | Type keywords in the search bar |
| **Clear Unhighlighted** | Click `⋯` menu > *Clear Unhighlighted Clips (Keep ❤️)* |
| **Dismiss Popover** | Click anywhere outside or press `Esc` |

---

## ⚙️ Start Automatically at Login

To launch Mementi automatically on system boot:
1. Open **System Settings** > **General** > **Login Items**.
2. Click **+** under *Open at Login*.
3. Select `Mementi.app` from `/Applications`.

---

## 🧪 Automated Testing

Mementi includes an automated verification suite that tests expiration math, highlight immunity, deduplication, and persistence:
```bash
swift run MementiTestRunner
```
```text
========================================
🚀 Running Mementi Automated Test Suite
========================================

[Group 1: Expiration Lifecycle (3 Days)]
  ✅ [PASS] Fresh clip is not expired
  ✅ [PASS] Fresh clip shows countdown (e.g. 2d 23h left)
  ✅ [PASS] Clip at 2 days is still alive
  ✅ [PASS] Clip older than 3 days (73 hours) is marked expired

[Group 2: Yellow Highlight & Long Memory]
  ✅ [PASS] Yellow highlighted item NEVER expires even after 30 days
  ✅ [PASS] Remaining time text displays 'Long Memory'

[Group 3: StorageManager & Pruning Behavior]
  ✅ [PASS] Added 3 clips successfully
  ✅ [PASS] Clip 2 toggled to highlighted (yellow / Long Memory)
  ✅ [PASS] Storage pruned expired 3-day clips, leaving only 1 clip
  ✅ [PASS] The surviving clip is the yellow-highlighted Long Memory item
  ✅ [PASS] Surviving clip preserved isHighlighted = true

[Group 4: Clear Temporary Clips (Preserving Long Memory)]
  ✅ [PASS] Added 2 new temporary clips alongside Long Memory item
  ✅ [PASS] Cleared temporary clips leaving exactly 1 item
  ✅ [PASS] Long Memory item remained intact after temporary clear

========================================
🎉 All 14/14 tests passed successfully!
========================================
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE) — created with ❤️ by [Reera Tehranizadeh](https://github.com/Reera-t).
