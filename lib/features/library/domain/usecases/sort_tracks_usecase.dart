import '../../../../entities/track/track.dart';

enum TrackSortCriteria { title, artist, album, duration }

enum SortOrder { ascending, descending }

class SortTracksUseCase {
  const SortTracksUseCase();

  List<Track> call(
    List<Track> tracks, {
    TrackSortCriteria criteria = TrackSortCriteria.title,
    SortOrder order = SortOrder.ascending,
  }) {
    final sorted = List<Track>.from(tracks);

    sorted.sort((a, b) {
      final comparison = switch (criteria) {
        TrackSortCriteria.title => a.title.toLowerCase().compareTo(
          b.title.toLowerCase(),
        ),
        TrackSortCriteria.artist => a.artist.toLowerCase().compareTo(
          b.artist.toLowerCase(),
        ),
        TrackSortCriteria.album => a.album.toLowerCase().compareTo(
          b.album.toLowerCase(),
        ),
        TrackSortCriteria.duration => a.durationMs.compareTo(b.durationMs),
      };

      return order == SortOrder.ascending ? comparison : -comparison;
    });

    return sorted;
  }
}
