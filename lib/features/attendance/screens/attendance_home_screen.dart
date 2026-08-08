import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../Core/widgets/app_section_app_bar.dart';
import '../attendance_repository.dart';
import '../events/attendance_event_bloc.dart';
import '../events/screens/attendance_event_list_screen.dart';
import '../groups/attendance_group_bloc.dart';
import '../groups/screens/attendance_group_list_screen.dart';
import '../reports/screens/absence_report_screen.dart';
import '../../consolidator/people/person_repository.dart';

class AttendanceHomeScreen extends StatelessWidget {
  final ApiClient apiClient;

  const AttendanceHomeScreen({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final repo = AttendanceRepository(apiClient: apiClient);
    final peopleRepo = PersonRepository(apiClient: apiClient);

    return Scaffold(
      appBar: const DefaultSectionAppBar(titleText: 'Asistencia'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Toma de asistencia por grupo, informe de fallas y export Excel para visitas. Solo administradores.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 18),
          _ModuleTile(
            icon: Icons.groups_rounded,
            title: 'Grupos',
            subtitle: 'Crear grupos y gestionar miembros',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => AttendanceGroupBloc(repo)
                      ..add(LoadAttendanceGroups()),
                    child: AttendanceGroupListScreen(
                      attendanceRepository: repo,
                      peopleRepository: peopleRepo,
                    ),
                  ),
                ),
              );
            },
          ),
          _ModuleTile(
            icon: Icons.event_available_rounded,
            title: 'Eventos de asistencia',
            subtitle: 'Cultos / reuniones y pasar lista',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => AttendanceEventBloc(repo)
                      ..add(LoadAttendanceEvents()),
                    child: AttendanceEventListScreen(
                      attendanceRepository: repo,
                      peopleRepository: peopleRepo,
                    ),
                  ),
                ),
              );
            },
          ),
          _ModuleTile(
            icon: Icons.report_gmailerrorred_rounded,
            title: 'Informe de ausencias',
            subtitle: 'Flagged ≥ umbral + export Excel',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AbsenceReportScreen(
                    attendanceRepository: repo,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
