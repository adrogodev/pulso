import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/online_search/domain/services/online_music_service.dart';
import 'package:pulso/features/online_search/presentation/controllers/online_search_notifier.dart';
import 'package:pulso/features/online_search/presentation/screens/online_search_screen.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_notifier.dart';
import 'package:pulso/features/playback/presentation/controllers/playback_state.dart';
import 'package:pulso/features/playback/presentation/screens/expanded_player_screen.dart';
import 'package:pulso/features/playback/presentation/widgets/mini_player.dart';
import 'package:pulso/shared/base_data/audio/audio_player_service.dart';
import 'package:pulso/shared/base_domain/error/failures.dart';
import 'package:pulso/shared/base_domain/models/track.dart';
import 'package:pulso/shared/base_domain/result/result.dart';

class _FakeOnlineMusicService implements OnlineMusicService {
  _FakeOnlineMusicService(this.response);

  final Result<List<Track>> response;

  @override
  Future<Result<List<Track>>> searchTracks(String query) async => response;
}

/// Reproducción en memoria que registra qué pistas se mandaron a sonar.
class _FakePlaybackNotifier extends PlaybackNotifier {
  _FakePlaybackNotifier([this.initial = const PlaybackState()]);

  final PlaybackState initial;
  final List<Track> played = [];

  @override
  PlaybackState build() => initial;

  @override
  Future<void> playTrack(Track track, {List<Track>? inQueue}) async {
    played.add(track);
    state = state.copyWith(
      currentTrack: track,
      queue: inQueue ?? [track],
      status: AppPlayerStatus.playing,
    );
  }
}

Widget _app(Result<List<Track>> response, {_FakePlaybackNotifier? playback}) =>
    ProviderScope(
      overrides: [
        onlineMusicServiceProvider.overrideWithValue(
          _FakeOnlineMusicService(response),
        ),
        playbackNotifierProvider.overrideWith(
          () => playback ?? _FakePlaybackNotifier(),
        ),
      ],
      child: const MaterialApp(home: OnlineSearchScreen()),
    );

const _lluvia = Track(
  id: 'audius:abc',
  title: 'Lluvia',
  artist: 'Artista Uno',
  album: 'Audius',
  durationMs: 125000,
  uri: 'https://api.audius.co/v1/tracks/abc/stream?app_name=pulso',
);

const _sol = Track(
  id: 'audius:def',
  title: 'Sol',
  artist: 'Artista Dos',
  album: 'Audius',
  durationMs: 90000,
  uri: 'https://api.audius.co/v1/tracks/def/stream?app_name=pulso',
);

Future<void> _search(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'lluvia');
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
}

void main() {
  group('OnlineSearchScreen reproducción', () {
    testWidgets(
      'al tocar una canción la reproduce y abre la vista en reproducción',
      (tester) async {
        final playback = _FakePlaybackNotifier();
        await tester.pumpWidget(
          _app(const Result.ok([_lluvia, _sol]), playback: playback),
        );
        await _search(tester);

        await tester.tap(find.text('Sol'));
        await tester.pumpAndSettle();

        expect(playback.played, [_sol]);
        expect(find.byType(ExpandedPlayerScreen), findsOneWidget);
      },
    );

    testWidgets('distingue la canción que está sonando', (tester) async {
      final playback = _FakePlaybackNotifier(
        const PlaybackState(
          currentTrack: _lluvia,
          queue: [_lluvia, _sol],
          status: AppPlayerStatus.playing,
        ),
      );
      await tester.pumpWidget(
        _app(const Result.ok([_lluvia, _sol]), playback: playback),
      );
      await _search(tester);

      expect(find.byKey(const ValueKey('sonando-audius:abc')), findsOneWidget);
      expect(find.byKey(const ValueKey('sonando-audius:def')), findsNothing);
    });

    testWidgets('tocar la que ya suena abre su vista sin reiniciarla', (
      tester,
    ) async {
      final playback = _FakePlaybackNotifier(
        const PlaybackState(
          currentTrack: _lluvia,
          queue: [_lluvia, _sol],
          status: AppPlayerStatus.playing,
        ),
      );
      await tester.pumpWidget(
        _app(const Result.ok([_lluvia, _sol]), playback: playback),
      );
      await _search(tester);

      await tester.tap(find.text('Lluvia').first);
      await tester.pumpAndSettle();

      expect(playback.played, isEmpty);
      expect(find.byType(ExpandedPlayerScreen), findsOneWidget);
    });

    testWidgets('muestra el mini reproductor y abre la vista al tocarlo', (
      tester,
    ) async {
      final playback = _FakePlaybackNotifier(
        const PlaybackState(
          currentTrack: _lluvia,
          queue: [_lluvia],
          status: AppPlayerStatus.playing,
        ),
      );
      await tester.pumpWidget(_app(const Result.ok([]), playback: playback));

      expect(find.byType(MiniPlayer), findsOneWidget);

      await tester.tap(find.text('Artista Uno'));
      await tester.pumpAndSettle();

      expect(find.byType(ExpandedPlayerScreen), findsOneWidget);
    });
  });

  group('OnlineSearchScreen Widget', () {
    testWidgets('muestra el estado inicial antes de buscar', (tester) async {
      await tester.pumpWidget(_app(const Result.ok([])));

      expect(find.text('Busca música libre en Audius'), findsOneWidget);
    });

    testWidgets('lista los resultados al enviar la búsqueda', (tester) async {
      await tester.pumpWidget(
        _app(
          const Result.ok([
            Track(
              id: 'audius:abc',
              title: 'Lluvia',
              artist: 'Artista Uno',
              album: 'Audius',
              durationMs: 125000,
              uri: 'https://api.audius.co/v1/tracks/abc/stream?app_name=pulso',
            ),
          ]),
        ),
      );

      await tester.enterText(find.byType(TextField), 'lluvia');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('Lluvia'), findsOneWidget);
      expect(find.textContaining('Artista Uno'), findsOneWidget);
    });

    testWidgets('muestra el mensaje de error de red', (tester) async {
      await tester.pumpWidget(
        _app(const Result.err(NetworkFailure('Sin conexión a internet'))),
      );

      await tester.enterText(find.byType(TextField), 'lluvia');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('Sin conexión a internet'), findsOneWidget);
    });

    testWidgets('avisa cuando no hay resultados', (tester) async {
      await tester.pumpWidget(_app(const Result.ok([])));

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('Sin resultados para "zzzz"'), findsOneWidget);
    });
  });
}
