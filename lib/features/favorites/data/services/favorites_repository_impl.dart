import 'package:pulso/shared/base_data/database/database_service.dart';
import 'package:pulso/shared/base_domain/error/failures.dart';
import 'package:pulso/shared/base_domain/result/result.dart';
import 'package:pulso/features/favorites/domain/services/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final DatabaseService _dbService;
  Set<String>? _cachedFavorites;

  FavoritesRepositoryImpl(this._dbService);

  @override
  Future<Result<Set<String>>> getFavoriteTrackIds() async {
    try {
      if (_cachedFavorites != null) {
        return Result.ok(_cachedFavorites!);
      }
      final ids = await _dbService.getFavoriteTrackIds();
      _cachedFavorites = Set.from(ids);
      return Result.ok(_cachedFavorites!);
    } catch (e) {
      return Result.err(
        StorageFailure('Error al leer favoritos de la base de datos', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> toggleFavorite(String trackId) async {
    try {
      final current = await getFavoriteTrackIds();
      final ids = current.dataOrNull ?? {};

      if (ids.contains(trackId)) {
        await _dbService.removeFavorite(trackId);
        _cachedFavorites?.remove(trackId);
      } else {
        await _dbService.addFavorite(trackId);
        _cachedFavorites?.add(trackId);
      }
      return const Result.ok(null);
    } catch (e) {
      return Result.err(
        StorageFailure('Error al alternar estado de favorito', cause: e),
      );
    }
  }

  @override
  Future<Result<bool>> isFavorite(String trackId) async {
    final current = await getFavoriteTrackIds();
    if (current is Success<Set<String>>) {
      return Result.ok(current.data.contains(trackId));
    }
    return const Result.ok(false);
  }
}
