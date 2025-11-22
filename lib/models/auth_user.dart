import 'package:equatable/equatable.dart';
import 'subscription_plan.dart' as sub;
import 'subscription_tier.dart' as sub;

/// Authentication status enum
enum AuthStatus { unknown, authenticated, unauthenticated, loading }

/// User authentication model
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.isEmailVerified = false,
    this.createdAt,
    this.lastSignIn,
  });

  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final DateTime? lastSignIn;

  /// Empty user which represents an unauthenticated user
  static const empty = AuthUser(id: '', email: '', displayName: '');

  /// Convenience getter to determine whether the current user is empty
  bool get isEmpty => this == AuthUser.empty;

  /// Convenience getter to determine whether the current user is not empty
  bool get isNotEmpty => this != AuthUser.empty;

  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? lastSignIn,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastSignIn: lastSignIn ?? this.lastSignIn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt?.toIso8601String(),
      'lastSignIn': lastSignIn?.toIso8601String(),
    };
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastSignIn: json['lastSignIn'] != null
          ? DateTime.parse(json['lastSignIn'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    photoUrl,
    phoneNumber,
    isEmailVerified,
    createdAt,
    lastSignIn,
  ];
}

/// Login request model
class LoginRequest extends Equatable {
  const LoginRequest({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  final String email;
  final String password;
  final bool rememberMe;

  @override
  List<Object?> get props => [email, password, rememberMe];
}

/// Signup request model
class SignupRequest extends Equatable {
  const SignupRequest({
    required this.email,
    required this.password,
    required this.displayName,
    this.phoneNumber,
  });

  final String email;
  final String password;
  final String displayName;
  final String? phoneNumber;

  @override
  List<Object?> get props => [email, password, displayName, phoneNumber];
}

/// Password reset request model
class PasswordResetRequest extends Equatable {
  const PasswordResetRequest({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

/// Authentication exception
class AuthException implements Exception {
  const AuthException(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() =>
      'AuthException: $message${code != null ? ' ($code)' : ''}';
}

// ============================================================================
// SUBSCRIPTION SYSTEM MODELS
// ============================================================================

/// Subscription status enum
enum SubscriptionStatus {
  active,
  inactive,
  cancelled,
  expired,
  pending,
  suspended,
}

/// Payment method enum
enum PaymentMethod { creditCard, paypal, googlePay, applePay, bankTransfer }

/// User subscription model
class UserSubscription extends Equatable {
  const UserSubscription({
    required this.id,
    required this.userId,
    required this.plan,
    required this.startDate,
    required this.status,
    required this.paymentMethod,
    this.endDate,
    this.familyId,
    this.isFamilyAdmin = false,
    this.familyMembers = const [],
    this.isYearlyBilling = false,
    this.nextBillingDate,
    this.autoRenew = true,
    this.isTrialPeriod = false,
    this.trialEndDate,
    this.trialDays = 0,
  });

  final String id;
  final String userId;
  final sub.SubscriptionPlan plan;
  final DateTime startDate;
  final DateTime? endDate;
  final SubscriptionStatus status;
  final PaymentMethod paymentMethod;

  // Family-specific properties
  final String? familyId;
  final bool isFamilyAdmin;
  final List<FamilyMember> familyMembers;

  // Billing properties
  final bool isYearlyBilling;
  final DateTime? nextBillingDate;
  final bool autoRenew;

  // Trial period properties
  final bool isTrialPeriod;
  final DateTime? trialEndDate;
  final int trialDays;

  /// Check if subscription is currently active
  bool get isActive => status == SubscriptionStatus.active;

  /// Check if subscription is in trial period
  bool get isInTrial {
    if (!isTrialPeriod || trialEndDate == null) return false;
    return DateTime.now().isBefore(trialEndDate!);
  }

  /// Get days remaining in trial
  int? get daysRemainingInTrial {
    if (!isInTrial || trialEndDate == null) return null;
    return trialEndDate!.difference(DateTime.now()).inDays;
  }

  /// Check if subscription has expired
  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Get days until expiration
  int? get daysUntilExpiration {
    if (endDate == null) return null;
    final difference = endDate!.difference(DateTime.now());
    return difference.inDays;
  }

  /// Get renewal date (alias for nextBillingDate)
  DateTime? get renewalDate => nextBillingDate;

  @override
  List<Object?> get props => [
    id,
    userId,
    plan,
    startDate,
    endDate,
    status,
    paymentMethod,
    familyId,
    isFamilyAdmin,
    familyMembers,
    isYearlyBilling,
    nextBillingDate,
    autoRenew,
    isTrialPeriod,
    trialEndDate,
    trialDays,
  ];
}

/// Family member model
class FamilyMember extends Equatable {
  const FamilyMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.assignedTier,
    required this.addedDate,
    this.email,
    this.relationship,
    this.isActive = true,
  });

  final String id;
  final String userId;
  final String name;
  final String? email;
  final String? relationship;
  final sub.SubscriptionTier assignedTier;
  final DateTime addedDate;
  final bool isActive;

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    email,
    relationship,
    assignedTier,
    addedDate,
    isActive,
  ];
}

/// Family subscription model
class FamilySubscription extends Equatable {
  const FamilySubscription({
    required this.id,
    required this.adminUserId,
    required this.plan,
    required this.members,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
    this.sharedContacts = const [],
    this.familyName,
  });

  final String id;
  final String adminUserId;
  final sub.SubscriptionPlan plan;
  final List<FamilyMember> members;
  final FamilySettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> sharedContacts;
  final String? familyName;

  /// Get total number of family members
  int get totalMembers => members.length;

  /// Get members by tier
  List<FamilyMember> getMembersByTier(sub.SubscriptionTier tier) {
    return members.where((member) => member.assignedTier == tier).toList();
  }

  /// Check if family has available slots
  bool hasAvailableSlots(sub.SubscriptionTier tier) {
    final currentCount = getMembersByTier(tier).length;
    switch (tier) {
      case sub.SubscriptionTier.essentialPlus:
        return currentCount < (plan.essentialPlusAccounts ?? 0);
      case sub.SubscriptionTier.pro:
        return currentCount < (plan.proAccounts ?? 0);
      case sub.SubscriptionTier.ultra:
        return currentCount < (plan.ultraAccounts ?? 0);
      case sub.SubscriptionTier.family:
        return false; // Family tier is not assignable to members
      case sub.SubscriptionTier.free:
        return false; // Free tier is not assignable to members
    }
  }

  @override
  List<Object?> get props => [
    id,
    adminUserId,
    plan,
    members,
    settings,
    createdAt,
    updatedAt,
    sharedContacts,
    familyName,
  ];
}

/// Family settings model
class FamilySettings extends Equatable {
  const FamilySettings({
    this.allowLocationSharing = true,
    this.allowCrossAccountNotifications = true,
    this.allowSharedEmergencyContacts = true,
    this.allowActivitySharing = true,
    this.familyChatEnabled = true,
    this.parentalControls = false,
    this.emergencyOverride = true,
  });

  final bool allowLocationSharing;
  final bool allowCrossAccountNotifications;
  final bool allowSharedEmergencyContacts;
  final bool allowActivitySharing;
  final bool familyChatEnabled;
  final bool parentalControls;
  final bool emergencyOverride;

  FamilySettings copyWith({
    bool? allowLocationSharing,
    bool? allowCrossAccountNotifications,
    bool? allowSharedEmergencyContacts,
    bool? allowActivitySharing,
    bool? familyChatEnabled,
    bool? parentalControls,
    bool? emergencyOverride,
  }) {
    return FamilySettings(
      allowLocationSharing: allowLocationSharing ?? this.allowLocationSharing,
      allowCrossAccountNotifications:
          allowCrossAccountNotifications ?? this.allowCrossAccountNotifications,
      allowSharedEmergencyContacts:
          allowSharedEmergencyContacts ?? this.allowSharedEmergencyContacts,
      allowActivitySharing: allowActivitySharing ?? this.allowActivitySharing,
      familyChatEnabled: familyChatEnabled ?? this.familyChatEnabled,
      parentalControls: parentalControls ?? this.parentalControls,
      emergencyOverride: emergencyOverride ?? this.emergencyOverride,
    );
  }

  @override
  List<Object?> get props => [
    allowLocationSharing,
    allowCrossAccountNotifications,
    allowSharedEmergencyContacts,
    allowActivitySharing,
    familyChatEnabled,
    parentalControls,
    emergencyOverride,
  ];
}
