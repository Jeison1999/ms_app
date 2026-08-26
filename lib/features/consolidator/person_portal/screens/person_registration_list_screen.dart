import 'package:flutter/material.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import '../models/person_registration_model.dart';
import '../person_portal_repository.dart';
import 'person_registration_detail_screen.dart';

class PersonRegistrationListScreen extends StatefulWidget {
  final PersonPortalRepository repository;

  const PersonRegistrationListScreen({super.key, required this.repository});

  @override
  State<PersonRegistrationListScreen> createState() =>
      _PersonRegistrationListScreenState();
}

class _PersonRegistrationListScreenState
    extends State<PersonRegistrationListScreen> {
  String _status = 'pending';
  String? _kind;
  bool _loading = true;
  String? _error;
  List<PersonRegistrationModel> _items = [];
  int _pendingCount = 0;

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
      final result = await widget.repository.getRegistrations(
        status: _status.isEmpty ? null : _status,
        kind: _kind,
      );
      if (!mounted) return;
      setState(() {
        _items = result.registrations;
        _pendingCount = result.pendingCount;
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

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: DefaultSectionAppBar(
        titleText: 'Solicitudes web',
        customActions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.white,
            elevation: 0.5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _pendingCount == 1
                              ? '1 solicitud pendiente'
                              : '$_pendingCount solicitudes pendientes',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Estado',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _StatusPill(
                          label: 'Pendientes',
                          selected: _status == 'pending',
                          onTap: () {
                            setState(() => _status = 'pending');
                            _load();
                          },
                        ),
                        _StatusPill(
                          label: 'Aprobadas',
                          selected: _status == 'approved',
                          onTap: () {
                            setState(() => _status = 'approved');
                            _load();
                          },
                        ),
                        _StatusPill(
                          label: 'Rechazadas',
                          selected: _status == 'rejected',
                          onTap: () {
                            setState(() => _status = 'rejected');
                            _load();
                          },
                        ),
                        _StatusPill(
                          label: 'Todas',
                          selected: _status.isEmpty,
                          onTap: () {
                            setState(() => _status = '');
                            _load();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tipo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _KindToggle(
                          label: 'Altas',
                          icon: Icons.person_add_alt_1_outlined,
                          selected: _kind == 'create',
                          onTap: () {
                            setState(
                              () => _kind =
                                  _kind == 'create' ? null : 'create',
                            );
                            _load();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _KindToggle(
                          label: 'Actualizaciones',
                          icon: Icons.edit_outlined,
                          selected: _kind == 'update',
                          onTap: () {
                            setState(
                              () => _kind =
                                  _kind == 'update' ? null : 'update',
                            );
                            _load();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _items.isEmpty
                        ? const Center(child: Text('No hay solicitudes'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: item.isCreate
                                          ? colorScheme.primary
                                              .withValues(alpha: 0.15)
                                          : Colors.orange
                                              .withValues(alpha: 0.15),
                                      child: Icon(
                                        item.isCreate
                                            ? Icons.person_add_alt_1
                                            : Icons.edit_outlined,
                                        color: item.isCreate
                                            ? colorScheme.primary
                                            : Colors.orange,
                                      ),
                                    ),
                                    title: Text(
                                      item.listTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${item.kindLabel} · ${item.statusLabel}'
                                      '${item.createdAt != null ? ' · ${_formatDate(item.createdAt)}' : ''}'
                                      '${item.summary?.documentNumber != null ? '\nDoc: ${item.summary!.documentNumber}' : ''}',
                                    ),
                                    isThreeLine:
                                        item.summary?.documentNumber != null,
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () async {
                                      final changed =
                                          await Navigator.of(context)
                                              .push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              PersonRegistrationDetailScreen(
                                            repository: widget.repository,
                                            registrationId: item.id,
                                          ),
                                        ),
                                      );
                                      if (changed == true && mounted) {
                                        _load();
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KindToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _KindToggle({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.12)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.45)
                  : colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? colorScheme.primary : Colors.black54,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? colorScheme.primary : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
