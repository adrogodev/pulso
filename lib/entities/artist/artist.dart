import 'package:flutter/foundation.dart';

/// Entidad inmutable que representa un artista en la biblioteca.
@immutable
class Artist {
  final int id;
  final String name;
  final int numOfTracks;
  final int numOfAlbums;

  const Artist({
    required this.id,
    required this.name,
    required this.numOfTracks,
    required this.numOfAlbums,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Artist &&
          other.id == id &&
          other.name == name &&
          other.numOfTracks == numOfTracks &&
          other.numOfAlbums == numOfAlbums);

  @override
  int get hashCode => Object.hash(id, name, numOfTracks, numOfAlbums);

  @override
  String toString() =>
      'Artist(id: $id, name: $name, tracks: $numOfTracks, albums: $numOfAlbums)';
}
