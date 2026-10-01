import 'package:dio/dio.dart';

/// A wall tier one of the member's chapters or photos reached that has not
/// been celebrated yet. Served by `GET /walls/celebrations`.
class WallCelebration {
  const WallCelebration({
    required this.id,
    required this.kind,
    required this.contentId,
    required this.tier,
    required this.reach,
    required this.title,
    this.themeId = '',
  });

  factory WallCelebration.fromJson(Map<dynamic, dynamic> json) =>
      WallCelebration(
        id: json['id'] as String,
        kind: json['kind'] as String? ?? 'chapter',
        contentId: json['content_id'] as String,
        themeId: json['theme_id'] as String? ?? '',
        tier: (json['tier'] as num?)?.toInt() ?? 1,
        reach: (json['reach'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
      );

  final String id, kind, contentId, themeId, title;
  final int tier, reach;

  /// True for a photo on members' walls and for a photo chosen as Cover of
  /// the Week; both open the theme gallery.
  bool get isPhoto => kind == 'photo' || isCover;

  /// The member's photo was chosen as Cover of the Week (`reach` is 0).
  bool get isCover => kind == 'cover';

  /// "Your chapter reached 50 walls" / "Your photo reached 100 walls" /
  /// "Your photo is Cover of the Week".
  String get headline => isCover
      ? 'Your photo is Cover of the Week'
      : 'Your ${isPhoto ? 'photo' : 'chapter'} reached $reach walls';

  /// The line under the headline on the celebration card.
  String get message => isCover
      ? 'Members loved it. Everyone sees it on Today this week.'
      : 'Members loved it. It is now on their Today walls.';
}

/// Loads unseen celebrations. Failures return an empty list: a celebration is
/// a delight, never a reason to show an error.
Future<List<WallCelebration>> fetchWallCelebrations(Dio api) async {
  try {
    final response = await api.get<dynamic>('/walls/celebrations');
    final items = (response.data as Map?)?['celebrations'];
    if (items is! List) {
      return const [];
    }
    return items
        .whereType<Map<dynamic, dynamic>>()
        .map(WallCelebration.fromJson)
        .toList();
  } on Object {
    return const [];
  }
}

/// Acknowledges a celebration so it plays only once. Errors are swallowed;
/// the worst case is that the shower plays again on the next open.
Future<void> markWallCelebrationSeen(Dio api, String id) async {
  try {
    await api.post<dynamic>('/walls/celebrations/$id/seen');
  } on Object {
    // Best effort.
  }
}
