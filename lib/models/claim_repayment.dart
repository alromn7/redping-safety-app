/// Claim Repayment System
///
/// When a user makes a claim, their monthly contribution increases from $5 to $15
/// until they fully repay what the Safety Fund covered for them.
///
/// This keeps the fund sustainable while ensuring rescue is never blocked.

class ClaimRepayment {
  /// Base monthly contribution (no claims)
  static const double baseMonthlyContribution = 5.0;

  /// Repayment monthly contribution (repaying previous claim)
  static const double repaymentMonthlyContribution = 15.0;

  /// Amount per month that goes toward repayment
  static const double repaymentPerMonth =
      repaymentMonthlyContribution - baseMonthlyContribution; // $10

  /// Outstanding balance from previous claims
  final double outstandingBalance;

  /// Date repayment started
  final DateTime? repaymentStartDate;

  /// List of claim amounts being repaid
  final List<RepaymentItem> items;

  const ClaimRepayment({
    required this.outstandingBalance,
    this.repaymentStartDate,
    this.items = const [],
  });

  /// Check if user is currently in repayment mode
  bool get isRepaying => outstandingBalance > 0;

  /// Current monthly contribution based on repayment status
  double get currentMonthlyContribution {
    return isRepaying ? repaymentMonthlyContribution : baseMonthlyContribution;
  }

  /// Calculate months remaining to pay off balance
  int get monthsRemaining {
    if (outstandingBalance <= 0) return 0;
    return (outstandingBalance / repaymentPerMonth).ceil();
  }

  /// Calculate how much has been repaid so far
  double get totalRepaid {
    return items.fold(0.0, (sum, item) => sum + item.amountRepaid);
  }

  /// Calculate original total debt
  double get originalDebt {
    return items.fold(0.0, (sum, item) => sum + item.originalAmount);
  }

  /// Calculate repayment progress percentage
  double get progressPercent {
    if (originalDebt == 0) return 0;
    return (totalRepaid / originalDebt * 100).clamp(0, 100);
  }

  /// Add a new claim to repayment
  ClaimRepayment addClaim({
    required double fundShareAmount,
    required DateTime claimDate,
    required String claimId,
  }) {
    final newItem = RepaymentItem(
      claimId: claimId,
      originalAmount: fundShareAmount,
      amountRepaid: 0.0,
      claimDate: claimDate,
      repaymentStartDate: repaymentStartDate ?? DateTime.now(),
    );

    return ClaimRepayment(
      outstandingBalance: outstandingBalance + fundShareAmount,
      repaymentStartDate: repaymentStartDate ?? DateTime.now(),
      items: [...items, newItem],
    );
  }

  /// Process monthly payment
  ClaimRepayment processMonthlyPayment() {
    if (outstandingBalance <= 0) return this;

    final newBalance = (outstandingBalance - repaymentPerMonth).clamp(
      0.0,
      double.infinity,
    );

    // Update repaid amounts in items
    var remainingPayment = repaymentPerMonth;
    final updatedItems = <RepaymentItem>[];

    for (final item in items) {
      if (remainingPayment <= 0 || item.isFullyPaid) {
        updatedItems.add(item);
        continue;
      }

      final itemRemaining = item.amountRemaining;
      final paymentForThisItem = remainingPayment.clamp(0.0, itemRemaining);

      updatedItems.add(
        item.copyWith(amountRepaid: item.amountRepaid + paymentForThisItem),
      );

      remainingPayment -= paymentForThisItem;
    }

    return ClaimRepayment(
      outstandingBalance: newBalance,
      repaymentStartDate: repaymentStartDate,
      items: updatedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'outstandingBalance': outstandingBalance,
      'repaymentStartDate': repaymentStartDate?.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  factory ClaimRepayment.fromJson(Map<String, dynamic> json) {
    return ClaimRepayment(
      outstandingBalance:
          (json['outstandingBalance'] as num?)?.toDouble() ?? 0.0,
      repaymentStartDate: json['repaymentStartDate'] != null
          ? DateTime.parse(json['repaymentStartDate'] as String)
          : null,
      items:
          (json['items'] as List?)
              ?.map(
                (item) => RepaymentItem.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  ClaimRepayment copyWith({
    double? outstandingBalance,
    DateTime? repaymentStartDate,
    List<RepaymentItem>? items,
  }) {
    return ClaimRepayment(
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      repaymentStartDate: repaymentStartDate ?? this.repaymentStartDate,
      items: items ?? this.items,
    );
  }
}

/// Individual claim being repaid
class RepaymentItem {
  final String claimId;
  final double originalAmount;
  final double amountRepaid;
  final DateTime claimDate;
  final DateTime repaymentStartDate;

  const RepaymentItem({
    required this.claimId,
    required this.originalAmount,
    required this.amountRepaid,
    required this.claimDate,
    required this.repaymentStartDate,
  });

  /// Amount still owed on this claim
  double get amountRemaining =>
      (originalAmount - amountRepaid).clamp(0.0, double.infinity);

  /// Check if this item is fully paid
  bool get isFullyPaid => amountRemaining <= 0;

  /// Progress percentage for this item
  double get progressPercent {
    if (originalAmount == 0) return 100;
    return (amountRepaid / originalAmount * 100).clamp(0, 100);
  }

  Map<String, dynamic> toJson() {
    return {
      'claimId': claimId,
      'originalAmount': originalAmount,
      'amountRepaid': amountRepaid,
      'claimDate': claimDate.toIso8601String(),
      'repaymentStartDate': repaymentStartDate.toIso8601String(),
    };
  }

  factory RepaymentItem.fromJson(Map<String, dynamic> json) {
    return RepaymentItem(
      claimId: json['claimId'] as String,
      originalAmount: (json['originalAmount'] as num).toDouble(),
      amountRepaid: (json['amountRepaid'] as num).toDouble(),
      claimDate: DateTime.parse(json['claimDate'] as String),
      repaymentStartDate: DateTime.parse(json['repaymentStartDate'] as String),
    );
  }

  RepaymentItem copyWith({
    String? claimId,
    double? originalAmount,
    double? amountRepaid,
    DateTime? claimDate,
    DateTime? repaymentStartDate,
  }) {
    return RepaymentItem(
      claimId: claimId ?? this.claimId,
      originalAmount: originalAmount ?? this.originalAmount,
      amountRepaid: amountRepaid ?? this.amountRepaid,
      claimDate: claimDate ?? this.claimDate,
      repaymentStartDate: repaymentStartDate ?? this.repaymentStartDate,
    );
  }
}
