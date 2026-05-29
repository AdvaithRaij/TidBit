# 🚀 Tidbit Launch Checklist

Use this checklist to launch Tidbit to the public.

## ✅ Pre-Launch (Complete)

- [x] Code audit and cleanup
- [x] Remove duplicate files
- [x] Create release build system
- [x] Update Info.plist for production
- [x] Write comprehensive README
- [x] Create privacy policy
- [x] Add MIT license
- [x] Test release build
- [x] Create DMG distribution file
- [x] Install and verify app works

## 📸 Marketing Assets (To Do)

### Screenshots Needed
- [ ] Hero shot (app docked to right edge)
- [ ] Todo list in action (with some sample todos)
- [ ] Clipboard history view
- [ ] Settings/Preferences window
- [ ] Auto-hide demonstration (GIF)
- [ ] Theme switching (Light/Dark)

**Tip**: Use macOS Screenshot app (⌘⇧5) or create a screen recording, then convert key moments to GIF.

### Demo GIF/Video
- [ ] Record 30-second demo showing:
  - Opening with hotkey
  - Adding a todo
  - Editing a todo
  - Using clipboard history
  - Auto-hide in action

**Tools**: 
- QuickTime Player (⌘⇧5 for recording)
- GIF converter: [ezgif.com](https://ezgif.com) or Gifski app

## 🌐 Distribution Setup

### Option A: Direct DMG (Simplest)

- [ ] Upload `Dist/Tidbit-1.0.0.dmg` to file host:
  - [ ] Google Drive (get shareable link)
  - [ ] Dropbox
  - [ ] GitHub Releases
  - [ ] Your own server

- [ ] Test download link works
- [ ] Verify users can mount DMG and install

### Option B: GitHub Releases (Recommended)

- [ ] Create GitHub repository (if not exists)
- [ ] Push all code to GitHub
- [ ] Create release v1.0.0:
  ```bash
  git tag -a v1.0.0 -m "Release v1.0.0"
  git push origin v1.0.0
  ```
- [ ] Upload `Tidbit-1.0.0.dmg` to GitHub Release
- [ ] Copy README content into release notes
- [ ] Mark as "Latest Release"

### Option C: Landing Page Website

- [ ] Create simple landing page with:
  - [ ] Hero image/GIF
  - [ ] Feature list
  - [ ] Download button
  - [ ] Privacy statement link
  - [ ] Installation instructions
- [ ] Add download link to DMG
- [ ] Test on mobile (responsive design)

## 📱 Reddit Marketing

### Prepare Post

- [ ] Choose primary subreddit to launch
  - **Recommended first**: r/MacApps or r/SideProject
- [ ] Write post using template from `DISTRIBUTION.md`
- [ ] Upload hero image/GIF to Imgur or Reddit
- [ ] Prepare for comments:
  - [ ] FAQ answers ready
  - [ ] Feature request acknowledgment
  - [ ] Bug report process explained

### Post Template (Customize)

```markdown
Title: [macOS] Tidbit - Menu bar todo list + clipboard manager

Body:
Hey r/MacApps! I built Tidbit, a native macOS productivity app.

🎯 What it does:
• Quick todo list with image attachments
• Clipboard history (last 20 items)
• Auto-hides to screen edges, reveals on hover
• Global hotkey (⌥⌘Space)
• Light/Dark/Auto themes

🔒 Privacy-first:
• All data stays local on your Mac
• No cloud, no tracking, no analytics
• Zero external dependencies

📦 Download:
[Your DMG link or GitHub release]

Built with SwiftUI for macOS 14+. Free and open source!

Happy to answer questions or hear feedback!
```

### Timing
- [ ] Post during peak Reddit hours:
  - **Best**: 9-11 AM EST or 1-3 PM EST on weekdays
  - **Avoid**: Late night, weekends

### After Posting
- [ ] Respond to comments within first hour
- [ ] Answer questions thoroughly
- [ ] Be gracious about criticism
- [ ] Update app if critical bugs found

## 📊 Post-Launch Monitoring

### Week 1
- [ ] Check Reddit post daily for comments
- [ ] Monitor GitHub issues (if public)
- [ ] Track download count (if analytics available)
- [ ] Note feature requests in a doc
- [ ] Fix any critical bugs immediately

### Week 2-4
- [ ] Consider posting to additional subreddits:
  - [ ] r/macOS
  - [ ] r/productivity
  - [ ] r/InternetIsBeautiful
- [ ] Cross-post with updated stats (X downloads, Y upvotes)
- [ ] Respond to all GitHub issues

## 🐛 Support Plan

### Bug Reports
- [ ] Set up GitHub Issues
- [ ] Create issue templates:
  - [ ] Bug report
  - [ ] Feature request
- [ ] Commit to response time (e.g., 48 hours)

### FAQ Document
Create `FAQ.md` with answers to:
- [ ] How do I uninstall?
- [ ] Where is my data stored?
- [ ] Can I sync across Macs? (No, local only)
- [ ] How do I backup my todos?
- [ ] Why does macOS say "unidentified developer"?
- [ ] Will this work on Intel Macs? (Currently no)

## 🎨 Optional Enhancements

### Nice to Have (Later)
- [ ] Custom app icon (hire designer or use SF Symbols)
- [ ] Product Hunt launch
- [ ] Twitter announcement thread
- [ ] Hacker News Show HN post
- [ ] Blog post about building it
- [ ] YouTube demo video

### Future Versions
- [ ] Export/import todos feature
- [ ] Intel Mac support (if requested)
- [ ] Keyboard shortcuts for todo actions
- [ ] Tags/categories for todos
- [ ] Search todos feature

## ⚠️ Important Warnings to Users

In your README/posts, mention:

1. **First Launch Warning**
   ```
   On first launch, macOS may show "unidentified developer" warning.
   Fix: Right-click app → Open → Click "Open" in dialog
   ```

2. **System Requirements**
   ```
   Requires: macOS 14.0 (Sonoma) or later
   Apple Silicon (M1/M2/M3) Macs only
   ```

3. **Permissions**
   ```
   No special permissions required
   Optional: Accessibility for global hotkey (some macOS versions)
   ```

## 📈 Success Metrics

Track these to measure success:
- [ ] Reddit post upvotes (Target: 50+ first post)
- [ ] Comments/engagement
- [ ] GitHub stars (if public repo)
- [ ] Download count
- [ ] Feature requests volume
- [ ] Bug reports (low is good!)

## 🎉 Launch Day Checklist

**Morning of launch**:
1. [ ] Double-check DMG link works
2. [ ] Verify README is up-to-date
3. [ ] Have coffee ☕
4. [ ] Post to Reddit
5. [ ] Share on Twitter/LinkedIn if you use them
6. [ ] Monitor first hour closely
7. [ ] Celebrate! 🎊

---

## Quick Commands Reference

**Build release**:
```bash
./build_release.sh
```

**Create DMG**:
```bash
./create_dmg.sh
```

**Install locally**:
```bash
cp -r Dist/Tidbit.app /Applications/
```

**Git tag release**:
```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

---

## You're Ready! 🚀

Everything is in place. Pick your distribution method, create your marketing assets, and launch!

Good luck! 🍀
