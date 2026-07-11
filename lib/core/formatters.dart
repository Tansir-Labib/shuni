import 'package:intl/intl.dart';

/// # AppFormatters
/// 
/// Provides standardized data formatters for dates, times, file sizes, and phone numbers.
/// 
/// ## Learning Note
/// Formatting logic often gets duplicated in UI widgets. By writing simple pure-function
/// formatters, we ensure:
/// - Consistent presentation (e.g. file sizes are always rounded to 1 decimal place)
/// - Easier unit testing (pure functions are simple to verify)
/// - Cleaner UI code (widgets focus only on drawing, not computing format logic)
class AppFormatters {
  AppFormatters._(); // Private constructor prevents instantiation

  /// Formats duration in seconds to a readable string (e.g. "2m 34s" or "1h 05m 12s").
  static String formatDuration(int seconds) {
    if (seconds <= 0) return '0s';
    
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int remainingSeconds = seconds % 60;

    if (hours > 0) {
      final String mStr = minutes.toString().padLeft(2, '0');
      final String sStr = remainingSeconds.toString().padLeft(2, '0');
      return '${hours}h ${mStr}m ${sStr}s';
    } else if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }

  /// Formats date to a human-readable string (e.g. "Jul 11, 2026").
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  /// Formats time to 12-hour format with AM/PM (e.g. "11:30 PM").
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  /// Formats full date and time (e.g. "Jul 11, 2026 · 11:30 PM").
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} · ${formatTime(dateTime)}';
  }

  /// Formats a file size in bytes to a human-readable unit (e.g. "2.3 MB" or "450 KB").
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const List<String> units = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    
    // If it's bytes, show as integer, otherwise show with 1 decimal place
    return i == 0 ? '${bytes} B' : '${size.toStringAsFixed(1)} ${units[i]}';
  }

  /// Cleans and formats phone numbers to have readable spacing (e.g. "+880 1712 345678").
  static String formatPhoneNumber(String rawNumber) {
    final String clean = rawNumber.replaceAll(RegExp(r'\s+|-'), '');
    if (clean.startsWith('+880') && clean.length == 14) {
      // Bangladesh standard formatting (+880 17XX-XXXXXX)
      return '${clean.substring(0, 4)} ${clean.substring(4, 8)} ${clean.substring(8)}';
    }
    return rawNumber; // Return original if it doesn't match standard patterns
  }

  /// Extracts initials from a contact name (e.g. "Rahim Khan" -> "RK").
  static String getInitials(String name) {
    if (name.isEmpty) return '?';
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
