import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/shared/ui_kit/theme/app_colors.dart';
import 'package:pulso/shared/ui_kit/theme/app_typography.dart';

import '../controllers/equalizer_notifier.dart';
import '../widgets/equalizer_band_slider.dart';

/// Pantalla del ecualizador: activación, una banda por slider y restablecer.
class EqualizerScreen extends ConsumerStatefulWidget {
  const EqualizerScreen({super.key});

  @override
  ConsumerState<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends ConsumerState<EqualizerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(equalizerNotifierProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(equalizerNotifierProvider);
    final notifier = ref.read(equalizerNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('ECUALIZADOR', style: AppTypography.titleMedium),
      ),
      body: _buildBody(state, notifier),
    );
  }

  Widget _buildBody(EqualizerState state, EqualizerNotifier notifier) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    if (!state.isSupported) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'El ecualizador no está disponible en este dispositivo',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.accent,
          title: const Text(
            'Activar ecualizador',
            style: AppTypography.bodyLarge,
          ),
          value: state.enabled,
          onChanged: notifier.setEnabled,
        ),
        const Divider(color: AppColors.divider),
        for (final band in state.bands)
          EqualizerBandSlider(
            band: band,
            enabled: state.enabled,
            onChanged: (db) => notifier.setBandGain(band.index, db),
            onChangeEnd: notifier.commitGains,
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: notifier.reset,
            child: const Text('Restablecer'),
          ),
        ),
      ],
    );
  }
}
