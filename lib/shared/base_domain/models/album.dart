import 'package:flutter/foundation.dart';

/// Entidad inmutable que representa un álbum en la biblioteca.
@immutable
class Album {
  final int id;
  final String title;
  final String artist;
  final int numOfSongs;
  final int? firstYear;
  final int? lastYear;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.numOfSongs,
    this.firstYear,
    this.lastYear,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Album &&
          other.id == id &&
          other.title == title &&
          other.artist == artist &&
          other.numOfSongs == numOfSongs);

  @override
  int get hashCode => Object.hash(id, title, artist, numOfSongs);

  @override
  String toString() =>
      'Album(id: $id, title: $title, artist: $artist, songs: $numOfSongs)';
}
