import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../core/formatters.dart';
import 'glass_card.dart';

/// # MiniPlayer
/// 
/// A floating, docked mini player control bar that automatically displays at the bottom
/// of the screen if a track is active.
/// 
/// ## Features
/// - Frosted glass background layout.
/// - Linear progress indicator bar.
/// - Inline Play/Pause control toggle.
/// - Close button to stop playback.
/// - Direct tap navigates to full player interface.
class MiniPlayer extends ConsumerWidget {
  final VoidCallback? onTap;

  const MiniPlayer({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final activeRecord = playerState.activeRecord;

    if (activeRecord == null) return const SizedBox.shrink();

    final double progress = playerState.duration.inMilliseconds > 0
        ? playerState.position.inMilliseconds / playerState.duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GlassCard(
          padding: EdgeInsets.zero, // Zero padding for alignment
          color: AppColors.surface.withOpacity(0.95),
          border: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 1.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress Bar
              SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Visual playing animation or speaker icon
                    Icon(
                      playerState.isPlaying ? Icons.volume_up : Icons.volume_mute,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    
                    // Track Title/Contact Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeRecord.contactName,
                            style: AppTypography.titleMedium.copyWith(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${AppFormatters.formatDuration(playerState.position.inSeconds)} / ${AppFormatters.formatDuration(playerState.duration.inSeconds)}',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    
                    // Play / Pause Control
                    IconButton(
                      icon: Icon(
                        playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        ref.read(playerProvider.notifier).togglePlay();
                      },
                    ),
                    
                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                      onPressed: () {
                        // For closing, we stop player and release record
                        ref.read(playerProvider.notifier).seek(Duration.zero);
                        ref.read(playerProvider.notifier).togglePlay(); // Pause
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
