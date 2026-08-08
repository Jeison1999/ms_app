import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import 'package:ms_app/features/attendance/attendance_repository.dart';
import 'package:ms_app/features/attendance/groups/attendance_group_bloc.dart';
import 'package:ms_app/features/attendance/groups/screens/attendance_group_detail_screen.dart';
import 'package:ms_app/features/attendance/groups/screens/attendance_group_form_screen.dart';
import 'package:ms_app/features/consolidator/people/person_repository.dart';

class AttendanceGroupListScreen extends StatelessWidget {
  final AttendanceRepository attendanceRepository;
  final PersonRepository peopleRepository;

  const AttendanceGroupListScreen({
    super.key,
    required this.attendanceRepository,
    required this.peopleRepository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultSectionAppBar(titleText: 'Grupos de asistencia'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<AttendanceGroupBloc>(),
                child: AttendanceGroupFormScreen(
                  attendanceRepository: attendanceRepository,
                  peopleRepository: peopleRepository,
                ),
              ),
            ),
          );
          if (created == true && context.mounted) {
            context.read<AttendanceGroupBloc>().add(LoadAttendanceGroups());
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo grupo'),
      ),
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
          if (state is AttendanceGroupLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AttendanceGroupsLoaded) {
            if (state.groups.isEmpty) {
              return const Center(child: Text('No hay grupos activos'));
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AttendanceGroupBloc>().add(LoadAttendanceGroups());
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                itemCount: state.groups.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final group = state.groups[index];
                  Color? accent;
                  if (group.color != null && group.color!.startsWith('#')) {
                    try {
                      accent = Color(
                        int.parse(group.color!.substring(1), radix: 16) +
                            0xFF000000,
                      );
                    } catch (_) {}
                  }
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            (accent ?? Theme.of(context).colorScheme.primary)
                                .withValues(alpha: 0.18),
                        child: Icon(
                          Icons.groups,
                          color: accent ?? Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        group.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${group.memberCount} miembros · umbral ${group.absenceThreshold}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BlocProvider(
                              create: (_) =>
                                  AttendanceGroupBloc(attendanceRepository)
                                    ..add(LoadAttendanceGroupDetail(group.id)),
                              child: AttendanceGroupDetailScreen(
                                groupId: group.id,
                                attendanceRepository: attendanceRepository,
                                peopleRepository: peopleRepository,
                              ),
                            ),
                          ),
                        );
                        if (context.mounted) {
                          context
                              .read<AttendanceGroupBloc>()
                              .add(LoadAttendanceGroups());
                        }
                      },
                    ),
                  );
                },
              ),
            );
          }
          if (state is AttendanceGroupError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
