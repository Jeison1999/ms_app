import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import '../models/people_filter_options.dart';
import '../models/person_filters.dart';
import '../models/person_model.dart';
import '../person_bloc.dart';
import '../person_repository.dart';
import '../widgets/create_person_fab.dart';
import '../widgets/people_filters_sheet.dart';
import '../widgets/person_card.dart';
import 'person_detail_screen.dart';
import 'person_export_screen.dart';
import 'person_form_screen.dart';

class PersonListScreen extends StatefulWidget {
  const PersonListScreen({super.key});

  @override
  State<PersonListScreen> createState() => _PersonListScreenState();
}

class _PersonListScreenState extends State<PersonListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  PersonFilters _filters = PersonFilters(status: 'active');
  PeopleFilterOptions? _options;
  bool _loadingOptions = false;
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  PersonRepository get _repository =>
      context.read<PersonBloc>().repository;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOptions());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() => _loadingOptions = true);
    try {
      final options = await _repository.getFilterOptions();
      if (!mounted) return;
      setState(() => _options = options);
    } catch (_) {
      // Filtros básicos siguen disponibles sin catálogo.
    } finally {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  void _reload() {
    _filters.q = _searchController.text.trim().isEmpty
        ? null
        : _searchController.text.trim();
    context.read<PersonBloc>().add(LoadPeople(filters: _filters.copy()));
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _reload);
    setState(() {});
  }

  Future<void> _openFilters() async {
    PeopleFilterOptions options;
    final cached = _options;
    if (cached != null) {
      options = cached;
    } else {
      setState(() => _loadingOptions = true);
      try {
        options = await _repository.getFilterOptions();
        if (!mounted) return;
        setState(() => _options = options);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cargar filtros: $e')),
        );
        return;
      } finally {
        if (mounted) setState(() => _loadingOptions = false);
      }
    }

    if (!mounted) return;

    final result = await showPeopleFiltersSheet(
      context: context,
      options: options,
      initial: _filters,
    );
    if (result != null && mounted) {
      setState(() => _filters = result);
      _reload();
    }
  }

  Future<void> _openExport() async {
    PeopleFilterOptions options;
    final cached = _options;
    if (cached != null) {
      options = cached;
    } else {
      try {
        options = await _repository.getFilterOptions();
        if (!mounted) return;
        setState(() => _options = options);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cargar columnas: $e')),
        );
        return;
      }
    }

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonExportScreen(
          repository: _repository,
          options: options,
          filters: _filters.copy(),
          personIds: _selectedIds.toList(),
        ),
      ),
    );
  }

  void _toggleSelected(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
      if (_selectedIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _enterSelectionMode(int id) {
    setState(() {
      _selectionMode = true;
      _selectedIds
        ..clear()
        ..add(id);
    });
  }

  void _selectAllVisible(List<PersonModel> people) {
    setState(() {
      _selectionMode = true;
      _selectedIds
        ..clear()
        ..addAll(people.map((p) => p.id));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _selectionMode = false;
    });
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

  String _monthLabel(int month) {
    final fromOptions = _options?.birthdayMonths
        .where((m) => m.value == month)
        .map((m) => m.label);
    if (fromOptions != null && fromOptions.isNotEmpty) {
      return fromOptions.first;
    }
    const names = [
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
    return month >= 1 && month <= 12 ? names[month] : '$month';
  }

  String _customLabel(String key) {
    final field = _options?.customFields.where((f) => f.key == key);
    if (field != null && field.isNotEmpty) return field.first.name;
    return key;
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
          if (_filters.hasAnyAdvanced ||
              (_filters.q != null && _filters.q!.isNotEmpty)) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _filters.clearAdvanced();
                  _filters.status = 'active';
                  _searchController.clear();
                  _filters.q = null;
                });
                _reload();
              },
              child: const Text('Limpiar filtros'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chips = _filters.buildChips(
      monthLabel: _monthLabel,
      customFieldLabel: _customLabel,
    );

    return Scaffold(
      appBar: DefaultSectionAppBar(
        titleText: 'Personas',
        customActions: [
          IconButton(
            tooltip: _selectedIds.isEmpty
                ? 'Exportar Excel (filtros)'
                : 'Exportar ${_selectedIds.length} seleccionada(s)',
            onPressed: _openExport,
            icon: Badge(
              isLabelVisible: _selectedIds.isNotEmpty,
              label: Text('${_selectedIds.length}'),
              child: const Icon(Icons.file_download_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Filtros',
            onPressed: _loadingOptions ? null : _openFilters,
            icon: Badge(
              isLabelVisible: _filters.advancedCount > 0,
              label: Text('${_filters.advancedCount}'),
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
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
                          _filters.q = null;
                          _reload();
                          setState(() {});
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (chips.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                itemCount: chips.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final chip = chips[index];
                  return InputChip(
                    label: Text(chip.label),
                    onDeleted: () {
                      setState(() => chip.onClear());
                      _reload();
                    },
                  );
                },
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
                  final allSelected = state.people.isNotEmpty &&
                      state.people.every((p) => _selectedIds.contains(p.id));
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
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  !_selectionMode
                                      ? 'Total: ${state.total} personas · Mantén pulsado para seleccionar'
                                      : '${_selectedIds.length} seleccionada(s) · ${state.total} en listado',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                              if (_selectionMode) ...[
                                TextButton(
                                  onPressed: allSelected
                                      ? () => setState(() => _selectedIds.clear())
                                      : () => _selectAllVisible(state.people),
                                  child: Text(
                                    allSelected ? 'Ninguno' : 'Todos',
                                  ),
                                ),
                                TextButton(
                                  onPressed: _clearSelection,
                                  child: const Text('Listo'),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...state.people.map(
                          (person) => PersonCard(
                            person: person,
                            selectionMode: _selectionMode,
                            selected: _selectedIds.contains(person.id),
                            onSelectedChanged: (v) =>
                                _toggleSelected(person.id, v),
                            onLongPress: () => _enterSelectionMode(person.id),
                            onTap: () => _openDetail(person.id),
                            onEdit: () => _openEdit(person),
                            onDeactivate: person.isActive
                                ? () => _confirmDeactivate(person)
                                : null,
                            onReactivate: !person.isActive
                                ? () => context
                                    .read<PersonBloc>()
                                    .add(ReactivatePerson(person.id))
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
