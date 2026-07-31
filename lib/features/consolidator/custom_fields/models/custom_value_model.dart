import 'custom_field_model.dart';

class CustomValueModel {
  final int? id;
  final int customFieldId;
  final dynamic value;
  final CustomFieldModel? customField;

  CustomValueModel({
    this.id,
    required this.customFieldId,
    required this.value,
    this.customField,
  });

  factory CustomValueModel.fromJson(Map<String, dynamic> json) {
    CustomFieldModel? field;
    final rawField = json['custom_field'];
    if (rawField is Map<String, dynamic>) {
      field = CustomFieldModel.fromJson(rawField);
    }

    return CustomValueModel(
      id: json['id'] as int?,
      customFieldId: (json['custom_field_id'] as num).toInt(),
      value: json['value'],
      customField: field,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'custom_field_id': customFieldId,
      'value': value,
    };
  }

  String displayValue() {
    if (value == null) return '—';
    if (value is bool) return value == true ? 'Sí' : 'No';
    if (value is List) {
      final list = (value as List).map((e) => e.toString()).toList();
      if (list.isEmpty) return '—';
      if (customField != null) {
        return list
            .map((v) {
              final opt = customField!.options.where((o) => o.value == v);
              return opt.isEmpty ? v : opt.first.label;
            })
            .join(', ');
      }
      return list.join(', ');
    }
    final str = value.toString();
    if (str.isEmpty) return '—';
    if (customField != null &&
        (customField!.fieldType == 'select' ||
            customField!.fieldType == 'boolean')) {
      final opt = customField!.options.where((o) => o.value == str);
      if (opt.isNotEmpty) return opt.first.label;
      if (customField!.fieldType == 'boolean' ||
          customField!.fieldType == 'checkbox') {
        if (str == 'true' || str == '1') return 'Sí';
        if (str == 'false' || str == '0') return 'No';
      }
    }
    return str;
  }
}
