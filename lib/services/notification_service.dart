import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// # NotificationService
/// 
/// Manages system-level status notifications for active recordings and backups.
/// 
/// ## Learning Note
/// Since Android 13+ (API 33), apps must request user permission (`POST_NOTIFICATIONS`) 
/// before they can send push notifications. Furthermore, if a background service runs
/// (like our Kotlin call recording service), Android *requires* a foreground notification 
/// to notify the user that an active background task is running, ensuring the operating
/// system doesn't kill it.
class NotificationService {
  // Singleton pattern
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static const int recordingNotificationId = 8881;
  static const int backupNotificationId = 8882;
  
  static const String channelId = 'shuni_call_recorder';
  static const String channelName = 'Shuni Call Recorder Service';
  static const String channelDescription = 'Displays ongoing call recording alerts';

  /// Initializes the local notifications plugin.
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Create high-importance notification channel for Android
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.low, // Lower importance so it doesn't make noisy sounds repeatedly
          showBadge: false,
          playSound: false,
        ),
      );
    }
  }

  /// Displays an alert telling the user that a backup is starting/succeeding.
  Future<void> showBackupNotification({
    required String title,
    required String body,
    bool ongoing = false,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: ongoing,
      onlyAlertOnce: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      backupNotificationId,
      title,
      body,
      platformDetails,
    );
  }

  /// Cancels/removes the backup notification.
  Future<void> cancelBackupNotification() async {
    await _notificationsPlugin.cancel(backupNotificationId);
  }
}
