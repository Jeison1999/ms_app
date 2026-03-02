import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ms_app/features/auth/bloc/auth_bloc.dart';
import 'package:ms_app/features/auth/bloc/auth_event.dart';
import '../event_bloc.dart';
import '../event_repository.dart';
import '../models/event_model.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  EventRepository get _repository => context.read<EventBloc>().repository;

  Future<void> _openCreateEvent() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventFormScreen(repository: _repository),
      ),
    );
    if (created == true && mounted) {
      context.read<EventBloc>().add(LoadAllEvents());
    }
  }

  Future<void> _openEditEvent(EventModel event) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventFormScreen(
          repository: _repository,
          initialEvent: event,
        ),
      ),
    );
    if (updated == true && mounted) {
      context.read<EventBloc>().add(LoadAllEvents());
    }
  }

  Future<void> _openEventDetail(int eventId) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          repository: _repository,
          eventId: eventId,
        ),
      ),
    );
    if (changed == true && mounted) {
      context.read<EventBloc>().add(LoadAllEvents());
    }
  }

  Future<void> _deleteEvent(EventModel event) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString();
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  Widget _eventTile(EventModel event) {
    return Card(
      child: ListTile(
        leading: event.imageUrl != null && event.imageUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  event.imageUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported),
                ),
              )
            : const Icon(Icons.event),
        title: Text(event.title),
        subtitle: Text('${_formatDate(event.eventDate)} - ${event.location}'),
        onTap: () => _openEventDetail(event.id),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view') {
              _openEventDetail(event.id);
            } else if (value == 'edit') {
              _openEditEvent(event);
            } else if (value == 'delete') {
              _deleteEvent(event);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(
              value: 'view',
              child: Text('Ver detalle'),
            ),
            PopupMenuItem<String>(
              value: 'edit',
              child: Text('Editar'),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Text('Eliminar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<EventBloc>().add(LoadAllEvents());
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateEvent,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo evento'),
      ),
      body: BlocConsumer<EventBloc, EventState>(
        listener: (context, state) {
          if (state is EventSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<EventBloc>().add(LoadAllEvents());
          } else if (state is EventError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is EventLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is EventAllLoaded) {
            if (state.upcoming.isEmpty && state.past.isEmpty) {
              return const Center(child: Text('No hay eventos.'));
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<EventBloc>().add(LoadAllEvents());
              },
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  const Text(
                    'Próximos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (state.upcoming.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text('No hay eventos próximos.'),
                    ),
                  ...state.upcoming.map(_eventTile),
                  const SizedBox(height: 16),
                  const Text(
                    'Pasados',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (state.past.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text('No hay eventos pasados.'),
                    ),
                  ...state.past.map(_eventTile),
                  const SizedBox(height: 80),
                ],
              ),
            );
          }
          return const Center(child: Text('Cargando eventos...'));
        },
      ),
    );
  }
}
