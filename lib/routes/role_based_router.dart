import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../features/auth/models/user_model.dart';
import '../features/marketing/marketing_home/screens/marketing_home_screen.dart';
import '../features/consolidator/screens/consolidator_home_screen.dart';
import '../features/sales/screens/sales_home_screen.dart';
import '../features/accounting/screens/accounting_home_screen.dart';
import '../features/admin/screens/admin_home_screen.dart';

// Esta clase se encarga de determinar qué pantalla mostrar según el rol del usuario
class RoleBasedRouter {
  static Widget getHomeScreen(UserModel user, {required ApiClient apiClient}) {
    // Administrador tiene acceso a todo
    if (user.isAdmin) {
      return AdminHomeScreen(apiClient: apiClient);
    }

    // Content Manager -> Marketing
    if (user.isContentManager) {
      return MarketingHomeScreen(apiClient: apiClient);
    }

    // User Manager -> Consolidador
    if (user.isUserManager) {
      return const ConsolidatorHomeScreen();
    }

    // Sales Agent -> Ventas
    if (user.isSalesAgent) {
      return const SalesHomeScreen();
    }

    // Accountant -> Contabilidad
    if (user.isAccountant) {
      return const AccountingHomeScreen();
    }

    // Por defecto, si no tiene rol específico
    return const _NoRoleScreen();
  }
}

class _NoRoleScreen extends StatelessWidget {
  const _NoRoleScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MS App')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange),
            SizedBox(height: 24),
            Text(
              'Sin rol asignado',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Contacta al administrador para asignarte un rol',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
