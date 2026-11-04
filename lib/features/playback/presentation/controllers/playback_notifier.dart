import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../shared/base_data/audio/audio_player_service.dart';
import '../../../../shared/base_data/audio/online_audio_cache.dart';
import '../../../equalizer/presentation/controllers/equalizer_notifier.dart';
import '../../../../shared/base_data/audio/just_audio_player_service.dart';
import '../../../../shared/base_domain/models/track.dart';
import '../../../settings/domain/services/settings_repository.dart';
import '../../../settings/presentation/controllers/settings_notifier.dart';
import 'playback_state.dart';

/// Caché de la música en línea dentro del directorio de caché de la app.
final onlineAudioCacheProvider = Provider<OnlineAudioCache>((ref) {
  return OnlineAudioCache(
    directory: () async => Directory(
      '${(await getApplicationCacheDirectory()).path}'
      '${Platform.pathSeparator}online_audio',
    ),
  );
});

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  // El ecualizador tiene que estar en el pipeline desde que se crea el
  // reproductor; AndroidEqualizer solo existe en Android.
  final isAndroid = !kIsWeb && Platform.isAndroid;
  final service = JustAudioPlayerService(
    equalizer: isAndroid ? ref.watch(androidEqualizerProvider) : null,
    onlineCache: isAndroid ? ref.watch(onlineAudioCacheProvider) : null,
  );
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final playbackNotifierProvider =
    NotifierProvider<PlaybackNotifier, PlaybackState>(PlaybackNotifier.new);

class PlaybackNotifier extends Notifier<PlaybackState> {
  static const _buildingQueueKey = 'queue_built_by_hand';
  static const _queueIdsKey = 'last_session_queue';

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Tras vaciar la cola, se arma solo con lo que se va escuchando, hasta que
  /// el usuario crea una nueva con "Reproducir todo".
  bool _buildingQueue = false;

  AudioPlayerService get _audioService => ref.read(audioPlayerServiceProvider);
  SettingsRepository get _settingsRepo => ref.read(settingsRepositoryProvider);

  @override
  PlaybackState build() {
    ref.onDispose(() {
      for (final sub in _subscriptions) {
        sub.cancel();
      }
      _subscriptions.clear();
    });

    _initListeners();
    unawaited(_loadBuildingQueue());
    return const PlaybackState();
  }

  Future<void> _loadBuildingQueue() async {
    final saved = await _settingsRepo.getPreference(_buildingQueueKey);
    _buildingQueue = saved.dataOrNull == 'true';
  }

  Future<void> _setBuildingQueue(bool value) async {
    _buildingQueue = value;
    await _settingsRepo.setPreference(_buildingQueueKey, '$value');
  }

