import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import '../models/person_model.dart';
import '../person_bloc.dart';
import '../person_repository.dart';
import '../widgets/create_person_fab.dart';
import '../widgets/person_card.dart';
import 'person_detail_screen.dart';
import 'person_form_screen.dart';

class PersonListScreen extends StatefulWidget {
  const PersonListScreen({super.key});

  @override
  State<PersonListScreen> createState() => _PersonListScreenState();
}

class _PersonListScreenState extends State<PersonListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _statusFilter = 'active'; // active | inactive | '' (todos)

  PersonRepository get _repository =>
      context.read<PersonBloc>().repository;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    context.read<PersonBloc>().add(
      LoadPeople(
        q: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        status: _statusFilter.isEmpty ? null : _statusFilter,
      ),
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _reload);
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PersonFormScreen(repository: _repository),
      ),
    );
    if (created == true && mounted) _reload();
  }

  Future<void> _openEdit(PersonModel person) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PersonFormScreen(
          repository: _repository,
          initialPerson: person,
        ),
      ),
    );
    if (updated == true && mounted) _reload();
  }

  Future<void> _openDetail(int id) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PersonDetailScreen(
          repository: _repository,
          personId: id,
        ),
      ),
    );
    if (changed == true && mounted) _reload();
  }

  Future<void> _confirmDeactivate(PersonModel person) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar persona'),
        content: Text('¿Desactivar a "${person.fullName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<PersonBloc>().add(DeactivatePerson(person.id));
    }
  }

  Future<void> _reactivate(PersonModel person) async {
    context.read<PersonBloc>().add(ReactivatePerson(person.id));
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay personas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const DefaultSectionAppBar(titleText: 'Personas'),
      floatingActionButton: CreatePersonFab(onPressed: _openCreate),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, documento...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _reload();
                          setState(() {});
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatusChip(
                  label: 'Activos',
                  selected: _statusFilter == 'active',
                  onSelected: () {
                    setState(() => _statusFilter = 'active');
                    _reload();
                  },
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'Inactivos',
                  selected: _statusFilter == 'inactive',
                  onSelected: () {
                    setState(() => _statusFilter = 'inactive');
                    _reload();
                  },
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'Todos',
                  selected: _statusFilter.isEmpty,
                  onSelected: () {
                    setState(() => _statusFilter = '');
                    _reload();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocConsumer<PersonBloc, PersonState>(
              listener: (context, state) {
                if (state is PersonSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                  _reload();
                } else if (state is PersonError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                if (state is PersonLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is PeopleLoaded) {
                  if (state.people.isEmpty) return _buildEmptyState();
                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Total: ${state.total} personas',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...state.people.map(
                          (person) => PersonCard(
                            person: person,
                            onTap: () => _openDetail(person.id),
                            onEdit: () => _openEdit(person),
                            onDeactivate: person.isActive
                                ? () => _confirmDeactivate(person)
                                : null,
                            onReactivate: !person.isActive
                                ? () => _reactivate(person)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (state is PersonError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: colorScheme.primary.withValues(alpha: 0.18),
      checkmarkColor: colorScheme.primary,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected ? colorScheme.primary : Colors.black87,
      ),
    );
  }
}
