import 'package:dio/dio.dart';
import 'package:forge_gym/app/bootstrap/app_environment.dart';
import 'package:forge_gym/core/constants/app_constants.dart';
import 'package:forge_gym/core/errors/failures.dart';

/// Creates the shared Dio client.
///
/// Cubits and repositories never build their own — they receive this via
/// constructor injection, configured here from [EnvConfig].
Dio createDio(EnvConfig config) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: const {'Accept': 'application/json'},
    ),
  );

  if (config.logNetworkTraffic) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  return dio;
}

/// Maps a [DioException] to a user-friendly domain [Failure].
///
/// Called at the repository boundary so presentation code only ever
/// deals with [Failure]s.
Failure mapDioExceptionToFailure(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        return const UnauthorizedFailure();
      }
      if (statusCode != null && statusCode >= 500) {
        return const ServerFailure();
      }
      return const UnknownFailure();
    case DioExceptionType.badCertificate:
      return const NetworkFailure(
        'Secure connection failed. Please check your connection and try again.',
      );
    case DioExceptionType.cancel:
    case DioExceptionType.unknown:
      return const UnknownFailure();
  }
}
