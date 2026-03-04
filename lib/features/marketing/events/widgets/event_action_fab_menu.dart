import 'package:flutter/material.dart';

class EventActionFabMenu extends StatefulWidget {
  final bool isDisabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EventActionFabMenu({
    super.key,
    required this.isDisabled,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<EventActionFabMenu> createState() => _EventActionFabMenuState();
}

class _EventActionFabMenuState extends State<EventActionFabMenu> {
  bool _open = false;

  void _toggle() {
    if (widget.isDisabled) return;
    setState(() => _open = !_open);
  }

  void _runAction(VoidCallback action) {
    setState(() => _open = false);
    action();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            right: 0,
            bottom: _open ? 74 : 8,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _open ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_open || widget.isDisabled,
                child: _ActionMiniFab(
                  heroTag: 'event_edit_fab',
                  tooltip: 'Editar',
                  icon: Icons.edit_rounded,
                  background: colorScheme.primary,
                  onPressed: () => _runAction(widget.onEdit),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            right: _open ? 74 : 8,
            bottom: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _open ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_open || widget.isDisabled,
                child: _ActionMiniFab(
                  heroTag: 'event_delete_fab',
                  tooltip: 'Eliminar',
                  icon: Icons.delete_outline_rounded,
                  background: Colors.red.shade600,
                  onPressed: () => _runAction(widget.onDelete),
                ),
              ),
            ),
          ),
          FloatingActionButton(
            heroTag: 'event_main_fab',
            onPressed: _toggle,
            backgroundColor: colorScheme.primary,
            child: AnimatedRotation(
              turns: _open ? 0.125 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                _open ? Icons.close_rounded : Icons.more_horiz_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionMiniFab extends StatelessWidget {
  final String heroTag;
  final String tooltip;
  final IconData icon;
  final Color background;
  final VoidCallback onPressed;

  const _ActionMiniFab({
    required this.heroTag,
    required this.tooltip,
    required this.icon,
    required this.background,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      tooltip: tooltip,
      backgroundColor: background,
      onPressed: onPressed,
      child: Icon(icon),
    );
  }
}
