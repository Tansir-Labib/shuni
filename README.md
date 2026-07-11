# Shuni (শুনি) — Secure Call Recorder

> **Slogan**: *"শোনো, মনে রাখো"* — Listen, Remember.
> **Tagline**: Every conversation, preserved.

[![Flutter](https://img.shields.io/badge/Flutter-3.41.1-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11-blue.svg)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-API%2030%2B-green.svg)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)

Shuni is a secure, personal call recording application built using **Flutter** and **Kotlin** for modern Android devices. It captures crystal clear two-way audio on non-rooted devices using the **Shizuku** framework, maps call coordinates, locks data behind a Linux-style invisible PIN pad, and pushes gzipped backups to your Google Drive.

---

## 🚀 Key Features

- **Privileged Two-Way Capture**: Accesses the native `VOICE_CALL` stream using Shizuku binders, capturing both sides clearly at **32kbps Opus** VBR (highly compressed, ~2.3MB per hour).
- **Interactive Location Mapping**: Records GPS coordinates during active calls. View clusters of call marker pins on a free, offline-capable **OpenStreetMap** panel inside the app.
- **Linux Monospace PIN Lock**: Secure keypad entry that draws absolutely zero characters on screen, preventing shoulder-surfing. Integrated with fingerprint/face biometrics.
- **Free Google Drive Sync**: OAuth2 direct sync (no expensive backend servers) that packages your database and audio archives as compressed backups on Google Drive.
- **External Local Storage**: Saves recordings directly to the accessible `/Shuni/recordings/` folder (next to Downloads, Documents, etc.) with sortable, human-readable file naming.

---

## 🛠️ Tech Stack

- **Frontend**: Flutter / Dart
- **State Management**: Riverpod
- **Local Database**: SQLite (Sqflite)
- **Maps**: OpenStreetMap (`flutter_map`)
- **Native Binders**: Shizuku API (Kotlin)
- **Audio Codec**: Opus (.ogg container)
- **Secure Storage**: Android Keystore (`flutter_secure_storage`)

---

## 📁 Repository Structure

```
shuni/
├── .fvm/                  # Flutter Version Management configuration
├── android/               # Native Android Kotlin call recording service
├── lib/                   # Flutter Dart interface, models, and providers
│   ├── core/              # Global constants and formatting utilities
│   ├── theme/             # Design typography and dark theme config
│   ├── models/            # Immutable database data models
│   ├── services/          # SQLite, Location, Backup, and API bridges
│   ├── providers/         # State notification controllers
│   ├── screens/           # Onboarding, locks, maps, and details screens
│   └── widgets/           # Glassmorphism cards and invisible text fields
├── docs/                  # Detailed configuration guides
├── website/               # HTML/CSS landing page (GitHub Pages ready)
└── pubspec.yaml           # App configuration and dependencies
```

---

## ⚡ Quick Start (Developer Setup)

To build and compile Shuni locally on your machine, follow these commands:

1. **Install Prerequisites**: Ensure Flutter SDK, Android Studio, and ADB are installed.
2. **Install FVM**: Pin the project's Flutter version to prevent version conflicts:
   ```bash
   dart pub global activate fvm
   fvm install
   ```
3. **Download Dependencies**:
   ```bash
   fvm flutter pub get
   ```
4. **Compile Debug APK**: Connect your phone and run:
   ```bash
   fvm flutter build apk --debug
   adb install build/app/outputs/flutter-apk/app-debug.apk
   ```

For detailed instructions, see [INSTALLATION.md](INSTALLATION.md).

---

## 🔒 Security & Privacy Notice
All voice logs and location coordinates are stored **locally** on your device. Shuni does not send details to third-party tracking APIs. Google Drive backups are authenticated via your personal Google Account directly and saved securely inside your private cloud storage.

---

## 📄 License
This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
