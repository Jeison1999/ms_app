import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import 'package:ms_app/features/auth/bloc/auth_bloc.dart';
import 'package:ms_app/features/auth/bloc/auth_state.dart';
import 'package:ms_app/features/consolidator/custom_fields/custom_field_repository.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/person_model.dart';
import '../person_bloc.dart';
import '../person_repository.dart';
import 'person_form_screen.dart';

class PersonDetailScreen extends StatelessWidget {
  final PersonRepository repository;
  final int personId;

  const PersonDetailScreen({
    super.key,
    required this.repository,
    required this.personId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PersonBloc(repository)..add(LoadPersonDetail(personId)),
      child: _PersonDetailView(
        personId: personId,
        repository: repository,
      ),
    );
  }
}

class _PersonDetailView extends StatefulWidget {
  final int personId;
  final PersonRepository repository;

  const _PersonDetailView({
    required this.personId,
    required this.repository,
  });

  @override
  State<_PersonDetailView> createState() => _PersonDetailViewState();
}

class _PersonDetailViewState extends State<_PersonDetailView> {
  PersonModel? _person;
  Map<int, String> _fieldNames = {};

  @override
  void initState() {
    super.initState();
    _loadFieldNames();
  }

  Future<void> _loadFieldNames() async {
    try {
      final repo = CustomFieldRepository(
        apiClient: widget.repository.apiClient,
      );
      final fields = await repo.getCustomFields();
      if (!mounted) return;
      setState(() {
        _fieldNames = {for (final f in fields) f.id: f.name};
      });
    } catch (_) {
      // Detalle sigue funcionando sin nombres de campos.
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  String _sexLabel(String? sex) {
    switch (sex) {
      case 'male':
        return 'Masculino';
      case 'female':
        return 'Femenino';
      case 'other':
        return 'Otro';
      case 'unspecified':
        return 'No especificado';
      default:
        return '—';
    }
  }

  Future<void> _openEdit() async {
    final person = _person;
    if (person == null) return;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PersonFormScreen(
          repository: widget.repository,
          initialPerson: person,
        ),
      ),
    );

    if (updated == true && mounted) {
      context.read<PersonBloc>().add(LoadPersonDetail(widget.personId));
    }
  }

