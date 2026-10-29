import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/shared/base_data/database/database_service.dart';
import 'package:pulso/shared/base_data/database/memory_database_service.dart';
import 'package:pulso/shared/base_data/database/sqflite_database_service.dart';
import 'package:pulso/shared/base_domain/result/result.dart';
import 'package:pulso/features/favorites/data/services/favorites_repository_impl.dart';
import 'package:pulso/features/favorites/domain/services/favorites_repository.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final service = Platform.isAndroid
      ? SqfliteDatabaseService()
      : MemoryDatabaseService();
  service.initialize();
  ref.onDispose(() {
    service.close();
  });
  return service;
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return FavoritesRepositoryImpl(dbService);
});

final favoritesNotifierProvider =
    NotifierProvider<FavoritesNotifier, Set<String>>(FavoritesNotifier.new);

class FavoritesNotifier extends Notifier<Set<String>> {
  FavoritesRepository get _repo => ref.read(favoritesRepositoryProvider);

  @override
  Set<String> build() {
    loadFavorites();
    return const {};
  }

  Future<void> loadFavorites() async {
    final result = await _repo.getFavoriteTrackIds();
    if (result is Success<Set<String>>) {
      state = Set.from(result.data);
    }
  }

  Future<void> toggleFavorite(String trackId) async {
    // Optimistic UI update
    final next = Set<String>.from(state);
    if (next.contains(trackId)) {
      next.remove(trackId);
    } else {
      next.add(trackId);
    }
    state = next;

    final res = await _repo.toggleFavorite(trackId);
    if (res is Err) {
      // Revertir si hubo error
      await loadFavorites();
    }
  }

  bool isFavorite(String trackId) => state.contains(trackId);
}
