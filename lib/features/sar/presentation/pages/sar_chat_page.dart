import 'package:flutter/material.dart';

/// SAR Chat Page - Stub
/// Community chat removed - available on website only
class SARChatPage extends StatelessWidget {
  final String sarMemberId;
  final String userId;
  final String userName;

  const SARChatPage({
    super.key,
    required this.sarMemberId,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messaging (Web Only)')),
      body: const Center(
        child: Text(
          'Community chat is available on the RedPing website (not in-app in this build).',
        ),
      ),
    );
  }
}
