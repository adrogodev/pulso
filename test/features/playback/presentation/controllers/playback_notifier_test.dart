import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/shared/base_data/audio/audio_player_service.dart';
import 'package:pulso/shared/base_domain/models/track.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_notifier.dart';

class MockAudioPlayerService implements AudioPlayerService {
  final _statusController = StreamController<AppPlayerStatus>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _currentIndexController = StreamController<int?>.broadcast();
  final _shuffleController = StreamController<bool>.broadcast();
  final _loopController = StreamController<AppLoopMode>.broadcast();
  final _volumeController = StreamController<double>.broadcast();

  bool isPlaying = false;
  bool isShuffle = false;
  AppLoopMode loopMode = AppLoopMode.off;
  int currentIndex = 0;
  List<Track> queue = [];

  @override
  Stream<AppPlayerStatus> get statusStream => _statusController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Stream<int?> get currentIndexStream => _currentIndexController.stream;

  @override
  Stream<bool> get shuffleModeStream => _shuffleController.stream;

  @override
  Stream<AppLoopMode> get loopModeStream => _loopController.stream;

  @override
  Stream<double> get volumeStream => _volumeController.stream;

  @override
  Future<void> setQueue(List<Track> tracks, {int initialIndex = 0}) async {
    queue = List.from(tracks);
    currentIndex = initialIndex;
    _currentIndexController.add(initialIndex);
  }

  @override
  Future<void> play() async {
    isPlaying = true;
    _statusController.add(AppPlayerStatus.playing);
  }

  @override
  Future<void> pause() async {
    isPlaying = false;
    _statusController.add(AppPlayerStatus.paused);
  }

  @override
  Future<void> seek(Duration position) async {
    _positionController.add(position);
  }

  @override
  Future<void> skipToNext() async {
    if (currentIndex + 1 < queue.length) {
      currentIndex++;
      _currentIndexController.add(currentIndex);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (currentIndex > 0) {
      currentIndex--;
      _currentIndexController.add(currentIndex);
    }
  }

  @override
  Future<void> skipToIndex(int index) async {
    currentIndex = index;
    _currentIndexController.add(index);
  }

  @override
  Future<void> setShuffleMode(bool enabled) async {
    isShuffle = enabled;
    _shuffleController.add(enabled);
  }

  @override
  Future<void> setLoopMode(AppLoopMode mode) async {
    loopMode = mode;
    _loopController.add(mode);
  }

  @override
  Future<void> setVolume(double volume) async {
    _volumeController.add(volume);
  }

  @override
  Future<void> stop() async {
    _statusController.add(AppPlayerStatus.idle);
  }

  @override
  Future<void> dispose() async {
    await _statusController.close();
    await _positionController.close();
    await _durationController.close();
    await _currentIndexController.close();
    await _shuffleController.close();
    await _loopController.close();
    await _volumeController.close();
  }
}

void main() {
  group('PlaybackNotifier', () {
    late MockAudioPlayerService mockAudioService;
    late ProviderContainer container;

    const trackA = Track(
      id: '1',
      title: 'Pista Alfa',
      artist: 'Artista 1',
      album: 'Álbum 1',
      durationMs: 180000,
      uri: 'uri/alfa',
    );
    const trackB = Track(
      id: '2',
      title: 'Pista Beta',
      artist: 'Artista 2',
      album: 'Álbum 2',
      durationMs: 240000,
      uri: 'uri/beta',
    );

    setUp(() {
      mockAudioService = MockAudioPlayerService();
      container = ProviderContainer(
        overrides: [
          audioPlayerServiceProvider.overrideWithValue(mockAudioService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      mockAudioService.dispose();
    });

    test('reproduce una pista y actualiza la cola en PlaybackState', () async {
      final notifier = container.read(playbackNotifierProvider.notifier);

      await notifier.playTrack(trackA, inQueue: [trackA, trackB]);

      final state = container.read(playbackNotifierProvider);
      expect(state.currentTrack?.title, 'Pista Alfa');
      expect(state.queue.length, 2);
      expect(state.currentIndex, 0);
    });

    test('alterna reproducción y pausa', () async {
      final notifier = container.read(playbackNotifierProvider.notifier);
      await notifier.playTrack(trackA);

      await notifier.play();
      expect(mockAudioService.isPlaying, isTrue);

      await notifier.pause();
      expect(mockAudioService.isPlaying, isFalse);
    });

    test('cicla los modos de repetición off -> all -> one -> off', () async {
      final notifier = container.read(playbackNotifierProvider.notifier);

      await notifier.cycleLoopMode();
      expect(mockAudioService.loopMode, AppLoopMode.all);

      await notifier.cycleLoopMode();
      expect(mockAudioService.loopMode, AppLoopMode.one);

      await notifier.cycleLoopMode();
      expect(mockAudioService.loopMode, AppLoopMode.off);
    });

    test('activa y desactiva el modo aleatorio', () async {
      final notifier = container.read(playbackNotifierProvider.notifier);

      await notifier.toggleShuffle();
      expect(mockAudioService.isShuffle, isTrue);

      await notifier.toggleShuffle();
      expect(mockAudioService.isShuffle, isFalse);
    });

    test('reordena elementos de la cola adecuadamente', () async {
      final notifier = container.read(playbackNotifierProvider.notifier);
      await notifier.playTrack(trackA, inQueue: [trackA, trackB]);

      // Mover trackA al final (índice 0 a índice 2)
      await notifier.reorderQueue(0, 2);

      final state = container.read(playbackNotifierProvider);
      expect(state.queue.map((t) => t.title), ['Pista Beta', 'Pista Alfa']);
      expect(state.currentIndex, 1);
    });

    test('elimina una pista de la cola y actualiza el estado', () async {
      final notifier = container.read(playbackNotifierProvider.notifier);
      await notifier.playTrack(trackA, inQueue: [trackA, trackB]);

      // Eliminar la segunda pista
      await notifier.removeFromQueue(1);

      final state = container.read(playbackNotifierProvider);
      expect(state.queue.length, 1);
      expect(state.queue.first.title, 'Pista Alfa');
    });

    test('vacía la cola y detiene el reproductor', () async {
      final notifier = container.read(playbackNotifierProvider.notifier);
      await notifier.playTrack(trackA, inQueue: [trackA, trackB]);

      await notifier.clearQueue();

      final state = container.read(playbackNotifierProvider);
      expect(state.queue, isEmpty);
      expect(state.currentTrack, isNull);
    });
  });
}
