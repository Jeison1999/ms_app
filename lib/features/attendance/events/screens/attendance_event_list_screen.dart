import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import 'package:ms_app/features/attendance/attendance_repository.dart';
import 'package:ms_app/features/attendance/events/attendance_event_bloc.dart';
import 'package:ms_app/features/attendance/events/screens/attendance_event_form_screen.dart';
import 'package:ms_app/features/attendance/events/screens/take_attendance_screen.dart';
import 'package:ms_app/features/attendance/models/attendance_event.dart';
import 'package:ms_app/features/consolidator/people/person_repository.dart';

class AttendanceEventListScreen extends StatefulWidget {
  final AttendanceRepository attendanceRepository;
  final PersonRepository peopleRepository;

  const AttendanceEventListScreen({
    super.key,
    required this.attendanceRepository,
    required this.peopleRepository,
  });

  @override
  State<AttendanceEventListScreen> createState() =>
      _AttendanceEventListScreenState();
}

class _AttendanceEventListScreenState extends State<AttendanceEventListScreen> {
  String? _statusFilter;

  void _reload() {
    context.read<AttendanceEventBloc>().add(
          LoadAttendanceEvents(status: _statusFilter),
        );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Sin fecha';
    final local = dt.toLocal();
    final d =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
    final t =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$d $t';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultSectionAppBar(titleText: 'Eventos de asistencia'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => AttendanceEventFormScreen(
                attendanceRepository: widget.attendanceRepository,
                peopleRepository: widget.peopleRepository,
              ),
            ),
          );
          if (created == true && mounted) _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo evento'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _statusFilter == null,
                  onSelected: (_) {
                    setState(() => _statusFilter = null);
                    _reload();
                  },
                ),
                ChoiceChip(
                  label: const Text('Abiertos'),
                  selected: _statusFilter == 'open',
                  onSelected: (_) {
                    setState(() => _statusFilter = 'open');
                    _reload();
                  },
                ),
                ChoiceChip(
                  label: const Text('Cerrados'),
                  selected: _statusFilter == 'closed',
                  onSelected: (_) {
                    setState(() => _statusFilter = 'closed');
                    _reload();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<AttendanceEventBloc, AttendanceEventState>(
              listener: (context, state) {
                if (state is AttendanceEventSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                } else if (state is AttendanceEventError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                if (state is AttendanceEventLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AttendanceEventsLoaded) {
                  if (state.events.isEmpty) {
                    return const Center(child: Text('No hay eventos'));
                  }
                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: state.events.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final event = state.events[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              event.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              [
                                AttendanceLabels.eventTypes[event.eventType] ??
                                    event.eventType,
                                _formatDate(event.scheduledAt),
                                if (event.groupName != null) event.groupName!,
                                AttendanceLabels.eventStatuses[event.status] ??
                                    event.status,
                              ].join(' · '),
                            ),
                            trailing: Icon(
                              event.isOpen
                                  ? Icons.play_circle_outline
                                  : Icons.lock_outline,
                            ),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider(
                                    create: (_) => AttendanceEventBloc(
                                      widget.attendanceRepository,
                                    )..add(
                                        LoadAttendanceEventDetail(event.id),
                                      ),
                                    child: TakeAttendanceScreen(
                                      eventId: event.id,
                                      attendanceRepository:
                                          widget.attendanceRepository,
                                    ),
                                  ),
                                ),
                              );
                              if (mounted) _reload();
                            },
                          ),
                        );
                      },
                    ),
                  );
                }
                if (state is AttendanceEventError) {
                  return Center(child: Text(state.message));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
