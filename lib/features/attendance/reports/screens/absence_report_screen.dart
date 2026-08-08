import 'package:flutter/material.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import 'package:ms_app/features/attendance/attendance_repository.dart';
import 'package:ms_app/features/attendance/models/absence_report.dart';
import 'package:ms_app/features/attendance/models/attendance_group.dart';
import 'package:ms_app/features/consolidator/people/utils/person_excel_exporter.dart';
import 'package:share_plus/share_plus.dart';

class AbsenceReportScreen extends StatefulWidget {
  final AttendanceRepository attendanceRepository;

  const AbsenceReportScreen({
    super.key,
    required this.attendanceRepository,
  });

  @override
  State<AbsenceReportScreen> createState() => _AbsenceReportScreenState();
}

class _AbsenceReportScreenState extends State<AbsenceReportScreen> {
  List<AttendanceGroup> _groups = [];
  AttendanceGroup? _group;
  late int _year;
  int? _month;
  bool _flaggedOnly = true;
  bool _loadingGroups = true;
  bool _loadingReport = false;
  bool _exporting = false;
  AbsenceReportResult? _report;
  String? _error;

  static const _months = <int?, String>{
    null: 'Todo el año',
    1: 'Enero',
    2: 'Febrero',
    3: 'Marzo',
    4: 'Abril',
    5: 'Mayo',
    6: 'Junio',
    7: 'Julio',
    8: 'Agosto',
    9: 'Septiembre',
    10: 'Octubre',
    11: 'Noviembre',
    12: 'Diciembre',
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _loadingGroups = true;
      _error = null;
    });
    try {
      final groups = await widget.attendanceRepository.getGroups(active: true);
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _group = groups.isNotEmpty ? groups.first : null;
        _loadingGroups = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingGroups = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadReport() async {
    final group = _group;
    if (group == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un grupo')),
      );
      return;
    }
    setState(() {
      _loadingReport = true;
      _error = null;
    });
    try {
      final report = await widget.attendanceRepository.getAbsencesReport(
        groupId: group.id,
        year: _year,
        month: _month,
        flaggedOnly: _flaggedOnly,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _loadingReport = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingReport = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _export() async {
    final group = _group;
    if (group == null) return;
    setState(() => _exporting = true);
    try {
      final file = await widget.attendanceRepository.exportAbsencesReport(
        groupId: group.id,
        year: _year,
        month: _month,
        flaggedOnly: _flaggedOnly,
      );
      if (!mounted) return;
      final share = await PersonExcelExporter.shareExcel(
        bytes: file.bytes,
        filename: file.filename,
      );
      if (!mounted) return;
      if (share.status == ShareResultStatus.dismissed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exportación cancelada')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel listo: ${file.filename}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(5, (i) => DateTime.now().year - i);

    return Scaffold(
      appBar: DefaultSectionAppBar(
        titleText: 'Informe de ausencias',
        customActions: [
          IconButton(
            tooltip: 'Exportar Excel',
            onPressed: (_group == null || _exporting) ? null : _export,
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      body: _loadingGroups
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      DropdownButtonFormField<AttendanceGroup>(
                        // ignore: deprecated_member_use
                        value: _group,
                        decoration: const InputDecoration(
                          labelText: 'Grupo',
                          border: OutlineInputBorder(),
                        ),
                        items: _groups
                            .map(
                              (g) => DropdownMenuItem(
                                value: g,
                                child: Text(g.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _group = v),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              // ignore: deprecated_member_use
                              value: _year,
                              decoration: const InputDecoration(
                                labelText: 'Año',
                                border: OutlineInputBorder(),
                              ),
                              items: years
                                  .map(
                                    (y) => DropdownMenuItem(
                                      value: y,
                                      child: Text('$y'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _year = v ?? _year),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              // ignore: deprecated_member_use
                              value: _month,
                              decoration: const InputDecoration(
                                labelText: 'Mes',
                                border: OutlineInputBorder(),
                              ),
                              items: _months.entries
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Text(e.value),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _month = v),
                            ),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Solo flagged (necesitan visita)'),
                        value: _flaggedOnly,
                        onChanged: (v) => setState(() => _flaggedOnly = v),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loadingReport ? null : _loadReport,
                          child: Text(
                            _loadingReport ? 'Cargando…' : 'Consultar informe',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                Expanded(
                  child: _report == null
                      ? const Center(
                          child: Text('Consulta un informe para ver resultados'),
                        )
                      : _report!.people.isEmpty
                          ? const Center(child: Text('Sin resultados'))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: _report!.people.length + 1,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Text(
                                    'Total: ${_report!.total} · Flagged: ${_report!.flaggedCount}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                }
                                final person = _report!.people[index - 1];
                                return Card(
                                  color: person.flagged
                                      ? Colors.orange.withValues(alpha: 0.12)
                                      : null,
                                  child: ListTile(
                                    title: Text(
                                      person.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      [
                                        '${person.absenceCount}/${person.threshold} ausencias',
                                        if (person.phone != null) person.phone!,
                                        if (person.absentDates.isNotEmpty)
                                          person.absentDates.join(', '),
                                      ].join('\n'),
                                    ),
                                    isThreeLine: true,
                                    trailing: person.needsVisit
                                        ? const Chip(label: Text('Visita'))
                                        : null,
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
