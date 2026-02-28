import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// Interceptor personalizado para agregar el token de autenticación a cada solicitud.
class AuthInterceptor extends Interceptor {
  final Future<String?> Function() getToken;

  AuthInterceptor({required this.getToken});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('🚀 REQUEST[${options.method}] => PATH: ${options.path}');
      print('Headers: ${options.headers}');
      print('Data: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print(
        '✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
      );
      print('Data: ${response.data}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print(
        '❌ ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
      );
      print('Message: ${err.message}');
      print('Response: ${err.response?.data}');
    }
    handler.next(err);
  }
}
