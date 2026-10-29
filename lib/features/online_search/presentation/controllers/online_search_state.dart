import 'package:flutter/foundation.dart';

import '../../../../shared/base_domain/models/track.dart';

/// Estado inmutable de la búsqueda de música en línea.
@immutable
class OnlineSearchState {
  final String query;
  final List<Track> results;
  final bool isLoading;
  final String? errorMessage;

  /// Distingue el estado inicial de una búsqueda sin resultados.
  final bool hasSearched;

  const OnlineSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.errorMessage,
    this.hasSearched = false,
  });

  OnlineSearchState copyWith({
    String? query,
    List<Track>? results,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? hasSearched,
  }) {
    return OnlineSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }
}
