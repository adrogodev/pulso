import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/open_with/data/data_sources/opened_audio_channel.dart';
import 'package:pulso/features/open_with/domain/models/opened_audio.dart';
import 'package:pulso/features/open_with/presentation/widgets/opened_audio_listener.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_notifier.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_state.dart';
import 'package:pulso/features/playback/presentation/screens/expanded_player_screen.dart';
import 'package:pulso/shared/base_data/audio/audio_player_service.dart';
import 'package:pulso/shared/base_domain/models/track.dart';

/// Canal en memoria: entrega los audios en orden y deja disparar el aviso.
class _FakeChannel implements OpenedAudioChannel {
  _FakeChannel(this.pending);

  final List<OpenedAudio> pending;
  void Function()? notify;

  @override
  Future<OpenedAudio?> take() async =>
      pending.isEmpty ? null : pending.removeAt(0);

  @override
  void onAvailable(void Function() callback) => notify = callback;
}

class _FakePlaybackNotifier extends PlaybackNotifier {
  final List<Track> played = [];

  @override
  PlaybackState build() => const PlaybackState();

  @override
  Future<void> playTrack(Track track, {List<Track>? inQueue}) async {
    played.add(track);
    state = state.copyWith(
      currentTrack: track,
      queue: [track],
      status: AppPlayerStatus.playing,
    );
  }
}

void main() {
  late _FakeChannel channel;
  late _FakePlaybackNotifier playback;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          openedAudioChannelProvider.overrideWithValue(channel),
          playbackNotifierProvider.overrideWith(() => playback),
        ],
        child: const MaterialApp(
          home: OpenedAudioListener(child: Text('inicio')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => playback = _FakePlaybackNotifier());

  testWidgets('al abrir Pulso con un audio, lo reproduce y muestra la vista', (
    tester,
  ) async {
    channel = _FakeChannel([
      const OpenedAudio(uri: 'content://a/1', displayName: 'Nota.ogg'),
    ]);

    await pumpApp(tester);

    expect(playback.played.single.uri, 'content://a/1');
    expect(playback.played.single.title, 'Nota');
    expect(find.byType(ExpandedPlayerScreen), findsOneWidget);
  });

  testWidgets('si se abrió normal, no reproduce nada', (tester) async {
    channel = _FakeChannel([]);

    await pumpApp(tester);

    expect(playback.played, isEmpty);
    expect(find.text('inicio'), findsOneWidget);
  });

  testWidgets('con la app abierta, reproduce el audio que llega después', (
    tester,
  ) async {
    channel = _FakeChannel([]);
    await pumpApp(tester);

    channel.pending.add(const OpenedAudio(uri: 'file:///sdcard/b.mp3'));
    channel.notify!();
    await tester.pumpAndSettle();

    expect(playback.played.single.uri, 'file:///sdcard/b.mp3');
    expect(find.byType(ExpandedPlayerScreen), findsOneWidget);
  });
}
