import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // We use show to prevent importing everything if not needed
import 'colors.dart';

/// # AppTypography
/// 
/// Manages the complete typography system for the Shuni application.
/// 
/// ## Fonts Selection
/// - **Outfit**: A geometric sans-serif typeface used for headers, numbers, and prominent labels.
///   It gives the app a modern, tech-forward, and premium appearance.
/// - **Inter**: A highly legible typeface optimized for computer screens, used for all body text,
///   descriptions, and general UI items.
/// 
/// ## Learning Note
/// By using the `google_fonts` package, we get access to high-quality typography without bundling
/// large `.ttf` files directly in our repository. Google Fonts handles caching and loading automatically.
class AppTypography {
  AppTypography._(); // Private constructor prevents instantiation

  // Base TextStyle overrides for color
  static const TextStyle _baseText = TextStyle(color: AppColors.textPrimary);

  // Display Styles (Large hero texts, splash screen, onboarding headers)
  static final TextStyle displayLarge = GoogleFonts.outfit(
    textStyle: _baseText,
    fontSize: 40,
    fontWeight: FontWeight.bold,
    letterSpacing: -1.0,
  );

  static final TextStyle displayMedium = GoogleFonts.outfit(
    textStyle: _baseText,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static final TextStyle displaySmall = GoogleFonts.outfit(
    textStyle: _baseText,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  // Headline Styles (Page titles, call screen headers)
  static final TextStyle headlineLarge = GoogleFonts.outfit(
    textStyle: _baseText,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle headlineMedium = GoogleFonts.outfit(
    textStyle: _baseText,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle headlineSmall = GoogleFonts.outfit(
    textStyle: _baseText,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  // Title Styles (Card headers, list item main texts)
  static final TextStyle titleLarge = GoogleFonts.outfit(
    textStyle: _baseText,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static final TextStyle titleMedium = GoogleFonts.outfit(
    textStyle: _baseText,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle titleSmall = GoogleFonts.outfit(
    textStyle: _baseText,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // Body Styles (Paragraphs, metadata descriptions, list subtitles)
  static final TextStyle bodyLarge = GoogleFonts.inter(
    textStyle: _baseText,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static final TextStyle bodyMedium = GoogleFonts.inter(
    textStyle: _baseText,
    fontSize: 14,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static final TextStyle bodySmall = GoogleFonts.inter(
    textStyle: _baseText,
    fontSize: 12,
    color: AppColors.textMuted,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );

  // Label Styles (Chips, button texts, indicators)
  static final TextStyle labelLarge = GoogleFonts.inter(
    textStyle: _baseText,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static final TextStyle labelMedium = GoogleFonts.inter(
    textStyle: _baseText,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  static final TextStyle labelSmall = GoogleFonts.inter(
    textStyle: _baseText,
    fontSize: 10,
    color: AppColors.textMuted,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );
}
