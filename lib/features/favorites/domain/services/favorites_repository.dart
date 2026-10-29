import 'package:pulso/shared/base_domain/result/result.dart';

/// Contrato del repositorio para la gestión de canciones favoritas.
abstract class FavoritesRepository {
  Future<Result<Set<String>>> getFavoriteTrackIds();
  Future<Result<void>> toggleFavorite(String trackId);
  Future<Result<bool>> isFavorite(String trackId);
}
