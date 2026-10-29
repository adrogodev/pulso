import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/features/online_search/domain/services/online_music_service.dart';
import 'package:pulso/features/online_search/presentation/controllers/online_search_notifier.dart';
import 'package:pulso/features/online_search/presentation/screens/online_search_screen.dart';
import 'package:pulso/shared/base_domain/error/failures.dart';
import 'package:pulso/shared/base_domain/models/track.dart';
import 'package:pulso/shared/base_domain/result/result.dart';

class _FakeOnlineMusicService implements OnlineMusicService {
  _FakeOnlineMusicService(this.response);

  final Result<List<Track>> response;

  @override
  Future<Result<List<Track>>> searchTracks(String query) async => response;
}

Widget _app(Result<List<Track>> response) => ProviderScope(
  overrides: [
    onlineMusicServiceProvider.overrideWithValue(
      _FakeOnlineMusicService(response),
    ),
  ],
  child: const MaterialApp(home: OnlineSearchScreen()),
);

void main() {
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
