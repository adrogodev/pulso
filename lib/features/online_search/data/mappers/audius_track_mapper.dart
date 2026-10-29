import '../../../../shared/base_domain/models/track.dart';
import '../data_sources/remote/audius_remote_data_source.dart';
import '../dto/audius_track_dto.dart';

/// Convierte las pistas de Audius en [Track] reproducibles por streaming.
class AudiusTrackMapper {
  const AudiusTrackMapper();

  Track toTrack(AudiusTrackDto dto) {
    return Track(
      // Prefijo para que nunca coincida con los IDs numéricos de MediaStore.
      id: 'audius:${dto.id}',
      title: dto.title,
      artist: dto.artistName,
      album: 'Audius',
      durationMs: dto.durationSeconds * 1000,
      genre: dto.genre,
      uri: AudiusRemoteDataSource.streamUri(dto.id).toString(),
      artworkUrl: dto.artworkUrl,
    );
  }
}
