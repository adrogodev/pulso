import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulso/shared/base_domain/error/failures.dart';
import 'package:pulso/shared/base_data/permissions/permission_service.dart';
import 'package:pulso/shared/base_domain/result/result.dart';
import 'package:pulso/shared/base_domain/models/album.dart';
import 'package:pulso/shared/base_domain/models/artist.dart';
import 'package:pulso/shared/base_domain/models/track.dart';
import 'package:pulso/features/library/domain/services/audio_library_repository.dart';
import 'package:pulso/features/library/domain/use_cases/sort_tracks_usecase.dart';
import 'package:pulso/features/library/presentation/controllers/library_notifier.dart';
import 'package:pulso/features/settings/presentation/controllers/settings_notifier.dart';
import 'package:pulso/features/settings/presentation/controllers/settings_state.dart';

class MockPermissionService implements PermissionService {
  bool hasPermission = true;
  bool requestGranted = true;
  int requestCalls = 0;

  @override
  Future<Result<bool>> hasAudioPermission() async => Result.ok(hasPermission);

  @override
  Future<Result<bool>> requestAudioPermission() async {
    requestCalls++;
    if (requestGranted) {
      hasPermission = true;
      return const Result.ok(true);
    }
    return const Result.err(PermissionFailure('Permiso denegado'));
  }

  @override
  Future<bool> openSettings() async => true;
}

/// Preferencias en memoria, sin base de datos.
class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  SettingsState build() => const SettingsState();

  @override
  Future<void> setHideShortClips(bool value) async {
    state = state.copyWith(hideShortClips: value);
  }
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

    test(
      'checkPermissionsAndLoad no vuelve a pedir un permiso ya concedido',
      () async {
        await container
            .read(libraryNotifierProvider.notifier)
            .checkPermissionsAndLoad();

        expect(mockPermissionService.requestCalls, 0);
      },
    );

    test('checkPermissionsAndLoad pide el permiso cuando falta y carga si se concede', () async {
      mockPermissionService.hasPermission = false;

      await container
          .read(libraryNotifierProvider.notifier)
          .checkPermissionsAndLoad();

      final state = container.read(libraryNotifierProvider);
      expect(mockPermissionService.requestCalls, 1);
      expect(state.hasPermission, isTrue);
      expect(state.tracks.length, 2);
      expect(state.isLoading, isFalse);
    });

    test(
      'checkPermissionsAndLoad informa cuando el usuario deniega el permiso',
      () async {
        mockPermissionService
          ..hasPermission = false
          ..requestGranted = false;

        await container
            .read(libraryNotifierProvider.notifier)
            .checkPermissionsAndLoad();

        final state = container.read(libraryNotifierProvider);
        expect(state.hasPermission, isFalse);
        expect(state.tracks, isEmpty);
        expect(state.isLoading, isFalse);
        expect(state.errorMessage, 'Permiso denegado');
      },
    );

    test(
      'refreshLibrary pide el permiso en lugar de escanear sin él',
      () async {
        mockPermissionService.hasPermission = false;
        final notifier = container.read(libraryNotifierProvider.notifier);

        await notifier.refreshLibrary();

        final state = container.read(libraryNotifierProvider);
        expect(mockPermissionService.requestCalls, 1);
        expect(state.hasPermission, isTrue);
        expect(state.tracks.length, 2);
      },
    );

    group('filtro de audios cortos', () {
      const voiceNote = Track(
        id: '9',
        title: 'AUD-20220318-WA0035',
        artist: Track.unknownArtist,
        album: 'WhatsApp Audio',
        durationMs: 3000,
        uri: 'uri/9',
      );
      late _FakeSettingsNotifier settings;

      setUp(() {
        mockRepository.mockTracks = [sampleTrack1, sampleTrack2, voiceNote];
        settings = _FakeSettingsNotifier();
        container.dispose();
        container = ProviderContainer(
          overrides: [
            permissionServiceProvider.overrideWithValue(mockPermissionService),
            audioLibraryRepositoryProvider.overrideWithValue(mockRepository),
            settingsNotifierProvider.overrideWith(() => settings),
          ],
        );
      });

      test('oculta las notas de voz al cargar la biblioteca', () async {
        await container
            .read(libraryNotifierProvider.notifier)
            .checkPermissionsAndLoad();

        final tracks = container.read(libraryNotifierProvider).tracks;
        expect(tracks, [sampleTrack1, sampleTrack2]);
      });

      test(
        'las vuelve a mostrar al desactivar el filtro sin reescanear',
        () async {
          await container
              .read(libraryNotifierProvider.notifier)
              .checkPermissionsAndLoad();

          await settings.setHideShortClips(false);

          final tracks = container.read(libraryNotifierProvider).tracks;
          expect(tracks, containsAll([sampleTrack1, sampleTrack2, voiceNote]));
        },
      );
    });

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
