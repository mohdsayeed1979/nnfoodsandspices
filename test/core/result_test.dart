import 'package:flutter_test/flutter_test.dart';
import 'package:nn_food_spices/core/error/result.dart';

void main() {
  group('Result', () {
    test('success wraps data and reports isSuccess', () {
      const result = Result<int>.success(42);
      expect(result.isSuccess, isTrue);
      expect(result.when(success: (d) => d, failure: (_) => -1), 42);
    });

    test('failure wraps AppFailure and reports isSuccess false', () {
      final failure = AppFailure.network();
      final result = Result<int>.failure(failure);
      expect(result.isSuccess, isFalse);
      expect(result.when(success: (d) => d, failure: (f) => f.code), 'network');
    });

    test('AppFailure factories set expected codes', () {
      expect(AppFailure.notFound().code, 'not_found');
      expect(AppFailure.unauthorized().code, 'unauthorized');
      expect(AppFailure.server().code, 'server');
      expect(AppFailure.unknown().code, 'unknown');
    });
  });
}
