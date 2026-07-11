# Contributing to Shuni

We welcome contributions to Shuni! To maintain code readability and clean structures, please follow these guidelines.

---

## 💻 Code Style Conventions

### Dart / Flutter
- Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style).
- Use `dart format` to format all code.
- Files should be named in `snake_case.dart`.
- Class names should be in `PascalCase`.
- Variables, properties, and methods should be in `camelCase`.
- Use Riverpod state management only (no raw SetState in large pages).

### Kotlin / Android
- Follow standard [Kotlin Style Conventions](https://kotlinlang.org/docs/coding-conventions.html).
- Keep native logic strictly separated from platform channel dispatcher classes.
- Use Kotlin idioms (e.g. sealed classes, coroutines, extension functions).
- Target Android API 30+ (Android 11).

---

## 🌿 Git Branching Strategy

- **`main`**: Production-ready branch. Never commit directly to main.
- **`feature/[name]`**: For new features (e.g. `feature/voip-recording-beta`).
- **`bugfix/[name]`**: For bug resolutions (e.g. `bugfix/location-permission-crash`).
- **`docs/[name]`**: For documentation tweaks (e.g. `docs/shizuku-guide-update`).

---

## 💬 Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):
- **`feat: [description]`**: A new feature (e.g. `feat: add OSM maps view`).
- **`fix: [description]`**: A bug resolution (e.g. `fix: resolve MediaRecorder lifecycle leak`).
- **`docs: [description]`**: Documentation updates (e.g. `docs: add key properties setup`).
- **`style: [description]`**: Visual tweaks, indentation formats.
- **`refactor: [description]`**: Restructuring code without changing functionality.
- **`chore: [description]`**: Updating dependencies, Gradle files, pubspec assets.
