import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import 'package:ms_app/features/attendance/attendance_repository.dart';
import 'package:ms_app/features/attendance/events/attendance_event_bloc.dart';
import 'package:ms_app/features/attendance/models/attendance_event.dart';

class TakeAttendanceScreen extends StatefulWidget {
  final int eventId;
  final AttendanceRepository attendanceRepository;

  const TakeAttendanceScreen({
    super.key,
    required this.eventId,
    required this.attendanceRepository,
  });

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  final Map<int, AttendanceRecord> _local = {};
  bool _dirty = false;
  bool _saving = false;

  void _syncFromEvent(AttendanceEvent event) {
    _local
      ..clear()
      ..addEntries(event.records.map((r) => MapEntry(r.personId, r)));
    _dirty = false;
  }

  Future<void> _save(AttendanceEvent event) async {
    setState(() => _saving = true);
    try {
      context.read<AttendanceEventBloc>().add(
            UpdateAttendanceRecords(
              event.id,
              _local.values.toList(),
            ),
          );
      _dirty = false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _close(AttendanceEvent event) async {
    if (_dirty) {
      await _save(event);
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar evento'),
        content: const Text(
          '¿Cerrar este evento? Después no podrás editar la asistencia con normalidad.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<AttendanceEventBloc>().add(CloseAttendanceEvent(event.id));
    }
  }

  Color _statusColor(String status, ColorScheme scheme) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.redAccent;
      case 'excused':
        return Colors.blueGrey;
      case 'late':
        return Colors.orange;
      default:
        return scheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultSectionAppBar(titleText: 'Tomar asistencia'),
      body: BlocConsumer<AttendanceEventBloc, AttendanceEventState>(
        listener: (context, state) {
          if (state is AttendanceEventDetailLoaded) {
            setState(() => _syncFromEvent(state.event));
          } else if (state is AttendanceEventSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            if (state.event != null) {
              setState(() => _syncFromEvent(state.event!));
            }
          } else if (state is AttendanceEventError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          AttendanceEvent? event;
          if (state is AttendanceEventDetailLoaded) {
            event = state.event;
          } else if (state is AttendanceEventSuccess && state.event != null) {
            event = state.event;
          }

          if (event == null) {
            if (state is AttendanceEventError) {
              return Center(child: Text(state.message));
            }
            return const Center(child: CircularProgressIndicator());
          }

          final records = _local.values.toList()
            ..sort((a, b) => a.fullName.compareTo(b.fullName));
          final present =
              records.where((r) => r.status == 'present').length;
          final absent = records.where((r) => r.status == 'absent').length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AttendanceLabels.eventStatuses[event.status] ?? event.status}'
                      ' · Presentes $present · Ausentes $absent'
                      '${event.groupName != null ? ' · ${event.groupName}' : ''}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final locked = event!.isClosed;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (record.code != null || record.phone != null)
                              Text(
                                [
                                  if (record.code != null) 'ID ${record.code}',
                                  if (record.phone != null) record.phone!,
                                ].join(' · '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: AttendanceLabels.recordStatuses.entries
                                  .where((e) => e.key != 'pending')
                                  .map((e) {
                                final selected = record.status == e.key;
                                return ChoiceChip(
                                  label: Text(e.value),
                                  selected: selected,
                                  selectedColor: _statusColor(
                                    e.key,
                                    Theme.of(context).colorScheme,
                                  ).withValues(alpha: 0.25),
                                  onSelected: locked
                                      ? null
                                      : (_) {
                                          setState(() {
                                            _local[record.personId] =
                                                record.copyWith(status: e.key);
                                            _dirty = true;
                                          });
                                        },
                                );
                              }).toList(),
                            ),
                            if (!locked) ...[
                              const SizedBox(height: 6),
                              TextFormField(
                                initialValue: record.notes ?? '',
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: 'Notas (opcional)',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) {
                                  _local[record.personId] =
                                      record.copyWith(notes: v);
                                  _dirty = true;
                                },
                              ),
                            ] else if (record.notes != null &&
                                record.notes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Nota: ${record.notes}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (event.isOpen)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: _saving
                                ? null
                                : () => _save(event!),
                            child: Text(_saving ? 'Guardando…' : 'Guardar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: _saving ? null : () => _close(event!),
                            child: const Text('Cerrar evento'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
