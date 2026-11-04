import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/favorites/presentation/controllers/favorites_notifier.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_notifier.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_state.dart';
import 'package:pulso/features/playback/presentation/screens/expanded_player_screen.dart';
import 'package:pulso/features/playback/presentation/widgets/now_playing_navigation.dart';
import 'package:pulso/shared/base_data/audio/audio_player_service.dart';
import 'package:pulso/shared/base_domain/models/track.dart';

const _sonando = Track(
  id: '1',
  title: 'Sonando',
  artist: 'A',
  album: 'B',
  durationMs: 1000,
  uri: 'uri/1',
);

const _otra = Track(
  id: '2',
  title: 'Otra',
  artist: 'A',
  album: 'B',
  durationMs: 1000,
  uri: 'uri/2',
);

class _FakePlayback extends PlaybackNotifier {
  final List<(Track, List<Track>?)> played = [];

  @override
  PlaybackState build() => const PlaybackState(
    currentTrack: _sonando,
    queue: [_sonando, _otra],
    status: AppPlayerStatus.playing,
  );

  @override
  Future<void> playTrack(Track track, {List<Track>? inQueue}) async {
    played.add((track, inQueue));
  }
}

class _NoFavorites extends FavoritesNotifier {
  @override
  Set<String> build() => {};
}

void main() {
  late _FakePlayback playback;

  Future<void> pumpList(WidgetTester tester) async {
    playback = _FakePlayback();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playbackNotifierProvider.overrideWith(() => playback),
          favoritesNotifierProvider.overrideWith(_NoFavorites.new),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Column(
                children: [
                  for (final track in [_sonando, _otra])
                    ListTile(
                      title: Text(track.title),
                      onTap: () => playOrOpenNowPlaying(
                        context,
                        ref,
                        track,
                        queue: const [_sonando, _otra],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('tocar la que ya suena abre el reproductor sin repetirla', (
    tester,
  ) async {
    await pumpList(tester);

    await tester.tap(find.text('Sonando'));
    await tester.pumpAndSettle();

    expect(playback.played, isEmpty);
    expect(find.byType(ExpandedPlayerScreen), findsOneWidget);
  });

  testWidgets('tocar otra canción la reproduce con la lista como cola', (
    tester,
  ) async {
    await pumpList(tester);

    await tester.tap(find.text('Otra'));
    await tester.pumpAndSettle();

    expect(playback.played.single.$1, _otra);
    expect(playback.played.single.$2, [_sonando, _otra]);
    expect(find.byType(ExpandedPlayerScreen), findsNothing);
  });
}
