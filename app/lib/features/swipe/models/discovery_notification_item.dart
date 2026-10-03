enum DiscoveryNotificationType { whoRepliedMe, whoLikedMe }

/// An unread Discover notification. The sheet words it from [type] and
/// [count] in the member's language.
class DiscoveryNotificationItem {
  const DiscoveryNotificationItem({
    required this.id,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.count = 0,
  });

  final String id;
  final DiscoveryNotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final int count;
}

List<DiscoveryNotificationItem> buildDiscoveryNotificationStack({
  required int repliedCount,
  required int likedMeCount,
  DateTime? now,
}) {
  final timestamp = now ?? DateTime.now().toUtc();
  final stack = <DiscoveryNotificationItem>[];

  if (repliedCount > 0) {
    stack.add(
      DiscoveryNotificationItem(
        id: 'who-replied-me',
        type: DiscoveryNotificationType.whoRepliedMe,
        createdAt: timestamp.subtract(const Duration(minutes: 2)),
        isRead: false,
        count: repliedCount,
      ),
    );
  }

  if (likedMeCount > 0) {
    stack.add(
      DiscoveryNotificationItem(
        id: 'who-liked-me',
        type: DiscoveryNotificationType.whoLikedMe,
        createdAt: timestamp.subtract(const Duration(minutes: 1)),
        isRead: false,
        count: likedMeCount,
      ),
    );
  }

  stack.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return stack.where((item) => !item.isRead).take(3).toList(growable: false);
}
