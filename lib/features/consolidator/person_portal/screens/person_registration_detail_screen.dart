import 'package:flutter/material.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import '../models/person_registration_model.dart';
import '../person_portal_repository.dart';

class PersonRegistrationDetailScreen extends StatefulWidget {
  final PersonPortalRepository repository;
  final int registrationId;

  const PersonRegistrationDetailScreen({
    super.key,
    required this.repository,
    required this.registrationId,
  });

  @override
  State<PersonRegistrationDetailScreen> createState() =>
      _PersonRegistrationDetailScreenState();
}

class _PersonRegistrationDetailScreenState
    extends State<PersonRegistrationDetailScreen> {
  PersonRegistrationModel? _reg;
  bool _loading = true;
  bool _acting = false;
  String? _error;

  static const _fieldLabels = <String, String>{
    'first_name': 'Nombres',
    'last_name': 'Apellidos',
    'document_type': 'Tipo doc.',
    'document_number': 'Documento',
    'birth_date': 'Fecha nac.',
    'sex': 'Sexo',
    'phone': 'Teléfono',
    'email': 'Email',
    'address': 'Dirección',
    'city': 'Ciudad',
    'photo_url': 'Foto',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reg = await widget.repository.getRegistration(widget.registrationId);
      if (!mounted) return;
      setState(() {
        _reg = reg;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Map<String, dynamic> get _personPayload {
    final payload = _reg?.payload;
    if (payload == null) return {};
    final person = payload['person'];
    if (person is Map) return Map<String, dynamic>.from(person);
    return {};
  }

  List<dynamic> get _customValues {
    final payload = _reg?.payload;
    if (payload == null) return const [];
    final values = payload['custom_values'];
    if (values is List) return values;
    return const [];
  }

  Future<void> _approve() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aprobar solicitud'),
        content: Text(
          _reg!.isCreate
              ? 'Se creará/activará la persona con estos datos.'
              : 'Se aplicarán los cambios a la ficha existente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _acting = true);
    try {
      await widget.repository.approve(widget.registrationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud aprobada')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _reject() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectRegistrationDialog(),
    );
    if (reason == null || !mounted) return;

    setState(() => _acting = true);
    try {
      await widget.repository.reject(
        widget.registrationId,
        rejectionReason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud rechazada')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _delete() async {
    final reg = _reg;
    if (reg == null || !reg.deletable) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar solicitud'),
        content: Text(
          '¿Eliminar esta solicitud rechazada de "${reg.listTitle}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _acting = true);
    try {
      await widget.repository.deleteRegistration(widget.registrationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud eliminada')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _label(String key) => _fieldLabels[key] ?? key;

  String _fmt(dynamic value) {
    if (value == null) return '—';
    if (value is bool) return value ? 'Sí' : 'No';
    if (value is List) return value.join(', ');
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final reg = _reg;

    return Scaffold(
      appBar: const DefaultSectionAppBar(titleText: 'Detalle solicitud'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : reg == null
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            children: [
                              Text(
                                reg.listTitle,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${reg.kindLabel} · ${reg.statusLabel}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              if (reg.rejectionReason != null) ...[
                                const SizedBox(height: 8),
                                Text('Motivo: ${reg.rejectionReason}'),
                              ],
                              const SizedBox(height: 18),
                              if (reg.diff.isNotEmpty) ...[
                                const Text(
                                  'Cambios propuestos',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                ...reg.diff.map(
                                  (d) => Card(
                                    child: ListTile(
                                      title: Text(_label(d.field)),
                                      subtitle: Text(
                                        '${_fmt(d.before)}  →  ${_fmt(d.after)}',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              const Text(
                                'Datos enviados',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 8),
                              ..._personPayload.entries.map(
                                (e) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(_label(e.key)),
                                  subtitle: Text(_fmt(e.value)),
                                ),
                              ),
                              if (_customValues.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Campos personalizados',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                ..._customValues.whereType<Map>().map((raw) {
                                  final map = Map<String, dynamic>.from(raw);
                                  final key = map['key'] ??
                                      map['custom_field_id'] ??
                                      'campo';
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(key.toString()),
                                    subtitle: Text(_fmt(map['value'])),
                                  );
                                }),
                              ],
                              if (reg.currentPerson != null) ...[
                                const SizedBox(height: 16),
                                const Text(
                                  'Ficha actual',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  reg.currentPerson!['full_name']?.toString() ??
                                      '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (reg.currentPerson!['code'] != null)
                                  Text('Código: ${reg.currentPerson!['code']}'),
                              ],
                            ],
                          ),
                        ),
                        if (reg.isPending)
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _acting ? null : _reject,
                                      child: const Text('Rechazar'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: _acting ? null : _approve,
                                      child: Text(
                                        _acting ? 'Procesando…' : 'Aprobar',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (reg.deletable)
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _acting ? null : _delete,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).colorScheme.error,
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                  label: Text(
                                    _acting ? 'Eliminando…' : 'Eliminar solicitud',
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }
}

class _RejectRegistrationDialog extends StatefulWidget {
  const _RejectRegistrationDialog();

  @override
  State<_RejectRegistrationDialog> createState() =>
      _RejectRegistrationDialogState();
}

class _RejectRegistrationDialogState extends State<_RejectRegistrationDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rechazar solicitud'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Motivo (opcional)',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Rechazar'),
        ),
      ],
    );
  }
}
