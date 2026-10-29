import '../../../../shared/base_domain/result/result.dart';
import '../../../../shared/base_domain/models/album.dart';
import '../services/audio_library_repository.dart';

class GetAlbumsUseCase {
  final AudioLibraryRepository _repository;

  const GetAlbumsUseCase(this._repository);

  Future<Result<List<Album>>> call({bool refresh = false}) {
    return _repository.getAlbums(refresh: refresh);
  }
}
