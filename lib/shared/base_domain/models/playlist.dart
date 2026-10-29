import 'package:flutter/foundation.dart';

/// Entidad inmutable que representa una lista de reproducción gestionada por el usuario.
@immutable
class Playlist {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int trackCount;

  const Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.trackCount = 0,
  });

  Playlist copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? trackCount,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      trackCount: trackCount ?? this.trackCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Playlist &&
          other.id == id &&
          other.name == name &&
          other.trackCount == trackCount);

  @override
  int get hashCode => Object.hash(id, name, trackCount);

  @override
  String toString() =>
      'Playlist(id: $id, name: $name, trackCount: $trackCount)';
}
