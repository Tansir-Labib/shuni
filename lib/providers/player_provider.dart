import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/call_record.dart';

/// # PlayerStateData
/// 
/// holds details about the active playing call record, playing states, speed, and time positions.
class PlayerStateData {
  final CallRecord? activeRecord;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double playbackSpeed;
  final String error;

  PlayerStateData({
    this.activeRecord,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playbackSpeed = 1.0,
    this.error = '',
  });

  PlayerStateData copyWith({
    CallRecord? activeRecord,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? playbackSpeed,
    String? error,
  }) {
    return PlayerStateData(
      activeRecord: activeRecord ?? this.activeRecord,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      error: error ?? this.error,
    );
  }
}

/// # PlayerNotifier
/// 
/// State notifier wrapping the `just_audio` player engine.
class PlayerNotifier extends StateNotifier<PlayerStateData> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  PlayerNotifier() : super(PlayerStateData()) {
    _initListeners();
  }

  void _initListeners() {
    // 1. Listen to playing/completed state
    _audioPlayer.playerStateStream.listen((playerState) {
      final bool playing = playerState.playing;
      final ProcessingState processing = playerState.processingState;
      
      if (processing == ProcessingState.completed) {
        state = state.copyWith(isPlaying: false, position: Duration.zero);
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
      } else {
        state = state.copyWith(isPlaying: playing);
      }
    });

    // 2. Listen to position changes
    _audioPlayer.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });

    // 3. Listen to duration changes
    _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        state = state.copyWith(duration: dur);
      }
    });
  }

  /// Sets the active call record for playback and preloads the audio source.
  Future<void> loadRecord(CallRecord record) async {
    if (state.activeRecord?.id == record.id) return;
    
    try {
      await _audioPlayer.stop();
      state = state.copyWith(
        activeRecord: record,
        position: Duration.zero,
        duration: Duration.zero,
      );

      final dur = await _audioPlayer.setFilePath(record.audioFilePath);
      state = state.copyWith(duration: dur ?? Duration.zero);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load audio: ${e.toString()}');
    }
  }

  /// Toggles play / pause state.
  Future<void> togglePlay() async {
    if (state.activeRecord == null) return;
    
    if (state.isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  /// Seeks to a specific timestamp in the audio track.
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Changes playback speed (e.g. 1.0x, 1.5x, 2.0x).
  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
    state = state.copyWith(playbackSpeed: speed);
  }

  /// Skips ahead or backward by [seconds].
  Future<void> skip(int seconds) async {
    final int target = state.position.inSeconds + seconds;
    final int total = state.duration.inSeconds;
    
    if (target < 0) {
      await seek(Duration.zero);
    } else if (target > total) {
      await seek(state.duration);
    } else {
      await seek(Duration(seconds: target));
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

// Global Provider declaration
final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerStateData>((ref) {
  return PlayerNotifier();
});
