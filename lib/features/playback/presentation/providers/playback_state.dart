import 'package:flutter/foundation.dart';

import '../../../../core/audio/audio_player_service.dart';
import '../../../../entities/track/track.dart';

/// Estado inmutable de la reproducción actual en Pulso.
@immutable
class PlaybackState {
  final Track? currentTrack;
  final List<Track> queue;
  final int currentIndex;
  final AppPlayerStatus status;
  final Duration position;
  final Duration duration;
  final AppLoopMode loopMode;
  final bool isShuffleEnabled;
  final double volume;
  final String? errorMessage;

  const PlaybackState({
    this.currentTrack,
    this.queue = const [],
    this.currentIndex = 0,
    this.status = AppPlayerStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.loopMode = AppLoopMode.off,
    this.isShuffleEnabled = false,
    this.volume = 1.0,
    this.errorMessage,
  });

  bool get isPlaying => status == AppPlayerStatus.playing;
  bool get isBuffering =>
      status == AppPlayerStatus.buffering || status == AppPlayerStatus.loading;
  bool get hasTrack => currentTrack != null;

  double get progress {
    if (duration.inMilliseconds <= 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  PlaybackState copyWith({
    Track? currentTrack,
    bool clearCurrentTrack = false,
    List<Track>? queue,
    int? currentIndex,
    AppPlayerStatus? status,
    Duration? position,
    Duration? duration,
    AppLoopMode? loopMode,
    bool? isShuffleEnabled,
    double? volume,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlaybackState(
      currentTrack: clearCurrentTrack
          ? null
          : (currentTrack ?? this.currentTrack),
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      loopMode: loopMode ?? this.loopMode,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      volume: volume ?? this.volume,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
