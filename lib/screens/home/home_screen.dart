import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/call_records_provider.dart';
import '../../providers/recording_provider.dart';
import '../../providers/player_provider.dart';
import '../../models/call_record.dart';
import '../../services/recording_service.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/animations.dart';
import '../../widgets/call_record_tile.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/recording_indicator.dart';
import '../../widgets/shizuku_status_badge.dart';
import '../../widgets/empty_state.dart';
import '../player/player_screen.dart';
import '../map/map_screen.dart';
import '../settings/settings_screen.dart';

/// # HomeScreen
/// 
/// The core dashboard of Shuni. Displays recording history, stats, search, and active states.
/// 
/// ## Visual Composition
/// - Header: Search bar + Shizuku active badge.
/// - Body: Staggered list of [CallRecordTile] cards.
/// - Bottom: Docked [MiniPlayer] + Navigation buttons.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordsState = ref.watch(callRecordsProvider);
    final recordingState = ref.watch(recordingProvider);
    
    final int recordCount = recordsState.records.length;
    final bool isRecording = recordingState.engineState == RecordingState.recording;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              Color(0xFF0C0C24),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header & Stats
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shuni',
                          style: AppTypography.displaySmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$recordCount recordings archived',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                    
                    // Shizuku & Recording Badges
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isRecording) ...[
                          const RecordingIndicator(),
                          const SizedBox(width: 8),
                        ],
                        ShizukuStatusBadge(
                          status: recordingState.shizukuStatusString,
                          onTap: () {
                            ref.read(recordingProvider.notifier).requestShizukuAccess();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(callRecordsProvider.notifier).setSearchQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search calls by name or number...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(callRecordsProvider.notifier).setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
              ),

              // Filter Chips
              _buildFilterChips(ref, recordsState),

              // Recording List
              Expanded(
                child: recordsState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : recordsState.records.isEmpty
                        ? EmptyState(
                            title: _searchController.text.isNotEmpty 
                                ? 'No results found' 
                                : 'No recordings yet',
                            description: _searchController.text.isNotEmpty
                                ? 'Try refining your search text parameters.'
                                : 'Recordings will automatically appear here when calls occur.',
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              await ref.read(callRecordsProvider.notifier).refreshRecords();
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: recordsState.records.length,
                              itemBuilder: (context, index) {
                                final record = recordsState.records[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: CallRecordTile(
                                    record: record,
                                    onTap: () {
                                      // Load and navigate to full player screen
                                      ref.read(playerProvider.notifier).loadRecord(record);
                                      Navigator.of(context).push(
                                        AppAnimations.slideUpRoute(
                                          PlayerScreen(record: record),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
              ),

              // Bottom control bar (Mini Player & Nav)
              const MiniPlayer(
                onTap: null, // Tap to expand handled dynamically
              ),

              // Navigation Bar
              _buildBottomNavigationBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(WidgetRef ref, CallRecordsState state) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // All chip
          FilterChip(
            label: const Text('All'),
            selected: state.directionFilter == null && state.isBookmarkedFilter == null,
            onSelected: (_) => ref.read(callRecordsProvider.notifier).clearFilters(),
          ),
          const SizedBox(width: 8),
          
          // Incoming chip
          FilterChip(
            label: const Text('Incoming'),
            selected: state.directionFilter == 'incoming',
            onSelected: (_) => ref.read(callRecordsProvider.notifier).setDirectionFilter(CallDirection.incoming),
          ),
          const SizedBox(width: 8),
          
          // Outgoing chip
          FilterChip(
            label: const Text('Outgoing'),
            selected: state.directionFilter == 'outgoing',
            onSelected: (_) => ref.read(callRecordsProvider.notifier).setDirectionFilter(CallDirection.outgoing),
          ),
          const SizedBox(width: 8),
          
          // Bookmarked chip
          FilterChip(
            label: const Text('Bookmarked'),
            selected: state.isBookmarkedFilter == true,
            onSelected: (_) => ref.read(callRecordsProvider.notifier).toggleBookmarkFilter(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.home, color: AppColors.primary),
            onPressed: () {}, // Already home
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.of(context).push(
                AppAnimations.slideUpRoute(const MapScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.of(context).push(
                AppAnimations.slideUpRoute(const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
