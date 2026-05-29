# Distribution Guide for Tidbit

This guide explains how to distribute Tidbit for production use.

## Quick Distribution

### For Reddit/Website Distribution (DMG)
```bash
./build_release.sh
./create_dmg.sh
```

**Output**: `Dist/Tidbit-1.0.0.dmg` (ready to distribute!)

Upload this DMG to:
- Your website
- Google Drive / Dropbox
- GitHub Releases

### For App Store Distribution

**Note**: App Store requires code signing and more setup. Follow these steps:

1. **Apple Developer Account Required**
   - Enroll at https://developer.apple.com
   - Cost: $99/year

2. **Code Signing**
   ```bash
   # Sign the app
   codesign --deep --force --verify --verbose \
     --sign "Developer ID Application: Your Name (TEAM_ID)" \
     Dist/Tidbit.app
   ```

3. **Notarization** (for distribution outside App Store)
   ```bash
   # Create a zip
   ditto -c -k --keepParent Dist/Tidbit.app Tidbit.zip
   
   # Submit for notarization
   xcrun notarytool submit Tidbit.zip \
     --apple-id "your@email.com" \
     --team-id "TEAM_ID" \
     --password "app-specific-password"
   
   # Staple the notarization ticket
   xcrun stapler staple Dist/Tidbit.app
   ```

4. **Create signed DMG**
   ```bash
   ./create_dmg.sh
   codesign --sign "Developer ID Application: Your Name (TEAM_ID)" \
     Dist/Tidbit-1.0.0.dmg
   ```

## Reddit Marketing Strategy

### Suggested Subreddits
- r/MacApps
- r/macOS
- r/productivity
- r/SideProject
- r/SomebodyMakeThis (if opensource)
- r/InternetIsBeautiful

### Post Template

```markdown
[macOS] Tidbit - A sleek menu bar todo list + clipboard manager

I built Tidbit, a native macOS app that lives in your menu bar and combines:
• Quick todo list with image attachments
• Clipboard history (last 20 items)
• Auto-hiding panel that snaps to screen edges
• Global hotkey (⌥⌘Space)
• Light/Dark theme support

Features:
- Zero dependencies, pure Swift
- All data stays local (no cloud, no tracking)
- Minimal, distraction-free design
- Free and open source

Download: [Your link]
GitHub: [Your repo]

Built with SwiftUI for macOS 14+. Would love feedback!
```

### Key Points to Mention
- **Privacy-first**: All data local, no tracking
- **Native**: Built specifically for macOS
- **Free**: No subscription, no ads
- **Lightweight**: Only 1.3MB binary
- **Open Source**: Full source available

## Website Distribution

### Landing Page Must-Haves
1. **Hero Section**
   - Large screenshot/GIF of the app in action
   - One-line description
   - Download button (primary CTA)

2. **Feature List**
   - Visual icons for each feature
   - Short descriptions

3. **Privacy Statement**
   - "Your data never leaves your Mac"
   - Link to PRIVACY.md

4. **Download Section**
   - Direct DMG download link
   - System requirements (macOS 14+)
   - File size (596KB)

5. **Installation Instructions**
   - 3-step process with screenshots

### Example Structure
```
tidbit.app/
├── index.html (landing page)
├── downloads/
│   └── Tidbit-1.0.0.dmg
├── privacy.html (from PRIVACY.md)
└── screenshots/
    ├── hero.png
    ├── todos.png
    └── clipboard.png
```

## GitHub Release

Create a release on GitHub:

```bash
# Tag the release
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

Upload to GitHub Release:
- `Tidbit-1.0.0.dmg`
- Include README.md content in release notes
- Mark as "Production Ready"

## Marketing Copy

### Tagline Options
- "The todo list that stays out of your way"
- "Menu bar todos + clipboard history for Mac"
- "Your productivity sidekick for macOS"

### Key Benefits
- **No learning curve**: Open, type, done
- **Always available**: Global hotkey or menu bar
- **Respects your space**: Auto-hides when not needed
- **Privacy-first**: Everything stays local
- **One-time download**: No updates required, no subscriptions

## Support Plan

### Documentation
- ✅ README.md (installation & usage)
- ✅ PRIVACY.md (privacy policy)
- ✅ LICENSE (MIT)
- Create: FAQ.md (common questions)

### Community
- GitHub Issues for bug reports
- GitHub Discussions for feature requests
- Reddit for general discussion

## Metrics to Track

For website distribution:
- Download count
- DMG open rate
- Retention (via GitHub stars/watchers)

For Reddit:
- Upvotes
- Comments
- Click-through rate to download

## Version Updates

When releasing updates:
1. Update version in `AppBundle/Info.plist`
2. Update version in `create_dmg.sh`
3. Update README.md changelog
4. Build new release: `./build_release.sh && ./create_dmg.sh`
5. Create GitHub release with changelog
6. Post update on Reddit (if major version)

## Pre-Launch Checklist

- [x] Build release version
- [x] Create DMG
- [x] Test installation on clean macOS
- [x] Verify all features work
- [x] Check menu bar icon displays
- [x] Test global hotkey
- [x] Verify data persistence
- [x] Privacy policy complete
- [ ] Create screenshots/demo GIF
- [ ] Code signing (if distributing widely)
- [ ] Create landing page (if website)
- [ ] Prepare Reddit post
- [ ] Create GitHub release

## Ready to Ship! 🚀

Your app is production-ready for:
- ✅ Direct DMG distribution
- ✅ Website hosting
- ✅ Reddit marketing
- ✅ GitHub releases

For App Store, additional code signing and Apple Developer account required.
