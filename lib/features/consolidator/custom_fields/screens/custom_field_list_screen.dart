import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import 'package:ms_app/features/auth/bloc/auth_bloc.dart';
import 'package:ms_app/features/auth/bloc/auth_state.dart';
import '../custom_field_bloc.dart';
import '../custom_field_repository.dart';
import '../models/custom_field_model.dart';
import 'custom_field_form_screen.dart';

class CustomFieldListScreen extends StatefulWidget {
  const CustomFieldListScreen({super.key});

  @override
  State<CustomFieldListScreen> createState() => _CustomFieldListScreenState();
}

class _CustomFieldListScreenState extends State<CustomFieldListScreen> {
  bool? _activeFilter = true;

  CustomFieldRepository get _repository =>
      context.read<CustomFieldBloc>().repository;

  void _reload() {
    context.read<CustomFieldBloc>().add(LoadCustomFields(active: _activeFilter));
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CustomFieldFormScreen(repository: _repository),
      ),
    );
    if (created == true && mounted) _reload();
  }

  Future<void> _openEdit(CustomFieldModel field) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CustomFieldFormScreen(
          repository: _repository,
          initialField: field,
        ),
      ),
    );
    if (updated == true && mounted) _reload();
  }

  Future<void> _confirmDeactivate(CustomFieldModel field) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desactivar campo'),
        content: Text(
          '¿Desactivar "${field.name}"? Dejará de aparecer en formularios nuevos.',
        ),
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
      context.read<CustomFieldBloc>().add(DeactivateCustomField(field.id));
    }
  }

  bool _isAdmin(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticated && authState.user.isAdmin;
  }

  Future<void> _confirmPurge(CustomFieldModel field) async {
    final isAdmin = _isAdmin(context);
    final hasValues = field.valuesCount > 0;

    if (hasValues && !isAdmin) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No se puede eliminar'),
          content: Text(
            'El campo "${field.name}" tiene ${field.valuesCount} valor(es) '
            'guardados. Solo un administrador puede borrarlo con datos. '
            'Contacta al admin o desactiva el campo.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    var force = false;
    if (hasValues && isAdmin) {
      var acknowledged = false;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Eliminar permanentemente'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Se borrará el campo "${field.name}" y '
                  '${field.valuesCount} valor(es) asociados. '
                  'Esta acción no se puede deshacer.',
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: acknowledged,
                  onChanged: (v) =>
                      setDialogState(() => acknowledged = v ?? false),
                  title: const Text('Entiendo que se perderán los datos'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                ),
                onPressed: acknowledged ? () => Navigator.of(ctx).pop(true) : null,
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ),
      );
      if (ok != true || !mounted) return;
      force = true;
    } else {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Eliminar permanentemente'),
          content: Text(
            '¿Borrar el campo "${field.name}" de forma permanente? '
            'No tiene valores guardados.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    if (mounted) {
      context.read<CustomFieldBloc>().add(
        PurgeCustomField(field.id, force: force),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const DefaultSectionAppBar(titleText: 'Campos personalizados'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo campo'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Activos'),
                  selected: _activeFilter == true,
                  onSelected: (_) {
                    setState(() => _activeFilter = true);
                    _reload();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Inactivos'),
                  selected: _activeFilter == false,
                  onSelected: (_) {
                    setState(() => _activeFilter = false);
                    _reload();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Todos'),
                  selected: _activeFilter == null,
                  onSelected: (_) {
                    setState(() => _activeFilter = null);
                    _reload();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<CustomFieldBloc, CustomFieldState>(
              listener: (context, state) {
                if (state is CustomFieldSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                } else if (state is CustomFieldError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                if (state is CustomFieldLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CustomFieldsLoaded) {
                  if (state.fields.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.tune,
                            size: 64,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          const Text('No hay campos personalizados'),
                          const SizedBox(height: 8),
                          const Text(
                            'Crea campos como bautismo, ministerios, etc.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemCount: state.fields.length,
                      itemBuilder: (context, index) {
                        final field = state.fields[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  colorScheme.primary.withValues(alpha: 0.14),
                              child: Icon(
                                Icons.input,
                                color: colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              field.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${CustomFieldModel.typeLabel(field.fieldType)}'
                              ' · ${field.key}'
                              '${field.required ? ' · Oblig. app' : ''}'
                              '${field.includeInPublicForm ? ' · Web' : ''}'
                              '${field.includeInPublicForm && field.publicRequired ? ' · Oblig. web' : ''}'
                              '${field.valuesCount > 0 ? ' · ${field.valuesCount} valor(es)' : ''}'
                              '${field.active ? '' : ' · Inactivo'}',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openEdit(field);
                                } else if (value == 'deactivate') {
                                  _confirmDeactivate(field);
                                } else if (value == 'reactivate') {
                                  context.read<CustomFieldBloc>().add(
                                    ReactivateCustomField(field.id),
                                  );
                                } else if (value == 'purge') {
                                  _confirmPurge(field);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Editar'),
                                ),
                                if (field.active)
                                  const PopupMenuItem(
                                    value: 'deactivate',
                                    child: Text('Desactivar'),
                                  )
                                else
                                  const PopupMenuItem(
                                    value: 'reactivate',
                                    child: Text('Reactivar'),
                                  ),
                                if (field.purgeableWithoutForce ||
                                    _isAdmin(context))
                                  PopupMenuItem(
                                    value: 'purge',
                                    child: Text(
                                      'Eliminar permanentemente',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () => _openEdit(field),
                          ),
                        );
                      },
                    ),
                  );
                }
                if (state is CustomFieldError) {
                  return Center(child: Text(state.message));
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
