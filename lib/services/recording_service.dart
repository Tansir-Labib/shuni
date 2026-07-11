import 'dart:async';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../models/call_record.dart';

/// # RecordingState
/// 
/// Represents the running status of the recording engine.
enum RecordingState {
  idle,
  recording;

  static RecordingState fromJson(String value) {
    return values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RecordingState.idle,
    );
  }
}

/// # CallEvent
/// 
/// Data class representing call status changes broadcasted from native Android code.
class CallEvent {
  final String event; // 'ringing', 'answered', 'ended', 'recording_started', 'recording_stopped'
  final String phoneNumber;
  final String contactName;
  final CallDirection direction;
  final int durationSeconds;
  final String? audioPath;
  final int? fileSizeBytes;

  CallEvent({
    required this.event,
    required this.phoneNumber,
    required this.contactName,
    required this.direction,
    required this.durationSeconds,
    this.audioPath,
    this.fileSizeBytes,
  });

  factory CallEvent.fromMap(Map<dynamic, dynamic> map) {
    return CallEvent(
      event: map['event'] as String? ?? 'ended',
      phoneNumber: map['phone_number'] as String? ?? 'Unknown',
      contactName: map['contact_name'] as String? ?? 'Unknown',
      direction: CallDirection.fromJson(map['direction'] as String? ?? 'incoming'),
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      audioPath: map['audio_path'] as String?,
      fileSizeBytes: map['file_size_bytes'] as int?,
    );
  }
}

/// # RecordingService
/// 
/// Serves as the primary bridge between Flutter (Dart) and Android (Kotlin) call recording APIs
/// using Platform Channels.
/// 
/// ## Learning Note
/// Platform Channels allow Dart to execute native Kotlin/Java code on Android.
/// - **MethodChannel**: Used for one-shot, request-response calls (e.g. `startRecording()`).
/// - **EventChannel**: Used for subscribing to continuous streams of data from native code
///   (e.g. listening to active phone state triggers).
class RecordingService {
  // Singleton pattern
  static final RecordingService instance = RecordingService._internal();
  RecordingService._internal();

  static const MethodChannel _methodChannel = MethodChannel(AppConstants.methodChannelName);
  static const EventChannel _eventChannel = EventChannel(AppConstants.eventChannelName);

  Stream<CallEvent>? _eventStream;

  /// Returns a stream of active call events from Android (e.g. call rings, connects, ends).
  Stream<CallEvent> get callEventStream {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((dynamic data) => CallEvent.fromMap(data as Map<dynamic, dynamic>));
    return _eventStream!;
  }

  /// Queries whether the Shizuku background service is up, running, and authorized.
  Future<bool> isShizukuReady() async {
    try {
      final bool ready = await _methodChannel.invokeMethod<bool>('isShizukuReady') ?? false;
      return ready;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Triggers a request to authorize Shizuku shell bindings.
  Future<bool> requestShizukuPermission() async {
    try {
      final bool success = await _methodChannel.invokeMethod<bool>('requestShizukuPermission') ?? false;
      return success;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Checks the current state of Shizuku (Ready, NotInstalled, NotRunning, NoPermission).
  Future<Map<String, dynamic>> getShizukuStatus() async {
    try {
      final Map<dynamic, dynamic>? status = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('getShizukuStatus');
      return Map<String, dynamic>.from(status ?? {});
    } on PlatformException catch (e) {
      return {'status': 'error', 'message': e.message};
    }
  }

  /// Manually triggers recording start (for outgoing or VoIP call testing).
  Future<void> startRecording({
    required String phoneNumber,
    required String contactName,
    required CallDirection direction,
  }) async {
    try {
      await _methodChannel.invokeMethod('startRecording', {
        'phone_number': phoneNumber,
        'contact_name': contactName,
        'direction': direction.toJson(),
      });
    } on PlatformException catch (_) {
      // Handle native bridge error
    }
  }

  /// Manually stops the active recording.
  /// Returns a map with {'audio_path': String, 'duration_seconds': int, 'file_size_bytes': int}.
  Future<Map<String, dynamic>?> stopRecording() async {
    try {
      final Map<dynamic, dynamic>? result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('stopRecording');
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (_) {
      return null;
    }
  }

  /// Queries the active status of the recording engine.
  Future<RecordingState> getRecordingState() async {
    try {
      final String stateStr = await _methodChannel.invokeMethod<String>('getRecordingState') ?? 'idle';
      return RecordingState.fromJson(stateStr);
    } on PlatformException catch (_) {
      return RecordingState.idle;
    }
  }

  /// Updates the native service's auto-record configuration.
  Future<void> setAutoRecord(bool enabled) async {
    try {
      await _methodChannel.invokeMethod('setAutoRecord', {
        'enabled': enabled,
      });
    } on PlatformException catch (_) {
      // Error
    }
  }
}
