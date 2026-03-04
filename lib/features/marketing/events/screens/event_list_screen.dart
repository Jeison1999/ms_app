import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import '../event_bloc.dart';
import '../event_repository.dart';
import '../models/event_model.dart';
import '../widgets/create_event_fab.dart';
import '../widgets/event_card.dart';
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
        builder: (_) =>
            EventFormScreen(repository: _repository, initialEvent: event),
      ),
    );
    if (updated == true && mounted) {
      context.read<EventBloc>().add(LoadAllEvents());
    }
  }

  Future<void> _openEventDetail(int eventId) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            EventDetailScreen(repository: _repository, eventId: eventId),
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
    return EventCard(
      event: event,
      formattedDate: _formatDate(event.eventDate),
      onTap: () => _openEventDetail(event.id),
      onView: () => _openEventDetail(event.id),
      onEdit: () => _openEditEvent(event),
      onDelete: () => _deleteEvent(event),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<EventModel> events,
    required String emptyText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Text(
                emptyText,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ...events.map(_eventTile),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultSectionAppBar(titleText: 'Eventos'),
      floatingActionButton: CreateEventFab(onPressed: _openCreateEvent),
      body: BlocConsumer<EventBloc, EventState>(
        listener: (context, state) {
          if (state is EventSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            context.read<EventBloc>().add(LoadAllEvents());
          } else if (state is EventError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(
                            alpha: 0.11,
                          ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Total: ${state.upcoming.length + state.past.length} eventos',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSection(
                    title: 'Próximos',
                    icon: Icons.event_available_rounded,
                    events: state.upcoming,
                    emptyText: 'No hay eventos próximos.',
                  ),
                  _buildSection(
                    title: 'Recientes',
                    icon: Icons.history_rounded,
                    events: state.past,
                    emptyText: 'No hay eventos recientes.',
                  ),
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
