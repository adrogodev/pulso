import '../../../../core/result/result.dart';
import '../../../../entities/artist/artist.dart';
import '../repositories/audio_library_repository.dart';

class GetArtistsUseCase {
  final AudioLibraryRepository _repository;

  const GetArtistsUseCase(this._repository);

  Future<Result<List<Artist>>> call({bool refresh = false}) {
    return _repository.getArtists(refresh: refresh);
  }
}
