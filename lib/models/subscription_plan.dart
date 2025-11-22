import 'package:equatable/equatable.dart';
import 'subscription_tier.dart';

class SubscriptionPlan extends Equatable {
  /// Get yearly savings percentage
  double get yearlySavingsPercent {
    final monthlyTotal = monthlyPrice * 12;
    final savings = monthlyTotal - yearlyPrice;
    return monthlyTotal == 0 ? 0 : (savings / monthlyTotal) * 100;
  }

  /// Check if this is a family plan
  bool get isFamilyPlan => tier.toString().contains('family');
  final String id;
  final String name;
  final SubscriptionTier tier;
  final double monthlyPrice;
  final double yearlyPrice;
  final String description;
  final List<String> features;
  final Map<String, dynamic> limits;
  final int? durationDays;
  final int? maxFamilyMembers;
  final int? essentialAccounts;
  final int? essentialPlusAccounts; // NEW tier support
  final int? proAccounts;
  final int? ultraAccounts;
  final bool isActive;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.tier,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.description,
    required this.features,
    required this.limits,
    this.durationDays,
    this.maxFamilyMembers,
    this.essentialAccounts,
    this.essentialPlusAccounts, // NEW tier support
    this.proAccounts,
    this.ultraAccounts,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    tier,
    monthlyPrice,
    yearlyPrice,
    description,
    features,
    limits,
    durationDays,
    maxFamilyMembers,
    essentialAccounts,
    essentialPlusAccounts, // NEW tier support
    proAccounts,
    ultraAccounts,
    isActive,
  ];
}
