class AttendanceGroupMember {
  final int id;
  final String fullName;
  final String? code;
  final String? phone;

  AttendanceGroupMember({
    required this.id,
    required this.fullName,
    this.code,
    this.phone,
  });

  factory AttendanceGroupMember.fromJson(Map<String, dynamic> json) {
    final fullName = (json['full_name'] as String?)?.trim();
    final first = (json['first_name'] as String?)?.trim() ?? '';
    final last = (json['last_name'] as String?)?.trim() ?? '';
    return AttendanceGroupMember(
      id: (json['id'] as num?)?.toInt() ??
          (json['person_id'] as num?)?.toInt() ??
          0,
      fullName: (fullName != null && fullName.isNotEmpty)
          ? fullName
          : '$first $last'.trim(),
      code: json['code']?.toString(),
      phone: json['phone']?.toString(),
    );
  }
}

class AttendanceGroup {
  final int id;
  final String name;
  final String? description;
  final int absenceThreshold;
  final String? color;
  final bool active;
  final List<AttendanceGroupMember> members;
  final int? membersCount;

  AttendanceGroup({
    required this.id,
    required this.name,
    this.description,
    this.absenceThreshold = 3,
    this.color,
    this.active = true,
    this.members = const [],
    this.membersCount,
  });

  int get memberCount => membersCount ?? members.length;

  factory AttendanceGroup.fromJson(Map<String, dynamic> json) {
    final membersRaw = json['members'] ?? json['people'];
    final members = (membersRaw as List? ?? [])
        .whereType<Map>()
        .map((e) => AttendanceGroupMember.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return AttendanceGroup(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      absenceThreshold: (json['absence_threshold'] as num?)?.toInt() ?? 3,
      color: json['color']?.toString(),
      active: json['active'] as bool? ?? true,
      members: members,
      membersCount: (json['members_count'] as num?)?.toInt() ??
          (json['people_count'] as num?)?.toInt(),
    );
  }
}