  Future<void> _deactivate() async {
    final person = _person;
    if (person == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
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

  Future<void> _purge() async {
    final person = _person;
    if (person == null) return;

    final confirmation = await showDialog<String>(
      context: context,
      builder: (_) => _PurgePersonDialog(fullName: person.fullName),
    );
    if (confirmation == null || confirmation.isEmpty || !mounted) return;

    context.read<PersonBloc>().add(
      PurgePerson(person.id, confirmation: confirmation),
    );
  }

  void _reactivate() {
    final person = _person;
    if (person == null) return;
    context.read<PersonBloc>().add(ReactivatePerson(person.id));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<PersonBloc, PersonState>(
      listener: (context, state) {
        if (state is PersonDetailLoaded) {
          _person = state.person;
        } else if (state is PersonSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          // Tras desactivar/reactivar, refrescar o volver al listado
          if (state.message.contains('desactivada') ||
              state.message.contains('eliminada permanentemente')) {
            Navigator.of(context).pop(true);
          } else {
            context.read<PersonBloc>().add(
              LoadPersonDetail(widget.personId),
            );
          }
        } else if (state is PersonError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final loading = state is PersonLoading;
        final authState = context.watch<AuthBloc>().state;
        final isAdmin =
            authState is AuthAuthenticated && authState.user.isAdmin;

        return Scaffold(
          appBar: const DefaultSectionAppBar(titleText: 'Detalle de persona'),
          floatingActionButton: _person != null
              ? FloatingActionButton(
                  onPressed: loading ? null : _openEdit,
                  child: const Icon(Icons.edit),
                )
              : null,
          body: Builder(
            builder: (_) {
              if (state is PersonLoading && _person == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is PersonError && _person == null) {
                return Center(child: Text(state.message));
              }

              final person = _person;
              if (person == null) {
                return const Center(
                  child: Text('No se pudo cargar la persona.'),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.14),
                      backgroundImage:
                          person.photoUrl != null &&
                              person.photoUrl!.isNotEmpty
                          ? NetworkImage(person.photoUrl!)
                          : null,
                      child:
                          person.photoUrl == null || person.photoUrl!.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 52,
                              color: colorScheme.primary,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    person.fullName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: person.isActive
                            ? colorScheme.primary.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        person.isActive ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: person.isActive
                              ? colorScheme.primary
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if ((person.qrPayload != null &&
                          person.qrPayload!.isNotEmpty) ||
                      (person.code != null && person.code!.isNotEmpty)) ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          children: [
                            QrImageView(
                              data: person.qrPayload ??
                                  'MS-PERSON:${person.code}',
                              version: QrVersions.auto,
                              size: 180,
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              person.code != null
                                  ? 'ID ${person.code}'
                                  : (person.qrPayload ?? ''),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: colorScheme.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                final payload = person.qrPayload ??
                                    'MS-PERSON:${person.code}';
                                await Clipboard.setData(
                                  ClipboardData(text: payload),
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Código QR copiado'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copiar payload'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _InfoCard(
                    title: 'Identificación',
                    children: [
                      _InfoRow(
                        label: 'Código',
                        value: person.code ?? '—',
                      ),
                      _InfoRow(
                        label: 'Edad',
                        value: person.age != null
                            ? '${person.age} años'
                            : '—',
                      ),
                      if (person.turningAge != null ||
                          person.isBirthdayToday == true)
                        _InfoRow(
                          label: 'Cumpleaños',
                          value: person.isBirthdayToday == true
                              ? '¡Hoy cumple ${person.turningAge ?? person.age ?? ''}!'
                              : (person.turningAge != null
                                  ? 'Cumple ${person.turningAge} este año'
                                  : '—'),
                        ),
                      _InfoRow(
                        label: 'Documento',
                        value: person.documentType != null &&
                                person.documentNumber != null
                            ? '${person.documentType} ${person.documentNumber}'
                            : '—',
                      ),
                      _InfoRow(
                        label: 'Fecha de nacimiento',
                        value: _formatDate(person.birthDate),
                      ),
                      _InfoRow(label: 'Sexo', value: _sexLabel(person.sex)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Contacto',
                    children: [
                      _InfoRow(label: 'Teléfono', value: person.phone ?? '—'),
                      _InfoRow(label: 'Email', value: person.email ?? '—'),
                      _InfoRow(
                        label: 'Dirección',
                        value: person.address ?? '—',
                      ),
                      _InfoRow(label: 'Ciudad', value: person.city ?? '—'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Registro',
                    children: [
                      _InfoRow(
                        label: 'Registrado',
                        value: _formatDate(person.registeredAt),
                      ),
                      _InfoRow(
                        label: 'Creado',
                        value: _formatDate(person.createdAt),
                      ),
                      _InfoRow(
                        label: 'Actualizado',
                        value: _formatDate(person.updatedAt),
                      ),
                    ],
                  ),
                  if (person.customValues.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoCard(
                      title: 'Campos adicionales',
                      children: person.customValues.map((cv) {
                        final label = cv.customField?.name ??
                            _fieldNames[cv.customFieldId] ??
                            'Campo #${cv.customFieldId}';
                        return _InfoRow(
                          label: label,
                          value: cv.displayValue(),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (person.isActive)
                    OutlinedButton.icon(
                      onPressed: loading ? null : _deactivate,
                      icon: const Icon(Icons.person_off_outlined),
                      label: const Text('Desactivar'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: loading ? null : _reactivate,
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text('Reactivar'),
                    ),
                  if (isAdmin) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: loading ? null : _purge,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                      ),
                      icon: const Icon(Icons.delete_forever_outlined),
                      label: const Text('Eliminar permanentemente'),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurgePersonDialog extends StatefulWidget {
  final String fullName;

  const _PurgePersonDialog({required this.fullName});

  @override
  State<_PurgePersonDialog> createState() => _PurgePersonDialogState();
}

class _PurgePersonDialogState extends State<_PurgePersonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    Navigator.of(context).pop(text.isEmpty ? null : text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eliminar permanentemente'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Esta acción es irreversible. Se borrarán todos los datos de '
            '"${widget.fullName}" (asistencia, campos, solicitudes, etc.).',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Escribe "${widget.fullName}" o ELIMINAR',
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: _submit,
          child: const Text('Eliminar para siempre'),
        ),
      ],
    );
  }
}
