import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../Core/theme/app_colors.dart';
import '../../../Core/theme/app_text_styles.dart';
import '../../../Core/widgets/app_section_app_bar.dart';
import '../../accounting/screens/accounting_home_screen.dart';
import '../../consolidator/screens/consolidator_home_screen.dart';
import '../../marketing/marketing_home/screen.dart';
import '../../sales/screens/sales_home_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  final ApiClient apiClient;

  const AdminHomeScreen({super.key, required this.apiClient});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = AppColors.primary;
    final secondaryColor = AppColors.secondary;
    final accentColor = AppColors.accent;

    final modules = <_AdminModule>[
      _AdminModule(
        title: 'Marketing',
        subtitle: 'Eventos y contenido',
        icon: Icons.campaign_rounded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MarketingHomeScreen(apiClient: apiClient),
            ),
          );
        },
      ),
      _AdminModule(
        title: 'Consolidador',
        subtitle: 'Gestión de usuarios',
        icon: Icons.people_alt_rounded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ConsolidatorHomeScreen()),
          );
        },
      ),
      _AdminModule(
        title: 'Ventas',
        subtitle: 'Ventas e inventario',
        icon: Icons.shopping_cart_rounded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SalesHomeScreen()),
          );
        },
      ),
      _AdminModule(
        title: 'Contabilidad',
        subtitle: 'Gestión financiera',
        icon: Icons.account_balance_rounded,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AccountingHomeScreen()),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: DefaultSectionAppBar(
        titleText: 'Panel Administrativo',
        showBackButton: false,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        titleStyle: AppTextStyles.appBarTitle.copyWith(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.10),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: primaryColor,
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Acceso completo habilitado',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Administra todos los módulos desde un solo lugar.',
                            style: TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Módulos',
                style: AppTextStyles.sectionTitle.copyWith(color: accentColor),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                itemCount: modules.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.02,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final module = modules[index];
                  return _AdminModuleCard(
                    module: module,
                    primaryColor: primaryColor,
                    accentColor: accentColor,
                    borderColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    onTap: module.onTap,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  _AdminModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _AdminModuleCard extends StatelessWidget {
  final _AdminModule module;
  final Color primaryColor;
  final Color accentColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _AdminModuleCard({
    required this.module,
    required this.primaryColor,
    required this.accentColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0.8,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(module.icon, color: accentColor),
              ),
              const Spacer(),
              Text(
                module.title,
                style: AppTextStyles.cardTitle,
              ),
              const SizedBox(height: 4),
              Text(
                module.subtitle,
                style: AppTextStyles.cardSubtitle,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Abrir',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: accentColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
