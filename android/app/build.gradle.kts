plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // ---------------------------------------------------------------
    // NAMESPACE & SDK CONFIGURATION
    // namespace = unique identifier for this app's generated R class
    // compileSdk = which Android SDK version to compile against
    // minSdk = minimum Android version required (API 30 = Android 11)
    //   We need Android 11+ because:
    //   1. Shizuku requires API 30+
    //   2. InCallService is more reliable on 12+
    //   3. MANAGE_EXTERNAL_STORAGE requires API 30+
    // ---------------------------------------------------------------
    namespace = "com.shuni.app"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.shuni.app"
        minSdk = 30          // Android 11 — required for Shizuku
        targetSdk = 36       // Android 16 — latest target
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for release builds.
            // For now, signing with debug keys so `flutter run --release` works.
            // See INSTALLATION.md for signing instructions.
            signingConfig = signingConfigs.getByName("debug")

            // Disable code shrinking to prevent R8 from stripping Shizuku/Coroutine classes causing startup crashes
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// ---------------------------------------------------------------
// DEPENDENCIES
// Native Kotlin/Android libraries needed for the recording engine.
// Flutter packages handle UI; these handle OS-level functionality.
// ---------------------------------------------------------------
dependencies {
    // Core Library Desugaring for Java 8+ features on older Android versions
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // Shizuku API — bridge to privileged shell commands
    // This is what lets us access AudioSource.VOICE_CALL without root
    implementation("dev.rikka.shizuku:api:13.1.5")
    implementation("dev.rikka.shizuku:provider:13.1.5")

    // Kotlin Coroutines — for async operations in native code
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")

    // AndroidX Core — modern Android APIs
    implementation("androidx.core:core-ktx:1.15.0")

    // Google Play Services Location — battery-efficient GPS
    implementation("com.google.android.gms:play-services-location:21.3.0")
}

flutter {
    source = "../.."
}
