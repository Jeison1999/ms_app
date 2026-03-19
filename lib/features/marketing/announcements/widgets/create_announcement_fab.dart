import 'package:flutter/material.dart';

class CreateAnnouncementFab extends StatelessWidget {
  final VoidCallback onPressed;

  const CreateAnnouncementFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Crear anuncio'),
    );
  }
}
