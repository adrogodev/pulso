import 'package:flutter/foundation.dart';
import 'package:pulso/entities/album/album.dart';
import 'package:pulso/entities/artist/artist.dart';
import 'package:pulso/entities/track/track.dart';

@immutable
class SearchResult {
  final List<Track> tracks;
  final List<Album> albums;
  final List<Artist> artists;

  const SearchResult({
    this.tracks = const [],
    this.albums = const [],
    this.artists = const [],
  });

  bool get isEmpty => tracks.isEmpty && albums.isEmpty && artists.isEmpty;
  bool get isNotEmpty => !isEmpty;
}
