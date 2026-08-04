import 'package:flutter/foundation.dart';

/// Lightweight success/failure wrapper used across repositories, avoiding a
/// third-party functional-programming dependency for a single sum type.
@immutable
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(AppFailure failure) = ResultFailure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(AppFailure failure) failure,
  }) {
    final self = this;
    return switch (self) {
      Success<T>() => success(self.data),
      ResultFailure<T>() => failure(self.failure),
    };
  }

  bool get isSuccess => this is Success<T>;
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);
  final AppFailure failure;
}

@immutable
class AppFailure {
  const AppFailure(this.message, {this.code});
  final String message;
  final String? code;

  factory AppFailure.network() =>
      const AppFailure('No internet connection. Please check your network.', code: 'network');

  factory AppFailure.server([String? message]) =>
      AppFailure(message ?? 'Something went wrong on our end. Please try again.', code: 'server');

  factory AppFailure.notFound() => const AppFailure('Not found.', code: 'not_found');

  factory AppFailure.unauthorized() =>
      const AppFailure('Please sign in to continue.', code: 'unauthorized');

  factory AppFailure.unknown([String? message]) =>
      AppFailure(message ?? 'An unexpected error occurred.', code: 'unknown');

  @override
  String toString() => 'AppFailure($code: $message)';
}
