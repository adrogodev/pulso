import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../base_domain/models/track.dart';
import 'audio_player_service.dart';
import 'online_audio_cache.dart';

/// Implementación real del motor de audio mediante [just_audio].
class JustAudioPlayerService implements AudioPlayerService {
  final AudioPlayer _player;
  final OnlineAudioCache? onlineCache;
  List<Track> _currentTracks = [];
  StreamSubscription<void>? _noisySubscription;

  /// Si no se inyecta [player], se crea uno; con [equalizer] el audio pasa por
  /// su pipeline, de modo que el ecualizador afecta a toda la reproducción.
  /// Con [onlineCache], las pistas en línea se guardan y se repiten desde disco.
  JustAudioPlayerService({
    AudioPlayer? player,
    AndroidEqualizer? equalizer,
    this.onlineCache,
  }) : _player =
           player ??
           AudioPlayer(
             audioPipeline: equalizer == null
                 ? null
                 : AudioPipeline(androidAudioEffects: [equalizer]),
           ) {
    unawaited(_initAudioSession());
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      _noisySubscription = session.becomingNoisyEventStream.listen((_) {
        pause();
      });
    } catch (e) {
      debugPrint('Error configurando AudioSession: $e');
    }
  }

  @override
  Stream<AppPlayerStatus> get statusStream {
    return _player.playerStateStream.map((state) {
      if (state.processingState == ProcessingState.idle) {
        return AppPlayerStatus.idle;
      } else if (state.processingState == ProcessingState.loading) {
        return AppPlayerStatus.loading;
      } else if (state.processingState == ProcessingState.buffering) {
        return AppPlayerStatus.buffering;
      } else if (state.processingState == ProcessingState.completed) {
        return AppPlayerStatus.completed;
      } else if (state.playing) {
        return AppPlayerStatus.playing;
      } else {
        return AppPlayerStatus.paused;
      }
    });
  }

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  @override
  Stream<bool> get shuffleModeStream => _player.shuffleModeEnabledStream;

  @override
  Stream<AppLoopMode> get loopModeStream {
    return _player.loopModeStream.map(
      (mode) => switch (mode) {
        LoopMode.off => AppLoopMode.off,
        LoopMode.one => AppLoopMode.one,
        LoopMode.all => AppLoopMode.all,
      },
    );
  }

  @override
  Stream<double> get volumeStream => _player.volumeStream;

  @override
  Future<void> setQueue(List<Track> tracks, {int initialIndex = 0}) async {
    _currentTracks = List.unmodifiable(tracks);
    if (tracks.isEmpty) {
      await _player.stop();
      return;
    }

    final safeIndex = (initialIndex >= 0 && initialIndex < tracks.length)
        ? initialIndex
        : 0;

    final audioSources = <AudioSource>[];
    for (final track in tracks) {
      final tag = MediaItem(
        id: track.id,
        title: track.title,
        artist: track.artist,
        album: track.album,
        duration: track.duration,
        artUri: track.artworkUrl != null
            ? Uri.tryParse(track.artworkUrl!)
            : null,
      );
      final cache = onlineCache;
      audioSources.add(
        cache != null
            ? await cache.audioSourceFor(track, tag: tag)
            : _uriSource(track, tag),
      );
    }

    try {
      await _player.setAudioSources(
        audioSources,
        initialIndex: safeIndex,
        initialPosition: Duration.zero,
      );
      // Mantiene la caché acotada sin demorar el inicio de la reproducción.
      final cache = onlineCache;
      if (cache != null) unawaited(cache.trim());
    } catch (e, st) {
      debugPrint('Error al cargar la cola en JustAudio: $e\n$st');
      rethrow;
    }
  }

  static AudioSource _uriSource(Track track, MediaItem tag) {
    final uri =
        track.uri.startsWith('content://') ||
            track.uri.startsWith('file://') ||
            track.uri.startsWith('http')
        ? Uri.parse(track.uri)
        : Uri.file(track.uri);
    return AudioSource.uri(uri, tag: tag);
  }

  @override
  Future<void> play() async {
    try {
      await _player.play();
    } catch (e) {
      debugPrint('Error al reproducir: $e');
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_currentTracks.isNotEmpty) {
      // Si la cola llegó al final y no hay repetición, vuelve al primer elemento
      await _player.seek(Duration.zero, index: 0);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  @override
  Future<void> skipToIndex(int index) async {
    if (index >= 0 && index < _currentTracks.length) {
      await _player.seek(Duration.zero, index: index);
    }
  }

  @override
  Future<void> setShuffleMode(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
  }

  @override
  Future<void> setLoopMode(AppLoopMode mode) async {
    final justAudioMode = switch (mode) {
      AppLoopMode.off => LoopMode.off,
      AppLoopMode.one => LoopMode.one,
      AppLoopMode.all => LoopMode.all,
    };
    await _player.setLoopMode(justAudioMode);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    await _noisySubscription?.cancel();
    await _player.dispose();
  }
}
