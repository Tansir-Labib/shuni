# Shuni Native Android Engine (Kotlin)

This package contains the native Android implementation for the Shuni Call Recording engine.

## Core Components

```
com.shuni.app/
├── MainActivity.kt            # App entry point, registers Platform Channels
│
├── bridge/                    # Flutter ↔ Kotlin communication layers
│   ├── PlatformBridge.kt      # MethodChannel: requests from Flutter
│   └── CallEventStream.kt     # EventChannel: stream of call states to Flutter
│
├── recording/                 # Audio capture engine
│   ├── CallRecordingService.kt# Foreground service orchestrating recording
│   ├── AudioRecorder.kt       # MediaRecorder configuration wrapper
│   └── RecordingConfig.kt     # Opus codec/bitrate/path data parameters
│
├── detection/                 # Call state monitoring
│   ├── CallDetectorService.kt # InCallService hook (Android 12+)
│   ├── PhoneStateReceiver.kt  # Fallback BroadcastReceiver listener
│   ├── ContactResolver.kt     # Resolves raw numbers to Contact Display Names
│   └── BootReceiver.kt        # Re-registers listeners after phone reboot
│
└── shizuku/                   # Privilege escalation binder
    ├── ShizukuBridge.kt       # Interfaces with Shizuku framework
    └── ShizukuStatus.kt       # Sealed classes for connection states
```

---

## Technical Details

### 1. Privilege Escalation via Shizuku
Google blocks third-party call recording access to `AudioSource.VOICE_CALL` at the OS level since Android 9. Standard apps can only record microphone streams, which results in terrible, one-sided captures.
Shizuku runs a background service running under shell developer privileges. Shuni binds to this service using the Shizuku Binder API. This grants our app process access to Android's internal audio streams, capturing full-duplex, high-quality audio.

### 2. Audio Capture Configuration
We use standard Android `MediaRecorder`.
- **Audio Source**: `AudioSource.VOICE_CALL` (or falls back to `AudioSource.MIC` if Shizuku fails)
- **Container**: `Ogg` (.ogg)
- **Encoder**: `Opus`
- **Quality**: 32000 bps (32 kbps mono) VBR at 16 kHz sample rate.
Voice recordings are saved in the public directory `/storage/emulated/0/Shuni/recordings/` with standard filename layout:
`{timestamp}_{contactName}_{direction}.ogg`

### 3. Foreground Service Lifecycle
To prevent the Android OS from killing the audio capturing process when Shuni is closed or backgrounded during a call, the `CallRecordingService` runs as a **Foreground Service** with the active properties:
- `android:foregroundServiceType="phoneCall|microphone"`
It displays a persistent, ongoing notification showing call duration details during execution.

### 4. Call Detection Hooks
We implement a dual call-state monitoring flow:
- **Primary**: `CallDetectorService` extends `InCallService`. This is the modern, recommended hook. When active calls occur, Android binds to this service, providing caller phone number details and answered/hung up states.
- **Fallback**: `PhoneStateReceiver` checks `PHONE_STATE` broadcasts. If the `InCallService` fails to bind on custom devices, the receiver starts the recording service.

### 5. Multi-Threaded Channel Safety
Method calls from Flutter run on standard engine threads. Events sent back to Flutter (like a call finished details packet containing coordinates and path details) can originate from location client callbacks or telecom listeners. To prevent crashes, all `EventSink` emissions are safely dispatched onto Android's main loop thread using a Handler bound to `Looper.getMainLooper()`.
