import 'package:permission_handler/permission_handler.dart';

/// # AppPermissions
/// 
/// Handles checking and requesting all Android system permissions required by Shuni.
/// 
/// ## Permissions Explained (For Learning)
/// Android 16 enforces strict privacy runtime permission policies:
/// 1. **Microphone (`RECORD_AUDIO`)**: Essential to record microphone input.
/// 2. **Phone State (`READ_PHONE_STATE`)**: Triggers our listener when calls occur.
/// 3. **Call Logs (`READ_CALL_LOG`)**: Lets us fetch the phone number involved.
/// 4. **Contacts (`READ_CONTACTS`)**: Maps raw numbers to human contact names.
/// 5. **Location (`ACCESS_FINE_LOCATION`)**: Records *where* calls are picked up.
/// 6. **Draw Over Apps (`SYSTEM_ALERT_WINDOW`)**: Required to display overlays during a call.
/// 7. **Manage Files (`MANAGE_EXTERNAL_STORAGE`)**: Essential to write and read recordings in `/Shuni/`
///    which is a public directory outside the app's isolated sandbox.
/// 
/// ## Learning Note
/// Some permissions (like microphone, location, contacts) show standard popups. 
/// Special permissions (like overlay and manage files) require directing the user
/// to Android's System Settings screen where they must toggle the option manually.
class AppPermissions {
  AppPermissions._(); // Private constructor

  /// Checks if a specific permission is granted.
  static Future<bool> isGranted(Permission permission) async {
    return permission.isGranted;
  }

  /// Request all standard permissions in sequence.
  /// Special settings permission like overlay and storage are requested separately in UI.
  static Future<Map<Permission, PermissionStatus>> requestStandardPermissions() async {
    final List<Permission> permissions = [
      Permission.microphone,
      Permission.phone,
      Permission.contacts,
      Permission.location,
    ];

    return await permissions.request();
  }

  /// Special request for Storage Management (Android 11+ / API 30+)
  /// This will open Android's "All Files Access" page.
  static Future<bool> requestStorageManagement() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }
    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  /// Special request for overlay drawings.
  /// This will open Android's "Draw over other apps" settings page.
  static Future<bool> requestOverlayPermission() async {
    if (await Permission.systemAlertWindow.isGranted) {
      return true;
    }
    final status = await Permission.systemAlertWindow.request();
    return status.isGranted;
  }

  /// Comprehensive check to verify if the app has ALL necessary permissions to function.
  static Future<bool> hasAllRequiredPermissions() async {
    final bool hasMic = await Permission.microphone.isGranted;
    final bool hasPhone = await Permission.phone.isGranted;
    final bool hasContacts = await Permission.contacts.isGranted;
    final bool hasLocation = await Permission.location.isGranted;
    final bool hasOverlay = await Permission.systemAlertWindow.isGranted;
    final bool hasStorage = await Permission.manageExternalStorage.isGranted;

    return hasMic && hasPhone && hasContacts && hasLocation && hasOverlay && hasStorage;
  }

  /// Fetches a map of all permissions and their current status for the onboarding screen.
  static Future<Map<String, bool>> getDetailedStatus() async {
    return {
      'microphone': await Permission.microphone.isGranted,
      'phone': await Permission.phone.isGranted,
      'contacts': await Permission.contacts.isGranted,
      'location': await Permission.location.isGranted,
      'overlay': await Permission.systemAlertWindow.isGranted,
      'storage': await Permission.manageExternalStorage.isGranted,
    };
  }

  /// Opens the app's standard system settings page (useful if user clicked "Don't ask again").
  static Future<void> openAppSettingsPage() async {
    await openAppSettings();
  }
}
