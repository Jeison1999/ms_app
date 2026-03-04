import 'package:flutter/material.dart';
import '../../../Core/widgets/app_section_app_bar.dart';

class AccountingHomeScreen extends StatelessWidget {
  const AccountingHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DefaultSectionAppBar(
        titleText: 'Contabilidad',
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance, size: 80, color: Colors.teal),
            SizedBox(height: 24),
            Text(
              'Bienvenido al Módulo de Contabilidad',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Gestión financiera de la iglesia',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
