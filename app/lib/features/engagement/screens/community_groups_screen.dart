import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/community_groups_provider.dart';

class CommunityGroupsScreen extends ConsumerStatefulWidget {
  const CommunityGroupsScreen({super.key});

  @override
  ConsumerState<CommunityGroupsScreen> createState() =>
      _CommunityGroupsScreenState();
}

class _CommunityGroupsScreenState extends ConsumerState<CommunityGroupsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityGroupsProvider);
    final notifier = ref.read(communityGroupsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: state.isMutating ? null : _openCreateGroupSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (state.isLoading && state.groups.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (state.invites.isNotEmpty) ...[
                Text(
                  'Pending Invites',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ...state.invites.map(
                  (invite) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invite.groupName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text('${invite.groupCity} • ${invite.groupTopic}'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              ElevatedButton(
                                onPressed: state.isMutating
                                    ? null
                                    : () => notifier.respondInvite(
                                        groupId: invite.groupId,
                                        accept: true,
                                      ),
                                child: const Text('Accept'),
                              ),
                              OutlinedButton(
                                onPressed: state.isMutating
                                    ? null
                                    : () => notifier.respondInvite(
                                        groupId: invite.groupId,
                                        accept: false,
                                      ),
                                child: const Text('Decline'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Groups',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (state.groups.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No groups found. Create one to get started.'),
                  ),
                )
              else
                ...state.groups.map(
                  (group) => Card(
                    child: ListTile(
                      title: Text(group.name),
                      subtitle: Text(
                        '${group.city} • ${group.topic} • ${group.memberCount} members',
                      ),
                      trailing: Text(
                        group.isMember
                            ? (group.memberRole.isEmpty
                                  ? 'Member'
                                  : group.memberRole)
                            : group.visibility,
                      ),
                    ),
                  ),
                ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 16),
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

  Future<void> _openCreateGroupSheet() async {
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    final topicController = TextEditingController();
    final descriptionController = TextEditingController();
    final inviteesController = TextEditingController();
    var visibility = 'private';

    final shouldCreate = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Group',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Group name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: topicController,
              decoration: const InputDecoration(labelText: 'Topic/Fanclub'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: visibility,
              decoration: const InputDecoration(labelText: 'Visibility'),
              items: const [
                DropdownMenuItem(value: 'private', child: Text('private')),
                DropdownMenuItem(value: 'public', child: Text('public')),
              ],
              onChanged: (value) {
                if (value != null) {
                  visibility = value;
                }
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: inviteesController,
              decoration: const InputDecoration(
                labelText: 'Invite user IDs (comma separated)',
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Create'),
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldCreate == true && mounted) {
      final invitees = inviteesController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);

      await ref
          .read(communityGroupsProvider.notifier)
          .createGroup(
            name: nameController.text,
            city: cityController.text,
            topic: topicController.text,
            description: descriptionController.text,
            visibility: visibility,
            inviteeUserIds: invitees,
          );
    }
  }
}
