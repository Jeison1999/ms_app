//configuración de la aplicación, como URLs base, rutas de API, y tiempos de espera para las solicitudes HTTP.
class Environment {
  // Desarrollo local (Rails :3000). En celular físico usa la IP LAN del PC (no localhost).
  // Emulador Android: http://10.0.2.2:3000/
  static const String baseUrl = 'https://api.mstucasa.com/';
  static const String apiVersion = 'v1';
  static const String apiBasePath = '/api/$apiVersion';
  static const String cloudinaryCloudName = 'dsm6diilz';
  static const String cloudinaryUploadPreset = 'ml_default';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
