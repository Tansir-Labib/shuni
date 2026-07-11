import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/database_service.dart';
import '../services/recording_service.dart';

/// # SettingsNotifier
/// 
/// State notifier managing user configuration changes and persistence.
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings()) {
    loadSettings();
  }

  /// Loads configuration values from the SQLite database.
  Future<void> loadSettings() async {
    try {
      final AppSettings settings = await DatabaseService.instance.getSettings();
      state = settings;
      // Sync auto-record to native side
      await RecordingService.instance.setAutoRecord(settings.autoRecordEnabled);
    } catch (_) {
      // Fallback defaults
    }
  }

  /// Toggles call auto-recording and propagates settings changes to native code.
  Future<void> toggleAutoRecord() async {
    final bool nextVal = !state.autoRecordEnabled;
    final AppSettings updated = state.copyWith(autoRecordEnabled: nextVal);
    state = updated;
    await DatabaseService.instance.updateSettings(updated);
    await RecordingService.instance.setAutoRecord(nextVal);
  }

  /// Configures PIN lock status.
  Future<void> setPinLockEnabled(bool enabled) async {
    final AppSettings updated = state.copyWith(pinLockEnabled: enabled);
    state = updated;
    await DatabaseService.instance.updateSettings(updated);
  }

  /// Configures Biometric unlock status.
  Future<void> setBiometricLockEnabled(bool enabled) async {
    final AppSettings updated = state.copyWith(biometricLockEnabled: enabled);
    state = updated;
    await DatabaseService.instance.updateSettings(updated);
  }

  /// Updates auto-lock delay.
  Future<void> setAutoLockSeconds(int seconds) async {
    final AppSettings updated = state.copyWith(autoLockSeconds: seconds);
    state = updated;
    await DatabaseService.instance.updateSettings(updated);
  }

  /// Configures cloud backups.
  Future<void> setAutoBackupEnabled(bool enabled) async {
    final AppSettings updated = state.copyWith(autoBackupEnabled: enabled);
    state = updated;
    await DatabaseService.instance.updateSettings(updated);
  }

  /// Configures WiFi only backups.
  Future<void> setBackupWifiOnly(bool wifiOnly) async {
    final AppSettings updated = state.copyWith(backupWifiOnly: wifiOnly);
    state = updated;
    await DatabaseService.instance.updateSettings(updated);
  }

  /// Sets recording compression parameters.
  Future<void> setAudioQuality(AudioQuality quality) async {
    final AppSettings updated = state.copyWith(audioQuality: quality);
    state = updated;
    await DatabaseService.instance.updateSettings(updated);
  }

  /// Configures floating overlay widget availability.
  Future<void> setShowRecordingOverlay(bool show) async {
    final AppSettings updated = state.copyWith(showRecordingOverlay: show);
    state = updated;
    await DatabaseService.instance.updateSettings(updated);
  }

  /// Configures files purge cycle.
  Future<void> setAutoCleanupDays(int? days) async {
    final AppSettings updated = state.copyWith(autoCleanupDays: days);
    state = updated;
    await DatabaseService.instance.updateSettings(updated);
  }
}

// Global Provider declaration
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
