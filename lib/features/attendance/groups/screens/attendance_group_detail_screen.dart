import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import 'package:ms_app/features/attendance/attendance_repository.dart';
import 'package:ms_app/features/attendance/groups/attendance_group_bloc.dart';
import 'package:ms_app/features/attendance/groups/screens/attendance_group_form_screen.dart';
import 'package:ms_app/features/attendance/models/attendance_group.dart';
import 'package:ms_app/features/attendance/widgets/person_multi_picker.dart';
import 'package:ms_app/features/consolidator/people/person_repository.dart';

class AttendanceGroupDetailScreen extends StatelessWidget {
  final int groupId;
  final AttendanceRepository attendanceRepository;
  final PersonRepository peopleRepository;

  const AttendanceGroupDetailScreen({
    super.key,
    required this.groupId,
    required this.attendanceRepository,
    required this.peopleRepository,
  });

  Future<void> _addMembers(BuildContext context, AttendanceGroup group) async {
    final ids = await showPersonMultiPicker(
      context: context,
      repository: peopleRepository,
      excludeIds: group.members.map((m) => m.id).toSet(),
      title: 'Agregar miembros',
    );
    if (ids == null || ids.isEmpty || !context.mounted) return;
    context.read<AttendanceGroupBloc>().add(AddGroupMembers(group.id, ids));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultSectionAppBar(titleText: 'Detalle del grupo'),
      body: BlocConsumer<AttendanceGroupBloc, AttendanceGroupState>(
        listener: (context, state) {
          if (state is AttendanceGroupSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is AttendanceGroupError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is AttendanceGroupLoading &&
              state is! AttendanceGroupDetailLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is! AttendanceGroupDetailLoaded) {
            if (state is AttendanceGroupError) {
              return Center(child: Text(state.message));
            }
            return const Center(child: CircularProgressIndicator());
          }

          final group = state.group;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Text(
                group.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (group.description != null && group.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(group.description!),
                ),
              const SizedBox(height: 8),
              Text(
                'Umbral: ${group.absenceThreshold} ausencias',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.tonal(
                    onPressed: () async {
                      final ok = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => AttendanceGroupFormScreen(
                            attendanceRepository: attendanceRepository,
                            peopleRepository: peopleRepository,
                            initial: group,
                          ),
                        ),
                      );
                      if (ok == true && context.mounted) {
                        context
                            .read<AttendanceGroupBloc>()
                            .add(LoadAttendanceGroupDetail(group.id));
                      }
                    },
                    child: const Text('Editar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: () => _addMembers(context, group),
                    child: const Text('Agregar miembros'),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Desactivar',
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Desactivar grupo'),
                          content: Text('¿Desactivar "${group.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Desactivar'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        context
                            .read<AttendanceGroupBloc>()
                            .add(DeactivateAttendanceGroup(group.id));
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Miembros (${group.members.length})',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (group.members.isEmpty)
                const Text('Sin miembros aún')
              else
                ...group.members.map(
                  (m) => Card(
                    child: ListTile(
                      title: Text(m.fullName),
                      subtitle: Text(
                        [
                          if (m.code != null) 'ID ${m.code}',
                          if (m.phone != null) m.phone!,
                        ].join(' · '),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          context.read<AttendanceGroupBloc>().add(
                                RemoveGroupMembers(group.id, [m.id]),
                              );
                        },
                      ),
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
