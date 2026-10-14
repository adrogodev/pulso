import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/audio_player_service.dart';
import '../../../../core/audio/just_audio_player_service.dart';
import '../../../../entities/track/track.dart';
import 'playback_state.dart';

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = JustAudioPlayerService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final playbackNotifierProvider =
    NotifierProvider<PlaybackNotifier, PlaybackState>(PlaybackNotifier.new);

class PlaybackNotifier extends Notifier<PlaybackState> {
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  AudioPlayerService get _audioService => ref.read(audioPlayerServiceProvider);

  @override
  PlaybackState build() {
    ref.onDispose(() {
      for (final sub in _subscriptions) {
        sub.cancel();
      }
      _subscriptions.clear();
    });

    _initListeners();
    return const PlaybackState();
  }

  void _initListeners() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    _subscriptions.add(
      _audioService.statusStream.listen((status) {
        state = state.copyWith(status: status);
      }),
    );

    _subscriptions.add(
      _audioService.positionStream.listen((position) {
        state = state.copyWith(position: position);
      }),
    );

    _subscriptions.add(
      _audioService.durationStream.listen((duration) {
        if (duration != null) {
          state = state.copyWith(duration: duration);
        }
      }),
    );

    _subscriptions.add(
      _audioService.currentIndexStream.listen((index) {
        if (index != null && index >= 0 && index < state.queue.length) {
          final current = state.queue[index];
          state = state.copyWith(
            currentIndex: index,
            currentTrack: current,
            duration: current.duration,
          );
        }
      }),
    );

    _subscriptions.add(
      _audioService.loopModeStream.listen((mode) {
        state = state.copyWith(loopMode: mode);
      }),
    );

    _subscriptions.add(
      _audioService.shuffleModeStream.listen((enabled) {
        state = state.copyWith(isShuffleEnabled: enabled);
      }),
    );

    _subscriptions.add(
      _audioService.volumeStream.listen((vol) {
        state = state.copyWith(volume: vol);
      }),
    );
  }

  Future<void> playTrack(Track track, {List<Track>? inQueue}) async {
    final queue = (inQueue != null && inQueue.isNotEmpty) ? inQueue : [track];

    final index = queue.indexWhere((t) => t.id == track.id);
    final targetIndex = index >= 0 ? index : 0;

    state = state.copyWith(
      queue: queue,
      currentIndex: targetIndex,
      currentTrack: track,
      duration: track.duration,
      position: Duration.zero,
      status: AppPlayerStatus.loading,
      clearError: true,
    );

    try {
      await _audioService.setQueue(queue, initialIndex: targetIndex);
      await _audioService.play();
    } catch (e) {
      state = state.copyWith(
        status: AppPlayerStatus.error,
        errorMessage: 'No se pudo reproducir: ${track.title}',
      );
    }
  }

  Future<void> play() async {
    await _audioService.play();
  }

  Future<void> pause() async {
    await _audioService.pause();
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  Future<void> skipToNext() async {
    await _audioService.skipToNext();
  }

  Future<void> skipToPrevious() async {
    await _audioService.skipToPrevious();
  }

  Future<void> skipToIndex(int index) async {
    await _audioService.skipToIndex(index);
  }

  Future<void> toggleShuffle() async {
    final next = !state.isShuffleEnabled;
    await _audioService.setShuffleMode(next);
  }

  Future<void> cycleLoopMode() async {
    final next = switch (state.loopMode) {
      AppLoopMode.off => AppLoopMode.all,
      AppLoopMode.all => AppLoopMode.one,
      AppLoopMode.one => AppLoopMode.off,
    };
    await _audioService.setLoopMode(next);
  }

  Future<void> setVolume(double volume) async {
    await _audioService.setVolume(volume);
  }
}
