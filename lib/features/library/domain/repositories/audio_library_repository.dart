import '../../../../core/result/result.dart';
import '../../../../entities/album/album.dart';
import '../../../../entities/artist/artist.dart';
import '../../../../entities/track/track.dart';

/// Contrato del repositorio de la biblioteca musical local.
abstract class AudioLibraryRepository {
  Future<Result<List<Track>>> getTracks({bool refresh = false});
  Future<Result<List<Album>>> getAlbums({bool refresh = false});
  Future<Result<List<Artist>>> getArtists({bool refresh = false});
  Future<Result<Track?>> getTrackById(String id);
  Future<Result<List<Track>>> getTracksByAlbum(String albumName);
  Future<Result<List<Track>>> getTracksByArtist(String artistName);
}
