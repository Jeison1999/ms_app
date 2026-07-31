import 'package:flutter/material.dart';
import 'package:ms_app/features/consolidator/custom_fields/models/custom_field_model.dart';
import '../models/people_filter_options.dart';
import '../models/person_filters.dart';
import '../utils/person_text_normalize.dart';

Future<PersonFilters?> showPeopleFiltersSheet({
  required BuildContext context,
  required PeopleFilterOptions options,
  required PersonFilters initial,
}) {
  return showModalBottomSheet<PersonFilters>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PeopleFiltersSheet(
      options: options,
      initial: initial.copy(),
    ),
  );
}

class _PeopleFiltersSheet extends StatefulWidget {
  final PeopleFilterOptions options;
  final PersonFilters initial;

  const _PeopleFiltersSheet({
    required this.options,
    required this.initial,
  });

  @override
  State<_PeopleFiltersSheet> createState() => _PeopleFiltersSheetState();
}

class _PeopleFiltersSheetState extends State<_PeopleFiltersSheet> {
  late PersonFilters _filters;
  late final TextEditingController _ageMinController;
  late final TextEditingController _ageMaxController;

  static const sexLabels = {
    'male': 'Masculino',
    'female': 'Femenino',
    'other': 'Otro',
    'unspecified': 'No especificado',
  };

