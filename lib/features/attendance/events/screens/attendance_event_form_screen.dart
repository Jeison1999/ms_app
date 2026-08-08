import 'package:flutter/material.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import 'package:ms_app/features/attendance/attendance_repository.dart';
import 'package:ms_app/features/attendance/models/attendance_event.dart';
import 'package:ms_app/features/attendance/models/attendance_group.dart';
import 'package:ms_app/features/attendance/widgets/person_multi_picker.dart';
import 'package:ms_app/features/consolidator/people/person_repository.dart';

class AttendanceEventFormScreen extends StatefulWidget {
  final AttendanceRepository attendanceRepository;
  final PersonRepository peopleRepository;

  const AttendanceEventFormScreen({
    super.key,
    required this.attendanceRepository,
    required this.peopleRepository,
  });

  @override
  State<AttendanceEventFormScreen> createState() =>
      _AttendanceEventFormScreenState();
}

class _AttendanceEventFormScreenState extends State<AttendanceEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  String _eventType = 'worship';
  DateTime _scheduledAt = DateTime.now();
  bool _useGroup = true;
  AttendanceGroup? _group;
  List<AttendanceGroup> _groups = [];
  final Set<int> _personIds = {};
  bool _loadingGroups = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await widget.attendanceRepository.getGroups(active: true);
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _group = groups.isNotEmpty ? groups.first : null;
        _loadingGroups = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingGroups = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar grupos: $e')),
      );
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickPeople() async {
    final ids = await showPersonMultiPicker(
      context: context,
      repository: widget.peopleRepository,
      initiallySelected: _personIds,
      title: 'Personas del evento',
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
    if (_useGroup && _group == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un grupo')),
      );
      return;
    }
    if (!_useGroup && _personIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una persona')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final event = <String, dynamic>{
        'title': _title.text.trim(),
        'event_type': _eventType,
        'scheduled_at': _scheduledAt.toIso8601String(),
        if (_useGroup) 'attendance_group_id': _group!.id,
      };
      await widget.attendanceRepository.createEvent(
        event: event,
        personIds: _useGroup ? const [] : _personIds.toList(),
      );
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
    final local = _scheduledAt.toLocal();
    final when =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: const DefaultSectionAppBar(titleText: 'Nuevo evento'),
      body: _loadingGroups
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: _eventType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: AttendanceLabels.eventTypes.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _eventType = v ?? 'worship'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fecha y hora'),
                    subtitle: Text(when),
                    trailing: TextButton(
                      onPressed: _pickDateTime,
                      child: const Text('Cambiar'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Por grupo')),
                      ButtonSegment(value: false, label: Text('Personas')),
                    ],
                    selected: {_useGroup},
                    onSelectionChanged: (s) =>
                        setState(() => _useGroup = s.first),
                  ),
                  const SizedBox(height: 12),
                  if (_useGroup)
                    DropdownButtonFormField<AttendanceGroup>(
                      // ignore: deprecated_member_use
                      value: _group,
                      decoration: const InputDecoration(
                        labelText: 'Grupo',
                        border: OutlineInputBorder(),
                      ),
                      items: _groups
                          .map(
                            (g) => DropdownMenuItem(
                              value: g,
                              child: Text(g.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _group = v),
                    )
                  else
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Personas (${_personIds.length})'),
                      trailing: TextButton(
                        onPressed: _pickPeople,
                        child: const Text('Elegir'),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Creando…' : 'Crear evento'),
                  ),
                ],
              ),
            ),
    );
  }
}
