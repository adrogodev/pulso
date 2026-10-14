import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/core/error/failures.dart';
import 'package:pulso/core/permissions/permission_service.dart';
import 'package:pulso/core/result/result.dart';
import 'package:pulso/entities/album/album.dart';
import 'package:pulso/entities/artist/artist.dart';
import 'package:pulso/entities/track/track.dart';
import 'package:pulso/features/library/domain/repositories/audio_library_repository.dart';
import 'package:pulso/features/library/domain/usecases/sort_tracks_usecase.dart';
import 'package:pulso/features/library/presentation/providers/library_notifier.dart';

class MockPermissionService implements PermissionService {
  bool hasPermission = true;
  bool requestGranted = true;

  @override
  Future<Result<bool>> hasAudioPermission() async => Result.ok(hasPermission);

  @override
  Future<Result<bool>> requestAudioPermission() async {
    if (requestGranted) {
      return const Result.ok(true);
    }
    return const Result.err(PermissionFailure('Permiso denegado'));
  }

  @override
  Future<bool> openSettings() async => true;
}

class MockAudioLibraryRepository implements AudioLibraryRepository {
  List<Track> mockTracks = [];
  bool shouldFail = false;

  @override
  Future<Result<List<Track>>> getTracks({bool refresh = false}) async {
    if (shouldFail) {
      return const Result.err(AudioScanFailure('Fallo al escanear'));
    }
    return Result.ok(mockTracks);
  }

  @override
  Future<Result<List<Album>>> getAlbums({bool refresh = false}) async {
    return const Result.ok([]);
  }

  @override
  Future<Result<List<Artist>>> getArtists({bool refresh = false}) async {
    return const Result.ok([]);
  }

  @override
  Future<Result<Track?>> getTrackById(String id) async => const Result.ok(null);

  @override
  Future<Result<List<Track>>> getTracksByAlbum(String albumName) async =>
      const Result.ok([]);

  @override
  Future<Result<List<Track>>> getTracksByArtist(String artistName) async =>
      const Result.ok([]);
}

void main() {
  group('LibraryNotifier', () {
    late MockPermissionService mockPermissionService;
    late MockAudioLibraryRepository mockRepository;
    late ProviderContainer container;

    const sampleTrack1 = Track(
      id: '1',
      title: 'Boreal',
      artist: 'Pulso',
      album: 'Norte',
      durationMs: 200000,
      uri: 'uri/1',
    );
    const sampleTrack2 = Track(
      id: '2',
      title: 'Austral',
      artist: 'Pulso',
      album: 'Sur',
      durationMs: 180000,
      uri: 'uri/2',
    );

    setUp(() {
      mockPermissionService = MockPermissionService();
      mockRepository = MockAudioLibraryRepository()
        ..mockTracks = [sampleTrack1, sampleTrack2];

      container = ProviderContainer(
        overrides: [
          permissionServiceProvider.overrideWithValue(mockPermissionService),
          audioLibraryRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('estado inicial tiene valores por defecto', () {
      final state = container.read(libraryNotifierProvider);
      expect(state.tracks, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.hasPermission, isFalse);
      expect(state.errorMessage, isNull);
    });

    test(
      'checkPermissionsAndLoad carga las pistas cuando hay permiso',
      () async {
        final notifier = container.read(libraryNotifierProvider.notifier);
        await notifier.checkPermissionsAndLoad();

        final state = container.read(libraryNotifierProvider);
        expect(state.hasPermission, isTrue);
        expect(state.tracks.length, 2);
        expect(state.isLoading, isFalse);
        expect(state.errorMessage, isNull);
      },
    );

    test('maneja error cuando la carga de biblioteca falla', () async {
      mockRepository.shouldFail = true;

      final notifier = container.read(libraryNotifierProvider.notifier);
      await notifier.checkPermissionsAndLoad();

      final state = container.read(libraryNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, contains('Fallo al escanear'));
    });

    test('actualiza ordenación y orden en LibraryState', () async {
      final notifier = container.read(libraryNotifierProvider.notifier);
      await notifier.checkPermissionsAndLoad();

      notifier.setSortCriteria(TrackSortCriteria.duration);
      expect(
        container.read(libraryNotifierProvider).sortCriteria,
        TrackSortCriteria.duration,
      );

      notifier.toggleSortOrder();
      expect(
        container.read(libraryNotifierProvider).sortOrder,
        SortOrder.descending,
      );
    });
  });
}
