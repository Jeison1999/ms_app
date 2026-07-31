import 'package:dio/dio.dart';
import '../config/environment.dart';
import 'api_interceptors.dart';

// ApiClient es una clase que encapsula la lógica de comunicación con la API utilizando Dio.
class ApiClient {
  late final Dio _dio;

  ApiClient({required Future<String?> Function() getToken}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: Environment.baseUrl,
        connectTimeout: Environment.connectTimeout,
        receiveTimeout: Environment.receiveTimeout,
        sendTimeout: Environment.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Agregar interceptores
    _dio.interceptors.addAll([
      AuthInterceptor(getToken: getToken),
      LoggingInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Manejo de errores centralizado
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Tiempo de conexión agotado',
          statusCode: 408,
        );
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        String message = 'Error del servidor';
        if (data is Map) {
          if (data['details'] is List && (data['details'] as List).isNotEmpty) {
            message = (data['details'] as List).join('\n');
          } else {
            message =
                data['error']?.toString() ??
                data['message']?.toString() ??
                message;
          }
        }
        return ApiException(
          message: message,
          statusCode: error.response?.statusCode ?? 500,
        );
      case DioExceptionType.cancel:
        return ApiException(message: 'Solicitud cancelada');
      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          return ApiException(
            message: 'No hay conexión a internet',
            statusCode: 0,
          );
        }
        return ApiException(message: 'Error desconocido: ${error.message}');
      default:
        return ApiException(message: 'Error inesperado');
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;
}
