import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/call_record.dart';
import '../../providers/player_provider.dart';
import '../../providers/call_records_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../core/formatters.dart';
import '../../widgets/glass_card.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// # PlayerScreen
/// 
/// Full playback details dashboard for a single CallRecord.
/// 
/// ## Features
/// - Monospace details, waveform positioning.
/// - Adjustable speed controller.
/// - SQLite Notes editing fields.
/// - Embedded OpenStreetMap miniature map panel if GPS coordinates are resolved.
class PlayerScreen extends ConsumerStatefulWidget {
  final CallRecord record;

  const PlayerScreen({
    super.key,
    required this.record,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.record.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    await ref.read(callRecordsProvider.notifier).updateNotes(
          widget.record,
          _notesController.text,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final isPlaying = playerState.isPlaying;
    
    final double progress = playerState.duration.inMilliseconds > 0
        ? playerState.position.inMilliseconds / playerState.duration.inMilliseconds
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Playback Details'),
        actions: [
          // Bookmark Toggle
          IconButton(
            icon: Icon(
              widget.record.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: widget.record.isBookmarked ? AppColors.accent : Colors.white,
            ),
            onPressed: () {
              ref.read(callRecordsProvider.notifier).toggleBookmark(widget.record);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Contact Header Card
            _buildContactHeaderCard(),
            const SizedBox(height: 24),

            // Playback controls & Progress
            _buildPlaybackControlsCard(playerState, isPlaying, progress),
            const SizedBox(height: 24),

            // Map Card (OSM)
            if (widget.record.latitude != null && widget.record.longitude != null) ...[
              _buildLocationMapCard(),
              const SizedBox(height: 24),
            ],

            // Notes Editor
            _buildNotesEditorCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildContactHeaderCard() {
    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary,
            child: Text(
              AppFormatters.getInitials(widget.record.contactName),
              style: AppTypography.displaySmall.copyWith(fontSize: 22, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.record.contactName,
                  style: AppTypography.headlineLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.record.phoneNumber != 'Unknown'
                      ? AppFormatters.formatPhoneNumber(widget.record.phoneNumber)
                      : 'Unknown Number',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.formatDateTime(widget.record.dateTime),
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControlsCard(PlayerStateData playerState, bool isPlaying, double progress) {
    return GlassCard(
      child: Column(
        children: [
          // Waveform representation / position bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppFormatters.formatDuration(playerState.position.inSeconds),
                style: AppTypography.labelMedium,
              ),
              Text(
                AppFormatters.formatDuration(playerState.duration.inSeconds),
                style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.divider,
              thumbColor: AppColors.primary,
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (val) {
                final int targetMs = (val * playerState.duration.inMilliseconds).toInt();
                ref.read(playerProvider.notifier).seek(Duration(milliseconds: targetMs));
              },
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Speed
              TextButton(
                onPressed: () {
                  final double cur = playerState.playbackSpeed;
                  double next = 1.0;
                  if (cur == 1.0) {
                    next = 1.5;
                  } else if (cur == 1.5) {
                    next = 2.0;
                  } else if (cur == 2.0) {
                    next = 0.8;
                  }
                  ref.read(playerProvider.notifier).setSpeed(next);
                },
                child: Text(
                  '${playerState.playbackSpeed}x',
                  style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 16),

              // Skip backward 10s
              IconButton(
                icon: const Icon(Icons.replay_10, size: 28, color: Colors.white),
                onPressed: () => ref.read(playerProvider.notifier).skip(-10),
              ),
              const SizedBox(width: 16),

              // Play / Pause
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 56,
                  color: AppColors.primary,
                ),
                onPressed: () => ref.read(playerProvider.notifier).togglePlay(),
              ),
              const SizedBox(width: 16),

              // Skip forward 10s
              IconButton(
                icon: const Icon(Icons.forward_10, size: 28, color: Colors.white),
                onPressed: () => ref.read(playerProvider.notifier).skip(10),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMapCard() {
    final LatLng position = LatLng(widget.record.latitude!, widget.record.longitude!);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Call Location',
            style: AppTypography.headlineSmall.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            widget.record.address ?? 'Bangladesh',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 12),
          
          // Free OpenStreetMap panel
          SizedBox(
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: position,
                  initialZoom: 14.5,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), // Disable scrolls on minipanel
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.shuni.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: position,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.accent,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesEditorCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notes & Annotations',
                style: AppTypography.headlineSmall.copyWith(color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.check, color: AppColors.primary),
                onPressed: _saveNotes,
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          TextField(
            controller: _notesController,
            maxLines: 4,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Add summary notes about this conversation...',
              fillColor: AppColors.surfaceLight.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}
