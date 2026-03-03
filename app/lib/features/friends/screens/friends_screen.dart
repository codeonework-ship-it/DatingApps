import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/friends_provider.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendsProvider);
    final notifier = ref.read(friendsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Friends & Connections')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isMutating
            ? null
            : () => _showAddFriendDialog(context, notifier),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Friend'),
      ),
      body: RefreshIndicator(
        onRefresh: notifier.load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Maintain friendships and join friend-focused engagement activities.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Friends List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (state.isLoading && state.friends.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (state.friends.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No friends added yet.'),
                ),
              )
            else
              ...state.friends.map(
                (friend) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.people)),
                    title: Text(friend.friendName),
                    subtitle: Text(
                      'ID: ${friend.friendUserId}\nStatus: ${friend.status}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_remove),
                      onPressed: state.isMutating
                          ? null
                          : () => notifier.removeFriend(friend.friendUserId),
                    ),
                    isThreeLine: true,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Friend Engagement Activities',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (state.activities.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No friend activities yet.'),
                ),
              )
            else
              ...state.activities.map(
                (activity) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.local_activity_outlined),
                    title: Text(activity.title),
                    subtitle: Text(activity.description),
                    trailing: Text(activity.createdAt),
                  ),
                ),
              ),
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Text(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showAddFriendDialog(
    BuildContext context,
    FriendsNotifier notifier,
  ) async {
    final controller = TextEditingController();
    final add = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Friend'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Friend User ID',
            hintText: 'Enter user id',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (add == true) {
      final friendId = controller.text.trim();
      if (friendId.isNotEmpty) {
        await notifier.addFriend(friendId);
      }
    }
  }
}
