import 'package:flutter/material.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import 'package:ms_app/features/attendance/attendance_repository.dart';
import 'package:ms_app/features/attendance/models/attendance_group.dart';
import 'package:ms_app/features/attendance/widgets/person_multi_picker.dart';
import 'package:ms_app/features/consolidator/people/person_repository.dart';

class AttendanceGroupFormScreen extends StatefulWidget {
  final AttendanceRepository attendanceRepository;
  final PersonRepository peopleRepository;
  final AttendanceGroup? initial;

  const AttendanceGroupFormScreen({
    super.key,
    required this.attendanceRepository,
    required this.peopleRepository,
    this.initial,
  });

  @override
  State<AttendanceGroupFormScreen> createState() =>
      _AttendanceGroupFormScreenState();
}

class _AttendanceGroupFormScreenState extends State<AttendanceGroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _threshold;
  late final TextEditingController _color;
  final Set<int> _personIds = {};
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final g = widget.initial;
    _name = TextEditingController(text: g?.name ?? '');
    _description = TextEditingController(text: g?.description ?? '');
    _threshold = TextEditingController(
      text: (g?.absenceThreshold ?? 3).toString(),
    );
    _color = TextEditingController(text: g?.color ?? '#C48A2C');
    if (g != null) {
      _personIds.addAll(g.members.map((m) => m.id));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _threshold.dispose();
    _color.dispose();
    super.dispose();
  }

  Future<void> _pickPeople() async {
    final ids = await showPersonMultiPicker(
      context: context,
      repository: widget.peopleRepository,
      initiallySelected: _personIds,
      title: 'Miembros del grupo',
    );
    if (ids != null && mounted) {
      setState(() {
        _personIds
          ..clear()
          ..addAll(ids);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final payload = {
      'name': _name.text.trim(),
      'description': _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      'absence_threshold': int.tryParse(_threshold.text.trim()) ?? 3,
      'color': _color.text.trim().isEmpty ? null : _color.text.trim(),
    };

    try {
      if (_isEdit) {
        await widget.attendanceRepository.updateGroup(
          widget.initial!.id,
          payload,
        );
      } else {
        await widget.attendanceRepository.createGroup(
          group: payload,
          personIds: _personIds.toList(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DefaultSectionAppBar(
        titleText: _isEdit ? 'Editar grupo' : 'Nuevo grupo',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _threshold,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Umbral de ausencias',
                border: OutlineInputBorder(),
                helperText: 'Default 3 para marcar visita',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _color,
              decoration: const InputDecoration(
                labelText: 'Color (hex)',
                border: OutlineInputBorder(),
              ),
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Miembros (${_personIds.length})'),
                subtitle: const Text('Opcional al crear'),
                trailing: TextButton(
                  onPressed: _pickPeople,
                  child: const Text('Elegir'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Guardando…' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
