import 'package:flutter/material.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import 'package:share_plus/share_plus.dart';
import '../models/people_filter_options.dart';
import '../models/person_filters.dart';
import '../person_repository.dart';
import '../utils/person_excel_exporter.dart';

class PersonExportScreen extends StatefulWidget {
  final PersonRepository repository;
  final PeopleFilterOptions options;
  final PersonFilters filters;
  final List<int> personIds;

  const PersonExportScreen({
    super.key,
    required this.repository,
    required this.options,
    required this.filters,
    this.personIds = const [],
  });

  @override
  State<PersonExportScreen> createState() => _PersonExportScreenState();
}

class _PersonExportScreenState extends State<PersonExportScreen> {
  late Set<String> _selected;
  bool _exporting = false;

  bool get _hasSelection => widget.personIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final defaults = widget.options.defaultExportColumns;
    _selected = defaults.isNotEmpty
        ? defaults.toSet()
        : widget.options.exportColumns
            .where((c) => c.source == 'fixed')
            .map((c) => c.key)
            .take(10)
            .toSet();
  }

  Future<void> _export() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una columna')),
      );
      return;
    }

    setState(() => _exporting = true);
    try {
      final result = await widget.repository.exportPeople(
        columns: _selected.toList(),
        filters: _hasSelection ? null : widget.filters,
        personIds: _hasSelection ? widget.personIds : null,
      );

      if (!mounted) return;

      final shareResult = await PersonExcelExporter.shareExcel(
        bytes: result.bytes,
        filename: result.filename,
      );

      if (!mounted) return;

      if (shareResult.status == ShareResultStatus.dismissed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exportación cancelada. El archivo no se compartió.'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Excel listo: ${result.filename}. Usa el menú del sistema para guardar o compartir.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final message = () {
        final raw = e.toString();
        if (raw.contains('MissingPluginException')) {
          return 'Hay que reiniciar la app por completo (detener flutter run y volver a lanzarlo) para registrar los plugins de archivos.';
        }
        if (raw.contains('_Namespace') ||
            raw.contains('Unsupported operation')) {
          return 'Error de almacenamiento en el dispositivo. Detén la app, ejecuta flutter run de nuevo e inténtalo otra vez.';
        }
        return 'Error al exportar: $e';
      }();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fixed = widget.options.exportColumns
        .where((c) => c.source == 'fixed')
        .toList();
    final custom = widget.options.exportColumns
        .where((c) => c.source != 'fixed' && c.active)
        .toList();

    return Scaffold(
      appBar: const DefaultSectionAppBar(titleText: 'Exportar Excel'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _hasSelection
                        ? 'Se exportarán ${widget.personIds.length} persona(s) seleccionada(s).'
                        : 'Sin selección: se exportarán las personas según los filtros actuales del listado.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Elige las columnas. Al generar se abrirá el menú del sistema '
                  'para guardar o compartir el Excel.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                TextButton(
                  onPressed: _exporting
                      ? null
                      : () => setState(
                            () => _selected = widget.options.exportColumns
                                .where((c) => c.active)
                                .map((c) => c.key)
                                .toSet(),
                          ),
                  child: const Text('Todas'),
                ),
                TextButton(
                  onPressed: _exporting
                      ? null
                      : () => setState(() {
                            _selected = widget.options.defaultExportColumns
                                .toSet();
                          }),
                  child: const Text('Por defecto'),
                ),
                TextButton(
                  onPressed: _exporting
                      ? null
                      : () => setState(() => _selected.clear()),
                  child: const Text('Ninguna'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                const ListTile(
                  title: Text(
                    'Campos fijos',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                ...fixed.map(_columnTile),
                if (custom.isNotEmpty) ...[
                  const ListTile(
                    title: Text(
                      'Campos personalizados',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  ...custom.map(_columnTile),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _exporting ? null : _export,
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share),
            label: Text(
              _exporting
                  ? 'Generando…'
                  : 'Generar y compartir (${_selected.length} cols)',
            ),
          ),
        ),
      ),
    );
  }

  Widget _columnTile(ExportColumnOption col) {
    final selected = _selected.contains(col.key);
    return CheckboxListTile(
      value: selected,
      title: Text(col.label),
      subtitle: Text(col.key, style: const TextStyle(fontSize: 12)),
      onChanged: _exporting
          ? null
          : (v) {
              setState(() {
                if (v == true) {
                  _selected.add(col.key);
                } else {
                  _selected.remove(col.key);
                }
              });
            },
    );
  }
}
