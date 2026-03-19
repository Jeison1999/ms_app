import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import '../announcement_bloc.dart';
import '../announcement_repository.dart';
import '../models/announcement_model.dart';
import 'announcement_form_screen.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final AnnouncementRepository repository;
  final int announcementId;

  const AnnouncementDetailScreen({
    super.key,
    required this.repository,
    required this.announcementId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AnnouncementBloc(repository)
            ..add(LoadAnnouncementDetail(announcementId)),
      child: _AnnouncementDetailView(
        announcementId: announcementId,
        repository: repository,
      ),
    );
  }
}

class _AnnouncementDetailView extends StatefulWidget {
  final int announcementId;
  final AnnouncementRepository repository;

  const _AnnouncementDetailView({
    required this.announcementId,
    required this.repository,
  });

  @override
  State<_AnnouncementDetailView> createState() =>
      _AnnouncementDetailViewState();
}

class _AnnouncementDetailViewState extends State<_AnnouncementDetailView> {
  AnnouncementModel? _announcement;

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString();
    return '$d/$m/$y';
  }

  double _parseAspectRatio() {
    final announcement = _announcement;
    if (announcement == null) return 16 / 9;

    try {
      final parts = announcement.aspectRatio.split(':');
      if (parts.length == 2) {
        final width = double.parse(parts[0]);
        final height = double.parse(parts[1]);
        return width / height;
      }
    } catch (e) {
      // Default to 16:9 if parsing fails
    }
    return 16 / 9;
  }

  Future<void> _openEdit() async {
    final announcement = _announcement;
    if (announcement == null) return;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AnnouncementFormScreen(
          repository: widget.repository,
          initialAnnouncement: announcement,
        ),
      ),
    );

    if (updated == true && mounted) {
      context.read<AnnouncementBloc>().add(
        LoadAnnouncementDetail(widget.announcementId),
      );
    }
  }

  Future<void> _delete() async {
    final announcement = _announcement;
    if (announcement == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar anuncio'),
        content: Text('¿Seguro que deseas eliminar "${announcement.title}"?'),
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
      context.read<AnnouncementBloc>().add(DeleteAnnouncement(announcement.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<AnnouncementBloc, AnnouncementState>(
      listener: (context, state) {
        if (state is AnnouncementDetailLoaded) {
          _announcement = state.announcement;
        } else if (state is AnnouncementSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          Navigator.of(context).pop(true);
        } else if (state is AnnouncementError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final loading = state is AnnouncementLoading;
        return Scaffold(
          appBar: const DefaultSectionAppBar(titleText: 'Detalle del anuncio'),
          floatingActionButton: _announcement != null
              ? FloatingActionButton(
                  onPressed: loading ? null : _openEdit,
                  child: const Icon(Icons.edit),
                )
              : null,
          body: Builder(
            builder: (_) {
              if (state is AnnouncementLoading && _announcement == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is AnnouncementError && _announcement == null) {
                return Center(child: Text(state.message));
              }

              final announcement = _announcement;
              if (announcement == null) {
                return const Center(
                  child: Text('No se pudo cargar el anuncio.'),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
                children: [
                  // Media
                  if (announcement.mediaUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: _parseAspectRatio(),
                        child: Container(
                          color: Colors.grey[300],
                          child: Image.network(
                            announcement.mediaUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    announcement.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  // Status badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: announcement.isActive
                              ? colorScheme.primary.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          announcement.isActive ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: announcement.isActive
                                ? colorScheme.primary
                                : Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (announcement.isPublished)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Publicado',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Description
                  _InfoCard(
                    title: 'Descripción',
                    child: Text(
                      announcement.description,
                      style: const TextStyle(fontSize: 15.5, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Info
                  _InfoCard(
                    title: 'Información',
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.image_rounded,
                          label: 'Tipo de media',
                          value: announcement.mediaType,
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.aspect_ratio_rounded,
                          label: 'Relación de aspecto',
                          value: announcement.aspectRatio,
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Publicado',
                          value: announcement.isPublished
                              ? _formatDate(announcement.publishedAt!)
                              : 'No publicado',
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.create_rounded,
                          label: 'Creado',
                          value: _formatDate(announcement.createdAt),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: loading ? null : _delete,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: colorScheme.error),
                      ),
                      icon: Icon(Icons.delete, color: colorScheme.error),
                      label: Text(
                        'Eliminar anuncio',
                        style: TextStyle(color: colorScheme.error),
                      ),
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

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
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
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
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
