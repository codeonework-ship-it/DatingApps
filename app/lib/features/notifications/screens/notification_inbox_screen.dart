import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../friends/screens/friends_screen.dart';
import '../../support/support_routes.dart';
import '../../swipe/screens/liked_me_screen.dart';
import '../providers/notification_provider.dart';

class NotificationInboxScreen extends ConsumerWidget {
  const NotificationInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Rows can leave the tree before their command fails (a swiped-away
    // last row empties the list), so failures report through the screen.
    final screen = context;
    final state = ref.watch(notificationProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              key: const ValueKey('qa.notifications.read_all'),
              onPressed: () async {
                try {
                  await ref.read(notificationProvider.notifier).markAllRead();
                } on Object catch (error) {
                  if (context.mounted) {
                    _showError(
                      context,
                      apiErrorMessage(
                        error,
                        fallback: l10n.notificationsReadAllFailed,
                      ),
                    );
                  }
                }
              },
              child: Text(l10n.notificationsReadAll),
            ),
        ],
      ),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: RefreshIndicator(
            key: const ValueKey('qa.notifications.refresh'),
            onRefresh: () async {
              await ref.read(notificationProvider.notifier).bootstrap();
              final error = ref.read(notificationProvider).error;
              if (error != null && context.mounted) {
                _showError(context, error);
              }
            },
            child: state.isLoading && state.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.items.isEmpty && state.error != null
                // A failed load is not "all caught up": say so and offer
                // a retry (pull to refresh works too).
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 120),
                      const Icon(Icons.cloud_off_rounded, size: 56),
                      const SizedBox(height: 16),
                      Text(
                        state.error!,
                        key: const ValueKey('qa.notifications.load_error'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          key: const ValueKey('qa.notifications.retry'),
                          onPressed: () => ref
                              .read(notificationProvider.notifier)
                              .bootstrap(),
                          child: Text(l10n.commonRetry),
                        ),
                      ),
                    ],
                  )
                : state.items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      SizedBox(height: 120),
                      Icon(Icons.notifications_none_rounded, size: 56),
                      SizedBox(height: 16),
                      Text(
                        l10n.notificationsInboxCaughtUp,
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
                        key: ValueKey('qa.notifications.item.${item.id}'),
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
                        onDismissed: (_) async {
                          try {
                            await ref
                                .read(notificationProvider.notifier)
                                .dismiss(item.id);
                          } on Object catch (error) {
                            if (screen.mounted) {
                              _showError(
                                screen,
                                apiErrorMessage(
                                  error,
                                  fallback: l10n.notificationsDismissFailed,
                                ),
                              );
                            }
                          }
                        },
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
                              // Support replies and status changes open
                              // the ticket thread.
                              if (item.eventType.startsWith('support.')) {
                                openSupportRoute(context, item.actionRoute);
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
                                        _relativeTime(l10n, item.createdAt),
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

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
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

Color _categoryColor(String category, ColorScheme scheme) => switch (category) {
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

String _relativeTime(AppLocalizations l10n, DateTime value) {
  final difference = DateTime.now().difference(value.toLocal());
  if (difference.inMinutes < 1) {
    return l10n.timeAgoJustNow;
  }
  if (difference.inHours < 1) {
    return l10n.notificationsAgoMinutes(difference.inMinutes);
  }
  if (difference.inDays < 1) {
    return l10n.notificationsAgoHours(difference.inHours);
  }
  return l10n.notificationsAgoDays(difference.inDays);
}
