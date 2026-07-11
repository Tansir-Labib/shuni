import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// # Extensions
/// 
/// Contains extension methods on standard Dart and Flutter classes (String, DateTime, int, Color).
/// 
/// ## Why Extensions?
/// Extension methods allow adding behavior to standard SDK classes (like String or DateTime) 
/// without inheriting from them. This encourages highly readable code like:
/// `myDateTime.timeAgo()` instead of helper calls like `DateUtils.getTimeAgo(myDateTime)`.
/// 
/// ## Learning Note
/// Extensions are resolved statically. They do not add any overhead compared to helper functions,
/// but drastically improve code readability and maintainability.

extension StringExtension on String {
  /// Capitalizes the first letter of a string (e.g. "shuni" -> "Shuni").
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Extracts initials (e.g. "Rahim Uddin" -> "RU").
  String toInitials() {
    if (isEmpty) return '?';
    final List<String> parts = trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return this[0].toUpperCase();
  }
}

extension DateTimeExtension on DateTime {
  /// Checks if this date falls on today.
  bool get isToday {
    final DateTime now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Checks if this date falls on yesterday.
  bool get isYesterday {
    final DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  /// Returns a clean relative time description (e.g. "Today, 11:30 PM", "Yesterday", or "Jul 11").
  String timeAgo() {
    final DateTime now = DateTime.now();
    final String timeStr = DateFormat('hh:mm a').format(this);

    if (isToday) {
      return 'Today, $timeStr';
    } else if (isYesterday) {
      return 'Yesterday, $timeStr';
    } else if (now.difference(this).inDays < 7) {
      // Show day name (e.g. "Monday, 11:30 PM")
      return '${DateFormat('EEEE').format(this)}, $timeStr';
    } else {
      // Show full date (e.g. "Jul 11, 2026")
      return DateFormat('MMM dd, yyyy').format(this);
    }
  }

  /// Generates a standardized, filesystem-safe filename base for call recordings.
  String toFileNameString() {
    return DateFormat('yyyy-MM-dd_HH-mm-ss').format(this);
  }
}

extension IntExtension on int {
  /// Converts an integer count representing seconds into a standard [Duration] object.
  Duration get toDurationSeconds => Duration(seconds: this);
}

extension ColorExtension on Color {
  /// Adds a custom opacity factor to easily produce glassmorphism cards.
  Color withGlassOpacity([double factor = 0.1]) {
    return withOpacity(factor);
  }
}
