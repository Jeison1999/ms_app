//configuración de la aplicación, como URLs base, rutas de API, y tiempos de espera para las solicitudes HTTP.
class Environment {
  // Desarrollo: Rails en el PC (:3000).
  // Celular Wi‑Fi: el puerto 3000 debe estar publicado en la LAN (0.0.0.0:3000),
  //   no solo en 127.0.0.1. Si solo escucha localhost, la app no llega al backend.
  // Celular USB: adb reverse tcp:3000 tcp:3000 y baseUrl http://127.0.0.1:3000/
  // Emulador Android: http://10.0.2.2:3000/
  static const String baseUrl = 'http://192.168.100.16:3000/';
  static const String apiVersion = 'v1';
  static const String apiBasePath = '/api/$apiVersion';
  static const String cloudinaryCloudName = 'dsm6diilz';
  static const String cloudinaryUploadPreset = 'ml_default';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
