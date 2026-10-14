import '../../../../core/result/result.dart';
import '../../../../entities/album/album.dart';
import '../repositories/audio_library_repository.dart';

class GetAlbumsUseCase {
  final AudioLibraryRepository _repository;

  const GetAlbumsUseCase(this._repository);

  Future<Result<List<Album>>> call({bool refresh = false}) {
    return _repository.getAlbums(refresh: refresh);
  }
}
