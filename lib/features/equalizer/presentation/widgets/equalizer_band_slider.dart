import 'package:flutter/material.dart';
import 'package:pulso/shared/ui_kit/theme/app_colors.dart';
import 'package:pulso/shared/ui_kit/theme/app_typography.dart';

import '../../domain/models/equalizer_band.dart';

/// Fila con la frecuencia, el slider y la ganancia de una banda.
class EqualizerBandSlider extends StatelessWidget {
  final EqualizerBand band;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final VoidCallback onChangeEnd;

  const EqualizerBandSlider({
    super.key,
    required this.band,
    required this.enabled,
    required this.onChanged,
    required this.onChangeEnd,
  });

  /// Formatea la frecuencia central: '60 Hz', '1 kHz', '3.6 kHz'.
  static String formatFrequency(double hz) {
    if (hz < 1000) return '${hz.round()} Hz';
    final khz = hz / 1000;
    final text = khz == khz.roundToDouble()
        ? khz.round().toString()
        : khz.toStringAsFixed(1);
    return '$text kHz';
  }

  /// Formatea la ganancia con signo: '+3 dB', '-2.5 dB', '0 dB'.
  static String formatGain(double db) {
    final rounded = (db * 10).round() / 10;
    final text = rounded == rounded.roundToDouble()
        ? rounded.round().toString()
        : rounded.toStringAsFixed(1);
    return rounded > 0 ? '+$text dB' : '$text dB';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            formatFrequency(band.centerHz),
            style: AppTypography.bodyLarge,
          ),
        ),
        Expanded(
          child: Slider(
            value: band.gainDb.clamp(band.minDb, band.maxDb),
            min: band.minDb,
            max: band.maxDb,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.border,
            onChanged: enabled ? onChanged : null,
            onChangeEnd: enabled ? (_) => onChangeEnd() : null,
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(
            formatGain(band.gainDb),
            textAlign: TextAlign.end,
            style: AppTypography.bodyMedium,
          ),
        ),
      ],
    );
  }
}
