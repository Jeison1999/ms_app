import 'package:flutter/material.dart';
import '../index_announcement.dart';

class AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Media preview
                if (announcement.mediaUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
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
                const SizedBox(height: 12),
                // Title
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        announcement.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
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
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: announcement.isActive
                              ? colorScheme.primary
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  announcement.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                // Meta info
                Row(
                  children: [
                    if (announcement.isPublished)
                      Expanded(
                        child: Text(
                          'Publicado: ${_formatDate(announcement.publishedAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit();
                        } else if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20),
                              SizedBox(width: 8),
                              Text('Eliminar'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _parseAspectRatio() {
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'No publicado';
    final local = date.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString();
    return '$d/$m/$y';
  }
}
