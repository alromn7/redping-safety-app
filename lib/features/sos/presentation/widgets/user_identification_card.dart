import 'package:flutter/material.dart';
import '../../../../models/user_profile.dart';

class UserIdentificationCard extends StatelessWidget {
  final UserProfile? userProfile;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  const UserIdentificationCard({
    super.key,
    this.userProfile,
    this.isExpanded = false,
    this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('User Identification'),
        subtitle: Text(userProfile?.name ?? 'No profile available'),
      ),
    );
  }
}
