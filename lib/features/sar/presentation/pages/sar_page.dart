import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/sar_router.dart';
import 'professional_sar_dashboard.dart';

/// Professional SAR Dashboard Page
class SARPage extends StatelessWidget {
  const SARPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        title: const Text('SAR Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Map',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => context.go(SarRouter.map),
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go(SarRouter.profile),
          ),
        ],
      ),
      body: const ProfessionalSARDashboard(),
    );
  }
}
