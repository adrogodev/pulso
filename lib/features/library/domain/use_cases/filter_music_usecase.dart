import '../../../../shared/base_domain/models/track.dart';

/// Separa la música de los clips que MediaStore también indexa como audio.
///
/// Android marca como música casi todo (incluidas las notas de voz y los
/// audios reenviados por WhatsApp), así que ni `is_music` ni la carpeta sirven.
/// Medido en un dispositivo real: los audios de menos de un minuto sin artista
/// son ruido, mientras que las canciones cortas sí traen artista.
class FilterMusicUseCase {
  static const Duration minClipDuration = Duration(minutes: 1);

  const FilterMusicUseCase();

  List<Track> call(List<Track> tracks, {required bool hideShortClips}) {
    if (!hideShortClips) return tracks;
    return tracks.where(_isMusic).toList(growable: false);
  }

  static bool _isMusic(Track track) =>
      track.duration >= minClipDuration || track.artist != Track.unknownArtist;
}
