# Privacy Policy for Tidbit

**Last Updated: May 4, 2026**

## Overview

Tidbit is a menu bar productivity app for macOS that combines todo list management with clipboard history. We are committed to protecting your privacy and being transparent about how the app works.

## Data Collection

**Tidbit does NOT collect, transmit, or share any of your personal data.**

### What Data is Stored Locally

Tidbit stores the following data **only on your local computer**:

1. **Todo Items**: Text content, images you attach, creation dates, and completion status
2. **Clipboard History**: Recent clipboard content (text, images) up to 20 items
3. **App Settings**: Theme preference, dock edge preference, auto-hide setting, panel size and position

### Where Data is Stored

All data is stored locally on your Mac at:
```
~/Library/Application Support/Tidbit/
```

This directory contains:
- `state.json` - Your todos, clipboard items, and settings
- `images/` - Images you've attached to todos

### Data Access

- **No Internet Connection**: Tidbit does not connect to the internet
- **No Third-Party Services**: Tidbit does not use any third-party analytics, tracking, or advertising services
- **No Data Transmission**: Nothing you create or store in Tidbit is ever sent anywhere
- **Local Only**: All data remains on your computer

## Clipboard Monitoring

Tidbit monitors your system clipboard to provide clipboard history functionality:

- **When**: Only while the app is running
- **What**: Text and image content copied to clipboard
- **Storage**: Last 20 items stored locally
- **Control**: You can quit Tidbit at any time to stop clipboard monitoring

**Important**: Clipboard monitoring happens entirely on your local machine. Nothing is sent to any server.

## Permissions

Tidbit may request the following macOS permissions:

- **Accessibility** (Optional): May be needed for global hotkey functionality on some macOS versions
- **No other permissions required**

## Data Deletion

You have full control over your data:

- **Delete Todos**: Click the X button on any todo to delete it
- **Delete Clipboard Items**: Clipboard items are automatically pruned to 20 items
- **Delete All Data**: 
  - Quit Tidbit
  - Delete `~/Library/Application Support/Tidbit/`
  - Uninstall the app

## Third-Party Services

Tidbit does not use any third-party services, including:
- No analytics services
- No crash reporting services  
- No advertising networks
- No cloud storage services
- No authentication services

## Children's Privacy

Tidbit does not collect any data from anyone, including children under 13.

## Changes to Privacy Policy

If we update this privacy policy, we will:
- Update the "Last Updated" date
- Notify users in the app release notes
- Post the updated policy in the app repository

## Data Security

Since all data is stored locally on your computer:
- Data security depends on your macOS user account security
- We recommend using FileVault to encrypt your Mac's drive
- Regular Time Machine backups will include your Tidbit data

## Your Rights

You have complete control over your data:
- **Access**: All your data is in plaintext JSON at `~/Library/Application Support/Tidbit/`
- **Export**: Copy the folder to backup or export your data
- **Delete**: Remove the app and folder to delete all data
- **Modify**: Edit the JSON files directly if needed (while app is closed)

## Contact

For privacy questions or concerns:
- Open an issue on GitHub
- Email: [Your contact email]

## Compliance

This privacy policy is designed to comply with:
- GDPR (EU General Data Protection Regulation)
- CCPA (California Consumer Privacy Act)
- Apple's App Store Privacy Requirements

Since Tidbit doesn't collect or transmit any data, there are minimal privacy concerns.

---

**Summary**: Tidbit is completely private. All your todos and clipboard history stay on your Mac. Nothing is sent anywhere. Ever.
