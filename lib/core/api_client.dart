import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'config.dart';
import 'api_exceptions.dart';
import '../state/auth_notifier.dart';

Dio buildDio({required AuthNotifier authNotifier}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = authNotifier.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('🌐 [API REQ] ${options.method} -> ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final status = response.statusCode ?? 0;
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final path = error.requestOptions.path;


        if (status == 401 && !path.contains('/auth/')) {
          final success = await authNotifier.refreshTokens();
          if (success) {
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer ${authNotifier.accessToken}';
            try {
              final cloneReq = await dio.fetch(opts);
              return handler.resolve(cloneReq);
            } catch (_) {}
          }
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
}