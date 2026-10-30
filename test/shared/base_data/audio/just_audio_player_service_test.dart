import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pulso/shared/base_data/audio/just_audio_player_service.dart';

void main() {
  group('JustAudioPlayerService.reachedEnd', () {
    final start = DateTime(2026, 10, 30, 8);
    const duration = Duration(seconds: 25);

    PlaybackEvent eventAt(Duration position) => PlaybackEvent(
      updatePosition: position,
      updateTime: start,
      duration: duration,
      currentIndex: 1,
    );

    test('treats a track that played to its duration as ended', () {
      final ended = JustAudioPlayerService.reachedEnd(
        previous: eventAt(const Duration(seconds: 20)),
        at: start.add(const Duration(seconds: 5)),
        duration: duration,
        playing: true,
      );

      expect(ended, isTrue);
    });

    test('treats a skip in the middle of the track as not ended', () {
      final ended = JustAudioPlayerService.reachedEnd(
        previous: eventAt(const Duration(seconds: 5)),
        at: start.add(const Duration(seconds: 3)),
        duration: duration,
        playing: true,
      );

      expect(ended, isFalse);
    });

    test('treats a skip while paused as not ended', () {
      final ended = JustAudioPlayerService.reachedEnd(
        previous: eventAt(const Duration(seconds: 5)),
        at: start.add(const Duration(minutes: 10)),
        duration: duration,
        playing: false,
      );

      expect(ended, isFalse);
    });

    test('assumes the end when the duration is unknown', () {
      final ended = JustAudioPlayerService.reachedEnd(
        previous: eventAt(Duration.zero),
        at: start,
        duration: null,
        playing: true,
      );

      expect(ended, isTrue);
    });
  });
}
