import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ms_app/Core/theme/app_colors.dart';
import 'package:ms_app/Core/theme/app_text_styles.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import 'package:ms_app/core/api/api_client.dart';
import 'package:ms_app/features/consolidator/custom_fields/custom_field_bloc.dart';
import 'package:ms_app/features/consolidator/custom_fields/custom_field_repository.dart';
import 'package:ms_app/features/consolidator/custom_fields/screens/custom_field_list_screen.dart';
import 'package:ms_app/features/consolidator/people/models/person_filters.dart';
import 'package:ms_app/features/consolidator/people/person_bloc.dart';
import 'package:ms_app/features/consolidator/people/person_repository.dart';
import 'package:ms_app/features/consolidator/people/screens/birthday_list_screen.dart';
import 'package:ms_app/features/consolidator/people/screens/person_list_screen.dart';

class ConsolidatorHomeScreen extends StatefulWidget {
  final ApiClient apiClient;

  const ConsolidatorHomeScreen({super.key, required this.apiClient});

  @override
  State<ConsolidatorHomeScreen> createState() => _ConsolidatorHomeScreenState();
}

class _ConsolidatorHomeScreenState extends State<ConsolidatorHomeScreen> {
  int? _todayCount;
  int? _monthCount;
  bool _loadingBirthdays = true;

  @override
  void initState() {
    super.initState();
    _loadBirthdayCounts();
  }

  Future<void> _loadBirthdayCounts() async {
    final repo = PersonRepository(apiClient: widget.apiClient);
    try {
      final today = await repo.getBirthdaysToday();
      final month = await repo.getBirthdaysMonth();
      if (!mounted) return;
      setState(() {
        _todayCount = today.total;
        _monthCount = month.total;
        _loadingBirthdays = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _todayCount = null;
        _monthCount = null;
        _loadingBirthdays = false;
      });
    }
  }

  void _openBirthdays(BirthdayListMode mode) {
    final month = DateTime.now().month;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) {
            final bloc = PersonBloc(
              PersonRepository(apiClient: widget.apiClient),
            );
            if (mode == BirthdayListMode.today) {
              bloc.add(LoadBirthdaysToday());
            } else {
              bloc.add(LoadBirthdaysMonth(month: month));
            }
            return bloc;
          },
          child: BirthdayListScreen(
            mode: mode,
            initialMonth: month,
          ),
        ),
      ),
    ).then((_) => _loadBirthdayCounts());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const DefaultSectionAppBar(titleText: 'Consolidador'),
      body: RefreshIndicator(
        onRefresh: _loadBirthdayCounts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      child:
                          Icon(Icons.people_alt_rounded, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Módulo de Consolidación',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Gestiona el registro de personas de la comunidad.',
                            style:
                                TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Cumpleaños',
                style: AppTextStyles.sectionTitle.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _BirthdayStatCard(
                      title: 'Hoy cumplen',
                      count: _todayCount,
                      loading: _loadingBirthdays,
                      icon: Icons.cake_rounded,
                      color: colorScheme.primary,
                      onTap: () => _openBirthdays(BirthdayListMode.today),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BirthdayStatCard(
                      title: 'Cumpleaños del mes',
                      count: _monthCount,
                      loading: _loadingBirthdays,
                      icon: Icons.calendar_month_rounded,
                      color: colorScheme.tertiary,
                      onTap: () => _openBirthdays(BirthdayListMode.month),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Módulos',
                style: AppTextStyles.sectionTitle.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              _ModuleCard(
                title: 'Gestión de personas',
                subtitle: 'Buscar, crear, editar y activar/desactivar',
                icon: Icons.badge_outlined,
                accentColor: colorScheme.primary,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => PersonBloc(
                          PersonRepository(apiClient: widget.apiClient),
                        )..add(LoadPeople(filters: PersonFilters(status: 'active'))),
                        child: const PersonListScreen(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _ModuleCard(
                title: 'Campos personalizados',
                subtitle: 'Define datos extra sin tocar el código',
                icon: Icons.tune_rounded,
                accentColor: colorScheme.tertiary,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => CustomFieldBloc(
                          CustomFieldRepository(apiClient: widget.apiClient),
                        )..add(LoadCustomFields(active: true)),
                        child: const CustomFieldListScreen(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BirthdayStatCard extends StatelessWidget {
  final String title;
  final int? count;
  final bool loading;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BirthdayStatCard({
    required this.title,
    required this.count,
    required this.loading,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 6),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  count == null ? '—' : '$count',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 3),
                    Text(subtitle, style: AppTextStyles.cardSubtitle),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
