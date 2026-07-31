import 'package:ms_app/features/consolidator/custom_fields/models/custom_field_model.dart';
import 'package:ms_app/features/consolidator/people/utils/person_text_normalize.dart';

class ExportColumnOption {
  final String key;
  final String label;
  final String source; // fixed | custom_field
  final String? fieldType;
  final bool active;

  ExportColumnOption({
    required this.key,
    required this.label,
    required this.source,
    this.fieldType,
    this.active = true,
  });

  factory ExportColumnOption.fromJson(Map<String, dynamic> json) {
    return ExportColumnOption(
      key: json['key'] as String,
      label: json['label'] as String,
      source: (json['source'] as String?) ?? 'fixed',
      fieldType: json['field_type'] as String?,
      active: json['active'] as bool? ?? true,
    );
  }
}

class BirthdayMonthOption {
  final int value;
  final String label;

  BirthdayMonthOption({required this.value, required this.label});

  factory BirthdayMonthOption.fromJson(Map<String, dynamic> json) {
    return BirthdayMonthOption(
      value: (json['value'] as num).toInt(),
      label: json['label']?.toString() ?? json['value'].toString(),
    );
  }
}

class PeopleFilterOptions {
  final List<String> statuses;
  final List<String> sexes;
  final List<String> documentTypes;
  final List<String> cities;
  final List<BirthdayMonthOption> birthdayMonths;
  final List<String> presenceFilters;
  final List<CustomFieldModel> customFields;
  final List<ExportColumnOption> exportColumns;
  final List<String> defaultExportColumns;

  PeopleFilterOptions({
    required this.statuses,
    required this.sexes,
    required this.documentTypes,
    required this.cities,
    required this.birthdayMonths,
    required this.presenceFilters,
    required this.customFields,
    required this.exportColumns,
    required this.defaultExportColumns,
  });

  factory PeopleFilterOptions.fromJson(Map<String, dynamic> json) {
    final customFields = (json['custom_fields'] as List? ?? [])
        .whereType<Map>()
        .map((e) {
          final map = Map<String, dynamic>.from(e);
          final options = map['options'];
          final normalizedOptions = options is List
              ? _uniqueCustomFieldOptions(options)
              : <Map<String, dynamic>>[];
          return CustomFieldModel.fromJson({
            'id': map['id'],
            'name': map['name'],
            'key': map['key'],
            'field_type': map['field_type'],
            'required': false,
            'active': true,
            'position': 0,
            'options': normalizedOptions,
          });
        })
        .toList();

    return PeopleFilterOptions(
      statuses: PersonTextNormalize.uniqueIgnoreCase(
        json['statuses'] as List? ?? const [],
        canonicalize: (v) => v.toLowerCase(),
      ),
      sexes: PersonTextNormalize.uniqueIgnoreCase(
        json['sexes'] as List? ?? const [],
        canonicalize: (v) => v.toLowerCase(),
      ),
      documentTypes: PersonTextNormalize.uniqueIgnoreCase(
        json['document_types'] as List? ?? const [],
        canonicalize: (v) => v.toUpperCase(),
      ),
      cities: PersonTextNormalize.uniqueIgnoreCase(
        json['cities'] as List? ?? const [],
        canonicalize: PersonTextNormalize.titleCase,
      ),
      birthdayMonths: (json['birthday_months'] as List? ?? [])
          .whereType<Map>()
          .map((e) => BirthdayMonthOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      presenceFilters: PersonTextNormalize.uniqueIgnoreCase(
        json['presence_filters'] as List? ?? const [],
        canonicalize: (v) => v.toLowerCase(),
      ),
      customFields: customFields,
      exportColumns: (json['export_columns'] as List? ?? [])
          .whereType<Map>()
          .map((e) => ExportColumnOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      defaultExportColumns: (json['default_export_columns'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  static List<Map<String, dynamic>> _uniqueCustomFieldOptions(List raw) {
    final seen = <String, Map<String, dynamic>>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final value = PersonTextNormalize.collapseSpaces(
        (map['value'] ?? map['label'] ?? '').toString(),
      );
      if (value.isEmpty) continue;
      final key = value.toLowerCase();
      if (seen.containsKey(key)) continue;
      final label = PersonTextNormalize.collapseSpaces(
        (map['label'] ?? value).toString(),
      );
      seen[key] = {
        ...map,
        'value': value,
        'label': label.isEmpty ? value : label,
      };
    }
    return seen.values.toList();
  }
}
