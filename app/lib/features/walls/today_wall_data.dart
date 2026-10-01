import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/api_client_provider.dart';
import '../auth/providers/auth_provider.dart';
import '../blog/blog_data.dart';
import '../photo_themes/photo_themes_data.dart';

/// The two kinds of content a wall item or a view can refer to.
abstract final class WallKind {
  static const chapter = 'chapter';
  static const photo = 'photo';
}

/// The most items `GET /walls/today` returns, and the most Today shows.
const todayWallLimit = 10;

/// One item on Today's wall: a chapter ([post]) or a Photo Theme photo
/// ([entry]). Exactly one of the two is set, matching [kind].
class TodayWallItem {
  const TodayWallItem.chapter(BlogPost this.post, {this.position = 0})
    : kind = WallKind.chapter,
      entry = null;

  const TodayWallItem.photo(ThemeEntry this.entry, {this.position = 0})
    : kind = WallKind.photo,
      post = null;

  /// Parses one `items[]` element. Unknown kinds and malformed payloads give
  /// null so one bad item never empties the whole wall.
  static TodayWallItem? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final position = (json['position'] as num?)?.toInt() ?? 0;
    try {
      switch (json['kind']) {
        case WallKind.chapter:
          final post = json['post'];
          return post is Map
              ? TodayWallItem.chapter(
                  BlogPost.fromJson(post),
                  position: position,
                )
              : null;
        case WallKind.photo:
          final entry = json['entry'];
          return entry is Map
              ? TodayWallItem.photo(
                  ThemeEntry.fromJson(entry),
                  position: position,
                )
              : null;
      }
    } on Object {
      return null;
    }
    return null;
  }

  final String kind;
  final int position;
  final BlogPost? post;
  final ThemeEntry? entry;

  bool get isChapter => kind == WallKind.chapter;

  /// The chapter or photo ID, as `POST /walls/views` expects it.
  String get id => post?.id ?? entry?.id ?? '';
}

/// `GET /walls/today`: up to ten picks, fixed for the member's UTC day.
class TodayWall {
  const TodayWall({required this.day, required this.items});

  factory TodayWall.fromJson(Map<dynamic, dynamic> json) => TodayWall(
    day: json['day'] as String? ?? '',
    items: (json['items'] as List? ?? const <dynamic>[])
        .map(TodayWallItem.tryParse)
        .whereType<TodayWallItem>()
        .take(todayWallLimit)
        .toList(),
  );

  /// The UTC day the picks were made for, `YYYY-MM-DD`.
  final String day;

  /// In display order.
  final List<TodayWallItem> items;
}

/// `GET /themes/cover`: the one photo everyone sees this week.
class CoverOfTheWeek {
  const CoverOfTheWeek({required this.weekStart, required this.entry});

  /// Returns null for `{"cover": null}` or a cover without a usable entry.
  static CoverOfTheWeek? tryParse(Object? json) {
    final cover = json is Map ? json['cover'] : null;
    if (cover is! Map || cover['entry'] is! Map) {
      return null;
    }
    final entry = ThemeEntry.fromJson(cover['entry'] as Map);
    if (entry.id.isEmpty) {
      return null;
    }
    return CoverOfTheWeek(
      weekStart: DateTime.tryParse(cover['week_start'] as String? ?? ''),
      entry: entry,
    );
  }

  /// Monday (UTC) of the cover's week.
  final DateTime? weekStart;
  final ThemeEntry entry;
}

StateError _signedOut() => StateError('Sign in to see your wall.');

final todayWallProvider = FutureProvider.autoDispose<TodayWall>((ref) async {
  final user = ref.watch(authNotifierProvider.select((s) => s.userId));
  if (user == null) {
    throw _signedOut();
  }
  final response = await ref
      .watch(apiClientProvider)
      .get<dynamic>('/walls/today');
  return TodayWall.fromJson(response.data as Map? ?? const {});
});

/// Null when there is no cover this week, or this member cannot see it.
final coverOfWeekProvider = FutureProvider.autoDispose<CoverOfTheWeek?>((
  ref,
) async {
  final user = ref.watch(authNotifierProvider.select((s) => s.userId));
  if (user == null) {
    throw _signedOut();
  }
  final response = await ref
      .watch(apiClientProvider)
      .get<dynamic>('/themes/cover');
  return CoverOfTheWeek.tryParse(response.data);
});

/// `POST /walls/views`: counts a unique view of a chapter or photo. Returns
/// whether it was counted (false when already counted, own content, not
/// visible, or on any error). Never throws: a view count is never a reason to
/// interrupt reading.
Future<bool> recordWallView(
  Dio api, {
  required String kind,
  required String id,
}) async {
  if (id.isEmpty) {
    return false;
  }
  try {
    final response = await api.post<dynamic>(
      '/walls/views',
      data: {'kind': kind, 'id': id},
    );
    final data = response.data;
    return data is Map && data['recorded'] == true;
  } on Object {
    return false;
  }
}

/// Fire-and-forget [recordWallView] for screens that only have a
/// [BuildContext], such as the helpers that open a chapter or a photo.
void recordWallViewFrom(
  BuildContext context, {
  required String kind,
  required String id,
}) {
  final Dio api;
  try {
    api = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(apiClientProvider);
  } on Object {
    return;
  }
  unawaited(recordWallView(api, kind: kind, id: id));
}