  @override
  void initState() {
    super.initState();
    _filters = widget.initial;
    _filters.city = PersonTextNormalize.matchInList(
      _filters.city,
      widget.options.cities,
    );
    _filters.sex = PersonTextNormalize.matchInList(
      _filters.sex,
      widget.options.sexes,
    );
    _filters.documentType = PersonTextNormalize.matchInList(
      _filters.documentType,
      widget.options.documentTypes,
    );
    _ageMinController = TextEditingController(
      text: _filters.ageMin?.toString() ?? '',
    );
    _ageMaxController = TextEditingController(
      text: _filters.ageMax?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _ageMinController.dispose();
    _ageMaxController.dispose();
    super.dispose();
  }

  void _applyAges() {
    _filters.ageMin = int.tryParse(_ageMinController.text.trim());
    _filters.ageMax = int.tryParse(_ageMaxController.text.trim());
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.9;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filtros',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filters.clearAdvanced(keepStatus: true, keepQuery: true);
                      _ageMinController.clear();
                      _ageMaxController.clear();
                    });
                  },
                  child: const Text('Limpiar'),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _section('Estado', [
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Activos'),
                        selected: _filters.status == 'active',
                        onSelected: (_) =>
                            setState(() => _filters.status = 'active'),
                      ),
                      ChoiceChip(
                        label: const Text('Inactivos'),
                        selected: _filters.status == 'inactive',
                        onSelected: (_) =>
                            setState(() => _filters.status = 'inactive'),
                      ),
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: _filters.status == null ||
                            _filters.status!.isEmpty,
                        onSelected: (_) =>
                            setState(() => _filters.status = null),
                      ),
                    ],
                  ),
                ]),
                if (widget.options.cities.isNotEmpty)
                  _section('Ciudad', [
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _filters.city,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Ciudad',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todas'),
                        ),
                        ...widget.options.cities.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _filters.city = v),
                    ),
                  ]),
                _section('Sexo', [
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _filters.sex,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Sexo',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ...widget.options.sexes.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(sexLabels[s] ?? s),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _filters.sex = v),
                  ),
                ]),
                _section('Documento', [
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _filters.documentType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Tipo de documento',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ...widget.options.documentTypes.map(
                        (t) => DropdownMenuItem(value: t, child: Text(t)),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _filters.documentType = v),
                  ),
                ]),
                _section('Edad', [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ageMinController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Mín',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _ageMaxController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Máx',
                          ),
                        ),
                      ),
                    ],
                  ),
                ]),
                _section('Cumpleaños (mes)', [
                  DropdownButtonFormField<int>(
                    // ignore: deprecated_member_use
                    value: _filters.birthdayMonth,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Mes',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Cualquiera'),
                      ),
                      ...widget.options.birthdayMonths.map(
                        (m) => DropdownMenuItem(
                          value: m.value,
                          child: Text(m.label),
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _filters.birthdayMonth = v),
                  ),
                ]),
                _section('Presencia de datos', [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _triChip(
                        'Email',
                        _filters.hasEmail,
                        (v) => setState(() => _filters.hasEmail = v),
                      ),
                      _triChip(
                        'Teléfono',
                        _filters.hasPhone,
                        (v) => setState(() => _filters.hasPhone = v),
                      ),
                      _triChip(
                        'Documento',
                        _filters.hasDocument,
                        (v) => setState(() => _filters.hasDocument = v),
                      ),
                      _triChip(
                        'Foto',
                        _filters.hasPhoto,
                        (v) => setState(() => _filters.hasPhoto = v),
                      ),
                      _triChip(
                        'Fecha nac.',
                        _filters.hasBirthDate,
                        (v) => setState(() => _filters.hasBirthDate = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Toca: todos → con → sin → todos',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ]),
                if (widget.options.customFields.isNotEmpty)
                  _section(
                    'Campos personalizados',
                    widget.options.customFields
                        .map(_customFieldFilter)
                        .toList(),
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                onPressed: () {
                  _applyAges();
                  Navigator.pop(context, _filters);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Aplicar filtros'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _triChip(String label, bool? value, ValueChanged<bool?> onChanged) {
    final text = value == null
        ? label
        : value
            ? '$label ✓'
            : '$label ✗';
    return FilterChip(
      label: Text(text),
      selected: value != null,
      onSelected: (_) {
        if (value == null) {
          onChanged(true);
        } else if (value == true) {
          onChanged(false);
        } else {
          onChanged(null);
        }
      },
    );
  }

  Widget _customFieldFilter(CustomFieldModel field) {
    final current = _filters.customFields[field.key];

    switch (field.fieldType) {
      case 'boolean':
      case 'checkbox':
        final boolVal = current is bool ? current : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(child: Text(field.name)),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'any', label: Text('Todos')),
                  ButtonSegment(value: 'yes', label: Text('Sí')),
                  ButtonSegment(value: 'no', label: Text('No')),
                ],
                selected: {
                  boolVal == null
                      ? 'any'
                      : boolVal
                          ? 'yes'
                          : 'no',
                },
                onSelectionChanged: (s) {
                  setState(() {
                    final v = s.first;
                    if (v == 'any') {
                      _filters.customFields.remove(field.key);
                    } else {
                      _filters.customFields[field.key] = v == 'yes';
                    }
                  });
                },
              ),
            ],
          ),
        );
      case 'select':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: current is String ? current : null,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: field.name,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todos')),
              ...field.options.map(
                (o) => DropdownMenuItem(value: o.value, child: Text(o.label)),
              ),
            ],
            onChanged: (v) {
              setState(() {
                if (v == null) {
                  _filters.customFields.remove(field.key);
                } else {
                  _filters.customFields[field.key] = v;
                }
              });
            },
          ),
        );
      case 'multi_select':
        final selected = current is List
            ? current.map((e) => e.toString()).toSet()
            : <String>{};
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(field.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: field.options.map((o) {
                  final isOn = selected.contains(o.value);
                  return FilterChip(
                    label: Text(o.label),
                    selected: isOn,
                    onSelected: (sel) {
                      setState(() {
                        final next = Set<String>.from(selected);
                        if (sel) {
                          next.add(o.value);
                        } else {
                          next.remove(o.value);
                        }
                        if (next.isEmpty) {
                          _filters.customFields.remove(field.key);
                        } else {
                          _filters.customFields[field.key] = next.toList();
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            initialValue: current?.toString() ?? '',
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: field.name,
            ),
            onChanged: (v) {
              if (v.trim().isEmpty) {
                _filters.customFields.remove(field.key);
              } else {
                _filters.customFields[field.key] = v.trim();
              }
            },
          ),
        );
    }
  }
}
