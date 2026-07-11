import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// # EmptyState
/// 
/// Reusable empty list graphic representation shown when search results or call records
/// are empty.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? actionButton;

  const EmptyState({
    super.key,
    this.icon = Icons.record_voice_over_outlined,
    required this.title,
    required this.description,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
          // Large styled icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 1.5),
            ),
            child: Icon(
              icon,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Title
          Text(
            title,
            style: AppTypography.headlineLarge.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Description
          Text(
            description,
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          
          if (actionButton != null) ...[
            const SizedBox(height: 24),
            actionButton!,
          ],
        ],
      ),
     ),
    );
  }
}
