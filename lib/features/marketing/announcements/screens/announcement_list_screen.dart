import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ms_app/Core/widgets/app_section_app_bar.dart';
import '../announcement_bloc.dart';
import '../announcement_repository.dart';
import '../models/announcement_model.dart';
import '../widgets/announcement_card.dart';
import '../widgets/create_announcement_fab.dart';
import 'announcement_detail_screen.dart';
import 'announcement_form_screen.dart';

class AnnouncementListScreen extends StatefulWidget {
  const AnnouncementListScreen({super.key});

  @override
  State<AnnouncementListScreen> createState() => _AnnouncementListScreenState();
}

class _AnnouncementListScreenState extends State<AnnouncementListScreen> {
  AnnouncementRepository get _repository =>
      context.read<AnnouncementBloc>().repository;

  Future<void> _openCreateAnnouncement() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AnnouncementFormScreen(repository: _repository),
      ),
    );
    if (created == true && mounted) {
      context.read<AnnouncementBloc>().add(LoadAllAnnouncements());
    }
  }

  Future<void> _openEditAnnouncement(AnnouncementModel announcement) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AnnouncementFormScreen(
          repository: _repository,
          initialAnnouncement: announcement,
        ),
      ),
    );
    if (updated == true && mounted) {
      context.read<AnnouncementBloc>().add(LoadAllAnnouncements());
    }
  }

  Future<void> _openAnnouncementDetail(int announcementId) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AnnouncementDetailScreen(
          repository: _repository,
          announcementId: announcementId,
        ),
      ),
    );
    if (changed == true && mounted) {
      context.read<AnnouncementBloc>().add(LoadAllAnnouncements());
    }
  }

  Future<void> _deleteAnnouncement(AnnouncementModel announcement) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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

  Widget _announcementTile(AnnouncementModel announcement) {
    return AnnouncementCard(
      announcement: announcement,
      onTap: () => _openAnnouncementDetail(announcement.id),
      onEdit: () => _openEditAnnouncement(announcement),
      onDelete: () => _deleteAnnouncement(announcement),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay anuncios',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultSectionAppBar(titleText: 'Anuncios'),
      floatingActionButton: CreateAnnouncementFab(
        onPressed: _openCreateAnnouncement,
      ),
      body: BlocConsumer<AnnouncementBloc, AnnouncementState>(
        listener: (context, state) {
          if (state is AnnouncementSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            context.read<AnnouncementBloc>().add(LoadAllAnnouncements());
          } else if (state is AnnouncementError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is AnnouncementLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AnnouncementAllLoaded) {
            if (state.announcements.isEmpty) {
              return _buildEmptyState();
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AnnouncementBloc>().add(LoadAllAnnouncements());
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Total: ${state.announcements.length} anuncios',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...state.announcements.map(_announcementTile),
                ],
              ),
            );
          } else if (state is AnnouncementError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return _buildEmptyState();
        },
      ),
    );
  }
}
