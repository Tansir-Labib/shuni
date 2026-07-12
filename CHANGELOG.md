# Changelog — Shuni

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.2.2] — 2026-07-12
### Fixed
- **Call Recording Crash**: Fixed a core issue where the app would close instantly upon receiving a call on Android 14 devices. This was due to strict `ForegroundServiceStartNotAllowedException` limitations and improper foreground service types. Fallbacks and try-catch wrappers have been implemented to ensure robust recording similar to Cube ACR.
- **Settings Lag**: Removed heavy blur effects (`BackdropFilter`) from the configuration screen, eliminating scroll jank and ensuring butter-smooth performance when navigating.
- **Website Setup Instructions**: Updated the website text to accurately reflect generic "Android devices" instead of specifically referencing "Nothing 3a".
- **Database Path & Storage Fixes**: Fixed `MANAGE_EXTERNAL_STORAGE` permission requirements by saving metadata directly to internal SQLite and audio to package-specific external storage.

### Added
- **Changelog Support**: Implemented formal changelog tracking in the repository and updated the Settings page to allow viewing release notes.

## [1.2.1] — 2026-07-11
### Fixed
- Fixed in-app updater download bugs by implementing proper storage permissions and query intents.

## [1.0.0] — 2026-07-11

Initial release of Shuni.

### Added
- **Shizuku audio capture integration** using `moe.shizuku` API binders to record clean two-way audio on Android 11+ non-rooted devices.
- **InCallService telecom hooks** for automatic call connect detection.
- **Opus audio compressor (.ogg)** running at 32kbps mono to output tiny voice files (~2.3MB/hour).
- **Offline maps (OpenStreetMap)** integration to cluster and preview call origin coordinates on maps.
- **Linux monospace secure lock** keypad with zero visual character drawing.
- **Biometrics quick unlock** (fingerprint/face recognition).
- **Google Drive backup integration** using free client OAuth2 uploads.
- **External storage folder structure** (`/Shuni/recordings/`) visible in file managers.
- **Detailed developer guides** covering compilation, FVM configurations, and troubleshooting steps.
