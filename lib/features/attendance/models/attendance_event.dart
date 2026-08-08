class AttendanceRecord {
  final int? id;
  final int personId;
  final String fullName;
  final String? code;
  final String? phone;
  final String status; // pending | present | absent | excused | late
  final String? notes;

  AttendanceRecord({
    this.id,
    required this.personId,
    required this.fullName,
    this.code,
    this.phone,
    this.status = 'pending',
    this.notes,
  });

  AttendanceRecord copyWith({
    String? status,
    String? notes,
  }) {
    return AttendanceRecord(
      id: id,
      personId: personId,
      fullName: fullName,
      code: code,
      phone: phone,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final person = json['person'];
    Map<String, dynamic>? personMap;
    if (person is Map) {
      personMap = Map<String, dynamic>.from(person);
    }

    final fullName = (json['full_name'] as String?) ??
        (personMap?['full_name'] as String?) ??
        [
          personMap?['first_name'],
          personMap?['last_name'],
        ].whereType<String>().join(' ').trim();

    return AttendanceRecord(
      id: (json['id'] as num?)?.toInt(),
      personId: (json['person_id'] as num?)?.toInt() ??
          (personMap?['id'] as num?)?.toInt() ??
          0,
      fullName: fullName.isEmpty ? 'Persona' : fullName,
      code: json['code']?.toString() ?? personMap?['code']?.toString(),
      phone: json['phone']?.toString() ?? personMap?['phone']?.toString(),
      status: (json['status'] as String?) ?? 'pending',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'person_id': personId,
      'status': status,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    };
  }
}

class AttendanceEvent {
  final int id;
  final String title;
  final String eventType; // worship | meeting | other
  final DateTime? scheduledAt;
  final String status; // open | closed
  final int? attendanceGroupId;
  final String? groupName;
  final List<AttendanceRecord> records;
  final int? recordsCount;

  AttendanceEvent({
    required this.id,
    required this.title,
    this.eventType = 'worship',
    this.scheduledAt,
    this.status = 'open',
    this.attendanceGroupId,
    this.groupName,
    this.records = const [],
    this.recordsCount,
  });

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';

  factory AttendanceEvent.fromJson(Map<String, dynamic> json) {
    final group = json['attendance_group'] ?? json['group'];
    Map<String, dynamic>? groupMap;
    if (group is Map) {
      groupMap = Map<String, dynamic>.from(group);
    }

    final records = (json['records'] as List? ?? json['attendance_records'] as List? ?? [])
        .whereType<Map>()
        .map((e) => AttendanceRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    DateTime? scheduled;
    final raw = json['scheduled_at'];
    if (raw != null) {
      scheduled = DateTime.tryParse(raw.toString());
    }

    return AttendanceEvent(
      id: (json['id'] as num).toInt(),
      title: (json['title'] as String?) ?? '',
      eventType: (json['event_type'] as String?) ?? 'worship',
      scheduledAt: scheduled,
      status: (json['status'] as String?) ?? 'open',
      attendanceGroupId: (json['attendance_group_id'] as num?)?.toInt() ??
          (groupMap?['id'] as num?)?.toInt(),
      groupName: (json['group_name'] as String?) ??
          (groupMap?['name'] as String?),
      records: records,
      recordsCount: (json['records_count'] as num?)?.toInt(),
    );
  }
}

class AttendanceLabels {
  static const eventTypes = <String, String>{
    'worship': 'Culto',
    'meeting': 'Reunión',
    'other': 'Otro',
  };

  static const eventStatuses = <String, String>{
    'open': 'Abierto',
    'closed': 'Cerrado',
  };

  static const recordStatuses = <String, String>{
    'pending': 'Pendiente',
    'present': 'Presente',
    'absent': 'Ausente',
    'excused': 'Excusado',
    'late': 'Tarde',
  };
}
