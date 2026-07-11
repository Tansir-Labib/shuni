/// # AudioQuality
/// 
/// Enum representing different audio compression quality targets.
enum AudioQuality {
  standard(16000, 16000), // 16kbps, 16kHz sample rate — ultra compressed, voice only
  high(32000, 16000),     // 32kbps, 16kHz sample rate — standard voice call benchmark (Recommended)
  maximum(64000, 24000);  // 64kbps, 24kHz sample rate — studio level voice archiving

  final int bitRate;
  final int sampleRate;
  
  const AudioQuality(this.bitRate, this.sampleRate);

  String toJson() => name;

  static AudioQuality fromJson(String value) {
    return values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AudioQuality.high,
    );
  }
}

/// # AppSettings
/// 
/// Data model representing user configurations and preferences.
/// 
/// ## Settings Properties
/// - `autoRecordEnabled`: If active, records SIM calls automatically without user prompt.
/// - `biometricLockEnabled`: Accesses face/fingerprint authentication on open.
/// - `pinLockEnabled`: Locks the app with a secure PIN.
/// - `autoLockSeconds`: Timer for triggering lock when app is backgrounded.
/// - `autoBackupEnabled`: Automatically backs up gzipped databases to Google Drive.
/// - `backupWifiOnly`: Sync only when device is connected to a WiFi network.
/// - `audioQuality`: Quality profile for the Opus codec.
/// - `showRecordingOverlay`: Toggle drawing the floaty UI card during active calls.
/// - `autoCleanupDays`: Keep calls for X days before automated purging.
class AppSettings {
  final bool autoRecordEnabled;
  final bool biometricLockEnabled;
  final bool pinLockEnabled;
  final int autoLockSeconds;
  final bool autoBackupEnabled;
  final bool backupWifiOnly;
  final AudioQuality audioQuality;
  final bool showRecordingOverlay;
  final int? autoCleanupDays;

  AppSettings({
    this.autoRecordEnabled = true,
    this.biometricLockEnabled = false,
    this.pinLockEnabled = false,
    this.autoLockSeconds = 0, // 0 = Instant
    this.autoBackupEnabled = false,
    this.backupWifiOnly = true,
    this.audioQuality = AudioQuality.high,
    this.showRecordingOverlay = true,
    this.autoCleanupDays,
  });

  /// Clones the settings model with optional overrides.
  AppSettings copyWith({
    bool? autoRecordEnabled,
    bool? biometricLockEnabled,
    bool? pinLockEnabled,
    int? autoLockSeconds,
    bool? autoBackupEnabled,
    bool? backupWifiOnly,
    AudioQuality? audioQuality,
    bool? showRecordingOverlay,
    int? autoCleanupDays,
  }) {
    return AppSettings(
      autoRecordEnabled: autoRecordEnabled ?? this.autoRecordEnabled,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      pinLockEnabled: pinLockEnabled ?? this.pinLockEnabled,
      autoLockSeconds: autoLockSeconds ?? this.autoLockSeconds,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      backupWifiOnly: backupWifiOnly ?? this.backupWifiOnly,
      audioQuality: audioQuality ?? this.audioQuality,
      showRecordingOverlay: showRecordingOverlay ?? this.showRecordingOverlay,
      autoCleanupDays: autoCleanupDays ?? this.autoCleanupDays,
    );
  }

  /// Deserialization: Maps a standard Map to an [AppSettings] object.
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      autoRecordEnabled: (map['auto_record'] as int? ?? 1) == 1,
      biometricLockEnabled: (map['biometric_lock'] as int? ?? 0) == 1,
      pinLockEnabled: (map['pin_lock'] as int? ?? 0) == 1,
      autoLockSeconds: map['auto_lock_seconds'] as int? ?? 0,
      autoBackupEnabled: (map['auto_backup'] as int? ?? 0) == 1,
      backupWifiOnly: (map['backup_wifi_only'] as int? ?? 1) == 1,
      audioQuality: AudioQuality.fromJson(map['audio_quality'] as String? ?? 'high'),
      showRecordingOverlay: (map['show_overlay'] as int? ?? 1) == 1,
      autoCleanupDays: map['cleanup_days'] as int?,
    );
  }

  /// Serialization: Maps [AppSettings] parameters to a key-value Map.
  Map<String, dynamic> toMap() {
    return {
      'auto_record': autoRecordEnabled ? 1 : 0,
      'biometric_lock': biometricLockEnabled ? 1 : 0,
      'pin_lock': pinLockEnabled ? 1 : 0,
      'auto_lock_seconds': autoLockSeconds,
      'auto_backup': autoBackupEnabled ? 1 : 0,
      'backup_wifi_only': backupWifiOnly ? 1 : 0,
      'audio_quality': audioQuality.toJson(),
      'show_overlay': showRecordingOverlay ? 1 : 0,
      'cleanup_days': autoCleanupDays,
    };
  }
}
