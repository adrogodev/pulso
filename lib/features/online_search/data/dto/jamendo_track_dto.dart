import '../data_sources/remote/http_get.dart';

/// Pista de Jamendo: música Creative Commons que se escucha completa.
class JamendoTrackDto {
  final String id;
  final String title;
  final String artistName;
  final String albumTitle;
  final int durationSeconds;
  final String audioUrl;
  final int? year;
  final String? artworkUrl;

  const JamendoTrackDto({
    required this.id,
    required this.title,
    required this.artistName,
    required this.albumTitle,
    required this.durationSeconds,
    required this.audioUrl,
    this.year,
    this.artworkUrl,
  });

  static JamendoTrackDto? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final audio = httpsUrlOrNull(json['audio']);
    if (id == null || '$id'.isEmpty || audio == null) return null;

    final duration = json['duration'];
    final released = json['releasedate'];
    return JamendoTrackDto(
      id: '$id',
      title: textOr(json['name'], 'Sin título'),
      artistName: textOr(json['artist_name'], 'Artista desconocido'),
      albumTitle: textOr(json['album_name'], 'Jamendo'),
      durationSeconds: duration is num
          ? duration.toInt()
          : int.tryParse('$duration') ?? 0,
      audioUrl: audio,
      year: released is String ? DateTime.tryParse(released)?.year : null,
      artworkUrl: httpsUrlOrNull(json['image']),
    );
  }
}
