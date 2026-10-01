import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../friends/screens/friends_screen.dart';
import '../../swipe/screens/liked_me_screen.dart';
import '../providers/notification_provider.dart';

class NotificationInboxScreen extends ConsumerWidget {
  const NotificationInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationProvider.notifier).markAllRead(),
              child: const Text('Read all'),
            ),
        ],
      ),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(notificationProvider.notifier).bootstrap(),
            child: state.isLoading && state.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: const [
                      SizedBox(height: 120),
                      Icon(Icons.notifications_none_rounded, size: 56),
                      SizedBox(height: 16),
                      Text(
                        'You are all caught up',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: state.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: scheme.error,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: scheme.onError,
                          ),
                        ),
                        onDismissed: (_) => ref
                            .read(notificationProvider.notifier)
                            .dismiss(item.id),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: item.isRead
                              ? scheme.surface
                              : scheme.tertiaryContainer,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(20),
                          ),
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(notificationProvider.notifier)
                                  .markRead(item.id);
                              // "Someone liked you" opens who liked me.
                              if (item.eventType == 'like.received') {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const LikedMeScreen(),
                                  ),
                                );
                              }
                              // Friend requests and accepts open Friends.
                              if (item.eventType.startsWith(
                                'friend_request.',
                              )) {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const FriendsScreen(),
                                  ),
                                );
                              }
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: _categoryColor(
                                    item.category,
                                    scheme,
                                  ),
                                  child: Icon(
                                    _categoryIcon(item.category),
                                    color: _categoryForeground(
                                      item.category,
                                      scheme,
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
                                        item.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      if (item.body.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(item.body),
                                      ],
                                      const SizedBox(height: 8),
                                      Text(
                                        _relativeTime(item.createdAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!item.isRead)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: CircleAvatar(
                                      radius: 5,
                                      backgroundColor: scheme.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

IconData _categoryIcon(String category) => switch (category) {
  'call' => Icons.call_rounded,
  'nudge' => Icons.waving_hand_rounded,
  'message' => Icons.chat_bubble_rounded,
  'match' => Icons.favorite_rounded,
  'like' => Icons.thumb_up_rounded,
  'safety' => Icons.shield_rounded,
  'friend_plan' => Icons.event_available_rounded,
  _ => Icons.notifications_rounded,
};

Color _categoryColor(String category, ColorScheme scheme) =>
    switch (category) {
      'call' => AppTheme.successGreen,
      'safety' => scheme.error,
      'nudge' => AppTheme.marigold,
      'friend_plan' => AppTheme.successGreen,
      _ => scheme.primary,
    };

Color _categoryForeground(String category, ColorScheme scheme) =>
    switch (category) {
      'safety' => scheme.onError,
      'call' || 'nudge' || 'friend_plan' => Colors.white,
      _ => scheme.onPrimary,
    };

String _relativeTime(DateTime value) {
  final difference = DateTime.now().difference(value.toLocal());
  if (difference.inMinutes < 1) {
    return 'Just now';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  }
  if (difference.inDays < 1) {
    return '${difference.inHours}h ago';
  }
  return '${difference.inDays}d ago';
}
