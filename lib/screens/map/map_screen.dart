import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/extensions.dart';
import '../../models/call_record.dart';
import '../../providers/call_records_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/animations.dart';
import '../player/player_screen.dart';
import '../../widgets/glass_card.dart';

/// # MapScreen
/// 
/// Displays call locations on a full-screen OpenStreetMap interface.
/// 
/// ## Features
/// - Pinpoints call origins using database coordinates.
/// - Tapping a marker displays a summary bottom sheet.
/// - Live blue dot mapping using [flutter_map_location_marker].
/// - FAB to quickly center the camera on the user's real-time physical location.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _centerOnCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
    } catch (e) {
      // Permission denied or location disabled
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot access location. Please check permissions.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordsState = ref.watch(callRecordsProvider);

    // Filter out records that do not contain coordinates
    final List<CallRecord> mappedRecords = recordsState.records
        .where((r) => r.latitude != null && r.longitude != null)
        .toList();

    // Default center to Dhaka or the first recorded coordinate
    final LatLng initialCenter = mappedRecords.isNotEmpty
        ? LatLng(mappedRecords.first.latitude!, mappedRecords.first.longitude!)
        : const LatLng(23.8103, 90.4125); // Default Dhaka coordinate

    final List<Marker> markers = mappedRecords.map((record) {
      return Marker(
        point: LatLng(record.latitude!, record.longitude!),
        width: 48,
        height: 48,
        child: GestureDetector(
          onTap: () => _showRecordDetailsBottomSheet(context, record),
          child: const Icon(
            Icons.location_on,
            color: AppColors.accent,
            size: 38,
          ),
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Location Logs'),
      ),
      body: Stack(
        children: [
          // Full Screen Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.shuni.app',
              ),
              MarkerLayer(
                markers: markers,
              ),
              // Live Location Blue Dot Layer
              CurrentLocationLayer(
                alignPositionOnUpdate: AlignOnUpdate.never,
                alignDirectionOnUpdate: AlignOnUpdate.never,
                style: const LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    color: Colors.blue,
                  ),
                  markerSize: Size(20, 20),
                  markerDirection: MarkerDirection.heading,
                ),
              ),
            ],
          ),

          // Floating Hint overlay
          if (mappedRecords.isEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: GlassCard(
                color: AppColors.background.withOpacity(0.9),
                child: Text(
                  'No location logs captured yet. Call coordinates appear automatically when GPS is enabled during calls.',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnCurrentLocation,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  void _showRecordDetailsBottomSheet(BuildContext context, CallRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          child: GlassCard(
            color: AppColors.surface.withOpacity(0.95),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        record.contactName.toInitials(),
                        style: AppTypography.titleSmall.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.contactName,
                            style: AppTypography.titleMedium.copyWith(color: Colors.white),
                          ),
                          Text(
                            record.dateTime.timeAgo(),
                            style: AppTypography.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 18),
                      onPressed: () {
                        Navigator.pop(context); // Close bottom sheet
                        Navigator.of(context).push(
                          AppAnimations.slideUpRoute(PlayerScreen(record: record)),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Location Details Row
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        record.address ?? 'Bangladesh',
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
