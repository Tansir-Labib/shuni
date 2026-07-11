import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/recording_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/call_record.dart';
import 'call_records_provider.dart';

/// # RecordingStateData
/// 
/// Holds state variables relating to active calls and Shizuku status.
class RecordingStateData {
  final RecordingState engineState;
  final bool isShizukuReady;
  final String shizukuStatusString;
  final String activeCallerName;
  final String activeCallerNumber;
  final int activeCallDuration;
  final String error;

  RecordingStateData({
    this.engineState = RecordingState.idle,
    this.isShizukuReady = false,
    this.shizukuStatusString = 'checking',
    this.activeCallerName = '',
    this.activeCallerNumber = '',
    this.activeCallDuration = 0,
    this.error = '',
  });

  RecordingStateData copyWith({
    RecordingState? engineState,
    bool? isShizukuReady,
    String? shizukuStatusString,
    String? activeCallerName,
    String? activeCallerNumber,
    int? activeCallDuration,
    String? error,
  }) {
    return RecordingStateData(
      engineState: engineState ?? this.engineState,
      isShizukuReady: isShizukuReady ?? this.isShizukuReady,
      shizukuStatusString: shizukuStatusString ?? this.shizukuStatusString,
      activeCallerName: activeCallerName ?? this.activeCallerName,
      activeCallerNumber: activeCallerNumber ?? this.activeCallerNumber,
      activeCallDuration: activeCallDuration ?? this.activeCallDuration,
      error: error ?? this.error,
    );
  }
}

/// # RecordingNotifier
/// 
/// Listens to native Android events and manages foreground call state changes.
class RecordingNotifier extends StateNotifier<RecordingStateData> {
  final Ref _ref;
  StreamSubscription<CallEvent>? _callEventSubscription;
  Timer? _callDurationTimer;

  RecordingNotifier(this._ref) : super(RecordingStateData()) {
    _init();
  }

  Future<void> _init() async {
    await checkShizukuStatus();
    _subscribeToNativeEvents();
  }

  /// Checks if Shizuku is ready and updates local status strings.
  Future<void> checkShizukuStatus() async {
    final bool ready = await RecordingService.instance.isShizukuReady();
    final Map<String, dynamic> detailed = await RecordingService.instance.getShizukuStatus();
    
    state = state.copyWith(
      isShizukuReady: ready,
      shizukuStatusString: detailed['status'] as String? ?? 'unknown',
    );
  }

  /// Triggers Shizuku permission request.
  Future<void> requestShizukuAccess() async {
    state = state.copyWith(shizukuStatusString: 'requesting');
    await RecordingService.instance.requestShizukuPermission();
    // Poll status after brief delay to catch change
    await Future.delayed(const Duration(milliseconds: 1500));
    await checkShizukuStatus();
  }

  /// Starts listening to the EventChannel stream from Android.
  void _subscribeToNativeEvents() {
    _callEventSubscription = RecordingService.instance.callEventStream.listen(
      (CallEvent event) async {
        switch (event.event) {
          case 'ringing':
          case 'answered':
          case 'recording_started':
            _startDurationTimer();
            state = state.copyWith(
              engineState: RecordingState.recording,
              activeCallerName: event.contactName,
              activeCallerNumber: event.phoneNumber,
            );
            break;
            
          case 'ended':
          case 'recording_stopped':
            _stopDurationTimer();
            
            // If we have a completed file, insert it into database
            if (event.audioPath != null && event.audioPath!.isNotEmpty) {
              await _saveRecordingToDatabase(event);
            }

            state = state.copyWith(
              engineState: RecordingState.idle,
              activeCallerName: '',
              activeCallerNumber: '',
              activeCallDuration: 0,
            );
            
            // Trigger list refresh
            _ref.read(callRecordsProvider.notifier).refreshRecords();
            break;
        }
      },
      onError: (err) {
        state = state.copyWith(error: err.toString());
      },
    );
  }

  /// Standard timer updating current recording duration.
  void _startDurationTimer() {
    _callDurationTimer?.cancel();
    state = state.copyWith(activeCallDuration: 0);
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(activeCallDuration: state.activeCallDuration + 1);
    });
  }

  void _stopDurationTimer() {
    _callDurationTimer?.cancel();
    _callDurationTimer = null;
  }

  /// Saves metadata to database after recording finishes.
  Future<void> _saveRecordingToDatabase(CallEvent event) async {
    try {
      final CallRecord record = CallRecord(
        phoneNumber: event.phoneNumber,
        contactName: event.contactName,
        dateTime: DateTime.now().subtract(Duration(seconds: event.durationSeconds)),
        durationSeconds: event.durationSeconds,
        direction: event.direction,
        audioFilePath: event.audioPath!,
        fileSizeBytes: event.fileSizeBytes ?? 0,
        // Location will be checked dynamically or updated
        isBookmarked: false,
      );

      await DatabaseService.instance.insertRecord(record);
      await StorageService.initializeDirectories(); // Update Nomedia files if needed
    } catch (_) {
      // Handle db save error
    }
  }

  @override
  void dispose() {
    _callEventSubscription?.cancel();
    _callDurationTimer?.cancel();
    super.dispose();
  }
}

// Global Provider declaration
final recordingProvider = StateNotifierProvider<RecordingNotifier, RecordingStateData>((ref) {
  return RecordingNotifier(ref);
});
