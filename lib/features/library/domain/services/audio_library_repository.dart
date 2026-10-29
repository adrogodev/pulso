import '../../../../shared/base_domain/result/result.dart';
import '../../../../shared/base_domain/models/album.dart';
import '../../../../shared/base_domain/models/artist.dart';
import '../../../../shared/base_domain/models/track.dart';

/// Contrato del repositorio de la biblioteca musical local.
abstract class AudioLibraryRepository {
  Future<Result<List<Track>>> getTracks({bool refresh = false});
  Future<Result<List<Album>>> getAlbums({bool refresh = false});
  Future<Result<List<Artist>>> getArtists({bool refresh = false});
  Future<Result<Track?>> getTrackById(String id);
  Future<Result<List<Track>>> getTracksByAlbum(String albumName);
  Future<Result<List<Track>>> getTracksByArtist(String artistName);
}
