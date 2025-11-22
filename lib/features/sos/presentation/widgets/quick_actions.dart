import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../widgets/emessage_widget.dart';

/// Compact Quick action buttons - Single row with icon-only buttons
class QuickActions extends StatelessWidget {
  final VoidCallback onQuickCall;
  final VoidCallback onMedicalInfo;

  const QuickActions({
    super.key,
    required this.onQuickCall,
    required this.onMedicalInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildCompactButton(
            context: context,
            icon: Icons.phone,
            label: 'Emergency Call',
            color: AppTheme.safeGreen,
            onTap: onQuickCall,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactButton(
            context: context,
            icon: Icons.local_hospital,
            label: 'Medical',
            color: AppTheme.warningOrange,
            onTap: onMedicalInfo,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactButton(
            context: context,
            icon: Icons.message,
            label: 'E-message',
            color: AppTheme.primaryRed,
            onTap: () => _showEmessageDialog(context),
          ),
        ),
      ],
    );
  }

  /// Build compact icon-only button
  Widget _buildCompactButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Center(child: Icon(icon, color: color, size: 28)),
          ),
        ),
      ),
    );
  }

  /// Show E-message dialog with optimized loading
  void _showEmessageDialog(BuildContext context) {
    // Show immediately with loading state for better UX
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useRootNavigator: false, // Use local navigator for better performance
      builder: (context) => const EmessageWidget(showBackground: true),
    );
  }
}
