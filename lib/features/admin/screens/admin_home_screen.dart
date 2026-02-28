import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../accounting/screens/accounting_home_screen.dart';
import '../../consolidator/screens/consolidator_home_screen.dart';
import '../../marketing/marketing_home/screen.dart';
import '../../sales/screens/sales_home_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  final ApiClient apiClient;

  const AdminHomeScreen({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.admin_panel_settings, color: Colors.red),
            title: Text(
              'Panel de Administrador',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Acceso completo a todos los módulos'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.campaign),
            title: const Text('Marketing'),
            subtitle: const Text('Eventos y contenido'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MarketingHomeScreen(apiClient: apiClient),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Consolidador'),
            subtitle: const Text('Gestión de usuarios'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ConsolidatorHomeScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Ventas'),
            subtitle: const Text('Ventas e inventario'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SalesHomeScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance),
            title: const Text('Contabilidad'),
            subtitle: const Text('Gestión financiera'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AccountingHomeScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
