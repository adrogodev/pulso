import '../../../../entities/album/album.dart';
import '../../../../entities/artist/artist.dart';
import '../../../../entities/track/track.dart';
import '../models/search_result.dart';

class SearchLibraryUseCase {
  const SearchLibraryUseCase();

  SearchResult call({
    required String query,
    required List<Track> tracks,
    required List<Album> albums,
    required List<Artist> artists,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return const SearchResult();
    }

    final matchedTracks = tracks.where((t) {
      return t.title.toLowerCase().contains(cleanQuery) ||
          t.artist.toLowerCase().contains(cleanQuery) ||
          t.album.toLowerCase().contains(cleanQuery);
    }).toList();

    final matchedAlbums = albums.where((a) {
      return a.title.toLowerCase().contains(cleanQuery) ||
          a.artist.toLowerCase().contains(cleanQuery);
    }).toList();

    final matchedArtists = artists.where((art) {
      return art.name.toLowerCase().contains(cleanQuery);
    }).toList();

    return SearchResult(
      tracks: matchedTracks,
      albums: matchedAlbums,
      artists: matchedArtists,
    );
  }
}
