# Tidbit 📝

**A sleek menu bar todo list and clipboard manager for macOS**

Tidbit is a native macOS productivity app that lives in your menu bar, combining a powerful todo list with an intelligent clipboard history manager. Built with SwiftUI and AppKit for optimal performance.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-6.1-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## ✨ Features

### 📌 Todo Management
- Create, edit, and check off tasks
- Attach images to todos
- Manual drag-to-reorder todos
- Double-click to edit inline
- Persistent storage across restarts

### 📋 Clipboard History
- Automatically captures clipboard content
- Stores last 20 clipboard items
- Fuzzy search with 2+ characters
- Click any item to copy it back
- Timestamp tracking

### 🎨 User Interface
- **Auto-hide dock**: Panel snaps to screen edges (left/right) and auto-hides to a slim tab
- **Hover activation**: Slides out when you hover over the edge
- **Resizable panel**: Drag corners to resize
- **Theme support**: Light, Dark, and Auto (follows system)
- **Minimal design**: Clean, distraction-free interface

### ⚡ Productivity Features
- **Global hotkey**: `⌥⌘Space` (Option + Command + Space) to toggle
- **Menu bar access**: Quick access to all features from menu bar
- **Background app**: Runs as menu bar app, doesn't clutter Dock
- **Zero dependencies**: Pure Swift, no external frameworks

## 🚀 Installation

### Option 1: Download DMG (Recommended)
1. Download `Tidbit-1.0.0.dmg` from releases
2. Open the DMG file
3. Drag **Tidbit.app** to your **Applications** folder
4. Launch Tidbit from Applications

### Option 2: Build from Source
```bash
# Clone the repository
git clone https://github.com/yourusername/tidbit.git
cd tidbit

# Build release version
./build_release.sh

# Install to Applications
cp -r Dist/Tidbit.app /Applications/

# Launch
open /Applications/Tidbit.app
```

## 🎯 Usage

### First Launch
1. **Launch Tidbit** - You'll see a checklist icon in your menu bar
2. **Open the panel** - Press `⌥⌘Space` or click the menu bar icon → "Pin Tidbit"
3. **Position it** - Drag the panel to snap it to left or right edge
4. **Enable auto-hide** - The panel will hide when not in use and appear on hover

### Creating Todos
1. Click in the message box at the bottom
2. Type your todo text
3. (Optional) Click the 📷 button to attach an image
4. Click the ➕ button or press Enter to add

### Using Clipboard History
1. Click the "Clipboard" tab at the top
2. Your recent clipboard items appear automatically
3. Use the search box to filter (min 2 characters)
4. Click any item to copy it back to clipboard

### Keyboard Shortcuts
- `⌥⌘Space` - Toggle Tidbit panel
- Double-click todo text - Edit todo inline
- Drag todo item - Reorder todos

## ⚙️ Preferences

Access preferences from the menu bar icon:
- **Auto-hide**: Toggle edge auto-hide behavior
- **Theme**: Choose Light, Dark, or Auto (system)
- **Dock edge**: Prefer left or right side

## 🗂️ Data Storage

Tidbit stores all data locally on your Mac:
```
~/Library/Application Support/Tidbit/
├── state.json          # Todos, clipboard items, settings
└── images/             # Attached images
```

## 🛠️ Development

### Requirements
- macOS 14.0 (Sonoma) or later
- Xcode 15.0+ or Swift 6.1+

### Build for Development
```bash
# Quick run
swift run

# Build debug version
swift build
./bundle_app.sh
open Dist/Tidbit.app
```

### Build for Distribution
```bash
# Build optimized release
./build_release.sh

# Create DMG for distribution
./create_dmg.sh

# Output: Dist/Tidbit-1.0.0.dmg
```

## 📄 Privacy

Tidbit respects your privacy:
- **All data stays local** - Nothing is sent to any server
- **No analytics** - We don't track your usage
- **No network access** - The app doesn't connect to the internet
- **Clipboard monitoring** - Only reads clipboard when the app is running

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests

## 📝 License

Copyright © 2026 Codex. All rights reserved.

## 🙏 Acknowledgments

Built with SwiftUI and AppKit for optimal macOS integration.

---

**Download Tidbit today and boost your productivity!** 🚀
