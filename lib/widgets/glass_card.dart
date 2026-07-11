import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// # GlassCard
/// 
/// Reusable glassmorphism card widget that implements a frosted glass aesthetic.
/// 
/// ## Visual Composition
/// - Uses [BackdropFilter] with an `ImageFilter.blur` to blur background content.
/// - Border: A very thin (1px) white border with very low opacity (10%).
/// - Background: Rich Slate surface color with low opacity (85%).
/// 
/// ## Learning Note
/// Glassmorphism requires an elements stack: the blurred backdrop *must* sit behind
/// the card content. Using [ClipRRect] prevents the blur effect from leaking outside
/// the rounded border radius.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final Color? color;
  final BorderSide? border;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.borderRadius = 20.0,
    this.color,
    this.border,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: border ?? BorderSide(color: AppColors.cardBorder, width: 1),
    );

    Widget cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? AppColors.surface.withOpacity(0.85),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );

    // Apply InkWell if onTap callback is provided
    if (onTap != null) {
      cardContent = Material(
        color: Colors.transparent,
        shape: cardShape,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
    } else {
      cardContent = Material(
        color: Colors.transparent,
        shape: cardShape,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
