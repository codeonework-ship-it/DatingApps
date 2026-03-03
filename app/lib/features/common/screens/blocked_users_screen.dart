import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/glass_widgets.dart';
import '../../profile/providers/blocked_users_provider.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Users')),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: blockedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(blockedUsersProvider),
                  child: const Text('Retry'),
                ),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return GlassContainer(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    blur: 12,
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                    child: const Center(
                      child: Text('You have not blocked any users.'),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return GlassContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
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
                              user.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _onUnblock(
                              context: context,
                              ref: ref,
                              userId: user.id,
                              name: user.name,
                            ),
                            child: const Text('Unblock'),
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
    final shouldUnblock = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Unblock $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unblock'),
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
      ).showSnackBar(SnackBar(content: Text('$name has been unblocked.')));
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to unblock user. Please try again.'),
        ),
      );
    }
  }
}
