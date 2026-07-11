import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/call_record.dart';
import '../core/formatters.dart';
import '../core/extensions.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../providers/player_provider.dart';
import '../providers/call_records_provider.dart';
import 'glass_card.dart';

/// # CallRecordTile
/// 
/// Represents a single recording item card drawn inside the list.
/// 
/// ## Visual Features
/// - Frosted glass card design.
/// - Initials-based avatar colored dynamically by contact name hash.
/// - Bookmark button to flag recordings.
/// - Swipe-to-delete action template.
/// - Triggers audio player stream on card tap.
class CallRecordTile extends ConsumerWidget {
  final CallRecord record;
  final VoidCallback? onTap;

  const CallRecordTile({
    super.key,
    required this.record,
    this.onTap,
  });

  /// Generates a consistent background color for the avatar by hashing the contact's name.
  Color _getAvatarColor(String name) {
    if (name.isEmpty || name == 'Unknown') return AppColors.textMuted;
    
    final int hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    final List<Color> colors = [
      AppColors.primary,
      AppColors.accent,
      const Color(0xFF10AC84), // Emerald
      const Color(0xFF2E86DE), // Blue
      const Color(0xFFF368E0), // Pink
      const Color(0xFFFF9F43), // Amber
    ];
    
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final isCurrent = playerState.activeRecord?.id == record.id;
    final isPlaying = isCurrent && playerState.isPlaying;

    return Dismissible(
      key: Key('record_${record.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_sweep, color: AppColors.error, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Recording?'),
            content: Text('Are you sure you want to delete the recording for "${record.contactName}"? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await ref.read(callRecordsProvider.notifier).deleteRecord(record);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording deleted successfully')),
        );
      },
      child: GlassCard(
        onTap: onTap,
        color: isCurrent 
            ? AppColors.primary.withOpacity(0.08) 
            : AppColors.surface.withOpacity(0.85),
        border: isCurrent 
            ? BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1)
            : BorderSide(color: AppColors.cardBorder, width: 1),
        child: Row(
          children: [
            // Colored Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: _getAvatarColor(record.contactName),
              child: Text(
                AppFormatters.getInitials(record.contactName),
                style: AppTypography.titleLarge.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            
            // Call Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Direction Icon
                      Icon(
                        record.direction == CallDirection.incoming
                            ? Icons.call_received
                            : Icons.call_made,
                        size: 14,
                        color: record.direction == CallDirection.incoming
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          record.contactName,
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.phoneNumber != 'Unknown' 
                        ? AppFormatters.formatPhoneNumber(record.phoneNumber)
                        : 'Unknown Number',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.dateTime.timeAgo(),
                    style: AppTypography.labelSmall,
                  ),
                ],
              ),
            ),
            
            // Player controls + Bookmark
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Call Duration
                Text(
                  AppFormatters.formatDuration(record.durationSeconds),
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),

                // Bookmark Toggle
                IconButton(
                  icon: Icon(
                    record.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: record.isBookmarked ? AppColors.accent : AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () {
                    ref.read(callRecordsProvider.notifier).toggleBookmark(record);
                  },
                ),
                
                // Play Button
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  onPressed: () async {
                    final playerNotifier = ref.read(playerProvider.notifier);
                    await playerNotifier.loadRecord(record);
                    await playerNotifier.togglePlay();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
