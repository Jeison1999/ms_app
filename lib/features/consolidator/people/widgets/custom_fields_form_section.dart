import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ms_app/core/services/cloudinary_service.dart';
import 'package:ms_app/features/consolidator/custom_fields/models/custom_field_model.dart';
import 'package:ms_app/features/consolidator/custom_fields/models/custom_value_model.dart';

/// Controla y renderiza campos dinámicos según [CustomFieldModel.fieldType].
class CustomFieldsFormController {
  final List<CustomFieldModel> fields;
  final Map<int, dynamic> values = {};
  final Map<int, TextEditingController> textControllers = {};

  CustomFieldsFormController({
    required this.fields,
    List<CustomValueModel> initialValues = const [],
  }) {
    final initialById = {
      for (final v in initialValues) v.customFieldId: v.value,
    };

    for (final field in fields) {
      final initial = initialById[field.id];
      switch (field.fieldType) {
        case 'boolean':
        case 'checkbox':
          values[field.id] = _asBool(initial) ?? false;
          break;
        case 'multi_select':
          values[field.id] = _asStringList(initial);
          break;
        case 'select':
          values[field.id] = initial?.toString();
          break;
        case 'date':
          values[field.id] = initial?.toString();
          break;
        case 'number':
        case 'text':
        case 'textarea':
        case 'phone':
        case 'email':
        case 'file':
        case 'image':
        default:
          final text = initial?.toString() ?? '';
          textControllers[field.id] = TextEditingController(text: text);
          values[field.id] = text;
          break;
      }
    }
  }

  void dispose() {
    for (final c in textControllers.values) {
      c.dispose();
    }
  }

  bool validate(BuildContext context) {
    for (final field in fields) {
      if (!field.required) continue;
      final value = _currentValue(field);
      final empty = value == null ||
          (value is String && value.trim().isEmpty) ||
          (value is List && value.isEmpty);
      if (empty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${field.name} es obligatorio')),
        );
        return false;
      }
    }
    return true;
  }

  List<Map<String, dynamic>> toPayload() {
    final payload = <Map<String, dynamic>>[];
    for (final field in fields) {
      final value = _currentValue(field);
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      if (value is List && value.isEmpty) continue;
      payload.add({
        'custom_field_id': field.id,
        'value': value,
      });
    }
    return payload;
  }

  dynamic _currentValue(CustomFieldModel field) {
    switch (field.fieldType) {
      case 'boolean':
      case 'checkbox':
      case 'multi_select':
      case 'select':
      case 'date':
        return values[field.id];
      default:
        final text = textControllers[field.id]?.text.trim() ?? '';
        if (field.fieldType == 'number') {
          if (text.isEmpty) return null;
          return num.tryParse(text) ?? text;
        }
        return text;
    }
  }

  static bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value == null) return null;
    final s = value.toString().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes' || s == 'si' || s == 'sí') {
      return true;
    }
    if (s == 'false' || s == '0' || s == 'no') return false;
    return null;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      // Por si el backend manda JSON string
      if (value.startsWith('[') && value.endsWith(']')) {
        return value
            .substring(1, value.length - 1)
            .split(',')
            .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ''))
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [value];
    }
    return [];
  }
}

class CustomFieldsFormSection extends StatefulWidget {
  final CustomFieldsFormController controller;
  final bool enabled;

  const CustomFieldsFormSection({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  State<CustomFieldsFormSection> createState() =>
      _CustomFieldsFormSectionState();
}

class _CustomFieldsFormSectionState extends State<CustomFieldsFormSection> {
  final _picker = ImagePicker();
  final _cloudinary = CloudinaryService();
  final Set<int> _uploading = {};

  Future<void> _pickDate(CustomFieldModel field) async {
    final current = widget.controller.values[field.id]?.toString();
    final initial = current != null ? DateTime.tryParse(current) : null;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 30),
    );
    if (picked == null) return;
    final formatted =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    setState(() => widget.controller.values[field.id] = formatted);
  }

  Future<void> _uploadFile(CustomFieldModel field, {required bool image}) async {
    final picked = image
        ? await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85)
        : await _picker.pickMedia();
    if (picked == null || !mounted) return;

