enum DiscoveryNotificationType { whoRepliedMe, whoLikedMe }

class DiscoveryNotificationItem {
  const DiscoveryNotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    this.isRead = false,
    this.count = 0,
  });

  final String id;
  final DiscoveryNotificationType type;
  final String title;
  final String subtitle;
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
        title: 'Who replied me',
        subtitle: '$repliedCount new reply${repliedCount == 1 ? '' : 'ies'}',
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
        title: 'Who has liked me',
        subtitle: '$likedMeCount new like${likedMeCount == 1 ? '' : 's'}',
        createdAt: timestamp.subtract(const Duration(minutes: 1)),
        isRead: false,
        count: likedMeCount,
      ),
    );
  }

  stack.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return stack.where((item) => !item.isRead).take(3).toList(growable: false);
}
