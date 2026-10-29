import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/shared/base_data/audio/audio_player_service.dart';
import 'package:pulso/shared/base_domain/models/track.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_notifier.dart';
import 'package:pulso/features/settings/domain/services/settings_repository.dart';
import 'package:pulso/features/settings/presentation/controllers/settings_notifier.dart';

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

    group('última sesión', () {
      SettingsRepository settingsRepo() =>
          container.read(settingsRepositoryProvider);

      test('guarda la pista actual y su posición', () async {
        final notifier = container.read(playbackNotifierProvider.notifier);
        await notifier.playTrack(trackB, inQueue: [trackA, trackB]);
        await notifier.seek(const Duration(seconds: 42));
        await Future<void>.delayed(Duration.zero);

        await notifier.saveSession();

        final saved = (await settingsRepo().getLastSession()).dataOrNull;
        expect(saved, {'trackId': '2', 'positionMs': 42000});
      });

      test(
        'no guarda las pistas en línea, que no se pueden restaurar',
        () async {
          const online = Track(
            id: 'audius:abc',
            title: 'Remota',
            artist: 'A',
            album: 'Audius',
            durationMs: 1000,
            uri: 'https://api.audius.co/v1/tracks/abc/stream?app_name=pulso',
          );
          final notifier = container.read(playbackNotifierProvider.notifier);
          await notifier.playTrack(online);

          await notifier.saveSession();

          expect((await settingsRepo().getLastSession()).dataOrNull, isNull);
        },
      );

      test(
        'restaura la pista pausada en su posición con la biblioteca como cola',
        () async {
          await settingsRepo().saveLastSession('2', 42000);
          final notifier = container.read(playbackNotifierProvider.notifier);

          await notifier.restoreSession([trackA, trackB]);

          final state = container.read(playbackNotifierProvider);
          expect(state.currentTrack, trackB);
          expect(state.queue, [trackA, trackB]);
          expect(state.currentIndex, 1);
          expect(state.position, const Duration(seconds: 42));
          expect(mockAudioService.queue, [trackA, trackB]);
          expect(mockAudioService.currentIndex, 1);
          expect(mockAudioService.isPlaying, isFalse);
        },
      );

      test('no restaura cuando la preferencia está desactivada', () async {
        await settingsRepo().saveLastSession('2', 42000);
        await settingsRepo().setPreference('restore_last_session', 'false');
        final notifier = container.read(playbackNotifierProvider.notifier);

        await notifier.restoreSession([trackA, trackB]);

        expect(container.read(playbackNotifierProvider).currentTrack, isNull);
        expect(mockAudioService.queue, isEmpty);
      });

      test(
        'ignora una sesión cuya pista ya no está en la biblioteca',
        () async {
          await settingsRepo().saveLastSession('borrada', 1000);
          final notifier = container.read(playbackNotifierProvider.notifier);

          await notifier.restoreSession([trackA, trackB]);

          expect(container.read(playbackNotifierProvider).currentTrack, isNull);
        },
      );

      test('no pisa una reproducción que ya empezó', () async {
        await settingsRepo().saveLastSession('2', 42000);
        final notifier = container.read(playbackNotifierProvider.notifier);
        await notifier.playTrack(trackA, inQueue: [trackA]);

        await notifier.restoreSession([trackA, trackB]);

        expect(container.read(playbackNotifierProvider).currentTrack, trackA);
      });
    });
  });
}
