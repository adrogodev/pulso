import 'package:flutter/foundation.dart';

import '../../../../entities/album/album.dart';
import '../../../../entities/artist/artist.dart';
import '../../../../entities/track/track.dart';
import '../../domain/usecases/sort_tracks_usecase.dart';

@immutable
class LibraryState {
  final List<Track> tracks;
  final List<Album> albums;
  final List<Artist> artists;
  final bool isLoading;
  final String? errorMessage;
  final bool hasPermission;
  final TrackSortCriteria sortCriteria;
  final SortOrder sortOrder;

  const LibraryState({
    this.tracks = const [],
    this.albums = const [],
    this.artists = const [],
    this.isLoading = false,
    this.errorMessage,
    this.hasPermission = false,
    this.sortCriteria = TrackSortCriteria.title,
    this.sortOrder = SortOrder.ascending,
  });

  List<Track> get sortedTracks {
    const sorter = SortTracksUseCase();
    return sorter(tracks, criteria: sortCriteria, order: sortOrder);
  }

  LibraryState copyWith({
    List<Track>? tracks,
    List<Album>? albums,
    List<Artist>? artists,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? hasPermission,
    TrackSortCriteria? sortCriteria,
    SortOrder? sortOrder,
  }) {
    return LibraryState(
      tracks: tracks ?? this.tracks,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasPermission: hasPermission ?? this.hasPermission,
      sortCriteria: sortCriteria ?? this.sortCriteria,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
