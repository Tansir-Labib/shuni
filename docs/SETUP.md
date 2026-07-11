# Developer Environment Setup — Shuni

This document lists requirements to configure your development computer to compile Shuni.

---

## 🖥️ Operating System Setup

### Windows Configuration
1. Install **Git for Windows** (adds bash capabilities).
2. Install **Android Studio** (includes SDK Manager and tools).
3. Add ADB to your system's Environment Variables (Path):
   - Path: `C:\Users\[Username]\AppData\Local\Android\Sdk\platform-tools`
   - Test by running: `adb --version` in terminal.

---

## 🛠️ SDK & Editor Setup

### 1. Flutter SDK via FVM
Isolating SDK builds is recommended to prevent system conflicts.
1. Install FVM globally:
   ```bash
   dart pub global activate fvm
   ```
2. Navigate to Shuni project root and run:
   ```bash
   fvm install
   fvm use 3.41.1
   ```

### 2. VS Code Configuration
If using VS Code, install these extensions:
1. **Flutter** (by Dart Code)
2. **Dart** (by Dart Code)
3. **Kotlin Language Support**

Add this settings configuration to `.vscode/settings.json` to link the FVM SDK:
```json
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk",
  "search.exclude": {
    "**/.fvm": true
  },
  "files.watcherExclude": {
    "**/.fvm": true
  }
}
```

### 3. Android Studio Configuration
If using Android Studio:
1. Open Android Studio.
2. Go to **Settings** → **Languages & Frameworks** → **Flutter**.
3. Set the **Flutter SDK Path** to:
   `[ProjectRoot]\.fvm\flutter_sdk`
4. Tap Apply.
