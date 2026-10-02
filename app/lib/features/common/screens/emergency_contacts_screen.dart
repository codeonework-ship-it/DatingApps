import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final contactsAsync = ref.watch(emergencyContactsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyEmergencyContacts)),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: contactsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.commonSomethingWentWrongTryAgain,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      key: const ValueKey('qa.emergency.retry'),
                      onPressed: () =>
                          ref.invalidate(emergencyContactsProvider),
                      child: Text(l10n.commonRetry),
                    ),
                  ],
                ),
              ),
              data: (contacts) => Column(
                children: [
                  GlassContainer(
                    padding: EdgeInsets.all(16),
                    blur: 12,
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    child: Text(l10n.emergencyIntro),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: contacts.isEmpty
                        ? GlassContainer(
                            padding: EdgeInsets.all(16),
                            blur: 12,
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                            child: Center(child: Text(l10n.emergencyEmpty)),
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
                    key: const ValueKey('qa.emergency.add'),
                    label: contacts.length >= 3
                        ? l10n.emergencyMaxReached
                        : l10n.emergencyAddContact,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        blur: 12,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                '$displayOrder',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: ValueKey('qa.emergency.edit.${contact.id}'),
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _onEditContact(context, contact),
            ),
            IconButton(
              key: ValueKey('qa.emergency.delete.${contact.id}'),
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => _onDeleteContact(context, contact),
            ),
          ],
        ),
      );

  Future<void> _onAddContact(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final draft = await _showContactEditor(context: context);
    if (draft == null) return;

    if (!_isValidDraft(draft)) {
      _showMessage(l10n.emergencyInvalidInput);
      return;
    }

    try {
      await ref
          .read(emergencyContactsProvider.notifier)
          .addContact(name: draft.name, phoneNumber: draft.phoneNumber);
      _showMessage(l10n.emergencyAdded);
    } catch (_) {
      _showMessage(l10n.emergencyAddFailed);
    }
  }

  Future<void> _onEditContact(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    final l10n = AppLocalizations.of(context);
    final draft = await _showContactEditor(
      context: context,
      initialName: contact.name,
      initialPhone: contact.phoneNumber,
    );
    if (draft == null) return;

    if (!_isValidDraft(draft)) {
      _showMessage(l10n.emergencyInvalidInput);
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
      _showMessage(l10n.emergencyUpdated);
    } catch (_) {
      _showMessage(l10n.emergencyUpdateFailed);
    }
  }

  Future<void> _onDeleteContact(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    final l10n = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.emergencyRemoveTitle),
        content: Text(l10n.emergencyRemoveBody(contact.name)),
        actions: [
          TextButton(
            key: const ValueKey('qa.emergency.remove_cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            key: const ValueKey('qa.emergency.remove_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonRemove),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await ref
          .read(emergencyContactsProvider.notifier)
          .removeContact(contact.id);
      _showMessage(l10n.emergencyRemoved);
    } catch (_) {
      _showMessage(l10n.emergencyRemoveFailed);
    }
  }

  Future<_ContactDraft?> _showContactEditor({
    required BuildContext context,
    String? initialName,
    String? initialPhone,
  }) {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: initialName ?? '');
    final phoneController = TextEditingController(text: initialPhone ?? '');

    return showDialog<_ContactDraft>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          initialName == null
              ? l10n.emergencyAddContact
              : l10n.emergencyEditContact,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('qa.emergency.name_field'),
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.emergencyNameLabel),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('qa.emergency.phone_field'),
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.emergencyPhoneLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const ValueKey('qa.emergency.editor_cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            key: const ValueKey('qa.emergency.editor_save'),
            onPressed: () {
              Navigator.of(dialogContext).pop(
                _ContactDraft(
                  name: nameController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                ),
              );
            },
            child: Text(l10n.commonSave),
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
