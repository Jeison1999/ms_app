class PersonPortalModel {
  final int? id;
  final bool enabled;
  final String? slug;
  final String title;
  final String? description;
  final bool allowRegister;
  final bool allowUpdate;
  final DateTime? autoEnabledAt;
  final String? autoEnabledReason;
  final int publicCustomFieldsCount;
  final int pendingRegistrationsCount;
  final DateTime? updatedAt;

  PersonPortalModel({
    this.id,
    required this.enabled,
    this.slug,
    required this.title,
    this.description,
    required this.allowRegister,
    required this.allowUpdate,
    this.autoEnabledAt,
    this.autoEnabledReason,
    this.publicCustomFieldsCount = 0,
    this.pendingRegistrationsCount = 0,
    this.updatedAt,
  });

  factory PersonPortalModel.fromJson(Map<String, dynamic> json) {
    return PersonPortalModel(
      id: (json['id'] as num?)?.toInt(),
      enabled: json['enabled'] as bool? ?? false,
      slug: json['slug']?.toString(),
      title: (json['title'] as String?) ?? 'Portal de datos',
      description: json['description'] as String?,
      allowRegister: json['allow_register'] as bool? ?? true,
      allowUpdate: json['allow_update'] as bool? ?? true,
      autoEnabledAt: json['auto_enabled_at'] != null
          ? DateTime.tryParse(json['auto_enabled_at'].toString())
          : null,
      autoEnabledReason: json['auto_enabled_reason']?.toString(),
      publicCustomFieldsCount:
          (json['public_custom_fields_count'] as num?)?.toInt() ?? 0,
      pendingRegistrationsCount:
          (json['pending_registrations_count'] as num?)?.toInt() ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'enabled': enabled,
      if (slug != null) 'slug': slug,
      'title': title,
      'description': description,
      'allow_register': allowRegister,
      'allow_update': allowUpdate,
    };
  }

  PersonPortalModel copyWith({
    bool? enabled,
    String? title,
    String? description,
    bool? allowRegister,
    bool? allowUpdate,
    int? pendingRegistrationsCount,
  }) {
    return PersonPortalModel(
      id: id,
      enabled: enabled ?? this.enabled,
      slug: slug,
      title: title ?? this.title,
      description: description ?? this.description,
      allowRegister: allowRegister ?? this.allowRegister,
      allowUpdate: allowUpdate ?? this.allowUpdate,
      autoEnabledAt: autoEnabledAt,
      autoEnabledReason: autoEnabledReason,
      publicCustomFieldsCount: publicCustomFieldsCount,
      pendingRegistrationsCount:
          pendingRegistrationsCount ?? this.pendingRegistrationsCount,
      updatedAt: updatedAt,
    );
  }
}
