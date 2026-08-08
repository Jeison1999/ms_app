class AbsenceReportPerson {
  final int personId;
  final String fullName;
  final String? code;
  final String? phone;
  final int absenceCount;
  final int threshold;
  final bool flagged;
  final bool needsVisit;
  final List<String> absentDates;

  AbsenceReportPerson({
    required this.personId,
    required this.fullName,
    this.code,
    this.phone,
    required this.absenceCount,
    required this.threshold,
    required this.flagged,
    required this.needsVisit,
    this.absentDates = const [],
  });

  factory AbsenceReportPerson.fromJson(Map<String, dynamic> json) {
    return AbsenceReportPerson(
      personId: (json['person_id'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ??
          0,
      fullName: (json['full_name'] as String?) ?? 'Persona',
      code: json['code']?.toString(),
      phone: json['phone']?.toString(),
      absenceCount: (json['absence_count'] as num?)?.toInt() ?? 0,
      threshold: (json['threshold'] as num?)?.toInt() ?? 3,
      flagged: json['flagged'] as bool? ?? false,
      needsVisit: json['needs_visit'] as bool? ??
          (json['flagged'] as bool? ?? false),
      absentDates: (json['absent_dates'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class AbsenceReportResult {
  final List<AbsenceReportPerson> people;
  final int total;
  final int flaggedCount;
  final int? year;
  final int? month;
  final int? groupId;
  final int? threshold;

  AbsenceReportResult({
    required this.people,
    required this.total,
    required this.flaggedCount,
    this.year,
    this.month,
    this.groupId,
    this.threshold,
  });

  factory AbsenceReportResult.fromJson(Map<String, dynamic> json) {
    final people = (json['people'] as List? ?? [])
        .whereType<Map>()
        .map((e) => AbsenceReportPerson.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return AbsenceReportResult(
      people: people,
      total: (meta['total'] as num?)?.toInt() ?? people.length,
      flaggedCount: (meta['flagged_count'] as num?)?.toInt() ??
          people.where((p) => p.flagged).length,
      year: (meta['year'] as num?)?.toInt() ?? (json['year'] as num?)?.toInt(),
      month:
          (meta['month'] as num?)?.toInt() ?? (json['month'] as num?)?.toInt(),
      groupId: (meta['group_id'] as num?)?.toInt() ??
          (json['group_id'] as num?)?.toInt(),
      threshold: (meta['threshold'] as num?)?.toInt() ??
          (json['threshold'] as num?)?.toInt(),
    );
  }
}
