import 'package:flutter/material.dart';
import '../../../../screens/sar_chat_screen.dart';

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
    return SARChatScreen(
      sarMemberId: sarMemberId,
      userId: userId,
      userName: userName,
    );
  }
}
