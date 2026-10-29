import 'package:flutter/foundation.dart';

import '../error/failures.dart';

/// Tipo de retorno funcional para operaciones que pueden fallar de manera predecible.
@immutable
sealed class Result<T> {
  const Result();

  const factory Result.ok(T data) = Success<T>;
  const factory Result.err(Failure failure) = Err<T>;

  bool get isSuccess => this is Success<T>;
  bool get isError => this is Err<T>;

  T? get dataOrNull => switch (this) {
    Success(data: final d) => d,
    Err() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Success() => null,
    Err(failure: final f) => f,
  };

  R when<R>({
    required R Function(T data) ok,
    required R Function(Failure failure) err,
  }) {
    return switch (this) {
      Success(data: final d) => ok(d),
      Err(failure: final f) => err(f),
    };
  }
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Success<T> && other.data == data);

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Result.ok($data)';
}

final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Err<T> && other.failure == failure);

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Result.err($failure)';
}
