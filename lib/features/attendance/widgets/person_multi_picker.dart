import 'package:flutter/material.dart';
import 'package:ms_app/features/consolidator/people/models/person_filters.dart';
import 'package:ms_app/features/consolidator/people/models/person_model.dart';
import 'package:ms_app/features/consolidator/people/person_repository.dart';

Future<List<int>?> showPersonMultiPicker({
  required BuildContext context,
  required PersonRepository repository,
  Set<int> initiallySelected = const {},
  Set<int> excludeIds = const {},
  String title = 'Seleccionar personas',
}) {
  return showModalBottomSheet<List<int>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PersonMultiPickerSheet(
      repository: repository,
      initiallySelected: initiallySelected,
      excludeIds: excludeIds,
      title: title,
    ),
  );
}

class _PersonMultiPickerSheet extends StatefulWidget {
  final PersonRepository repository;
  final Set<int> initiallySelected;
  final Set<int> excludeIds;
  final String title;

  const _PersonMultiPickerSheet({
    required this.repository,
    required this.initiallySelected,
    required this.excludeIds,
    required this.title,
  });

  @override
  State<_PersonMultiPickerSheet> createState() =>
      _PersonMultiPickerSheetState();
}

class _PersonMultiPickerSheetState extends State<_PersonMultiPickerSheet> {
  late final Set<int> _selected;
  List<PersonModel> _people = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initiallySelected};
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.getPeople(
        filters: PersonFilters(status: 'active'),
      );
      if (!mounted) return;
      setState(() {
        _people = result.people
            .where((p) => !widget.excludeIds.contains(p.id))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.trim().isEmpty
        ? _people
        : _people.where((p) {
            final q = _query.toLowerCase();
            return p.fullName.toLowerCase().contains(q) ||
                (p.documentNumber?.toLowerCase().contains(q) ?? false) ||
                (p.code?.toLowerCase().contains(q) ?? false);
          }).toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(
                    () => _selected
                      ..clear()
                      ..addAll(filtered.map((p) => p.id)),
                  ),
                  child: const Text('Todos'),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final person = filtered[index];
                          final checked = _selected.contains(person.id);
                          return CheckboxListTile(
                            value: checked,
                            title: Text(person.fullName),
                            subtitle: Text(
                              [
                                if (person.code != null) 'ID ${person.code}',
                                if (person.phone != null) person.phone!,
                              ].join(' · '),
                            ),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selected.add(person.id);
                                } else {
                                  _selected.remove(person.id);
                                }
                              });
                            },
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                onPressed: () =>
                    Navigator.pop(context, _selected.toList()),
                child: Text('Confirmar (${_selected.length})'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
