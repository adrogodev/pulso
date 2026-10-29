import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'media_store_datasource.dart';

final mediaStoreDataSourceProvider = Provider<MediaStoreDataSource>((ref) {
  return MediaStoreDataSourceImpl();
});
