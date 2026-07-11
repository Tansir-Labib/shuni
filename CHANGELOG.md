# Changelog — Shuni

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

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
