import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

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
          appBar: DefaultSectionAppBar(
            titleText: 'Detalle del evento',
            customActions: [
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
                children: [
                  _EventHeader(
                    imageUrl: event.imageUrl,
                    title: event.title,
                    statusText: event.isUpcoming ? 'Próximo' : 'Pasado',
                    accentColor: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    title: 'Descripción',
                    child: Text(
                      event.description,
                      style: const TextStyle(fontSize: 15.5, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Información del evento',
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.schedule_rounded,
                          label: 'Fecha',
                          value: _formatDate(event.eventDate),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.place_rounded,
                          label: 'Ubicación',
                          value: event.location,
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.info_outline_rounded,
                          label: 'Estado',
                          value: event.isUpcoming ? 'Próximo' : 'Pasado',
                        ),
                        if (event.daysUntil != null) ...[
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.timer_outlined,
                            label: 'Faltan',
                            value: '${event.daysUntil} días',
                          ),
                        ],
                      ],
                    ),
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

class _EventHeader extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String statusText;
  final Color accentColor;

  const _EventHeader({
    required this.imageUrl,
    required this.title,
    required this.statusText,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            SizedBox(
              height: 240,
              width: double.infinity,
              child: hasImage
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _ImageFallback(
                        title: title,
                        accentColor: accentColor,
                      ),
                    )
                  : _ImageFallback(
                      title: title,
                      accentColor: accentColor,
                    ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.58),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 23,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final String title;
  final Color accentColor;

  const _ImageFallback({required this.title, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.18),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_rounded, size: 54, color: accentColor),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
