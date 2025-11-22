import 'package:flutter/material.dart';

class ActiveHelpRequestsWidget extends StatelessWidget {
  const ActiveHelpRequestsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        title: Text('Active Help Requests'),
        subtitle: Text('No active requests'),
      ),
    );
  }
}