    setState(() => _uploading.add(field.id));
    try {
      final url = await _cloudinary.uploadImage(
        filePath: picked.path,
        fileName: picked.name,
      );
      widget.controller.textControllers[field.id]?.text = url;
      widget.controller.values[field.id] = url;
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading.remove(field.id));
    }
  }

  InputDecoration _decoration(CustomFieldModel field) {
    return InputDecoration(
      labelText: field.required ? '${field.name} *' : field.name,
      helperText: field.helpText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildField(CustomFieldModel field) {
    final enabled = widget.enabled && !_uploading.contains(field.id);

    switch (field.fieldType) {
      case 'boolean':
      case 'checkbox':
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(field.required ? '${field.name} *' : field.name),
          subtitle: field.helpText != null ? Text(field.helpText!) : null,
          value: widget.controller.values[field.id] as bool? ?? false,
          onChanged: enabled
              ? (v) => setState(() => widget.controller.values[field.id] = v)
              : null,
        );
      case 'select':
        return DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: widget.controller.values[field.id] as String?,
          decoration: _decoration(field),
          items: field.options
              .map(
                (o) => DropdownMenuItem(value: o.value, child: Text(o.label)),
              )
              .toList(),
          onChanged: enabled
              ? (v) => setState(() => widget.controller.values[field.id] = v)
              : null,
          validator: field.required
              ? (v) => (v == null || v.isEmpty) ? 'Obligatorio' : null
              : null,
        );
      case 'multi_select':
        final selected =
            (widget.controller.values[field.id] as List<String>? ?? []);
        return InputDecorator(
          decoration: _decoration(field),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: field.options.map((o) {
              final isSelected = selected.contains(o.value);
              return FilterChip(
                label: Text(o.label),
                selected: isSelected,
                onSelected: !enabled
                    ? null
                    : (sel) {
                        setState(() {
                          final next = List<String>.from(selected);
                          if (sel) {
                            next.add(o.value);
                          } else {
                            next.remove(o.value);
                          }
                          widget.controller.values[field.id] = next;
                        });
                      },
              );
            }).toList(),
          ),
        );
      case 'date':
        final value = widget.controller.values[field.id]?.toString();
        return InkWell(
          onTap: enabled ? () => _pickDate(field) : null,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: _decoration(field).copyWith(
              prefixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            child: Text(
              value == null || value.isEmpty ? 'Seleccionar fecha' : value,
              style: TextStyle(
                color: value == null || value.isEmpty
                    ? Colors.black45
                    : Colors.black87,
              ),
            ),
          ),
        );
      case 'file':
      case 'image':
        final controller = widget.controller.textControllers[field.id]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: controller,
              enabled: enabled,
              decoration: _decoration(field),
              onChanged: (v) => widget.controller.values[field.id] = v,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: enabled
                  ? () => _uploadFile(
                        field,
                        image: field.fieldType == 'image',
                      )
                  : null,
              icon: _uploading.contains(field.id)
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(
                field.fieldType == 'image' ? 'Subir imagen' : 'Subir archivo',
              ),
            ),
          ],
        );
      case 'textarea':
        return TextFormField(
          controller: widget.controller.textControllers[field.id],
          enabled: enabled,
          maxLines: 4,
          decoration: _decoration(field),
          validator: field.required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null
              : null,
        );
      case 'number':
        return TextFormField(
          controller: widget.controller.textControllers[field.id],
          enabled: enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
          ],
          decoration: _decoration(field),
          validator: field.required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null
              : null,
        );
      case 'phone':
        return TextFormField(
          controller: widget.controller.textControllers[field.id],
          enabled: enabled,
          keyboardType: TextInputType.phone,
          decoration: _decoration(field),
          validator: field.required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null
              : null,
        );
      case 'email':
        return TextFormField(
          controller: widget.controller.textControllers[field.id],
          enabled: enabled,
          keyboardType: TextInputType.emailAddress,
          decoration: _decoration(field),
          validator: field.required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null
              : null,
        );
      case 'text':
      default:
        return TextFormField(
          controller: widget.controller.textControllers[field.id],
          enabled: enabled,
          decoration: _decoration(field),
          validator: field.required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null
              : null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.fields.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Campos adicionales',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Información personalizada definida por la iglesia',
          style: TextStyle(fontSize: 12.5, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        ...widget.controller.fields.map(
          (field) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildField(field),
          ),
        ),
      ],
    );
  }
}
