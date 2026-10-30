import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_sources/remote/audius_remote_data_source.dart';
import '../../data/data_sources/remote/internet_archive_remote_data_source.dart';
import '../../data/data_sources/remote/jamendo_remote_data_source.dart';
import '../../data/services/audius_music_service.dart';
import '../../data/services/multi_source_music_service.dart';
import '../../data/services/source_music_services.dart';
import '../../domain/services/online_music_service.dart';
import 'online_search_state.dart';

/// `client_id` gratuito de Jamendo; sin él, la fuente no se consulta.
/// Se pasa al compilar con `--dart-define=JAMENDO_CLIENT_ID=...`.
const String jamendoClientId = String.fromEnvironment('JAMENDO_CLIENT_ID');
final onlineMusicServiceProvider = Provider<OnlineMusicService>((ref) {
  // Solo fuentes que permiten escuchar la canción completa. El orden decide
  // qué versión se queda ante un duplicado.
  return MultiSourceMusicService([
    AudiusMusicService(AudiusRemoteDataSource()),
    if (jamendoClientId.isNotEmpty)
      JamendoMusicService(JamendoRemoteDataSource(clientId: jamendoClientId)),
    InternetArchiveMusicService(InternetArchiveRemoteDataSource()),
  ]);
});

final onlineSearchNotifierProvider =
    NotifierProvider<OnlineSearchNotifier, OnlineSearchState>(
      OnlineSearchNotifier.new,
    );

class OnlineSearchNotifier extends Notifier<OnlineSearchState> {
  OnlineMusicService get _service => ref.read(onlineMusicServiceProvider);

  /// Identifica la búsqueda más reciente; repetir el mismo texto no basta
  /// para distinguir una respuesta vieja de la actual.
  int _latestRequest = 0;

  @override
  OnlineSearchState build() {
    return const OnlineSearchState();
  }

  /// Busca en línea al confirmar la consulta, no en cada tecla, para no
  /// lanzar una petición de red por carácter escrito.
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final request = ++_latestRequest;
    state = state.copyWith(query: trimmed, isLoading: true, clearError: true);

    final result = await _service.searchTracks(trimmed);

    // Una búsqueda más nueva pudo empezar mientras esta esperaba la red.
    if (request != _latestRequest) return;

    state = result.when(
      ok: (tracks) =>
          state.copyWith(results: tracks, isLoading: false, hasSearched: true),
      err: (failure) => state.copyWith(
        results: const [],
        isLoading: false,
        errorMessage: failure.message,
        hasSearched: true,
      ),
    );
  }
}
