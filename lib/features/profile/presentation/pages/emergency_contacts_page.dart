import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/emergency_contact.dart';
import '../../../../services/emergency_contacts_service.dart';

/// Emergency contacts management page
class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  final EmergencyContactsService _contactsService = EmergencyContactsService();
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      await _contactsService.initialize();
      setState(() {
        _contacts = _contactsService.contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to load contacts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddContactDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContactsList(),
    );
  }

  Widget _buildContactsList() {
    if (_contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.contacts_outlined,
              size: 64,
              color: AppTheme.neutralGray,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Emergency Contacts',
              style: TextStyle(
                color: AppTheme.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add emergency contacts to receive SOS alerts',
              style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddContactDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _contacts.length,
      onReorder: _reorderContacts,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return _buildContactCard(contact, index);
      },
    );
  }

  Widget _buildContactCard(EmergencyContact contact, int index) {
    return Card(
      key: ValueKey(contact.id),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getContactTypeColor(
            contact.type,
          ).withValues(alpha: 0.2),
          child: Icon(
            _getContactTypeIcon(contact.type),
            color: _getContactTypeColor(contact.type),
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(
            color: AppTheme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact.phoneNumber.isEmpty
                  ? 'No phone number'
                  : contact.phoneNumber,
              style: TextStyle(
                color: contact.phoneNumber.isEmpty
                    ? AppTheme.criticalRed
                    : AppTheme.secondaryText,
                fontSize: 12,
              ),
            ),
            if (contact.relationship != null) ...[
              const SizedBox(height: 2),
              Text(
                contact.relationship!,
                style: const TextStyle(
                  color: AppTheme.disabledText,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: contact.isEnabled
                    ? AppTheme.safeGreen.withValues(alpha: 0.2)
                    : AppTheme.neutralGray.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                contact.isEnabled ? 'ACTIVE' : 'DISABLED',
                style: TextStyle(
                  color: contact.isEnabled
                      ? AppTheme.safeGreen
                      : AppTheme.neutralGray,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) => _handleContactAction(value, contact),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        contact.isEnabled
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(contact.isEnabled ? 'Disable' : 'Enable'),
                    ],
                  ),
                ),
                if (contact.type != ContactType.emergencyServices)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          size: 16,
                          color: AppTheme.criticalRed,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(color: AppTheme.criticalRed),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Icon(Icons.drag_handle, color: AppTheme.neutralGray),
          ],
        ),
        onTap: () => _showContactDetails(contact),
      ),
    );
  }

  void _handleContactAction(String action, EmergencyContact contact) {
    switch (action) {
      case 'edit':
        _showEditContactDialog(contact);
        break;
      case 'toggle':
        _toggleContact(contact);
        break;
      case 'delete':
        _showDeleteConfirmation(contact);
        break;
    }
  }

  Future<void> _reorderContacts(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = _contacts.removeAt(oldIndex);
    _contacts.insert(newIndex, item);

    final contactIds = _contacts.map((c) => c.id).toList();

    try {
      await _contactsService.reorderContacts(contactIds);
      setState(() {});
    } catch (e) {
      _showErrorDialog('Failed to reorder contacts: $e');
      // Revert the change
      _loadContacts();
    }
  }

  Future<void> _toggleContact(EmergencyContact contact) async {
    try {
      final updated = contact.copyWith(isEnabled: !contact.isEnabled);
      await _contactsService.updateContact(contact.id, updated);
      _loadContacts();
    } catch (e) {
      _showErrorDialog('Failed to update contact: $e');
    }
  }

  void _showAddContactDialog() {
    _showContactDialog();
  }

  void _showEditContactDialog(EmergencyContact contact) {
    _showContactDialog(contact: contact);
  }

  void _showContactDialog({EmergencyContact? contact}) {
    final isEditing = contact != null;
    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController = TextEditingController(
      text: contact?.phoneNumber ?? '',
    );
    final emailController = TextEditingController(text: contact?.email ?? '');
    final relationshipController = TextEditingController(
      text: contact?.relationship ?? '',
    );
    final notesController = TextEditingController(text: contact?.notes ?? '');

    ContactType selectedType = contact?.type ?? ContactType.family;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Contact' : 'Add Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ContactType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ContactType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(_getContactTypeIcon(type), size: 16),
                          const SizedBox(width: 8),
                          Text(_getContactTypeLabel(type)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: relationshipController,
                  decoration: const InputDecoration(
                    labelText: 'Relationship (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _saveContact(
                context,
                isEditing: isEditing,
                contactId: contact?.id,
                name: nameController.text,
                phone: phoneController.text,
                email: emailController.text,
                type: selectedType,
                relationship: relationshipController.text,
                notes: notesController.text,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveContact(
    BuildContext context, {
    required bool isEditing,
    String? contactId,
    required String name,
    required String phone,
    required String email,
    required ContactType type,
    required String relationship,
    required String notes,
  }) async {
    // Capture navigator early to avoid using BuildContext after awaits
    final navigator = Navigator.of(context);
    if (name.trim().isEmpty || phone.trim().isEmpty) {
      _showErrorDialog('Name and phone number are required');
      return;
    }

    try {
      if (isEditing && contactId != null) {
        final existingContact = _contactsService.getContact(contactId);
        if (existingContact != null) {
          final updated = existingContact.copyWith(
            name: name.trim(),
            phoneNumber: phone.trim(),
            email: email.trim().isEmpty ? null : email.trim(),
            type: type,
            relationship: relationship.trim().isEmpty
                ? null
                : relationship.trim(),
            notes: notes.trim().isEmpty ? null : notes.trim(),
            isEnabled: phone.trim().isNotEmpty, // Enable if phone is provided
          );
          await _contactsService.updateContact(contactId, updated);
        }
      } else {
        await _contactsService.addContact(
          name: name.trim(),
          phoneNumber: phone.trim(),
          email: email.trim().isEmpty ? null : email.trim(),
          type: type,
          relationship: relationship.trim().isEmpty
              ? null
              : relationship.trim(),
          notes: notes.trim().isEmpty ? null : notes.trim(),
        );
      }

      navigator.pop();
      _loadContacts();
    } catch (e) {
      _showErrorDialog('Failed to save contact: $e');
    }
  }

  void _showDeleteConfirmation(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _contactsService.deleteContact(contact.id);
                _loadContacts();
              } catch (e) {
                _showErrorDialog('Failed to delete contact: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showContactDetails(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(contact.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Phone', contact.phoneNumber),
            if (contact.email != null) _buildDetailRow('Email', contact.email!),
            _buildDetailRow('Type', _getContactTypeLabel(contact.type)),
            if (contact.relationship != null)
              _buildDetailRow('Relationship', contact.relationship!),
            _buildDetailRow('Priority', '#${contact.priority}'),
            _buildDetailRow(
              'Status',
              contact.isEnabled ? 'Active' : 'Disabled',
            ),
            if (contact.notes != null) _buildDetailRow('Notes', contact.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditContactDialog(contact);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.primaryText, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  IconData _getContactTypeIcon(ContactType type) {
    switch (type) {
      case ContactType.family:
        return Icons.family_restroom;
      case ContactType.friend:
        return Icons.people;
      case ContactType.medical:
        return Icons.local_hospital;
      case ContactType.work:
        return Icons.work;
      case ContactType.emergencyServices:
        return Icons.emergency;
      case ContactType.other:
        return Icons.person;
    }
  }

  Color _getContactTypeColor(ContactType type) {
    switch (type) {
      case ContactType.family:
        return AppTheme.safeGreen;
      case ContactType.friend:
        return AppTheme.infoBlue;
      case ContactType.medical:
        return AppTheme.criticalRed;
      case ContactType.work:
        return AppTheme.warningOrange;
      case ContactType.emergencyServices:
        return AppTheme.primaryRed;
      case ContactType.other:
        return AppTheme.neutralGray;
    }
  }

  String _getContactTypeLabel(ContactType type) {
    switch (type) {
      case ContactType.family:
        return 'Family';
      case ContactType.friend:
        return 'Friend';
      case ContactType.medical:
        return 'Medical';
      case ContactType.work:
        return 'Work';
      case ContactType.emergencyServices:
        return 'Emergency Services';
      case ContactType.other:
        return 'Other';
    }
  }
}
