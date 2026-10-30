import '../../../../shared/base_domain/models/track.dart';
import '../../../../shared/base_domain/result/result.dart';
import '../../domain/services/online_music_service.dart';
import '../data_sources/remote/internet_archive_remote_data_source.dart';
import '../data_sources/remote/jamendo_remote_data_source.dart';
import '../mappers/free_track_mapper.dart';
import 'guarded_search.dart';

/// Canciones completas de Jamendo (Creative Commons).
class JamendoMusicService implements OnlineMusicService {
  final JamendoRemoteDataSource _remote;

  JamendoMusicService(this._remote);

  @override
  Future<Result<List<Track>>> searchTracks(String query) =>
      guardedSearch('Jamendo', query, (trimmed) async {
        final dtos = await _remote.searchTracks(trimmed);
        return dtos.map(const FreeTrackMapper().fromJamendo).toList();
      });
}

/// Grabaciones antiguas y de dominio público de Internet Archive.
class InternetArchiveMusicService implements OnlineMusicService {
  final InternetArchiveRemoteDataSource _remote;

  InternetArchiveMusicService(this._remote);

  @override
  Future<Result<List<Track>>> searchTracks(String query) =>
      guardedSearch('Internet Archive', query, (trimmed) async {
        final dtos = await _remote.searchTracks(trimmed);
        return dtos.map(const FreeTrackMapper().fromInternetArchive).toList();
      });
}
