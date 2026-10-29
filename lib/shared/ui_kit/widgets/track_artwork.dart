import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../base_data/artwork/artwork_cache.dart';
import '../theme/app_colors.dart';
import 'pulso_waveform.dart';

/// Widget de carátula de pista o álbum con fallback monocromático minimalista.
class TrackArtwork extends StatelessWidget {
  final int? id;
  final ArtworkType type;
  final double size;
  final BorderRadius? borderRadius;

  /// Caché de carátulas; por defecto la instancia compartida de la app.
  final ArtworkCache? cache;

  const TrackArtwork({
    super.key,
    required this.id,
    this.type = ArtworkType.AUDIO,
    this.size = 50,
    this.borderRadius,
    this.cache,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(8);

    // Fallback si no hay ID o no estamos en Android
    if (id == null ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return _buildFallback(radius);
    }

    // QueryArtworkWidget relanza la consulta a MediaStore en cada build;
    // el caché comparte la misma consulta y los mismos bytes entre rebuilds.
    final cache = this.cache ?? ArtworkCache.instance;
    final requestSize = ArtworkCache.bucketFor(
      size,
      MediaQuery.devicePixelRatioOf(context),
    );
    final resolved = cache.peek(id!, type: type, size: requestSize);

    if (resolved != null) {
      return _buildArtwork(resolved.bytes, radius);
    }

    // La key reinicia el FutureBuilder al cambiar de carátula; si no,
    // conserva los bytes anteriores hasta que resuelve la nueva consulta.
    return FutureBuilder<Uint8List?>(
      key: ValueKey((id, type, requestSize)),
      future: cache.load(id!, type: type, size: requestSize),
      builder: (context, snapshot) => _buildArtwork(snapshot.data, radius),
    );
  }

  Widget _buildArtwork(Uint8List? bytes, BorderRadius radius) {
    if (bytes == null || bytes.isEmpty) {
      return _buildFallback(radius);
    }

    return ClipRRect(
      borderRadius: radius,
      child: Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => _buildFallback(radius),
      ),
    );
  }

  Widget _buildFallback(BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Center(
        child: PulsoWaveform(
          width: size * 0.55,
          height: size * 0.55,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
