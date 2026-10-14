import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulso/features/library/presentation/providers/library_notifier.dart';
import 'package:pulso/features/search/domain/models/search_result.dart';
import 'package:pulso/features/search/domain/usecases/search_library_usecase.dart';

import 'search_state.dart';

final searchLibraryUseCaseProvider = Provider<SearchLibraryUseCase>((ref) {
  return const SearchLibraryUseCase();
});

final searchNotifierProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);

class SearchNotifier extends Notifier<SearchState> {
  SearchLibraryUseCase get _searchUseCase =>
      ref.read(searchLibraryUseCaseProvider);

  @override
  SearchState build() {
    return const SearchState();
  }

  void onQueryChanged(String query) {
    if (query.trim().isEmpty) {
      state = state.copyWith(
        query: query,
        result: const SearchResult(),
        isSearching: false,
      );
      return;
    }

    state = state.copyWith(query: query, isSearching: true);

    final libraryState = ref.read(libraryNotifierProvider);
    final results = _searchUseCase(
      query: query,
      tracks: libraryState.tracks,
      albums: libraryState.albums,
      artists: libraryState.artists,
    );

    state = state.copyWith(result: results, isSearching: false);
  }

  void setFilter(SearchFilter filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void clearSearch() {
    state = state.copyWith(
      query: '',
      result: const SearchResult(),
      isSearching: false,
    );
  }
}
