import 'package:flutter/foundation.dart';

import '../../../../shared/base_domain/error/failures.dart';
import '../../../../shared/base_domain/models/track.dart';
import '../../../../shared/base_domain/result/result.dart';
import '../../domain/services/online_music_service.dart';
import '../data_sources/remote/audius_remote_data_source.dart';
import '../mappers/audius_track_mapper.dart';

/// Implementación de [OnlineMusicService] sobre la API pública de Audius.
class AudiusMusicService implements OnlineMusicService {
  final AudiusRemoteDataSource _remote;
  final AudiusTrackMapper _mapper = const AudiusTrackMapper();

  AudiusMusicService(this._remote);

  @override
  Future<Result<List<Track>>> searchTracks(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const Result.ok([]);

    try {
      final dtos = await _remote.searchTracks(trimmed);
      final tracks = dtos
          .where((dto) => dto.isStreamable)
          .map(_mapper.toTrack)
          .toList(growable: false);
      return Result.ok(tracks);
    } on FormatException catch (e) {
      // Un cambio en el formato de la API no es culpa de la conexión del
      // usuario: se informa distinto y queda registrado para diagnosticarlo.
      debugPrint('Audius devolvió una respuesta no válida: $e');
      return Result.err(
        NetworkFailure(
          'Audius devolvió una respuesta inesperada. Inténtalo más tarde.',
          cause: e,
        ),
      );
    } catch (e) {
      debugPrint('Falló la búsqueda en Audius: $e');
      return Result.err(
        NetworkFailure(
          'No se pudo buscar en línea. Revisa tu conexión a internet.',
          cause: e,
        ),
      );
    }
  }
}
