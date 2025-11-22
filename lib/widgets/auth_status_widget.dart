import '../models/subscription_tier.dart' as sub;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../core/theme/app_theme.dart';

class AuthStatusWidget extends StatefulWidget {
  const AuthStatusWidget({super.key});

  @override
  State<AuthStatusWidget> createState() => _AuthStatusWidgetState();
}

class _AuthStatusWidgetState extends State<AuthStatusWidget> {
  late final AuthService _authService;
  late final SubscriptionService _subscriptionService;
  AuthUser _currentUser = AuthUser.empty;
  AuthStatus _status = AuthStatus.unknown;
  UserSubscription? _currentSubscription;

  @override
  void initState() {
    super.initState();
    _authService = AuthService.instance;
    _subscriptionService = SubscriptionService.instance;
    _currentUser = _authService.currentUser;
    _status = _authService.status;
    _currentSubscription = _subscriptionService.currentSubscription;

    // Listen to authentication changes
    _authService.userStream.listen((user) {
      if (mounted) {
        setState(() => _currentUser = user);
      }
    });

    _authService.statusStream.listen((status) {
      if (mounted) {
        setState(() => _status = status);
      }
    });

    // Listen to subscription changes
    _subscriptionService.subscriptionStream.listen((subscription) {
      if (mounted) {
        setState(() => _currentSubscription = subscription);
      }
    });
  }

  Future<void> _handleSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.criticalRed),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Signed out successfully'),
              backgroundColor: AppTheme.safeGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error signing out: $e'),
              backgroundColor: AppTheme.criticalRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showAuthMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            if (_currentUser.isNotEmpty) ...[
              // User info
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryRed,
                  backgroundImage: _currentUser.photoUrl != null
                      ? NetworkImage(_currentUser.photoUrl!)
                      : null,
                  child: _currentUser.photoUrl == null
                      ? Text(
                          _currentUser.displayName.isNotEmpty
                              ? _currentUser.displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  _currentUser.displayName.isNotEmpty
                      ? _currentUser.displayName
                      : 'User',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(_currentUser.email),
              ),
              const Divider(),

              // Profile option
              ListTile(
                leading: const Icon(Icons.person_outlined),
                title: const Text('My Profile'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/profile');
                },
              ),

              // Settings option
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings');
                },
              ),

              // Subscription option
              ListTile(
                leading: Icon(
                  _currentSubscription?.plan.isFamilyPlan == true
                      ? Icons.family_restroom_outlined
                      : Icons.card_membership_outlined,
                  color: _getSubscriptionColor(),
                ),
                title: Text(_getSubscriptionTitle()),
                subtitle: Text(_getSubscriptionSubtitle()),
                onTap: () {
                  Navigator.pop(context);
                  if (_currentSubscription?.plan.isFamilyPlan == true) {
                    context.push('/subscription/family-dashboard');
                  } else {
                    context.push('/subscription/plans');
                  }
                },
              ),

              // Sign out option
              ListTile(
                leading: const Icon(
                  Icons.logout_outlined,
                  color: AppTheme.criticalRed,
                ),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: AppTheme.criticalRed),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleSignOut();
                },
              ),
            ] else ...[
              // Not signed in
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Not signed in'),
                subtitle: Text('Sign in to access all features'),
              ),
              const SizedBox(height: 16),

              // Sign in button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/login');
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Sign up button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/signup');
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Create Account'),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Color _getSubscriptionColor() {
    if (_currentSubscription == null) return Colors.grey;

    switch (_currentSubscription!.plan.tier) {
      case sub.SubscriptionTier.essentialPlus:
        return AppTheme.successGreen;
      case sub.SubscriptionTier.pro:
        return AppTheme.infoBlue;
      case sub.SubscriptionTier.ultra:
        return AppTheme.primaryRed;
      case sub.SubscriptionTier.family:
        return AppTheme.warningOrange;
      case sub.SubscriptionTier.free:
        return Colors.grey;
    }
  }

  String _getSubscriptionTitle() {
    if (_currentSubscription == null) {
      return 'View Plans';
    }

    if (_currentSubscription!.plan.isFamilyPlan) {
      return 'Family Dashboard';
    }

    return '${_currentSubscription!.plan.name} Plan';
  }

  String _getSubscriptionSubtitle() {
    if (_currentSubscription == null) {
      return 'Choose a subscription plan';
    }

    if (_currentSubscription!.plan.isFamilyPlan) {
      return 'Manage family subscription';
    }

    return 'Connected to SAR Network';
  }

  @override
  Widget build(BuildContext context) {
    if (_status == AuthStatus.loading) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      onPressed: _showAuthMenu,
      icon: _currentUser.isNotEmpty
          ? Stack(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryRed,
                  backgroundImage: _currentUser.photoUrl != null
                      ? NetworkImage(_currentUser.photoUrl!)
                      : null,
                  child: _currentUser.photoUrl == null
                      ? Text(
                          _currentUser.displayName.isNotEmpty
                              ? _currentUser.displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                // Online indicator
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.safeGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            )
          : const Icon(Icons.account_circle_outlined),
      tooltip: _currentUser.isNotEmpty ? 'Account Menu' : 'Sign In / Sign Up',
    );
  }
}
