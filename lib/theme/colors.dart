import 'package:flutter/material.dart';

/// # AppColors
/// 
/// Defines the complete color palette for the Shuni application.
/// 
/// ## Design System Notes
/// - Theme style is dark-mode first (glassmorphism ready)
/// - Primary: Deep Violet (#6C63FF) for brand identity
/// - Accent: Coral (#FF6B6B) for high-importance actions and indicators
/// - Background: Rich Dark Navy (#0A0A1A) for a premium dark feel
/// - Surface: Darker Slate (#12122B) to emulate frosted glass overlays
/// 
/// ## Learning Note
/// Storing colors as `static const Color` constants is a Flutter best practice.
/// This allows the compiler to optimize their usage, reducing layout/rendering overhead.
class AppColors {
  AppColors._(); // Private constructor prevents instantiation

  // Brand Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B83FF);
  static const Color primaryDark = Color(0xFF4A42DB);
  
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentLight = Color(0xFFFF8A8A);

  // Background and Surfaces
  static const Color background = Color(0xFF0A0A1A);
  static const Color surface = Color(0xFF12122B);
  static const Color surfaceLight = Color(0xFF1A1A3E);
  
  // Borders and Dividers
  static final Color cardBorder = Colors.white.withOpacity(0.08);
  static final Color divider = Colors.white.withOpacity(0.05);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B8BA7);
  static const Color textMuted = Color(0xFF5A5A7A);

  // Status Colors
  static const Color success = Color(0xFF00D2D3);
  static const Color warning = Color(0xFFFF9F43);
  static const Color error = Color(0xFFFF6B6B);
  
  // Specific Use Colors
  static const Color recording = Color(0xFFFF4757); // Flashing recording indicator red
}
