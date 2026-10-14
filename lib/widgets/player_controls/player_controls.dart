import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/audio/audio_player_service.dart';

/// Controles completos de reproducción: aleatorio, anterior, reproducir/pausar, siguiente y repetición.
class PlayerControls extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final bool isShuffleEnabled;
  final AppLoopMode loopMode;
  final VoidCallback? onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToggleShuffle;
  final VoidCallback? onCycleLoop;
  final double buttonSize;

  const PlayerControls({
    super.key,
    required this.isPlaying,
    this.isBuffering = false,
    this.isShuffleEnabled = false,
    this.loopMode = AppLoopMode.off,
    this.onPlayPause,
    this.onPrevious,
    this.onNext,
    this.onToggleShuffle,
    this.onCycleLoop,
    this.buttonSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Botón Aleatorio
        IconButton(
          icon: Icon(
            Icons.shuffle,
            color: isShuffleEnabled
                ? AppColors.textPrimary
                : AppColors.iconMuted,
            size: buttonSize * 0.85,
          ),
          tooltip: isShuffleEnabled
              ? 'Aleatorio activado'
              : 'Aleatorio desactivado',
          onPressed: onToggleShuffle,
        ),

        // Botón Anterior
        IconButton(
          icon: Icon(
            Icons.skip_previous_rounded,
            color: AppColors.iconActive,
            size: buttonSize * 1.25,
          ),
          tooltip: 'Canción anterior',
          onPressed: onPrevious,
        ),

        // Botón Principal Play / Pause
        Container(
          width: buttonSize * 2.2,
          height: buttonSize * 2.2,
          decoration: const BoxDecoration(
            color: AppColors.textPrimary,
            shape: BoxShape.circle,
          ),
          child: isBuffering
              ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryBackground,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: AppColors.primaryBackground,
                    size: buttonSize * 1.4,
                  ),
                  tooltip: isPlaying ? 'Pausar' : 'Reproducir',
                  onPressed: onPlayPause,
                ),
        ),

        // Botón Siguiente
        IconButton(
          icon: Icon(
            Icons.skip_next_rounded,
            color: AppColors.iconActive,
            size: buttonSize * 1.25,
          ),
          tooltip: 'Siguiente canción',
          onPressed: onNext,
        ),

        // Botón Repetición
        IconButton(
          icon: Icon(
            loopMode == AppLoopMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color: loopMode != AppLoopMode.off
                ? AppColors.textPrimary
                : AppColors.iconMuted,
            size: buttonSize * 0.85,
          ),
          tooltip: switch (loopMode) {
            AppLoopMode.off => 'Repetición desactivada',
            AppLoopMode.one => 'Repetir canción actual',
            AppLoopMode.all => 'Repetir toda la lista',
          },
          onPressed: onCycleLoop,
        ),
      ],
    );
  }
}
