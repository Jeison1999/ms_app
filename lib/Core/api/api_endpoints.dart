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

  // Content endpoints (Submodulo de marketing)
  static const String contentBase = '$_base/content';

  // Events endpoints
  static const String events = '$contentBase/events';
  static const String upcomingEvents = '$events/upcoming';
  static const String recentPastEvents = '$events/recent_past';

  // Announcements endpoints
  static const String announcements = '$contentBase/announcements';
  static const String activeAnnouncements = '$announcements/active';

  static String eventById(int id) => '$events/$id';
  static String announcementById(int id) => '$announcements/$id';

  // Users endpoints
  static const String usersBase = '$_base/users';

  // People endpoints (Submodulo de consolidación)
  static const String people = '$_base/people';
  static String personById(int id) => '$people/$id';
  static String reactivatePerson(int id) => '$people/$id/reactivate';
  static String personQr(int id) => '$people/$id/qr';
  static const String peopleBirthdaysToday = '$people/birthdays/today';
  static const String peopleBirthdaysMonth = '$people/birthdays/month';
  static const String peopleFilterOptions = '$people/filter_options';
  static const String peopleExport = '$people/export';

  // Custom fields endpoints (campos dinámicos de personas)
  static const String customFields = '$_base/custom_fields';
  static String customFieldById(int id) => '$customFields/$id';
  static String reactivateCustomField(int id) =>
      '$customFields/$id/reactivate';

  // Attendance endpoints (solo administrator)
  static const String attendanceBase = '$_base/attendance';
  static const String attendanceGroups = '$attendanceBase/groups';
  static String attendanceGroupById(int id) => '$attendanceGroups/$id';
  static String attendanceGroupAddMembers(int id) =>
      '$attendanceGroups/$id/add_members';
  static String attendanceGroupRemoveMembers(int id) =>
      '$attendanceGroups/$id/remove_members';
  static const String attendanceEvents = '$attendanceBase/events';
  static String attendanceEventById(int id) => '$attendanceEvents/$id';
  static String attendanceEventRecords(int id) =>
      '$attendanceEvents/$id/records';
  static String attendanceEventClose(int id) =>
      '$attendanceEvents/$id/close';
  static const String attendanceAbsencesReport =
      '$attendanceBase/reports/absences';
  static const String attendanceAbsencesExport =
      '$attendanceBase/reports/absences/export';

  // Sales endpoints
  static const String salesBase = '$_base/sales';
  static const String debtors = '$salesBase/debtors';

  // Accounting endpoints
  static const String accountingBase = '$_base/accounting';
  static const String transactions = '$accountingBase/transactions';
  static const String offerings = '$accountingBase/offerings';
  static const String reports = '$accountingBase/reports';
}
