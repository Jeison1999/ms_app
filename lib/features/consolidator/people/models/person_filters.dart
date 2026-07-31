class PersonFilters {
  String? q;
  String? status;
  String? city;
  String? sex;
  String? documentType;
  int? ageMin;
  int? ageMax;
  int? birthdayMonth;
  bool? hasEmail;
  bool? hasPhone;
  bool? hasDocument;
  bool? hasPhoto;
  bool? hasBirthDate;
  /// key del custom field → String, bool, o List de String
  Map<String, dynamic> customFields;
  bool includeCustomValues;

  PersonFilters({
    this.q,
    this.status = 'active',
    this.city,
    this.sex,
    this.documentType,
    this.ageMin,
    this.ageMax,
    this.birthdayMonth,
    this.hasEmail,
    this.hasPhone,
    this.hasDocument,
    this.hasPhoto,
    this.hasBirthDate,
    Map<String, dynamic>? customFields,
    this.includeCustomValues = false,
  }) : customFields = customFields ?? {};

  PersonFilters copy() {
    return PersonFilters(
      q: q,
      status: status,
      city: city,
      sex: sex,
      documentType: documentType,
      ageMin: ageMin,
      ageMax: ageMax,
      birthdayMonth: birthdayMonth,
      hasEmail: hasEmail,
      hasPhone: hasPhone,
      hasDocument: hasDocument,
      hasPhoto: hasPhoto,
      hasBirthDate: hasBirthDate,
      customFields: Map<String, dynamic>.from(customFields),
      includeCustomValues: includeCustomValues,
    );
  }

  void clearAdvanced({bool keepStatus = true, bool keepQuery = true}) {
    final keptStatus = keepStatus ? status : null;
    final keptQ = keepQuery ? q : null;
    q = keptQ;
    status = keptStatus;
    city = null;
    sex = null;
    documentType = null;
    ageMin = null;
    ageMax = null;
    birthdayMonth = null;
    hasEmail = null;
    hasPhone = null;
    hasDocument = null;
    hasPhoto = null;
    hasBirthDate = null;
    customFields.clear();
  }

  int get advancedCount {
    var n = 0;
    if (city != null && city!.isNotEmpty) n++;
    if (sex != null && sex!.isNotEmpty) n++;
    if (documentType != null && documentType!.isNotEmpty) n++;
    if (ageMin != null) n++;
    if (ageMax != null) n++;
    if (birthdayMonth != null) n++;
    if (hasEmail != null) n++;
    if (hasPhone != null) n++;
    if (hasDocument != null) n++;
    if (hasPhoto != null) n++;
    if (hasBirthDate != null) n++;
    n += customFields.values.where(_hasValue).length;
    return n;
  }

  bool get hasAnyAdvanced => advancedCount > 0;

  /// Query params para GET /people (Dio anida custom_fields[key]).
  Map<String, dynamic> toQueryParameters() {
    final query = <String, dynamic>{};
    void put(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      query[key] = value;
    }

    put('q', q?.trim());
    put('status', status);
    put('city', city);
    put('sex', sex);
    put('document_type', documentType);
    put('age_min', ageMin);
    put('age_max', ageMax);
    put('birthday_month', birthdayMonth);
    put('has_email', hasEmail);
    put('has_phone', hasPhone);
    put('has_document', hasDocument);
    put('has_photo', hasPhoto);
    put('has_birth_date', hasBirthDate);
    if (includeCustomValues) query['include_custom_values'] = true;

    final cf = <String, dynamic>{};
    customFields.forEach((key, value) {
      if (_hasValue(value)) cf[key] = value;
    });
    if (cf.isNotEmpty) query['custom_fields'] = cf;

    return query;
  }

  /// Body filters para POST /people/export
  Map<String, dynamic> toExportFilters() {
    final map = <String, dynamic>{};
    void put(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      map[key] = value;
    }

    put('q', q?.trim());
    put('status', status);
    put('city', city);
    put('sex', sex);
    put('document_type', documentType);
    put('age_min', ageMin);
    put('age_max', ageMax);
    put('birthday_month', birthdayMonth);
    put('has_email', hasEmail);
    put('has_phone', hasPhone);
    put('has_document', hasDocument);
    put('has_photo', hasPhoto);
    put('has_birth_date', hasBirthDate);

    final cf = <String, dynamic>{};
    customFields.forEach((key, value) {
      if (_hasValue(value)) cf[key] = value;
    });
    if (cf.isNotEmpty) map['custom_fields'] = cf;
    return map;
  }

  List<PersonFilterChip> buildChips({
    required String Function(int month) monthLabel,
    required String Function(String key) customFieldLabel,
  }) {
    final chips = <PersonFilterChip>[];

    void add(String id, String label, void Function() clear) {
      chips.add(PersonFilterChip(id: id, label: label, onClear: clear));
    }

    if (status != null && status!.isNotEmpty) {
      add(
        'status',
        status == 'active'
            ? 'Activos'
            : status == 'inactive'
                ? 'Inactivos'
                : status!,
        () => status = null,
      );
    }
    if (city != null && city!.isNotEmpty) {
      add('city', 'Ciudad: $city', () => city = null);
    }
    if (sex != null && sex!.isNotEmpty) {
      add('sex', 'Sexo: $sex', () => sex = null);
    }
    if (documentType != null && documentType!.isNotEmpty) {
      add('document_type', 'Doc: $documentType', () => documentType = null);
    }
    if (ageMin != null || ageMax != null) {
      final label = ageMin != null && ageMax != null
          ? 'Edad $ageMin–$ageMax'
          : ageMin != null
              ? 'Edad ≥ $ageMin'
              : 'Edad ≤ $ageMax';
      add('age', label, () {
        ageMin = null;
        ageMax = null;
      });
    }
    if (birthdayMonth != null) {
      add(
        'birthday_month',
        'Cumpleaños: ${monthLabel(birthdayMonth!)}',
        () => birthdayMonth = null,
      );
    }
    if (hasEmail != null) {
      add(
        'has_email',
        hasEmail! ? 'Con email' : 'Sin email',
        () => hasEmail = null,
      );
    }
    if (hasPhone != null) {
      add(
        'has_phone',
        hasPhone! ? 'Con teléfono' : 'Sin teléfono',
        () => hasPhone = null,
      );
    }
    if (hasDocument != null) {
      add(
        'has_document',
        hasDocument! ? 'Con documento' : 'Sin documento',
        () => hasDocument = null,
      );
    }
    if (hasPhoto != null) {
      add(
        'has_photo',
        hasPhoto! ? 'Con foto' : 'Sin foto',
        () => hasPhoto = null,
      );
    }
    if (hasBirthDate != null) {
      add(
        'has_birth_date',
        hasBirthDate! ? 'Con fecha nac.' : 'Sin fecha nac.',
        () => hasBirthDate = null,
      );
    }

    customFields.forEach((key, value) {
      if (!_hasValue(value)) return;
      final display = value is List
          ? value.join(', ')
          : value is bool
              ? (value ? 'Sí' : 'No')
              : value.toString();
      add(
        'cf:$key',
        '${customFieldLabel(key)}: $display',
        () => customFields.remove(key),
      );
    });

    return chips;
  }

  static bool _hasValue(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is List) return value.isNotEmpty;
    return true;
  }
}

class PersonFilterChip {
  final String id;
  final String label;
  final void Function() onClear;

  PersonFilterChip({
    required this.id,
    required this.label,
    required this.onClear,
  });
}
