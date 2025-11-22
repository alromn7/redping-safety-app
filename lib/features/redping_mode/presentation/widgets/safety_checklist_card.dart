import 'package:flutter/material.dart';
import '../../../../models/extreme_activity.dart';

/// Card widget for safety checklist items
class SafetyChecklistCard extends StatelessWidget {
  final SafetyChecklistItem item;
  final bool isCompleted;
  final Function(bool passed, String? notes) onCheck;

  const SafetyChecklistCard({
    super.key,
    required this.item,
    required this.isCompleted,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: (checked) {
            if (checked == true) {
              _showCheckDialog(context);
            }
          },
        ),
        title: Row(
          children: [
            Expanded(child: Text(item.title)),
            if (item.isRequired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red),
                ),
                child: const Text(
                  'REQUIRED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
        subtitle: item.description != null
            ? Text(
                item.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: isCompleted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
      ),
    );
  }

  Future<void> _showCheckDialog(BuildContext context) async {
    bool passed = true;
    String notes = '';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(item.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.description != null) ...[
                Text(item.description!),
                const SizedBox(height: 16),
              ],
              const Text('Status:'),
              // ignore: deprecated_member_use
              RadioListTile<bool>(
                title: const Text('Pass'),
                value: true,
                // ignore: deprecated_member_use
                groupValue: passed,
                // ignore: deprecated_member_use
                onChanged: (value) => setState(() => passed = value!),
              ),
              // ignore: deprecated_member_use
              RadioListTile<bool>(
                title: const Text('Fail'),
                value: false,
                // ignore: deprecated_member_use
                groupValue: passed,
                // ignore: deprecated_member_use
                onChanged: (value) => setState(() => passed = value!),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) => notes = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                onCheck(passed, notes.isEmpty ? null : notes);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
