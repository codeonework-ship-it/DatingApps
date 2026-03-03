import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/conversation_rooms_provider.dart';

class ConversationRoomsScreen extends ConsumerStatefulWidget {
  const ConversationRoomsScreen({super.key});

  @override
  ConsumerState<ConversationRoomsScreen> createState() =>
      _ConversationRoomsScreenState();
}

class _ConversationRoomsScreenState
    extends ConsumerState<ConversationRoomsScreen> {
  static const List<String> _filters = <String>[
    '',
    'scheduled',
    'active',
    'closed',
  ];

  String _selectedFilter = '';
  bool _friendOnly = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationRoomsProvider);
    final notifier = ref.read(conversationRoomsProvider.notifier);
    if (_friendOnly != state.friendOnly) {
      _friendOnly = state.friendOnly;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Conversation Rooms')),
      body: RefreshIndicator(
        onRefresh: () => notifier.loadRooms(
          stateFilter: _selectedFilter,
          friendOnly: _friendOnly,
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedFilter,
              decoration: const InputDecoration(labelText: 'State Filter'),
              items: _filters
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.isEmpty ? 'All' : value),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _selectedFilter = value);
                notifier.loadRooms(stateFilter: value, friendOnly: _friendOnly);
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _friendOnly,
              title: const Text('Friend-only rooms'),
              subtitle: const Text(
                'Show rooms where you or your friends are participants',
              ),
              onChanged: (value) {
                setState(() => _friendOnly = value);
                notifier.loadRooms(
                  stateFilter: _selectedFilter,
                  friendOnly: value,
                );
              },
            ),
            const SizedBox(height: 12),
            if (state.isLoading && state.rooms.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.rooms.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No rooms available right now.'),
                ),
              )
            else
              ...state.rooms.map(
                (room) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.theme,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(room.description),
                        const SizedBox(height: 8),
                        Text(
                          'State: ${room.lifecycleState} • Participants: ${room.participantCount}/${room.capacity}',
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton(
                              onPressed: state.isMutating
                                  ? null
                                  : () {
                                      if (room.isParticipant) {
                                        notifier.leaveRoom(room.id);
                                      } else {
                                        notifier.joinRoom(room.id);
                                      }
                                    },
                              child: Text(
                                room.isParticipant ? 'Leave' : 'Join',
                              ),
                            ),
                            OutlinedButton(
                              onPressed: state.isMutating
                                  ? null
                                  : () =>
                                        _showModerationSheet(context, room.id),
                              child: const Text('Moderate'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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

  Future<void> _showModerationSheet(BuildContext context, String roomId) async {
    final targetController = TextEditingController();
    final reasonController = TextEditingController();
    var selectedAction = 'warn';

    final submit = await showModalBottomSheet<bool>(
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
              'Moderate Room Participant',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetController,
              decoration: const InputDecoration(labelText: 'Target User ID'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedAction,
              decoration: const InputDecoration(labelText: 'Action'),
              items: const [
                DropdownMenuItem(value: 'warn', child: Text('warn')),
                DropdownMenuItem(value: 'mute', child: Text('mute')),
                DropdownMenuItem(value: 'remove', child: Text('remove')),
              ],
              onChanged: (value) {
                if (value != null) {
                  selectedAction = value;
                }
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );

    if (submit == true && mounted) {
      final target = targetController.text.trim();
      if (target.isNotEmpty) {
        await ref
            .read(conversationRoomsProvider.notifier)
            .moderateRoom(
              roomId: roomId,
              targetUserId: target,
              action: selectedAction,
              reason: reasonController.text.trim(),
            );
      }
    }
  }
}
