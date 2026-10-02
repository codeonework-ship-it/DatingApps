import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/providers/blocked_users_provider.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final blockedAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyBlockedUsers)),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: blockedAsync.when(
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
                      key: const ValueKey('qa.blocked.retry'),
                      onPressed: () => ref.invalidate(blockedUsersProvider),
                      child: Text(l10n.commonRetry),
                    ),
                  ],
                ),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return GlassContainer(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.9),
                    blur: 12,
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                    child: Center(child: Text(l10n.blockedEmpty)),
                  );
                }

                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    // The provider falls back to an English placeholder when
                    // the server sends no name; show it in the member's
                    // language instead.
                    final name = user.name == 'Unknown User'
                        ? l10n.blockedUnknownUser
                        : user.name;
                    return GlassContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.9),
                      blur: 12,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundImage: user.photoUrl == null
                                ? null
                                : NetworkImage(user.photoUrl!),
                            child: user.photoUrl == null
                                ? const Icon(Icons.person_outline)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TextButton(
                            key: ValueKey('qa.blocked.unblock.${user.id}'),
                            onPressed: () => _onUnblock(
                              context: context,
                              ref: ref,
                              userId: user.id,
                              name: name,
                            ),
                            child: Text(l10n.blockedUnblock),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onUnblock({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    required String name,
  }) async {
    final l10n = AppLocalizations.of(context);
    final shouldUnblock = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.blockedUnblockTitle),
        content: Text(l10n.blockedUnblockBody(name)),
        actions: [
          TextButton(
            key: const ValueKey('qa.blocked.unblock_cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            key: const ValueKey('qa.blocked.unblock_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.blockedUnblock),
          ),
        ],
      ),
    );

    if (shouldUnblock != true) {
      return;
    }

    try {
      await ref.read(blockedUsersProvider.notifier).unblockUser(userId);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.blockedUnblockedSnack(name))));
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.blockedUnblockFailed)));
    }
  }
}
