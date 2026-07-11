import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/database_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';

/// # main
/// 
/// Application entry point. Performs early asynchronous service initializations
/// before rendering UI frames.
/// 
/// ## Startup Sequence
/// 1. Ensures Flutter widget bindings are initialized.
/// 2. Creates the `/Shuni/` storage directories (and nomedia locks).
/// 3. Instantiates local databases (compiling schemas/tables).
/// 4. Configures notification settings.
/// 5. Wraps the app shell in [ProviderScope] to bootstrap Riverpod state containers.
void main() async {
  // 1. Ensure Flutter framework binds properly
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Initialize public directories
    await StorageService.initializeDirectories();

    // 3. Open SQLite connection
    await DatabaseService.instance.database;

    // 4. Register local notification alerts
    await NotificationService.instance.initialize();
  } catch (_) {
    // Fail gracefully during silent startup issues;
    // Splash screen or onboarding will catch missing directory permissions
  }

  // 5. Start main app loops
  runApp(
    const ProviderScope(
      child: ShuniApp(),
    ),
  );
}
