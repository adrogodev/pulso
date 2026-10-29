import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../theme/app_colors.dart';
import 'pulso_waveform.dart';

/// Widget de carátula de pista o álbum con fallback monocromático minimalista.
class TrackArtwork extends StatelessWidget {
  final int? id;
  final ArtworkType type;
  final double size;
  final BorderRadius? borderRadius;

  const TrackArtwork({
    super.key,
    required this.id,
    this.type = ArtworkType.AUDIO,
    this.size = 50,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(8);

    // Fallback si no hay ID o no estamos en Android
    if (id == null || !Platform.isAndroid || kIsWeb) {
      return _buildFallback(radius);
    }

    return ClipRRect(
      borderRadius: radius,
      child: QueryArtworkWidget(
        id: id!,
        type: type,
        artworkWidth: size,
        artworkHeight: size,
        artworkFit: BoxFit.cover,
        artworkBorder: BorderRadius.zero,
        nullArtworkWidget: _buildFallback(radius),
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
