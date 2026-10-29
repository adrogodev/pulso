import '../../../../shared/base_domain/result/result.dart';
import '../../../../shared/base_domain/models/artist.dart';
import '../services/audio_library_repository.dart';

class GetArtistsUseCase {
  final AudioLibraryRepository _repository;

  const GetArtistsUseCase(this._repository);

  Future<Result<List<Artist>>> call({bool refresh = false}) {
    return _repository.getArtists(refresh: refresh);
  }
}
