import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/shared/base_data/artwork/artwork_cache.dart';
import 'package:pulso/shared/ui_kit/widgets/track_artwork.dart';

void main() {
  group('TrackArtwork', () {
    testWidgets(
      'no muestra la carátula anterior mientras carga la de otra pista',
      (tester) async {
        final pending = Completer<Uint8List?>();
        final cache = ArtworkCache(
          loader: (id, type, size) =>
              id == 1 ? Future.value(Uint8List.fromList([1])) : pending.future,
        );

        Widget build(int id) => MaterialApp(
          home: TrackArtwork(id: id, cache: cache),
        );

        await tester.pumpWidget(build(1));
        await tester.pump();
        expect(find.byType(Image), findsOneWidget);

        await tester.pumpWidget(build(2));
        await tester.pump();

        expect(find.byType(Image), findsNothing);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );

    testWidgets('muestra el fallback cuando no hay carátula', (tester) async {
      final cache = ArtworkCache(loader: (id, type, size) async => null);

      await tester.pumpWidget(
        MaterialApp(home: TrackArtwork(id: 1, cache: cache)),
      );
      await tester.pump();

      expect(find.byType(Image), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });
}
