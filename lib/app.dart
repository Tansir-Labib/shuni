import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/lock/lock_screen.dart';

/// # ShuniApp
/// 
/// Main MaterialApp wrapper that manages app lifecycle states and coordinates route security.
/// 
/// ## Security Lifecycle
/// - Hooks into [WidgetsBindingObserver] to monitor app backgrounding.
/// - If the app transitions to the background and the user has PIN lock configured,
///   we automatically flip the `isLocked` state in our [AuthProvider].
/// - On return, the app presents the [LockScreen] preventing raw memory peeking.
class ShuniApp extends ConsumerStatefulWidget {
  const ShuniApp({super.key});

  @override
  ConsumerState<ShuniApp> createState() => _ShuniAppState();
}

class _ShuniAppState extends ConsumerState<ShuniApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App backgrounded, trigger lock
      final settings = ref.read(settingsProvider);
      if (settings.pinLockEnabled) {
        ref.read(authProvider.notifier).lock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Shuni',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // If locked, override navigation and direct immediately to LockScreen
      home: authState.isLocked && authState.hasPin
          ? const LockScreen()
          : const SplashScreen(),
    );
  }
}
