import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../playback/presentation/controllers/playback_notifier.dart';
import '../../../playback/presentation/screens/expanded_player_screen.dart';
import '../../data/data_sources/opened_audio_channel.dart';
import '../../data/mappers/opened_audio_mapper.dart';

final openedAudioChannelProvider = Provider<OpenedAudioChannel>(
  (ref) => OpenedAudioChannel(),
);

/// Reproduce los audios que llegan desde el menú "Abrir con" o "Compartir"
/// de Android, tanto al abrir la app como con la app ya abierta.
class OpenedAudioListener extends ConsumerStatefulWidget {
  const OpenedAudioListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<OpenedAudioListener> createState() =>
      _OpenedAudioListenerState();
}

class _OpenedAudioListenerState extends ConsumerState<OpenedAudioListener> {
  @override
  void initState() {
    super.initState();
    final channel = ref.read(openedAudioChannelProvider);
    channel.onAvailable(_playPending);
    WidgetsBinding.instance.addPostFrameCallback((_) => _playPending());
  }

  Future<void> _playPending() async {
    final channel = ref.read(openedAudioChannelProvider);
    try {
      final audio = await channel.take();
      if (audio == null || !mounted) return;

      final track = trackFromOpenedAudio(audio);
      unawaited(
        ref.read(playbackNotifierProvider.notifier).playFromList(track, [track]),
      );
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ExpandedPlayerScreen()),
      );
    } on MissingPluginException {
      // Fuera de Android no existe el canal nativo.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
