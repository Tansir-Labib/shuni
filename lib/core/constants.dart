/// # AppConstants
/// 
/// Contains all global, project-wide constants for the Shuni application.
/// 
/// ## Learning Note
/// Isolating key strings and configuration properties in a centralized `constants.dart`
/// file prevents typos, keeps configuration consistent, and enables rapid refactoring
/// (e.g. changing platform channel names or database locations in one place).
class AppConstants {
  AppConstants._(); // Private constructor prevents instantiation

  // Brand Name & Slogans
  static const String appName = 'Shuni';
  static const String appNameBangla = 'শুনি';
  static const String slogan = 'শোনো, মনে রাখো';
  static const String sloganEnglish = 'Every conversation, preserved.';

  // Platform Channel Configuration
  static const String methodChannelName = 'com.shuni/core';
  static const String eventChannelName = 'com.shuni/call_events';

  // Storage Directories (Stored in public external storage under '/Shuni/')
  static const String baseFolder = 'Shuni';
  static const String recordingsFolder = 'Shuni/recordings';
  static const String databaseFolder = 'Shuni/.shuni_db';
  
  // Database Name
  static const String databaseName = 'shuni.db';

  // Audio Configuration
  static const int opusBitrate = 32000; // 32kbps mono VBR — perfect balance of speech clarity and tiny size

  // Security configuration
  static const int maxPinAttempts = 5;
  static const int lockoutDurationSeconds = 30;

  // Backup configuration
  static const String driveBackupFolder = 'Shuni Backups';
}
