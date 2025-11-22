import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/payment_service.dart';

/// Billing History Page - View past transactions and invoices
class BillingHistoryPage extends StatefulWidget {
  const BillingHistoryPage({super.key});

  @override
  State<BillingHistoryPage> createState() => _BillingHistoryPageState();
}

class _BillingHistoryPageState extends State<BillingHistoryPage> {
  final PaymentService _paymentService = PaymentService.instance;

  bool _isLoading = true;
  List<PaymentTransaction> _transactions = [];
  PaymentStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      await _paymentService.initialize();
      setState(() {
        _transactions = _paymentService.transactionHistory;
      });
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<PaymentTransaction> get _filteredTransactions {
    if (_filterStatus == null) return _transactions;
    return _transactions.where((t) => t.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          PopupMenuButton<PaymentStatus?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by status',
            onSelected: (status) {
              setState(() => _filterStatus = status);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All Transactions')),
              const PopupMenuItem(
                value: PaymentStatus.succeeded,
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.safeGreen,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text('Succeeded'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: PaymentStatus.failed,
                child: Row(
                  children: [
                    Icon(Icons.error, color: AppTheme.criticalRed, size: 20),
                    SizedBox(width: 8),
                    Text('Failed'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: PaymentStatus.refunded,
                child: Row(
                  children: [
                    Icon(Icons.undo, color: AppTheme.warningOrange, size: 20),
                    SizedBox(width: 8),
                    Text('Refunded'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final filtered = _filteredTransactions;

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: AppTheme.neutralGray,
              ),
              const SizedBox(height: 24),
              Text(
                _filterStatus == null
                    ? 'No Transactions Yet'
                    : 'No ${_filterStatus!.name} Transactions',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _filterStatus == null
                    ? 'Your transaction history will appear here.'
                    : 'Try changing the filter to see other transactions.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_filterStatus != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppTheme.infoBlue.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filtered.length} ${_filterStatus!.name} transactions',
                  style: const TextStyle(fontSize: 14),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _filterStatus = null);
                  },
                  child: const Text('Clear Filter'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final transaction = filtered[index];
              return _buildTransactionCard(transaction);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(PaymentTransaction transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        transaction.status,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(transaction.status),
                      color: _getStatusColor(transaction.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${transaction.tier.name} Subscription',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(transaction.createdAt),
                          style: TextStyle(
                            color: AppTheme.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${transaction.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            transaction.status,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          transaction.status.name.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(transaction.status),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (transaction.paymentMethodId != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.credit_card,
                      size: 16,
                      color: AppTheme.neutralGray,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Card ending in ${transaction.paymentMethodId!.substring(transaction.paymentMethodId!.length - 4)}',
                      style: TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(PaymentTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getStatusIcon(transaction.status),
              color: _getStatusColor(transaction.status),
            ),
            const SizedBox(width: 12),
            const Text('Transaction Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Transaction ID', transaction.id),
              const SizedBox(height: 12),
              _buildDetailRow('Plan', transaction.tier.name),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Amount',
                '\$${transaction.amount.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Status', transaction.status.name.toUpperCase()),
              const SizedBox(height: 12),
              _buildDetailRow('Date', _formatDateTime(transaction.createdAt)),
              if (transaction.paymentMethodId != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Payment Method',
                  'Card •••• ${transaction.paymentMethodId!.substring(transaction.paymentMethodId!.length - 4)}',
                ),
              ],
              if (transaction.updatedAt != null &&
                  transaction.updatedAt != transaction.createdAt) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Last Updated',
                  _formatDateTime(transaction.updatedAt!),
                ),
              ],
              if (transaction.status == PaymentStatus.failed) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.criticalRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.criticalRed,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Payment failed. Please update your payment method and try again.',
                          style: TextStyle(
                            color: AppTheme.criticalRed,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (transaction.status == PaymentStatus.succeeded)
            ElevatedButton.icon(
              onPressed: () {
                // Download invoice functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invoice download coming soon'),
                    backgroundColor: AppTheme.infoBlue,
                  ),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Download'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.succeeded:
        return AppTheme.safeGreen;
      case PaymentStatus.failed:
      case PaymentStatus.cancelled:
        return AppTheme.criticalRed;
      case PaymentStatus.refunded:
        return AppTheme.warningOrange;
      case PaymentStatus.pending:
      case PaymentStatus.processing:
        return AppTheme.infoBlue;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.succeeded:
        return Icons.check_circle;
      case PaymentStatus.failed:
      case PaymentStatus.cancelled:
        return Icons.error;
      case PaymentStatus.refunded:
        return Icons.undo;
      case PaymentStatus.pending:
        return Icons.pending;
      case PaymentStatus.processing:
        return Icons.sync;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
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

    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$month $day, $year at $hour:$minute $period';
  }
}
