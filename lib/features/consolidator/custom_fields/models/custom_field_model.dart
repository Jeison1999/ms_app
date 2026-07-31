class CustomFieldOption {
  final int? id;
  final String label;
  final String value;
  final int position;

  CustomFieldOption({
    this.id,
    required this.label,
    required this.value,
    this.position = 0,
  });

  factory CustomFieldOption.fromJson(Map<String, dynamic> json) {
    return CustomFieldOption(
      id: json['id'] as int?,
      label: (json['label'] ?? json['value'] ?? '').toString(),
      value: (json['value'] ?? json['label'] ?? '').toString(),
      position: (json['position'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'label': label,
      'value': value,
      'position': position,
    };
  }
}

class CustomFieldModel {
  final int id;
  final String name;
  final String key;
  final String fieldType;
  final bool required;
  final bool active;
  final int position;
  final String? helpText;
  final List<CustomFieldOption> options;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomFieldModel({
    required this.id,
    required this.name,
    required this.key,
    required this.fieldType,
    required this.required,
    required this.active,
    this.position = 0,
    this.helpText,
    this.options = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => active;
  bool get needsOptions =>
      fieldType == 'select' || fieldType == 'multi_select';

  static const List<String> supportedTypes = [
    'text',
    'textarea',
    'number',
    'phone',
    'email',
    'date',
    'select',
    'multi_select',
    'boolean',
    'checkbox',
    'file',
    'image',
  ];

  static String typeLabel(String type) {
    switch (type) {
      case 'text':
        return 'Texto corto';
      case 'textarea':
        return 'Texto largo';
      case 'number':
        return 'Número';
      case 'phone':
        return 'Teléfono';
      case 'email':
        return 'Email';
      case 'date':
        return 'Fecha';
      case 'select':
        return 'Selección única';
      case 'multi_select':
        return 'Selección múltiple';
      case 'boolean':
      case 'checkbox':
        return 'Sí / No';
      case 'file':
        return 'Archivo (URL)';
      case 'image':
        return 'Imagen (URL)';
      default:
        return type;
    }
  }

  factory CustomFieldModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = <CustomFieldOption>[];
    if (rawOptions is List) {
      for (var i = 0; i < rawOptions.length; i++) {
        final item = rawOptions[i];
        if (item is Map<String, dynamic>) {
          options.add(CustomFieldOption.fromJson(item));
        } else if (item is String) {
          options.add(
            CustomFieldOption(label: item, value: item, position: i),
          );
        }
      }
    }

    return CustomFieldModel(
      id: json['id'] as int,
      name: json['name'] as String,
      key: json['key'] as String,
      fieldType: json['field_type'] as String,
      required: json['required'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
      position: json['position'] as int? ?? 0,
      helpText: json['help_text'] as String?,
      options: options,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
