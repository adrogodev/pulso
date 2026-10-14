import '../../../../core/result/result.dart';
import '../../../../entities/track/track.dart';
import '../repositories/audio_library_repository.dart';

class GetTracksUseCase {
  final AudioLibraryRepository _repository;

  const GetTracksUseCase(this._repository);

  Future<Result<List<Track>>> call({bool refresh = false}) {
    return _repository.getTracks(refresh: refresh);
  }
}
