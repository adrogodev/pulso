import '../../../../shared/base_domain/models/track.dart';
import '../../../../shared/base_domain/result/result.dart';
import '../../domain/services/online_music_service.dart';
import '../data_sources/remote/audius_remote_data_source.dart';
import '../mappers/audius_track_mapper.dart';
import 'guarded_search.dart';

/// Implementación de [OnlineMusicService] sobre la API pública de Audius.
class AudiusMusicService implements OnlineMusicService {
  final AudiusRemoteDataSource _remote;
  final AudiusTrackMapper _mapper = const AudiusTrackMapper();

  AudiusMusicService(this._remote);

  @override
  Future<Result<List<Track>>> searchTracks(String query) {
    return guardedSearch('Audius', query, (trimmed) async {
      final dtos = await _remote.searchTracks(trimmed);
      return dtos
          .where((dto) => dto.isStreamable)
          .map(_mapper.toTrack)
          .toList();
    });
  }
}
