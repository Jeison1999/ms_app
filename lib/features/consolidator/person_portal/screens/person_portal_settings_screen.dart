import 'package:flutter/material.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import '../models/person_portal_model.dart';
import '../person_portal_repository.dart';

class PersonPortalSettingsScreen extends StatefulWidget {
  final PersonPortalRepository repository;

  const PersonPortalSettingsScreen({super.key, required this.repository});

  @override
  State<PersonPortalSettingsScreen> createState() =>
      _PersonPortalSettingsScreenState();
}

class _PersonPortalSettingsScreenState
    extends State<PersonPortalSettingsScreen> {
  PersonPortalModel? _portal;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  late final TextEditingController _title;
  late final TextEditingController _description;
  bool _enabled = false;
  bool _allowRegister = true;
  bool _allowUpdate = true;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _description = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final portal = await widget.repository.getPortal();
      if (!mounted) return;
      setState(() {
        _portal = portal;
        _enabled = portal.enabled;
        _allowRegister = portal.allowRegister;
        _allowUpdate = portal.allowUpdate;
        _title.text = portal.title;
        _description.text = portal.description ?? '';
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await widget.repository.updatePortal({
        'enabled': _enabled,
        'title': _title.text.trim(),
        'description': _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        'allow_register': _allowRegister,
        'allow_update': _allowUpdate,
      });
      if (!mounted) return;
      setState(() {
        _portal = updated;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.enabled
                ? 'Portal activo en la web'
                : 'Portal desactivado en la web',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const DefaultSectionAppBar(titleText: 'Portal web'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (_enabled
                                ? Colors.green
                                : colorScheme.outline)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _enabled
                                ? Icons.public
                                : Icons.public_off_outlined,
                            color: _enabled ? Colors.green : Colors.black54,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _enabled
                                  ? 'La sección está visible en la web pública'
                                  : 'La sección está oculta en la web',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_portal != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Pendientes: ${_portal!.pendingRegistrationsCount} · '
                        'Campos públicos: ${_portal!.publicCustomFieldsCount}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      if (_portal!.autoEnabledReason != null &&
                          _portal!.autoEnabledReason!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Auto-activado: ${_portal!.autoEnabledReason}',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Portal habilitado'),
                      subtitle: const Text(
                        'Si está apagado, Angular no muestra el módulo',
                      ),
                      value: _enabled,
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _enabled = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Permitir altas'),
                      value: _allowRegister,
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _allowRegister = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Permitir actualizaciones'),
                      value: _allowUpdate,
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _allowUpdate = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _title,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'Título en la web',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _description,
                      enabled: !_saving,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(_saving ? 'Guardando…' : 'Guardar cambios'),
                      ),
                    ),
                  ],
                ),
    );
  }
}