  void _initListeners() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    _subscriptions.add(
      _audioService.statusStream.listen((status) {
        state = state.copyWith(status: status);
        if (status == AppPlayerStatus.paused) unawaited(saveSession());
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
          // Una pista nueva arranca de cero; si no, se guardaría con la
          // posición de la anterior. Un índice repetido (al restaurar) no es
          // un cambio de pista y conserva la posición.
          final changed = current.id != state.currentTrack?.id;
          state = state.copyWith(
            currentIndex: index,
            currentTrack: current,
            // Con la misma pista se conserva la duración que ya informó el
            // reproductor: un audio externo llega sin duración propia.
            duration: changed ? current.duration : null,
            position: changed ? Duration.zero : null,
          );
          unawaited(saveSession());
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

  /// Guarda la pista actual y su posición para restaurarlas al reabrir.
  ///
  /// Solo las pistas locales: con el id no alcanza para reconstruir una
  /// pista en línea, que no existe en la biblioteca.
  Future<void> saveSession() async {
    final track = state.currentTrack;
    if (track == null || track.isRemote) return;
    await _settingsRepo.saveLastSession(
      track.id,
      state.position.inMilliseconds,
    );
    // Una cola armada a mano no se puede rehacer desde la biblioteca: se
    // guardan sus pistas locales.
    if (_buildingQueue) {
      await _settingsRepo.setPreference(
        _queueIdsKey,
        state.queue.where((t) => !t.isRemote).map((t) => t.id).join('\n'),
      );
    }
  }

  /// Carga en pausa la última pista guardada. La cola es la biblioteca, o la
  /// que el usuario armó a mano si había vaciado la anterior.
  Future<void> restoreSession(List<Track> library) async {
    if (state.hasTrack || library.isEmpty) return;

    // Se lee del repositorio y no del estado de Ajustes, que se carga de forma
    // asíncrona y al arrancar todavía puede tener el valor por defecto.
    final enabled = await _settingsRepo.getPreference('restore_last_session');
    if (enabled.dataOrNull == 'false') return;

    final session = (await _settingsRepo.getLastSession()).dataOrNull;
    final queue = await _restorableQueue(library);
    final index = queue.indexWhere((t) => t.id == session?['trackId']);
    // El usuario pudo empezar a reproducir mientras se leía la sesión.
    if (index < 0 || state.hasTrack) return;

    final track = queue[index];
    final positionMs = session?['positionMs'];
    final position = Duration(milliseconds: positionMs is int ? positionMs : 0);
    final previous = state;
    state = state.copyWith(
      queue: queue,
      currentIndex: index,
      currentTrack: track,
      duration: track.duration,
      position: position,
      status: AppPlayerStatus.paused,
    );
    try {
      await _audioService.setQueue(queue, initialIndex: index);
      await _audioService.seek(position);
    } catch (e) {
      // Si el archivo ya no se puede abrir, no se muestra una pista que el
      // reproductor nunca cargó.
      debugPrint('No se pudo restaurar la última sesión: $e');
      state = previous;
    }
  }

  Future<List<Track>> _restorableQueue(List<Track> library) async {
    _buildingQueue =
        (await _settingsRepo.getPreference(_buildingQueueKey)).dataOrNull ==
        'true';
    if (!_buildingQueue) return library;

    final saved = (await _settingsRepo.getPreference(_queueIdsKey)).dataOrNull;
    final byId = {for (final track in library) track.id: track};
    return [
      for (final id in saved?.split('\n') ?? const <String>[])
        if (byId[id] != null) byId[id]!,
    ];
  }

  /// Reproduce una canción tocada en una lista.
  ///
  /// Normalmente la lista entera pasa a ser la cola. Si el usuario vació la
  /// cola, en cambio, la canción se suma al final (o se salta a ella si ya
  /// estaba), para que la cola sea solo lo que va escuchando.
  Future<void> playFromList(Track track, List<Track> list) async {
    if (!_buildingQueue) return playTrack(track, inQueue: list);

    final index = state.queue.indexWhere((t) => t.id == track.id);
    if (index < 0) return playTrack(track, inQueue: [...state.queue, track]);

    await _audioService.skipToIndex(index);
    await _audioService.play();
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

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        oldIndex >= state.queue.length ||
        newIndex < 0 ||
        newIndex > state.queue.length) {
      return;
    }

    final newQueue = List<Track>.from(state.queue);
    var adjustedNewIndex = newIndex;
    if (oldIndex < adjustedNewIndex) {
      adjustedNewIndex -= 1;
    }

    final movedItem = newQueue.removeAt(oldIndex);
    newQueue.insert(adjustedNewIndex, movedItem);

    // Identificar nueva posición de la pista en reproducción
    final currentId = state.currentTrack?.id;
    final updatedCurrentIndex = newQueue.indexWhere((t) => t.id == currentId);
    final safeIndex = updatedCurrentIndex >= 0 ? updatedCurrentIndex : 0;

    state = state.copyWith(queue: newQueue, currentIndex: safeIndex);

    await _audioService.setQueue(newQueue, initialIndex: safeIndex);
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= state.queue.length) return;

    final newQueue = List<Track>.from(state.queue);
    final isRemovingCurrent = index == state.currentIndex;

    newQueue.removeAt(index);

    if (newQueue.isEmpty) {
      await clearQueue();
      return;
    }

    var newCurrentIndex = state.currentIndex;
    if (isRemovingCurrent) {
      if (newCurrentIndex >= newQueue.length) {
        newCurrentIndex = 0;
      }
      final newCurrentTrack = newQueue[newCurrentIndex];
      state = state.copyWith(
        queue: newQueue,
        currentIndex: newCurrentIndex,
        currentTrack: newCurrentTrack,
        duration: newCurrentTrack.duration,
      );
      await _audioService.setQueue(newQueue, initialIndex: newCurrentIndex);
      if (state.isPlaying) {
        await _audioService.play();
      }
    } else {
      if (index < state.currentIndex) {
        newCurrentIndex -= 1;
      }
      state = state.copyWith(queue: newQueue, currentIndex: newCurrentIndex);
      await _audioService.setQueue(newQueue, initialIndex: newCurrentIndex);
    }
  }

  /// "Reproducir todo": crea una cola nueva con [tracks] y deja de armarla a
  /// mano.
  Future<void> playTracks(List<Track> tracks, {int initialIndex = 0}) async {
    if (tracks.isEmpty) return;
    await _setBuildingQueue(false);
    final safeIndex = (initialIndex >= 0 && initialIndex < tracks.length)
        ? initialIndex
        : 0;
    await playTrack(tracks[safeIndex], inQueue: tracks);
  }

  Future<void> playNext(Track track) async {
    if (state.queue.isEmpty) {
      await playTrack(track);
      return;
    }
    final newQueue = List<Track>.from(state.queue);
    final insertIndex = (state.currentIndex + 1).clamp(0, newQueue.length);
    newQueue.insert(insertIndex, track);
    state = state.copyWith(queue: newQueue);
    await _audioService.setQueue(newQueue, initialIndex: state.currentIndex);
  }

  Future<void> addToQueue(Track track) async {
    if (state.queue.isEmpty) {
      await playTrack(track);
      return;
    }
    final newQueue = List<Track>.from(state.queue)..add(track);
    state = state.copyWith(queue: newQueue);
    await _audioService.setQueue(newQueue, initialIndex: state.currentIndex);
  }

  /// Deja la cola en cero: descarga las pistas del reproductor y olvida la
  /// última sesión, para que al reabrir la app no reaparezca la cola vieja.
  Future<void> clearQueue() async {
    // El estado se vacía primero: así los eventos que emita el reproductor al
    // soltar las pistas no encuentran una cola de la que reponerlas.
    state = state.copyWith(
      queue: const [],
      clearCurrentTrack: true,
      currentIndex: 0,
      position: Duration.zero,
      duration: Duration.zero,
      status: AppPlayerStatus.idle,
    );
    await _audioService.setQueue(const []);
    await _settingsRepo.clearLastSession();
    await _settingsRepo.setPreference(_queueIdsKey, '');
    await _setBuildingQueue(true);
  }
}
