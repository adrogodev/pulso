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
  AppLoopMode _appLoopMode = AppLoopMode.off;
  final _loopModeController = StreamController<AppLoopMode>.broadcast();
  final List<StreamSubscription<dynamic>> _repeatSubscriptions = [];

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
    _repeatCurrentTrack();
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

  /// Modo de repetición de la app; ver [setLoopMode].
  @override
  Stream<AppLoopMode> get loopModeStream => _loopModeController.stream;

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

  /// "Repetir uno" no usa LoopMode.one de just_audio: con ese modo el
  /// reproductor considera que la siguiente y la anterior son la misma pista,
  /// y los botones (de la app, la notificación y los auriculares) no avanzan.
  /// El reproductor queda sin repetición y [_repeatCurrentTrack] vuelve a
  /// poner la pista cuando termina sola.
  @override
  Future<void> setLoopMode(AppLoopMode mode) async {
    _appLoopMode = mode;
    await _player.setLoopMode(
      mode == AppLoopMode.all ? LoopMode.all : LoopMode.off,
    );
    _loopModeController.add(mode);
  }

  void _repeatCurrentTrack() {
    _repeatSubscriptions.add(
      _player.positionDiscontinuityStream.listen((discontinuity) {
        // Solo el avance automático al terminar; un salto del usuario se
        // respeta aunque esté activo repetir uno.
        if (_appLoopMode != AppLoopMode.one ||
            discontinuity.reason != PositionDiscontinuityReason.autoAdvance) {
          return;
        }
        final previous = discontinuity.previousEvent;
        final finished = previous.currentIndex;
        if (finished == null) return;
        // Un salto desde la notificación o los auriculares lo hace el
        // reproductor nativo y también llega como autoAdvance; solo se repite
        // si la pista realmente llegó al final.
        final ended = reachedEnd(
          previous: previous,
          at: discontinuity.event.updateTime,
          duration: previous.duration ?? _durationAt(finished),
          playing: _player.playing,
        );
        if (ended) {
          _afterEvent(() => _player.seek(Duration.zero, index: finished));
        }
      }),
    );
    _repeatSubscriptions.add(
      _player.processingStateStream.listen((state) {
        // La última pista de la cola termina sin avance automático.
        if (_appLoopMode == AppLoopMode.one &&
            state == ProcessingState.completed) {
          _afterEvent(() async {
            await _player.seek(Duration.zero, index: _player.currentIndex);
            await _player.play();
          });
        }
      }),
    );
  }

  /// Margen entre la posición estimada y la duración para dar una pista por
  /// terminada; cubre el retraso de los eventos del reproductor.
  static const endTolerance = Duration(seconds: 2);

  /// Si la pista de [previous] terminó sola en el instante [at]: estaba
  /// sonando y su posición estimada alcanzó la [duration]. Sin duración
  /// conocida se asume el final, como hacía el reproductor.
  @visibleForTesting
  static bool reachedEnd({
    required PlaybackEvent previous,
    required DateTime at,
    required Duration? duration,
    required bool playing,
  }) {
    if (!playing) return false;
    if (duration == null || duration <= Duration.zero) return true;
    final position =
        previous.updatePosition + at.difference(previous.updateTime);
    return position >= duration - endTolerance;
  }

  Duration? _durationAt(int index) =>
      index < _currentTracks.length ? _currentTracks[index].duration : null;

  /// Los streams de just_audio son síncronos: un seek dentro de su listener
  /// falla con "Controller is already firing an event". Se ejecuta [action]
  /// cuando el evento actual terminó de emitirse.
  void _afterEvent(Future<void> Function() action) {
    unawaited(
      Future<void>(
        action,
      ).catchError((Object e) => debugPrint('Error al repetir la pista: $e')),
    );
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
    for (final subscription in _repeatSubscriptions) {
      await subscription.cancel();
    }
    await _loopModeController.close();
    await _player.dispose();
  }
}
