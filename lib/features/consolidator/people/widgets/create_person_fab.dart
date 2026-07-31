import 'package:flutter/material.dart';

class CreatePersonFab extends StatelessWidget {
  final VoidCallback onPressed;

  const CreatePersonFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      icon: const Icon(Icons.person_add_alt_1),
      label: const Text('Nueva persona'),
    );
  }
}
