import 'package:flutter/material.dart';
import '../../../Core/widgets/app_section_app_bar.dart';

class ConsolidatorHomeScreen extends StatelessWidget {
  const ConsolidatorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultSectionAppBar(
        titleText: 'Consolidador',
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 80, color: Colors.green),
            SizedBox(height: 24),
            Text(
              'Bienvenido al Módulo de Consolidador',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Gestión de usuarios',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
