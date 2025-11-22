// File removed: AI call test page is deprecated and no longer used.
/*
import 'package:flutter/material.dart';
import '../../widgets/emergency_call_test_button.dart';
import '../../services/app_service_manager.dart';

/// Developer testing page for AI Emergency Call
class AICallTestPage extends StatelessWidget {
  const AICallTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = AppServiceManager();
    final contacts = services.contactsService.contacts;
    final sortedContacts = List.from(contacts)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Emergency Call Test'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.phone_in_talk, size: 80, color: Colors.deepOrange),
            const SizedBox(height: 24),
            const Text(
              'AI Emergency Call Testing',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will immediately trigger an AI emergency call to your Priority 1 contact.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency Contacts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (contacts.isEmpty)
                      const Text(
                        '❌ No contacts configured',
                        style: TextStyle(color: Colors.red),
                      )
                    else
                      ...sortedContacts
                          .take(3)
                          .map(
                            (contact) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: contact.priority == 1
                                          ? Colors.red
                                          : Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${contact.priority}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          contact.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          contact.phoneNumber,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.info, color: Colors.white, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'What will happen:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. App will call your Priority 1 contact\n'
                      '2. After 3 seconds, AI will speak the emergency message\n'
                      '3. Call stays active for 15 seconds\n'
                      '4. You can speak during this time\n'
                      '5. Receiver will hear your voice',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            const EmergencyCallTestButton(),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
*/
