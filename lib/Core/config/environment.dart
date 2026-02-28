//configuración de la aplicación, como URLs base, rutas de API, y tiempos de espera para las solicitudes HTTP.
class Environment {
  static const String baseUrl = 'https://ape-hardy-monkey.ngrok-free.app';
  static const String apiVersion = 'v1';
  static const String apiBasePath = '/api/$apiVersion';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
