class PersonRegistrationSummary {
  final String? firstName;
  final String? lastName;
  final String? documentNumber;

  PersonRegistrationSummary({
    this.firstName,
    this.lastName,
    this.documentNumber,
  });

  factory PersonRegistrationSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PersonRegistrationSummary();
    return PersonRegistrationSummary(
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      documentNumber: json['document_number']?.toString(),
    );
  }

  String get displayName {
    final name = [firstName, lastName].whereType<String>().join(' ').trim();
    return name.isEmpty ? 'Sin nombre' : name;
  }
}

class PersonRegistrationDiff {
  final String field;
  final dynamic before;
  final dynamic after;

  PersonRegistrationDiff({
    required this.field,
    this.before,
    this.after,
  });

  factory PersonRegistrationDiff.fromJson(Map<String, dynamic> json) {
    return PersonRegistrationDiff(
      field: json['field']?.toString() ?? '',
      before: json['before'],
      after: json['after'],
    );
  }
}

class PersonRegistrationModel {
  final int id;
  final String kind; // create | update
  final String status; // pending | approved | rejected
  final int? personId;
  final String? personName;
  final String? submitterIp;
  final int? reviewedById;
  final String? reviewedByEmail;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final PersonRegistrationSummary? summary;
  final Map<String, dynamic>? payload;
  final Map<String, dynamic>? currentPerson;
  final List<PersonRegistrationDiff> diff;
  final bool deletable;

  PersonRegistrationModel({
    required this.id,
    required this.kind,
    required this.status,
    this.personId,
    this.personName,
    this.submitterIp,
    this.reviewedById,
    this.reviewedByEmail,
    this.reviewedAt,
    this.rejectionReason,
    this.createdAt,
    this.updatedAt,
    this.summary,
    this.payload,
    this.currentPerson,
    this.diff = const [],
    this.deletable = false,
  });

  bool get isPending => status == 'pending';
  bool get isCreate => kind == 'create';
  bool get isUpdate => kind == 'update';

  String get kindLabel => isCreate ? 'Alta nueva' : 'Actualización';
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'approved':
        return 'Aprobada';
      case 'rejected':
        return 'Rechazada';
      default:
        return status;
    }
  }

  String get listTitle {
    if (personName != null && personName!.trim().isNotEmpty) {
      return personName!;
    }
    return summary?.displayName ?? 'Solicitud #$id';
  }

  factory PersonRegistrationModel.fromJson(Map<String, dynamic> json) {
    final diffRaw = json['diff'] as List? ?? [];
    return PersonRegistrationModel(
      id: (json['id'] as num).toInt(),
      kind: (json['kind'] as String?) ?? 'create',
      status: (json['status'] as String?) ?? 'pending',
      personId: (json['person_id'] as num?)?.toInt(),
      personName: json['person_name']?.toString(),
      submitterIp: json['submitter_ip']?.toString(),
      reviewedById: (json['reviewed_by_id'] as num?)?.toInt(),
      reviewedByEmail: json['reviewed_by_email']?.toString(),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())
          : null,
      rejectionReason: json['rejection_reason']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      summary: PersonRegistrationSummary.fromJson(
        json['summary'] is Map
            ? Map<String, dynamic>.from(json['summary'] as Map)
            : null,
      ),
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : null,
      currentPerson: json['current_person'] is Map
          ? Map<String, dynamic>.from(json['current_person'] as Map)
          : null,
      diff: diffRaw
          .whereType<Map>()
          .map(
            (e) => PersonRegistrationDiff.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      deletable: json['deletable'] as bool? ??
          (json['status'] as String?) == 'rejected',
    );
  }
}

class PersonRegistrationsListResult {
  final List<PersonRegistrationModel> registrations;
  final int total;
  final int pendingCount;

  PersonRegistrationsListResult({
    required this.registrations,
    required this.total,
    required this.pendingCount,
  });
}
