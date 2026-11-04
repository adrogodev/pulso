import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/base_domain/models/track.dart';
import '../controllers/playback_notifier.dart';
import '../screens/expanded_player_screen.dart';

/// Abre la vista En reproducción.
void openNowPlaying(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const ExpandedPlayerScreen()),
  );
}

/// Responde al toque de una canción en una lista.
///
/// Si ya es la que suena, abre la vista En reproducción en lugar de
/// reiniciarla; si no, la reproduce con [queue] como cola (o la suma a la
/// cola que el usuario arma a mano, ver [PlaybackNotifier.playFromList]).
void playOrOpenNowPlaying(
  BuildContext context,
  WidgetRef ref,
  Track track, {
  required List<Track> queue,
}) {
  final current = ref.read(playbackNotifierProvider).currentTrack;
  if (current?.id == track.id) {
    openNowPlaying(context);
    return;
  }
  unawaited(
    ref.read(playbackNotifierProvider.notifier).playFromList(track, queue),
  );
}
