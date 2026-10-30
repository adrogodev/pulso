import '../../../../shared/base_domain/models/track.dart';
import '../dto/internet_archive_track_dto.dart';
import '../dto/jamendo_track_dto.dart';

/// Convierte las pistas completas de Jamendo e Internet Archive en [Track].
class FreeTrackMapper {
  const FreeTrackMapper();

  Track fromJamendo(JamendoTrackDto dto) => Track(
    id: 'jamendo:${dto.id}',
    title: dto.title,
    artist: dto.artistName,
    album: dto.albumTitle,
    durationMs: dto.durationSeconds * 1000,
    year: dto.year,
    uri: dto.audioUrl,
    artworkUrl: dto.artworkUrl,
  );

  Track fromInternetArchive(InternetArchiveTrackDto dto) => Track(
    id: 'archive:${dto.itemId}/${dto.fileName}',
    title: dto.title,
    artist: dto.artistName,
    album: dto.albumTitle,
    durationMs: dto.durationSeconds * 1000,
    year: dto.year,
    uri: dto.audioUri.toString(),
    artworkUrl: dto.artworkUrl,
  );
}
