import 'package:flutter/material.dart';

import '../../../../shared/ui_kit/theme/app_colors.dart';
import '../../../../shared/ui_kit/theme/app_typography.dart';
import '../../../../shared/utils/metadata_formatter.dart';

/// Barra de progreso interactiva con búsqueda temporal suave y etiquetas de tiempo.
class ProgressBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration>? onSeek;

  const ProgressBar({
    super.key,
    required this.position,
    required this.duration,
    this.onSeek,
  });

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final maxMs = widget.duration.inMilliseconds.toDouble();
    final currentMs = _dragValue ?? widget.position.inMilliseconds.toDouble();
    final clampedCurrent = (maxMs > 0) ? currentMs.clamp(0.0, maxMs) : 0.0;

    final elapsedStr = MetadataFormatter.formatDurationMs(
      clampedCurrent.round(),
    );
    final totalStr = MetadataFormatter.formatDurationMs(maxMs.round());

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.5,
            activeTrackColor: AppColors.textPrimary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.textPrimary,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: clampedCurrent,
            min: 0.0,
            max: maxMs > 0 ? maxMs : 1.0,
            onChanged: maxMs > 0
                ? (val) {
                    setState(() {
                      _dragValue = val;
                    });
                  }
                : null,
            onChangeEnd: (val) {
              final newPos = Duration(milliseconds: val.round());
              setState(() {
                _dragValue = null;
              });
              widget.onSeek?.call(newPos);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(elapsedStr, style: AppTypography.labelSmall),
              Text(totalStr, style: AppTypography.labelSmall),
            ],
          ),
        ),
      ],
    );
  }
}
