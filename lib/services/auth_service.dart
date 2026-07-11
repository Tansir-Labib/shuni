import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../core/constants.dart';

/// # AuthService
/// 
/// Manages device security, biometric verification, and PIN lockout checks.
/// 
/// ## Security Design
/// 1. **Biometrics**: Uses standard Android `BiometricPrompt` through the `local_auth` package.
/// 2. **PIN Storage**: Hashed with **SHA-256** and persisted in secure Keystore-backed storage.
/// 3. **Brute Force Protection**: Keeps track of consecutive failed entries and enforces a 
///    lockout timer if failed attempts exceed [AppConstants.maxPinAttempts] (5 attempts).
/// 
/// ## Learning Note
/// Storing raw plaintext passwords or PINs is a major security flaw. We hash the PIN using SHA-256:
/// `hash = sha256(pin)`. When the user enters a PIN, we hash their input and check if it matches 
/// the stored hash. This is mathematically irreversible.
class AuthService {
  // Singleton pattern
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _pinHashKey = 'shuni_pin_hash';
  static const String _pinEnabledKey = 'shuni_pin_enabled';
  static const String _bioEnabledKey = 'shuni_bio_enabled';
  
  // Runtime trackers
  int _failedAttempts = 0;
  DateTime? _lockoutEndTime;

  /// Hashes the given PIN string using SHA-256.
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Sets a new PIN. Hashes it and saves it securely.
  Future<void> setPin(String pin) async {
    final String hash = _hashPin(pin);
    await _secureStorage.write(key: _pinHashKey, value: hash);
    await _secureStorage.write(key: _pinEnabledKey, value: 'true');
    _failedAttempts = 0;
    _lockoutEndTime = null;
  }

  /// Checks if a PIN is currently configured.
  Future<bool> isPinEnabled() async {
    final String? enabled = await _secureStorage.read(key: _pinEnabledKey);
    return enabled == 'true';
  }

  /// Removes/disables the PIN.
  Future<void> disablePin() async {
    await _secureStorage.delete(key: _pinHashKey);
    await _secureStorage.write(key: _pinEnabledKey, value: 'false');
    _failedAttempts = 0;
    _lockoutEndTime = null;
  }

  /// Validates the input PIN against the secure database hash.
  Future<bool> verifyPin(String inputPin) async {
    // 1. Check lockout timer first
    if (isLockedOut()) {
      return false;
    }

    final String? savedHash = await _secureStorage.read(key: _pinHashKey);
    if (savedHash == null) return false;

    final String inputHash = _hashPin(inputPin);
    final bool isValid = savedHash == inputHash;

    if (isValid) {
      _failedAttempts = 0;
      _lockoutEndTime = null;
      return true;
    } else {
      _failedAttempts++;
      if (_failedAttempts >= AppConstants.maxPinAttempts) {
        _lockoutEndTime = DateTime.now().add(const Duration(seconds: AppConstants.lockoutDurationSeconds));
      }
      return false;
    }
  }

  /// Checks if the user is currently locked out from entering a PIN.
  bool isLockedOut() {
    if (_lockoutEndTime == null) return false;
    final bool active = DateTime.now().isBefore(_lockoutEndTime!);
    if (!active) {
      // Lockout duration has expired, reset attempts
      _failedAttempts = 0;
      _lockoutEndTime = null;
    }
    return active;
  }

  /// Returns the remaining lockout duration in seconds.
  int getRemainingLockoutSeconds() {
    if (_lockoutEndTime == null) return 0;
    final difference = _lockoutEndTime!.difference(DateTime.now()).inSeconds;
    return difference > 0 ? difference : 0;
  }

  /// Configures whether biometric (fingerprint/face) unlock is enabled.
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(key: _bioEnabledKey, value: enabled ? 'true' : 'false');
  }

  /// Checks if biometric unlock is enabled.
  Future<bool> isBiometricEnabled() async {
    final String? enabled = await _secureStorage.read(key: _bioEnabledKey);
    return enabled == 'true';
  }

  /// Checks if the device has biometric hardware available and configured.
  Future<bool> isBiometricHardwareAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool isSupported = await _localAuth.isDeviceSupported();
      return canAuthenticateWithBiometrics && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the user with native Android BiometricPrompt popup.
  Future<bool> authenticateWithBiometrics({
    String reason = 'Authenticate to unlock Shuni',
  }) async {
    final bool hardware = await isBiometricHardwareAvailable();
    if (!hardware) return false;

    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Master login verify method: tries biometrics first if enabled, otherwise lets UI fallback to PIN.
  Future<bool> attemptQuickUnlock() async {
    final bool bioEnabled = await isBiometricEnabled();
    if (bioEnabled) {
      return await authenticateWithBiometrics();
    }
    return false;
  }
}
