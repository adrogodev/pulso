import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/base_domain/models/track.dart';
import '../../../../shared/ui_kit/theme/app_colors.dart';
import '../../../../shared/ui_kit/theme/app_typography.dart';
import '../../../../shared/ui_kit/widgets/pulso_waveform.dart';
import '../../../../shared/ui_kit/widgets/track_artwork.dart';
import '../../../playback/presentation/controllers/playback_notifier.dart';
import '../../../playback/presentation/screens/expanded_player_screen.dart';
import '../../../playback/presentation/widgets/mini_player.dart';
import '../controllers/online_search_notifier.dart';
import '../controllers/online_search_state.dart';

/// Búsqueda de música libre en Audius, reproducible en segundo plano.
class OnlineSearchScreen extends ConsumerStatefulWidget {
  const OnlineSearchScreen({super.key});

  @override
  ConsumerState<OnlineSearchScreen> createState() => _OnlineSearchScreenState();
}

class _OnlineSearchScreenState extends ConsumerState<OnlineSearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onlineSearchNotifierProvider);
    final notifier = ref.read(onlineSearchNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('EN LÍNEA', style: AppTypography.titleMedium),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _controller,
              style: AppTypography.bodyLarge,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Buscar canciones o artistas en Audius...',
                prefixIcon: Icon(
                  Icons.public_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
              onSubmitted: notifier.search,
            ),
          ),
          if (state.isLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
            ),
          Expanded(child: _buildBody(state)),
        ],
      ),
      // Muestra qué suena y abre su vista, como en la biblioteca.
      bottomNavigationBar: MiniPlayer(onTap: _openNowPlaying),
    );
  }

  Widget _buildBody(OnlineSearchState state) {
    if (state.errorMessage != null) {
      return _buildMessage(
        icon: Icons.wifi_off_rounded,
        title: state.errorMessage!,
        subtitle: 'Inténtalo de nuevo en unos segundos',
      );
    }

    if (!state.hasSearched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PulsoWaveform(
              width: 60,
              height: 60,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 16),
            const Text(
              'Busca música libre en Audius',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Gratis, sin anuncios y con reproducción en segundo plano',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (state.results.isEmpty) {
      return _buildMessage(
        icon: Icons.search_off_rounded,
        title: 'Sin resultados para "${state.query}"',
        subtitle: 'Prueba con otro término de búsqueda',
      );
    }

    // Solo lo que identifica la pista actual: la posición no redibuja la lista.
    final nowPlaying = ref.watch(
      playbackNotifierProvider.select(
        (s) => (trackId: s.currentTrack?.id, isPlaying: s.isPlaying),
      ),
    );

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final track = state.results[index];
        final isCurrent = nowPlaying.trackId == track.id;
        return ListTile(
          selected: isCurrent,
          selectedTileColor: AppColors.surface,
          leading: TrackArtwork(id: null, url: track.artworkUrl, size: 44),
          title: Text(
            track.title,
            style: AppTypography.bodyLarge.copyWith(
              color: isCurrent ? AppColors.textPrimary : null,
              fontWeight: isCurrent ? FontWeight.bold : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            track.genre != null
                ? '${track.artist} • ${track.genre}'
                : track.artist,
            style: AppTypography.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: isCurrent
              ? Row(
                  key: ValueKey('sonando-${track.id}'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (nowPlaying.isPlaying)
                      const PulsoWaveform(width: 20, height: 16)
                    else
                      const Icon(
                        Icons.pause_rounded,
                        size: 18,
                        color: AppColors.textPrimary,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      track.formattedDuration,
                      style: AppTypography.labelSmall,
                    ),
                  ],
                )
              : Text(track.formattedDuration, style: AppTypography.labelSmall),
          onTap: () => _play(track, state.results, isCurrent: isCurrent),
        );
      },
    );
  }

  /// Reproduce la pista y abre la vista "En reproducción", para que siempre
  /// se vea qué suena. Si ya es la actual, solo abre la vista.
  void _play(Track track, List<Track> results, {required bool isCurrent}) {
    if (!isCurrent) {
      // Los resultados quedan como cola para seguir con la siguiente pista.
      ref
          .read(playbackNotifierProvider.notifier)
          .playTrack(track, inQueue: results);
    }
    _openNowPlaying();
  }

  void _openNowPlaying() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ExpandedPlayerScreen()),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
