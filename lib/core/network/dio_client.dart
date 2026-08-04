import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../env/app_env.dart';

/// Centralized Dio instance. All networking in the app goes through this
/// client so timeouts, headers, logging and (future) certificate pinning /
/// token refresh live in exactly one place.
class DioClient {
  DioClient._();

  static Dio? _instance;

  static Dio get instance {
    final existing = _instance;
    if (existing != null) return existing;

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
        // HTTPS only — the WooCommerce base URL is expected to already be
        // https://; requests are rejected otherwise via the interceptor below.
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.baseUrl.isNotEmpty && !options.baseUrl.startsWith('https://')) {
            handler.reject(
              DioException(
                requestOptions: options,
                error: 'Refusing to call a non-HTTPS API endpoint.',
                type: DioExceptionType.badCertificate,
              ),
            );
            return;
          }
          handler.next(options);
        },
      ),
    );

    if (AppEnv.isDebug) {
      dio.interceptors.add(
        PrettyDioLogger(requestHeader: true, requestBody: true, responseBody: true, compact: true),
      );
    }

    _instance = dio;
    return dio;
  }
}
