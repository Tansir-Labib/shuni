import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// # AuthState
/// 
/// Holds state variables relating to authentication status and lock screen timers.
class AuthState {
  final bool isLocked;
  final bool hasPin;
  final bool isBiometricAvailable;
  final bool isLockedOut;
  final int lockoutSecondsRemaining;
  final String error;

  AuthState({
    this.isLocked = true, // Locked on startup by default
    this.hasPin = false,
    this.isBiometricAvailable = false,
    this.isLockedOut = false,
    this.lockoutSecondsRemaining = 0,
    this.error = '',
  });

  AuthState copyWith({
    bool? isLocked,
    bool? hasPin,
    bool? isBiometricAvailable,
    bool? isLockedOut,
    int? lockoutSecondsRemaining,
    String? error,
  }) {
    return AuthState(
      isLocked: isLocked ?? this.isLocked,
      hasPin: hasPin ?? this.hasPin,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isLockedOut: isLockedOut ?? this.isLockedOut,
      lockoutSecondsRemaining: lockoutSecondsRemaining ?? this.lockoutSecondsRemaining,
      error: error ?? this.error,
    );
  }
}

/// # AuthNotifier
/// 
/// State notifier managing user login status, PIN lockout timers, and biometrics triggers.
class AuthNotifier extends StateNotifier<AuthState> {
  Timer? _lockoutTimer;

  AuthNotifier() : super(AuthState()) {
    checkInitialState();
  }

  /// Verifies lock setup details on startup.
  Future<void> checkInitialState() async {
    final bool pinEnabled = await AuthService.instance.isPinEnabled();
    final bool bioAvail = await AuthService.instance.isBiometricHardwareAvailable();
    final bool locked = pinEnabled; // Lock app on launch if PIN is set up

    state = state.copyWith(
      isLocked: locked,
      hasPin: pinEnabled,
      isBiometricAvailable: bioAvail,
    );

    if (AuthService.instance.isLockedOut()) {
      _startLockoutCountdown();
    }
  }

  /// Manually locks the app (e.g. on backgrounding).
  void lock() {
    if (state.hasPin) {
      state = state.copyWith(isLocked: true);
    }
  }

  /// Verifies input PIN.
  Future<bool> attemptPinUnlock(String pin) async {
    final bool success = await AuthService.instance.verifyPin(pin);
    
    if (success) {
      state = state.copyWith(isLocked: false, error: '');
      return true;
    } else {
      if (AuthService.instance.isLockedOut()) {
        _startLockoutCountdown();
      } else {
        state = state.copyWith(error: 'Invalid PIN. Try again.');
      }
      return false;
    }
  }

  /// Verifies fingerprint/face biometrics.
  Future<bool> attemptBiometricUnlock() async {
    if (!state.isBiometricAvailable) return false;
    
    final bool success = await AuthService.instance.authenticateWithBiometrics();
    if (success) {
      state = state.copyWith(isLocked: false, error: '');
      return true;
    }
    return false;
  }

  /// Sets up a new lock PIN.
  Future<void> registerPin(String pin) async {
    await AuthService.instance.setPin(pin);
    state = state.copyWith(isLocked: false, hasPin: true);
  }

  /// Disables security locks.
  Future<void> disableSecurity() async {
    await AuthService.instance.disablePin();
    await AuthService.instance.setBiometricEnabled(false);
    state = state.copyWith(isLocked: false, hasPin: false);
  }

  /// Starts the lockout timer tick.
  void _startLockoutCountdown() {
    _lockoutTimer?.cancel();
    state = state.copyWith(
      isLockedOut: true,
      lockoutSecondsRemaining: AuthService.instance.getRemainingLockoutSeconds(),
      error: 'Too many incorrect attempts.',
    );

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final int remaining = AuthService.instance.getRemainingLockoutSeconds();
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(isLockedOut: false, lockoutSecondsRemaining: 0, error: '');
      } else {
        state = state.copyWith(lockoutSecondsRemaining: remaining);
      }
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }
}

// Global Provider declaration
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
