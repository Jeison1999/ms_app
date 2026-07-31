import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import '../models/person_model.dart';
import '../person_bloc.dart';
import 'person_detail_screen.dart';

enum BirthdayListMode { today, month }

class BirthdayListScreen extends StatefulWidget {
  final BirthdayListMode mode;
  final int? initialMonth;

  const BirthdayListScreen({
    super.key,
    required this.mode,
    this.initialMonth,
  });

  @override
  State<BirthdayListScreen> createState() => _BirthdayListScreenState();
}

class _BirthdayListScreenState extends State<BirthdayListScreen> {
  late int _month;

  static const _monthNames = [
    '',
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  @override
  void initState() {
    super.initState();
    _month = widget.initialMonth ?? DateTime.now().month;
  }

  void _reload() {
    final bloc = context.read<PersonBloc>();
    if (widget.mode == BirthdayListMode.today) {
      bloc.add(LoadBirthdaysToday());
    } else {
      bloc.add(LoadBirthdaysMonth(month: _month));
    }
  }

  String _title() {
    if (widget.mode == BirthdayListMode.today) return 'Hoy cumplen';
    return 'Cumpleaños · ${_monthNames[_month]}';
  }

  String _daysLabel(PersonModel person) {
    if (person.isBirthdayToday == true) return '¡Hoy!';
    final days = person.daysUntilBirthday;
    if (days == null) return '';
    if (days == 0) return '¡Hoy!';
    if (days < 0) return 'Hace ${-days} día${days == -1 ? '' : 's'}';
    return 'En $days día${days == 1 ? '' : 's'}';
  }

  String _formatBirthday(DateTime? date) {
    if (date == null) return '—';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m';
  }

  Future<void> _openDetail(PersonModel person) async {
    final repo = context.read<PersonBloc>().repository;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonDetailScreen(
          repository: repo,
          personId: person.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: DefaultSectionAppBar(titleText: _title()),
      body: Column(
        children: [
          if (widget.mode == BirthdayListMode.month)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: List.generate(12, (i) {
                  final m = i + 1;
                  final selected = m == _month;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_monthNames[m].substring(0, 3)),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => _month = m);
                        context.read<PersonBloc>().add(
                          LoadBirthdaysMonth(month: m),
                        );
                      },
                    ),
                  );
                }),
              ),
            ),
          Expanded(
            child: BlocBuilder<PersonBloc, PersonState>(
              builder: (context, state) {
                if (state is PersonLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is PersonError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _reload,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (state is BirthdaysLoaded) {
                  if (state.people.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cake_outlined,
                            size: 64,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.mode == BirthdayListMode.today
                                ? 'Nadie cumple años hoy'
                                : 'Sin cumpleaños en ${_monthNames[_month]}',
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: state.people.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.11),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              widget.mode == BirthdayListMode.today
                                  ? 'Hoy: ${state.total} persona(s)'
                                  : 'Total mes: ${state.total}'
                                      '${state.todayCount != null ? ' · Hoy: ${state.todayCount}' : ''}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          );
                        }

                        final person = state.people[index - 1];
                        final isToday = person.isBirthdayToday == true ||
                            person.daysUntilBirthday == 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isToday
                                  ? colorScheme.primary.withValues(alpha: 0.2)
                                  : colorScheme.primary.withValues(alpha: 0.12),
                              backgroundImage: person.photoUrl != null &&
                                      person.photoUrl!.isNotEmpty
                                  ? NetworkImage(person.photoUrl!)
                                  : null,
                              child: person.photoUrl == null ||
                                      person.photoUrl!.isEmpty
                                  ? Icon(
                                      isToday
                                          ? Icons.cake
                                          : Icons.person_outline,
                                      color: colorScheme.primary,
                                    )
                                  : null,
                            ),
                            title: Text(
                              person.fullName,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              [
                                if (person.turningAge != null)
                                  'Cumple ${person.turningAge}',
                                _formatBirthday(
                                  person.birthdayThisYear ?? person.birthDate,
                                ),
                                _daysLabel(person),
                              ].where((e) => e.isNotEmpty).join(' · '),
                            ),
                            trailing: isToday
                                ? Chip(
                                    label: const Text('Hoy'),
                                    backgroundColor: colorScheme.primary
                                        .withValues(alpha: 0.15),
                                    labelStyle: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            onTap: () => _openDetail(person),
                          ),
                        );
                      },
                    ),
                  );
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
