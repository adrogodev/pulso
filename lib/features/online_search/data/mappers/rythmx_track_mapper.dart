import '../../../../shared/base_domain/models/track.dart';
import '../dto/rythmx_track_dto.dart';

/// Convierte las canciones de Rythmx en [Track] reproducibles por streaming.
class RythmxTrackMapper {
  const RythmxTrackMapper();

  Track toTrack(RythmxTrackDto dto) => Track(
    id: 'rythmx:${dto.id}',
    title: dto.title,
    artist: dto.artistNames.isEmpty
        ? Track.unknownArtist
        : dto.artistNames.join(', '),
    album: dto.albumTitle ?? 'YouTube Music',
    durationMs: dto.durationSeconds * 1000,
    uri: dto.streamUrl,
    artworkUrl: dto.thumbnailUrl,
  );
}
