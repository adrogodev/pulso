import '../../../../shared/base_domain/models/track.dart';
import '../../../../shared/base_domain/result/result.dart';
import '../../domain/services/online_music_service.dart';
import '../data_sources/remote/rythmx_remote_data_source.dart';
import '../mappers/rythmx_track_mapper.dart';
import 'guarded_search.dart';

/// Implementación de [OnlineMusicService] sobre la API de Rythmx.
class RythmxMusicService implements OnlineMusicService {
  final RythmxRemoteDataSource _remote;
  final RythmxTrackMapper _mapper = const RythmxTrackMapper();

  RythmxMusicService(this._remote);

  @override
  Future<Result<List<Track>>> searchTracks(String query) =>
      guardedSearch('Rythmx', query, (trimmed) async {
        final dtos = await _remote.searchTracks(trimmed);
        return dtos.map(_mapper.toTrack).toList();
      });
}
