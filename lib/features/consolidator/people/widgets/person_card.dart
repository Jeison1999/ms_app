import 'package:flutter/material.dart';
import '../models/person_model.dart';

class PersonCard extends StatelessWidget {
  final PersonModel person;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onDeactivate;
  final VoidCallback? onReactivate;
  final bool selectionMode;
  final bool selected;
  final ValueChanged<bool>? onSelectedChanged;
  final VoidCallback? onLongPress;

  const PersonCard({
    super.key,
    required this.person,
    required this.onTap,
    required this.onEdit,
    this.onDeactivate,
    this.onReactivate,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectedChanged,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = person.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: selectionMode
              ? () => onSelectedChanged?.call(!selected)
              : onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? colorScheme.primary.withValues(alpha: 0.45)
                    : colorScheme.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
            child: Row(
              children: [
                if (selectionMode) ...[
                  Checkbox(
                    value: selected,
                    onChanged: (v) => onSelectedChanged?.call(v ?? false),
                  ),
                  const SizedBox(width: 4),
                ],
                CircleAvatar(
                  radius: 26,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.14),
                  backgroundImage:
                      person.photoUrl != null && person.photoUrl!.isNotEmpty
                      ? NetworkImage(person.photoUrl!)
                      : null,
                  child: person.photoUrl == null || person.photoUrl!.isEmpty
                      ? Icon(Icons.person, color: colorScheme.primary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (person.code != null && person.code!.isNotEmpty)
                            'ID ${person.code}',
                          if (person.age != null) '${person.age} años',
                          if (person.documentType != null &&
                              person.documentNumber != null)
                            '${person.documentType} ${person.documentNumber}',
                          if (person.phone != null && person.phone!.isNotEmpty)
                            person.phone!,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? colorScheme.primary.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          active ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: active
                                ? colorScheme.primary
                                : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!selectionMode)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'deactivate') {
                        onDeactivate?.call();
                      } else if (value == 'reactivate') {
                        onReactivate?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      if (active && onDeactivate != null)
                        const PopupMenuItem(
                          value: 'deactivate',
                          child: Row(
                            children: [
                              Icon(Icons.person_off_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Desactivar'),
                            ],
                          ),
                        ),
                      if (!active && onReactivate != null)
                        const PopupMenuItem(
                          value: 'reactivate',
                          child: Row(
                            children: [
                              Icon(Icons.person_add_alt_1_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Reactivar'),
                            ],
                          ),
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
}
