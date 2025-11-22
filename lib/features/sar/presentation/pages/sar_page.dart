import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'professional_sar_dashboard.dart';

/// Professional SAR Dashboard Page
class SARPage extends StatelessWidget {
  const SARPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: ProfessionalSARDashboard(),
    );
  }
}
