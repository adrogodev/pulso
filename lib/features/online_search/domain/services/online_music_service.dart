import '../../../../shared/base_domain/models/track.dart';
import '../../../../shared/base_domain/result/result.dart';

/// Contrato de búsqueda de música en línea, gratuita y sin anuncios.
abstract class OnlineMusicService {
  /// Busca pistas reproducibles por streaming.
  ///
  /// Una búsqueda vacía devuelve una lista vacía sin consultar la red.
  Future<Result<List<Track>>> searchTracks(String query);
}
