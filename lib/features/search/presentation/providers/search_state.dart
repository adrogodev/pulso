import 'package:flutter/foundation.dart';

import '../../domain/models/search_result.dart';

enum SearchFilter { all, tracks, albums, artists }

@immutable
class SearchState {
  final String query;
  final SearchFilter activeFilter;
  final SearchResult result;
  final bool isSearching;

  const SearchState({
    this.query = '',
    this.activeFilter = SearchFilter.all,
    this.result = const SearchResult(),
    this.isSearching = false,
  });

  bool get hasQuery => query.trim().isNotEmpty;

  SearchState copyWith({
    String? query,
    SearchFilter? activeFilter,
    SearchResult? result,
    bool? isSearching,
  }) {
    return SearchState(
      query: query ?? this.query,
      activeFilter: activeFilter ?? this.activeFilter,
      result: result ?? this.result,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}
