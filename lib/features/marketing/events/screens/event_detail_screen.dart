import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ms_app/features/auth/bloc/auth_bloc.dart';
import 'package:ms_app/features/auth/bloc/auth_event.dart';
import '../event_bloc.dart';
import '../event_repository.dart';
import '../models/event_model.dart';
import 'event_form_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final EventRepository repository;
  final int eventId;

  const EventDetailScreen({
    super.key,
    required this.repository,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EventBloc(repository)..add(LoadEventDetail(eventId)),
      child: _EventDetailView(eventId: eventId, repository: repository),
    );
  }
}

class _EventDetailView extends StatefulWidget {
  final int eventId;
  final EventRepository repository;

  const _EventDetailView({
    required this.eventId,
    required this.repository,
  });

  @override
  State<_EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<_EventDetailView> {
  EventModel? _event;

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString();
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  Future<void> _openEdit() async {
    final event = _event;
    if (event == null) return;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventFormScreen(
          repository: widget.repository,
          initialEvent: event,
        ),
      ),
    );

    if (updated == true && mounted) {
      context.read<EventBloc>().add(LoadEventDetail(widget.eventId));
    }
  }

  Future<void> _delete() async {
    final event = _event;
    if (event == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: Text('¿Seguro que deseas eliminar "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      context.read<EventBloc>().add(DeleteEvent(event.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EventBloc, EventState>(
      listener: (context, state) {
        if (state is EventDetailLoaded) {
          _event = state.event;
        } else if (state is EventSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          Navigator.of(context).pop(true);
        } else if (state is EventError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final loading = state is EventLoading;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalle del evento'),
            actions: [
              IconButton(
                onPressed: () {
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                },
                icon: const Icon(Icons.logout),
                tooltip: 'Cerrar sesión',
              ),
              IconButton(
                onPressed: loading ? null : _openEdit,
                icon: const Icon(Icons.edit),
                tooltip: 'Editar',
              ),
              IconButton(
                onPressed: loading ? null : _delete,
                icon: const Icon(Icons.delete),
                tooltip: 'Eliminar',
              ),
            ],
          ),
          body: Builder(
            builder: (_) {
              if (state is EventLoading && _event == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is EventError && _event == null) {
                return Center(child: Text(state.message));
              }

              final event = _event;
              if (event == null) {
                return const Center(child: Text('No se pudo cargar el evento.'));
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (event.imageUrl != null && event.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        event.imageUrl!,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 90,
                          alignment: Alignment.center,
                          color: Colors.grey.shade200,
                          child: const Text('No se pudo cargar la imagen'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: const Text('Fecha'),
                    subtitle: Text(_formatDate(event.eventDate)),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.place),
                    title: const Text('Ubicación'),
                    subtitle: Text(event.location),
                  ),
                  if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.image),
                      title: const Text('Imagen'),
                      subtitle: Text(event.imageUrl!),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Estado'),
                    subtitle: Text(event.isUpcoming ? 'Próximo' : 'Pasado'),
                  ),
                  if (event.daysUntil != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.timer_outlined),
                      title: const Text('Faltan'),
                      subtitle: Text('${event.daysUntil} días'),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
