import 'package:flutter/material.dart';
import '../../../../models/travel_trip.dart';

/// Card widget for displaying travel expenses
class TravelExpenseCard extends StatelessWidget {
  final TravelExpense expense;
  final VoidCallback? onTap;

  const TravelExpenseCard({super.key, required this.expense, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Category icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCategoryColor(expense.category).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getCategoryIcon(expense.category),
                  color: _getCategoryColor(expense.category),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Expense details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatDate(expense.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (expense.location != null)
                      Text(
                        expense.location!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    _formatCategory(expense.category),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.transport:
        return Icons.directions_car;
      case ExpenseCategory.accommodation:
        return Icons.hotel;
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.activities:
        return Icons.local_activity;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.healthcare:
        return Icons.medical_services;
      case ExpenseCategory.communication:
        return Icons.phone;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.transport:
        return Colors.blue;
      case ExpenseCategory.accommodation:
        return Colors.purple;
      case ExpenseCategory.food:
        return Colors.orange;
      case ExpenseCategory.activities:
        return Colors.green;
      case ExpenseCategory.shopping:
        return Colors.pink;
      case ExpenseCategory.healthcare:
        return Colors.red;
      case ExpenseCategory.communication:
        return Colors.indigo;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }

  String _formatCategory(ExpenseCategory category) {
    return category
        .toString()
        .split('.')
        .last
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}')
        .trim()
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _formatDate(DateTime date) {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}
