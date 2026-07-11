# Installation and Dev Setup Guide — Shuni

This document provides step-by-step instructions to compile and build Shuni from source.

---

## 🛠️ Prerequisites

Ensure your development computer has the following tools installed:
1. **Flutter SDK**: Pinned to version `3.41.1`.
2. **Dart SDK**: Automatically packaged with Flutter.
3. **Android SDK**: JDK 17+ (available via Android Studio).
4. **FVM (Flutter Version Management)**: Isolates SDK instances.
5. **ADB (Android Debug Bridge)**: Required to install APK packages via command line.

---

## 🚀 Getting Started

### Step 1: Clone the Repository
Clone Shuni to your local machine:
```bash
git clone https://github.com/[YourGitHubUsername]/shuni.git
cd shuni
```

### Step 2: Configure SDK isolation via FVM
To prevent the project from conflicting with your computer's global Flutter version, use FVM to download and pin the correct compiler:
```bash
# 1. Activate FVM globally
dart pub global activate fvm

# 2. Add pub cache to your Windows PATH if needed:
# C:\Users\[Username]\AppData\Local\Pub\Cache\bin

# 3. Download and lock version 3.41.1
fvm install
fvm use 3.41.1
```

### Step 3: Fetch packages
```bash
fvm flutter pub get
```

### Step 4: Setup Android Keystore Signing
For testing release builds (`flutter build apk --release`), Android requires the APK to be digitally signed.
1. Generate a keystore file using Java's keytool:
   ```bash
   keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create an `android/key.properties` file with credentials:
   ```properties
   storePassword=[YourPassword]
   keyPassword=[YourPassword]
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```
   *(Note: `key.properties` is ignored by git to keep secrets safe.)*

---

## 📱 Building and Deploying

### 1. Build and Run in Debug Mode
Connect your Android phone with **USB Debugging** enabled, then run:
```bash
fvm flutter run
```

### 2. Compile Release APK
To compile a lightweight, optimized release build with code shrinking (ProGuard enabled):
```bash
fvm flutter build apk --release
```
The output package will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

### 3. Install on Device via ADB
Install the compiled APK directly onto your phone:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔧 Shizuku Setup on the Phone
After installing the APK:
1. Follow the [Shizuku Configuration Guide](docs/SHIZUKU_GUIDE.md) to activate the Shizuku background service on your phone.
2. Open Shuni, complete permission requests, and grant Shizuku permission.
3. Test recording by placing a test call.
