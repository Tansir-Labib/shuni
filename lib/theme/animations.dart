import 'package:flutter/material.dart';

/// # AppAnimations
/// 
/// Contains animation durations, curves, and transition utilities for the Shuni application.
/// 
/// ## Principles of UI Motion
/// - Keep animations fast to maintain a responsive feel (150ms-300ms range)
/// - Use non-linear curves (e.g. `easeOutCubic`) to mimic physical momentum
/// - Standardize transitions so the user experience feels cohesive
/// 
/// ## Learning Note
/// In Flutter, animating objects using pre-defined curves like `easeOut` or `elasticOut` 
/// yields significantly more premium results than linear interpolation (`Curves.linear`).
class AppAnimations {
  AppAnimations._(); // Private constructor prevents instantiation

  // Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration extraSlow = Duration(milliseconds: 800);

  // Curves
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve decelerate = Curves.decelerate;
  static const Curve bounce = Curves.elasticOut;
  static const Curve smooth = Curves.easeInOutQuad;

  // Custom Transitions
  /// Creates a premium fade-slide transition from bottom to top for page changes.
  static Route<T> slideUpRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: normal,
      reverseTransitionDuration: fast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final double begin = 0.08;
        final double end = 0.0;
        final Curve curve = defaultCurve;

        final Animatable<double> scaleAnimation = Tween<double>(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: curve));

        final Animatable<Offset> slideTween = Tween<Offset>(
          begin: Offset(0.0, begin),
          end: Offset(0.0, end),
        ).chain(CurveTween(curve: curve));

        final Animatable<double> fadeTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: ScaleTransition(
              scale: animation.drive(scaleAnimation),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Creates a premium cross-fade transition.
  static Route<T> fadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: normal,
      reverseTransitionDuration: fast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(CurveTween(curve: smooth)),
          child: child,
        );
      },
    );
  }
}
