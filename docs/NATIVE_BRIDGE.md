# Shuni Platform Channels API Documentation

This document describes the interface specifications for communication between Flutter (Dart) and Android (Kotlin) via MethodChannel and EventChannel.

---

## 1. MethodChannel: `com.shuni/core`

Used for request-response invocation from Dart to native Android.

### API Methods

#### `isShizukuReady`
Checks if Shizuku binder is active and app has permission to execute shell commands.
- **Parameters**: None
- **Return Type**: `bool` (true if ready, false otherwise)
- **Dart Code**:
  ```dart
  bool ready = await _channel.invokeMethod<bool>('isShizukuReady') ?? false;
  ```

#### `requestShizukuPermission`
Triggers the Shizuku system permission dialog overlay.
- **Parameters**: None
- **Return Type**: `bool` (true if call succeeded, false otherwise)

#### `getShizukuStatus`
Returns detailed connection parameters.
- **Parameters**: None
- **Return Type**: `Map<String, String>`
  - Key: `status`
  - Value: `ready` | `not_installed` | `not_running` | `no_permission`

#### `startRecording`
Manually starts call recording. Useful for outgoing call overrides or test cases.
- **Parameters**:
  - `phone_number` (`String`): Raw number
  - `contact_name` (`String`): Contact name
  - `direction` (`String`): `incoming` | `outgoing`
- **Return Type**: `bool`

#### `stopRecording`
Manually stops recording.
- **Parameters**: None
- **Return Type**: `bool`

#### `setAutoRecord`
Syncs user preference to native side to toggle call triggers.
- **Parameters**:
  - `enabled` (`bool`)
- **Return Type**: `bool`

---

## 2. EventChannel: `com.shuni/call_events`

Used to stream real-time call states from native Android Kotlin classes to Dart.

### Event Format

Every broadcasted event is a `Map<String, dynamic>`.

#### Structure:
- `event` (`String`): The event identifier.
- `phone_number` (`String`): Raw number.
- `contact_name` (`String`): Contact lookup name.
- `direction` (`String`): `incoming` | `outgoing`.
- `duration_seconds` (`int`): Active duration.
- `audio_path` (`String?`): Path to output file (emitted on stop only).
- `file_size_bytes` (`int?`): Output file size (emitted on stop only).
- `latitude` (`double?`): GPS Latitude (emitted on stop only).
- `longitude` (`double?`): GPS Longitude (emitted on stop only).

### Event Types

1. **`ringing`**
   Emitted when an incoming call starts ringing.
2. **`answered`**
   Emitted when a call connects and is answered.
3. **`recording_started`**
   Emitted when foreground recording service initiates audio capturing.
4. **`recording_stopped`**
   Emitted when active recording halts.
5. **`ended`**
   Emitted when call terminates. Emits output path and coordinates.
