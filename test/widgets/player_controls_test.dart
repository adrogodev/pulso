import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/core/audio/audio_player_service.dart';
import 'package:pulso/widgets/player_controls/player_controls.dart';
import 'package:pulso/widgets/player_controls/progress_bar.dart';

void main() {
  group('PlayerControls Widget', () {
    testWidgets('renderiza botones y responde a interacción de reproducir', (
      tester,
    ) async {
      var playToggled = false;
      var nextTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              isPlaying: false,
              onPlayPause: () => playToggled = true,
              onNext: () => nextTapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();
      expect(playToggled, isTrue);

      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      await tester.pump();
      expect(nextTapped, isTrue);
    });

    testWidgets('muestra icono de pausa cuando isPlaying es true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlayerControls(isPlaying: true, loopMode: AppLoopMode.one),
          ),
        ),
      );

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.repeat_one_rounded), findsOneWidget);
    });
  });

  group('ProgressBar Widget', () {
    testWidgets('muestra duraciones formateadas correctamente', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressBar(
              position: Duration(seconds: 45),
              duration: Duration(minutes: 3, seconds: 20),
            ),
          ),
        ),
      );

      expect(find.text('00:45'), findsOneWidget);
      expect(find.text('03:20'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });
  });
}
