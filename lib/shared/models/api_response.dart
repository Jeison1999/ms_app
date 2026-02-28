// Está clase se utiliza para representar la respuesta de una API, encapsulando los datos, el mensaje y el estado de éxito de la respuesta.
class ApiResponse<T> {
  final T? data;
  final String? message;
  final bool success;

  ApiResponse({this.data, this.message, this.success = true});

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(data: data, message: message, success: true);
  }

  factory ApiResponse.error(String message) {
    return ApiResponse(message: message, success: false);
  }
}
