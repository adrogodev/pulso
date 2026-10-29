import '../../../../shared/base_domain/result/result.dart';
import '../../../../shared/base_domain/models/track.dart';
import '../services/audio_library_repository.dart';

class GetTracksUseCase {
  final AudioLibraryRepository _repository;

  const GetTracksUseCase(this._repository);

  Future<Result<List<Track>>> call({bool refresh = false}) {
    return _repository.getTracks(refresh: refresh);
  }
}
