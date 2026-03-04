import 'package:flutter/material.dart';

class CreateEventFab extends StatelessWidget {
  final VoidCallback onPressed;

  const CreateEventFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('Nuevo evento'),
    );
  }
}
