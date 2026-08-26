import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import '../custom_field_bloc.dart';
import '../custom_field_repository.dart';
import '../models/custom_field_model.dart';

class CustomFieldFormScreen extends StatelessWidget {
  final CustomFieldRepository repository;
  final CustomFieldModel? initialField;

  const CustomFieldFormScreen({
    super.key,
    required this.repository,
    this.initialField,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomFieldBloc(repository),
      child: _CustomFieldFormView(
        initialField: initialField,
        isEdit: initialField != null,
      ),
    );
  }
}

class _CustomFieldFormView extends StatefulWidget {
  final CustomFieldModel? initialField;
  final bool isEdit;

  const _CustomFieldFormView({
    required this.initialField,
    required this.isEdit,
  });

  @override
  State<_CustomFieldFormView> createState() => _CustomFieldFormViewState();
}

class _CustomFieldFormViewState extends State<_CustomFieldFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _keyController;
  late final TextEditingController _helpController;
  late final TextEditingController _optionsController;
  late String _fieldType;
  late bool _required;
  late bool _includeInPublicForm;
  late bool _publicRequired;
  bool _keyEdited = false;

  @override
  void initState() {
    super.initState();
    final f = widget.initialField;
    _nameController = TextEditingController(text: f?.name ?? '');
    _keyController = TextEditingController(text: f?.key ?? '');
    _helpController = TextEditingController(text: f?.helpText ?? '');
    _fieldType = f?.fieldType ?? 'text';
    _required = f?.required ?? false;
    _includeInPublicForm = f?.includeInPublicForm ?? false;
    _publicRequired = f?.publicRequired ?? false;
    _optionsController = TextEditingController(
      text: (f?.options ?? [])
          .map((o) => o.label == o.value ? o.label : '${o.label}|${o.value}')
          .join('\n'),
    );
    if (widget.isEdit) _keyEdited = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keyController.dispose();
    _helpController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  String _slugify(String input) {
    final normalized = input
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'campo' : normalized;
  }

  bool get _needsOptions =>
      _fieldType == 'select' || _fieldType == 'multi_select';

  List<Map<String, dynamic>> _parseOptions() {
    final lines = _optionsController.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final existing = widget.initialField?.options ?? [];
    final options = <Map<String, dynamic>>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final parts = line.split('|');
      final label = parts.first.trim();
      final value = parts.length > 1
          ? parts[1].trim()
          : _slugify(label);
      final map = <String, dynamic>{
        'label': label,
        'value': value.isEmpty ? _slugify(label) : value,
        'position': i,
      };
      if (i < existing.length && existing[i].id != null) {
        map['id'] = existing[i].id;
      }
      options.add(map);
    }
    return options;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_needsOptions && _parseOptions().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos una opción (una por línea)'),
        ),
      );
      return;
    }

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'key': _keyController.text.trim(),
      'field_type': _fieldType,
      'required': _required,
      'include_in_public_form': _includeInPublicForm,
      'public_required': _includeInPublicForm && _publicRequired,
      'help_text': _helpController.text.trim().isEmpty
          ? null
          : _helpController.text.trim(),
      if (_needsOptions)
        'custom_field_options_attributes': _parseOptions(),
    };

    if (widget.isEdit) {
      context.read<CustomFieldBloc>().add(
        UpdateCustomField(widget.initialField!.id, data),
      );
    } else {
      context.read<CustomFieldBloc>().add(CreateCustomField(data));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomFieldBloc, CustomFieldState>(
      listener: (context, state) {
        if (state is CustomFieldSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          Navigator.of(context).pop(true);
        } else if (state is CustomFieldError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final loading = state is CustomFieldLoading;
        return Scaffold(
          appBar: DefaultSectionAppBar(
            titleText: widget.isEdit ? 'Editar campo' : 'Nuevo campo',
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                TextFormField(
                  controller: _nameController,
                  enabled: !loading,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                    helperText: 'Ej: Fecha de bautismo',
                  ),
                  onChanged: (value) {
                    if (!_keyEdited) {
                      _keyController.text = _slugify(value);
                    }
                  },
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _keyController,
                  enabled: !loading && !widget.isEdit,
                  decoration: const InputDecoration(
                    labelText: 'Clave (key) *',
                    border: OutlineInputBorder(),
                    helperText: 'Identificador interno único (snake_case)',
                  ),
                  onChanged: (_) => _keyEdited = true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Obligatorio';
                    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(v.trim())) {
                      return 'Usa snake_case (ej: fecha_bautismo)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _fieldType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de campo *',
                    border: OutlineInputBorder(),
                  ),
                  items: CustomFieldModel.supportedTypes
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(CustomFieldModel.typeLabel(t)),
                        ),
                      )
                      .toList(),
                  onChanged: loading || widget.isEdit
                      ? null
                      : (v) {
                          if (v != null) setState(() => _fieldType = v);
                        },
                ),
                if (widget.isEdit)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'El tipo no se puede cambiar al editar.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Obligatorio'),
                  value: _required,
                  onChanged: loading
                      ? null
                      : (v) => setState(() => _required = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Incluir en formulario web'),
                  subtitle: const Text(
                    'Si se activa, el portal público puede auto-abrirse',
                  ),
                  value: _includeInPublicForm,
                  onChanged: loading
                      ? null
                      : (v) => setState(() {
                            _includeInPublicForm = v;
                            if (!v) _publicRequired = false;
                          }),
                ),
                if (_includeInPublicForm)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Obligatorio en la web'),
                    value: _publicRequired,
                    onChanged: loading
                        ? null
                        : (v) => setState(() => _publicRequired = v),
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _helpController,
                  enabled: !loading,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Texto de ayuda',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_needsOptions) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _optionsController,
                    enabled: !loading,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Opciones *',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      helperText:
                          'Una por línea. Opcional: Etiqueta|valor\nEj: Soltero|soltero',
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: loading ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.isEdit ? 'Guardar' : 'Crear campo'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
