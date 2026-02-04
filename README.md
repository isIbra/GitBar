<p align="center">
  <img src="https://img.icons8.com/sf-symbols/96/arrow.triangle.branch.png" width="80" alt="GitBar icon"/>
</p>

<h1 align="center">GitBar</h1>

<p align="center">
  <strong>All your repos' git status at a glance — from the macOS menu bar.</strong>
</p>

<p align="center">
  <a href="https://github.com/isIbra/GitBar/actions"><img src="https://github.com/isIbra/GitBar/actions/workflows/build.yml/badge.svg" alt="Build Status"/></a>
  <a href="https://github.com/isIbra/GitBar/releases"><img src="https://img.shields.io/github/v/release/isIbra/GitBar?include_prereleases" alt="Latest Release"/></a>
  <img src="https://img.shields.io/badge/macOS-13%2B-blue" alt="macOS 13+"/>
  <img src="https://img.shields.io/badge/Swift-5.9%2B-orange" alt="Swift 5.9+"/>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/isIbra/GitBar" alt="License"/></a>
</p>

---

## ✨ Features

- **🟢🟡🔴 Color-coded status** — Green (all clean), yellow (uncommitted changes), red (merge conflicts)
- **📂 Watch multiple directories** — Configure folders containing your git repos
- **🔍 Auto-discovery** — Recursively finds `.git` repos up to configurable depth
- **📊 At-a-glance info** — Current branch, modified/staged/untracked counts, unpushed commits
- **⚡ Instant updates** — FSEvents file watcher detects changes in real-time
- **🔄 Configurable polling** — Fallback refresh interval (30s / 60s / 5min / manual)
- **🖱️ Quick actions** — Right-click to open in Terminal, Finder, or your editor
- **⚙️ Customizable** — Editor command, scan depth, launch at login
- **🪶 Lightweight** — Minimal CPU/memory usage when idle

## 📸 Screenshots

> *Coming soon — the app needs to be built on macOS first!*

<!-- 
<p align="center">
  <img src="docs/screenshot-popover.png" width="400" alt="GitBar popover"/>
  <img src="docs/screenshot-settings.png" width="400" alt="GitBar settings"/>
</p>
-->

## 📦 Installation

### Download

1. Go to [Releases](https://github.com/isIbra/GitBar/releases)
2. Download `GitBar.app.zip`
3. Extract and move `GitBar.app` to `/Applications`
4. Launch GitBar — it'll appear in your menu bar

### Build from Source

```bash
git clone https://github.com/isIbra/GitBar.git
cd GitBar
swift build -c release

# Create app bundle
mkdir -p GitBar.app/Contents/MacOS
cp .build/release/GitBar GitBar.app/Contents/MacOS/
cp Sources/GitBar/Resources/Info.plist GitBar.app/Contents/
open GitBar.app
```

**Requirements:** macOS 13+ (Ventura), Xcode 15+, Swift 5.9+

## 🚀 Getting Started

1. **Launch GitBar** — Look for the branch icon (⑂) in your menu bar
2. **Open Settings** — Click the gear icon in the popover
3. **Add directories** — Point to folders containing your git repos (e.g., `~/Developer`)
4. **Configure depth** — Set how deep to scan for repos (default: 2 levels)
5. **Done!** — GitBar will automatically find and monitor your repos

## 🏗️ Architecture

```
Sources/GitBar/
├── App/
│   ├── GitBarApp.swift          # @main entry point, MenuBarExtra
│   └── AppDelegate.swift        # AppState — central coordinator
├── Views/
│   ├── MenuBarView.swift        # Popover content — repo list
│   ├── RepoRowView.swift        # Individual repo status row
│   └── SettingsView.swift       # Settings panel
├── Models/
│   ├── GitRepo.swift            # Repo model with status
│   └── AppSettings.swift        # UserDefaults-backed settings
├── Services/
│   ├── GitService.swift         # Git command execution & parsing
│   ├── RepoScanner.swift        # Recursive .git discovery
│   └── FileWatcher.swift        # FSEvents file system watcher
└── Utilities/
    └── ProcessRunner.swift      # Async Process wrapper
```

### Key Design Decisions

- **MenuBarExtra** (macOS 13+) for native menu bar integration
- **Concurrent git queries** via Swift structured concurrency (`TaskGroup`)
- **FSEvents** for instant change detection + configurable polling as fallback
- **Debounced updates** (500ms) to avoid UI thrashing
- **No external dependencies** — pure Swift, Apple frameworks only

## 🔧 Git Commands Used

| Command | Purpose |
|---------|---------|
| `git rev-parse --abbrev-ref HEAD` | Current branch name |
| `git status --porcelain` | Modified, staged, untracked files |
| `git log @{u}..HEAD --oneline` | Unpushed commits count |
| `git diff --name-only --diff-filter=U` | Merge conflict files |
| `git stash list` | Stash entry count |

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing`)
5. Open a Pull Request

## 📄 License

[MIT License](LICENSE) — do whatever you want with it.

---

<p align="center">
  <sub>Built with ❤️ and Swift</sub>
</p>
