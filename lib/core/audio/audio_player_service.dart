import '../../entities/track/track.dart';

/// Modos de repetición soportados por Pulso.
enum AppLoopMode { off, one, all }

/// Estado simplificado del motor de audio sincronizado con la plataforma.
enum AppPlayerStatus {
  idle,
  loading,
  buffering,
  playing,
  paused,
  completed,
  error,
}

/// Contrato abstracto para el motor de reproducción de audio.
abstract class AudioPlayerService {
  Stream<AppPlayerStatus> get statusStream;
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<int?> get currentIndexStream;
  Stream<bool> get shuffleModeStream;
  Stream<AppLoopMode> get loopModeStream;
  Stream<double> get volumeStream;

  Future<void> setQueue(List<Track> tracks, {int initialIndex = 0});
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> skipToIndex(int index);
  Future<void> setShuffleMode(bool enabled);
  Future<void> setLoopMode(AppLoopMode mode);
  Future<void> setVolume(double volume);
  Future<void> stop();
  Future<void> dispose();
}
