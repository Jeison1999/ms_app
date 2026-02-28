import '../config/environment.dart';

// ApiEndpoints es una clase que define las rutas de los endpoints de la API de manera centralizada.
class ApiEndpoints {
  static const String _base = Environment.apiBasePath;

  // Auth endpoints
  static const String authBase = '$_base/auth';
  static const String login = '$authBase/login';
  static const String register = '$authBase/register';
  static const String me = '$authBase/me';
  static const String refresh = '$authBase/refresh';

  // Marketing endpoints
  static const String marketingBase = '$_base/marketing';
  static const String events = '$marketingBase/events';
  static const String announcements = '$marketingBase/announcements';

  // Users endpoints
  static const String usersBase = '$_base/users';

  // Sales endpoints
  static const String salesBase = '$_base/sales';
  static const String debtors = '$salesBase/debtors';

  // Accounting endpoints
  static const String accountingBase = '$_base/accounting';
  static const String transactions = '$accountingBase/transactions';
  static const String offerings = '$accountingBase/offerings';
  static const String reports = '$accountingBase/reports';
}
