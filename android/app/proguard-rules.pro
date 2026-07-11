# ============================================================
# ProGuard Rules — Shuni
# These rules tell the Android build system what NOT to strip
# when minifying the release APK.
# ============================================================

# --- Shizuku API ---
# Shizuku uses reflection internally, so we must keep its classes
-keep class rikka.shizuku.** { *; }
-keep class moe.shizuku.** { *; }

# --- Flutter ---
# Flutter's engine uses JNI, keep its native bridge
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# --- Google Play Services ---
-keep class com.google.android.gms.** { *; }

# --- Kotlin Coroutines ---
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# --- Our native code ---
# Keep all classes in our package that are called from Flutter via Platform Channels
-keep class com.shuni.app.bridge.** { *; }
-keep class com.shuni.app.recording.** { *; }
-keep class com.shuni.app.detection.** { *; }
-keep class com.shuni.app.shizuku.** { *; }

# --- General ---
# Keep annotations (needed for Shizuku and serialization)
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses

# Ignore missing Play Core classes referenced in Flutter embedding (since we do not use deferred components)
-dontwarn com.google.android.play.core.**
