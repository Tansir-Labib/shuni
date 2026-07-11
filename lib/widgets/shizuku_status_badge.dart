import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// # ShizukuStatusBadge
/// 
/// A status indicator chip showing the pairing status of Shizuku.
class ShizukuStatusBadge extends StatelessWidget {
  final String status;
  final VoidCallback? onTap;

  const ShizukuStatusBadge({
    super.key,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'ready':
      case 'authorized':
        badgeColor = AppColors.success;
        label = 'Shizuku: Active';
        icon = Icons.check_circle_outline;
        break;
      case 'not_running':
        badgeColor = AppColors.warning;
        label = 'Shizuku: Stopped';
        icon = Icons.pause_circle_outline;
        break;
      case 'unauthorized':
      case 'nopermission':
      case 'no_permission':
        badgeColor = AppColors.accent;
        label = 'Shizuku: No Permission';
        icon = Icons.vpn_key_outlined;
        break;
      case 'notinstalled':
      case 'not_installed':
        badgeColor = AppColors.error;
        label = 'Shizuku: Not Installed';
        icon = Icons.error_outline;
        break;
      default:
        badgeColor = AppColors.textMuted;
        label = 'Shizuku: Checking';
        icon = Icons.sync;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badgeColor.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: badgeColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
