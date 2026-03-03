import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../profile/models/profile_models.dart';
import '../../profile/providers/emergency_contacts_provider.dart';

class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState
    extends ConsumerState<EmergencyContactsScreen> {
  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(emergencyContactsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: contactsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(emergencyContactsProvider),
                  child: const Text('Retry'),
                ),
              ),
              data: (contacts) => Column(
                children: [
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    blur: 12,
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                    child: const Text(
                      'Add up to 3 trusted contacts. These contacts are used for safety workflows and SOS features in later phases.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: contacts.isEmpty
                        ? GlassContainer(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.9,
                            ),
                            blur: 12,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(24),
                            ),
                            child: const Center(
                              child: Text('No emergency contacts added yet.'),
                            ),
                          )
                        : ListView.separated(
                            itemCount: contacts.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final contact = contacts[index];
                              return _contactTile(contact, index + 1);
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  GlassButton(
                    label: contacts.length >= 3
                        ? 'Maximum contacts added'
                        : 'Add Contact',
                    onPressed: contacts.length >= 3
                        ? null
                        : () => _onAddContact(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactTile(EmergencyContact contact, int displayOrder) =>
      GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        blur: 12,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.15),
              child: Text(
                '$displayOrder',
                style: const TextStyle(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    contact.phoneNumber,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.textGrey),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _onEditContact(context, contact),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
              onPressed: () => _onDeleteContact(context, contact),
            ),
          ],
        ),
      );

  Future<void> _onAddContact(BuildContext context) async {
    final draft = await _showContactEditor(context: context);
    if (draft == null) return;

    if (!_isValidDraft(draft)) {
      _showMessage('Enter a valid name and phone number.');
      return;
    }

    try {
      await ref
          .read(emergencyContactsProvider.notifier)
          .addContact(name: draft.name, phoneNumber: draft.phoneNumber);
      _showMessage('Emergency contact added.');
    } catch (_) {
      _showMessage('Failed to add contact. Please try again.');
    }
  }

  Future<void> _onEditContact(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    final draft = await _showContactEditor(
      context: context,
      initialName: contact.name,
      initialPhone: contact.phoneNumber,
    );
    if (draft == null) return;

    if (!_isValidDraft(draft)) {
      _showMessage('Enter a valid name and phone number.');
      return;
    }

    try {
      await ref
          .read(emergencyContactsProvider.notifier)
          .updateContact(
            contactId: contact.id,
            name: draft.name,
            phoneNumber: draft.phoneNumber,
          );
      _showMessage('Emergency contact updated.');
    } catch (_) {
      _showMessage('Failed to update contact. Please try again.');
    }
  }

  Future<void> _onDeleteContact(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Contact'),
        content: Text('Remove ${contact.name} from emergency contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await ref
          .read(emergencyContactsProvider.notifier)
          .removeContact(contact.id);
      _showMessage('Emergency contact removed.');
    } catch (_) {
      _showMessage('Failed to remove contact. Please try again.');
    }
  }

  Future<_ContactDraft?> _showContactEditor({
    required BuildContext context,
    String? initialName,
    String? initialPhone,
  }) {
    final nameController = TextEditingController(text: initialName ?? '');
    final phoneController = TextEditingController(text: initialPhone ?? '');

    return showDialog<_ContactDraft>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(initialName == null ? 'Add Contact' : 'Edit Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(
                _ContactDraft(
                  name: nameController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  bool _isValidDraft(_ContactDraft draft) {
    if (draft.name.isEmpty) {
      return false;
    }

    final phone = draft.phoneNumber.replaceAll(RegExp(r'[^+0-9]'), '');
    if (phone.length < 8 || phone.length > 16) {
      return false;
    }

    return RegExp(r'^[+0-9]+$').hasMatch(phone);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ContactDraft {
  const _ContactDraft({required this.name, required this.phoneNumber});
  final String name;
  final String phoneNumber;
}
