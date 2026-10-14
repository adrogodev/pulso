import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/library/data/datasources/media_store_datasource.dart';

final mediaStoreDataSourceProvider = Provider<MediaStoreDataSource>((ref) {
  return MediaStoreDataSourceImpl();
});
