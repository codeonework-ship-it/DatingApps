import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/providers/api_client_provider.dart';
import '../auth/providers/auth_provider.dart';
import '../blog/blog_data.dart';
import '../walls/reactions.dart';

/// A shared photo prompt, such as "My perfect Sunday".
class PhotoTheme {
  const PhotoTheme({
    required this.id,
    required this.slug,
    required this.title,
    required this.prompt,
    required this.entryCount,
    required this.myEntryId,
  });
  factory PhotoTheme.fromJson(Map<dynamic, dynamic> json) => PhotoTheme(
    id: json['id'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    title: json['title'] as String? ?? '',
    prompt: json['prompt'] as String? ?? '',
    entryCount: (json['entry_count'] as num?)?.toInt() ?? 0,
    myEntryId: json['my_entry_id'] as String? ?? '',
  );
  final String id, slug, title, prompt, myEntryId;
  final int entryCount;

  /// True when the signed-in member already has a live entry for this theme.
  bool get shared => myEntryId.isNotEmpty;
}

/// One member's photo for a theme. The engagement fields follow the same
/// wall rules as chapters (likes, author-approved comments, opt-in reach to
/// other members' Today walls) and default safely when a server omits them.
class ThemeEntry {
  const ThemeEntry({
    required this.id,
    required this.themeId,
    required this.authorId,
    required this.authorName,
    required this.caption,
    required this.altText,
    required this.mine,
    this.createdAt,
    this.themeTitle = '',
    this.likeCount = 0,
    this.likedByMe = false,
    this.myReaction = '',
    this.reactions = const {},
    this.commentCount = 0,
    this.pendingCommentCount = 0,
    this.allowFeaturing = false,
    this.featured = false,
    this.wallReach = 0,
    this.viewCount = 0,
    this.nextTier,
  });
  factory ThemeEntry.fromJson(Map<dynamic, dynamic> json) => ThemeEntry(
    id: json['id'] as String? ?? '',
    themeId: json['theme_id'] as String? ?? '',
    authorId: json['author_id'] as String? ?? '',
    authorName: json['author_name'] as String? ?? '',
    caption: json['caption'] as String? ?? '',
    altText: json['alt_text'] as String? ?? '',
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    mine: json['mine'] as bool? ?? false,
    themeTitle: json['theme_title'] as String? ?? '',
    likeCount: _count(json['like_count']),
    likedByMe: json['liked_by_me'] == true,
    myReaction: json['my_reaction'] as String? ?? '',
    reactions: parseReactionCounts(json['reactions']),
    commentCount: _count(json['comment_count']),
    pendingCommentCount: _count(json['pending_comment_count']),
    allowFeaturing: json['allow_featuring'] == true,
    featured: json['featured'] == true,
    wallReach: _count(json['wall_reach']),
    viewCount: _count(json['view_count']),
    nextTier: json['next_tier'] is Map
        ? BlogNextTier.fromJson(json['next_tier'] as Map)
        : null,
  );
  final String id, themeId, authorId, authorName, caption, altText;
  final DateTime? createdAt;
  final bool mine;

  /// The prompt's title, e.g. "My perfect Sunday". Empty on older payloads.
  final String themeTitle;

  /// Likes from members. A member can never like their own photo.
  final int likeCount;
  final bool likedByMe;

  /// How this member reacted; empty when not liked.
  final String myReaction;

  /// Every member's reactions, counted per reaction id.
  final Map<String, int> reactions;

  /// Approved comments, visible to everyone who can see the photo.
  final int commentCount;

  /// Comments waiting for the author. Always 0 for anyone but the author.
  final int pendingCommentCount;

  /// The author opted in to reaching other members' walls.
  final bool allowFeaturing;

  /// True while the photo is on members' walls.
  final bool featured;

  /// How many members' walls the photo is on now.
  final int wallReach;

  /// Unique members who opened the photo (the author is never counted).
  final int viewCount;

  /// Author only, while featuring is allowed and a higher tier exists.
  final BlogNextTier? nextTier;

  /// The author's first name, for bylines; a neutral placeholder in the
  /// app's language when the server sent no name.
  String get firstName {
    final name = authorName.trim();
    if (name.isEmpty) {
      return currentAppL10n().commonMemberFallbackName;
    }
    return name.split(RegExp(r'\s+')).first;
  }
}

int _count(Object? value) => value is num && value > 0 ? value.toInt() : 0;

/// `GET /themes`: every active prompt plus whether the member may share.
class PhotoThemeList {
  const PhotoThemeList({
    required this.themes,
    required this.eligible,
    required this.eligibilityMessage,
  });
  factory PhotoThemeList.fromJson(Map<dynamic, dynamic> json) => PhotoThemeList(
    themes: [
      for (final theme in json['themes'] as List? ?? const <dynamic>[])
        PhotoTheme.fromJson(theme as Map),
    ],
    eligible: json['eligible'] as bool? ?? false,
    eligibilityMessage: json['eligibility_message'] as String? ?? '',
  );
  final List<PhotoTheme> themes;
  final bool eligible;
  final String eligibilityMessage;
}

/// One page of a theme's entries, newest first.
class ThemeEntryPage {
  const ThemeEntryPage({required this.entries, required this.next, this.theme});
  factory ThemeEntryPage.fromJson(Map<dynamic, dynamic> json) => ThemeEntryPage(
    theme: json['theme'] is Map
        ? PhotoTheme.fromJson(json['theme'] as Map)
        : null,
    entries: [
      for (final entry in json['entries'] as List? ?? const <dynamic>[])
        ThemeEntry.fromJson(entry as Map),
    ],
    next: json['next_cursor'] as String? ?? '',
  );
  final PhotoTheme? theme;
  final List<ThemeEntry> entries;
  final String next;
}

StateError _signedOut() => StateError('Sign in to see photo themes.');

final photoThemesProvider = FutureProvider.autoDispose<PhotoThemeList>((
  ref,
) async {
  final user = ref.watch(authNotifierProvider.select((s) => s.userId));
  if (user == null) {
    throw _signedOut();
  }
  final response = await ref.watch(apiClientProvider).get<dynamic>('/themes');
  return PhotoThemeList.fromJson(response.data as Map? ?? const {});
});

typedef ThemeEntriesQuery = ({String theme, String before});
final themeEntriesProvider = FutureProvider.autoDispose
    .family<ThemeEntryPage, ThemeEntriesQuery>((ref, query) async {
      final user = ref.watch(authNotifierProvider.select((s) => s.userId));
      if (user == null) {
        throw _signedOut();
      }
      final response = await ref
          .watch(apiClientProvider)
          .get<dynamic>(
            '/themes/${query.theme}/entries',
            queryParameters: {
              if (query.before.isNotEmpty) 'before': query.before,
            },
          );
      return ThemeEntryPage.fromJson(response.data as Map? ?? const {});
    });

typedef ThemePhotoKey = ({String user, String theme, String entry});
final themeEntryPhotoProvider = FutureProvider.autoDispose
    .family<Uint8List, ThemePhotoKey>((ref, key) async {
      final user = ref.watch(authNotifierProvider.select((s) => s.userId));
      if (user == null || user != key.user) {
        throw StateError('Sign in to view this photo.');
      }
      final response = await ref
          .watch(apiClientProvider)
          .get<List<int>>(
            '/themes/${key.theme}/entries/${key.entry}/photo',
            options: Options(responseType: ResponseType.bytes),
          );
      return Uint8List.fromList(response.data!);
    });

/// Refreshes the theme list, every loaded gallery page and the Today wall
/// after a write.
void invalidatePhotoThemes(WidgetRef ref) {
  ref
    ..invalidate(photoThemesProvider)
    ..invalidate(themeEntriesProvider)
    ..invalidate(photoWallProvider);
}

/// The multipart body for `PUT /themes/{theme}/entries/{entry}`.
/// `allow_featuring` is only sent when the member opted in.
FormData themeEntryForm({
  required List<int> bytes,
  required String filename,
  required String caption,
  required String altText,
  bool allowFeaturing = false,
}) => FormData.fromMap({
  'caption': caption,
  'alt_text': altText,
  if (allowFeaturing) 'allow_featuring': 'true',
  'image': MultipartFile.fromBytes(bytes, filename: filename),
});

/// Shares a photo for [themeId] under a client-generated [entryId], so a
/// retry of the same upload returns the saved entry.
Future<ThemeEntry?> uploadThemeEntry(
  Dio api, {
  required String themeId,
  required String entryId,
  required List<int> bytes,
  required String filename,
  required String caption,
  required String altText,
  bool allowFeaturing = false,
}) async {
  final response = await api.put<dynamic>(
    '/themes/$themeId/entries/$entryId',
    data: themeEntryForm(
      bytes: bytes,
      filename: filename,
      caption: caption,
      altText: altText,
      allowFeaturing: allowFeaturing,
    ),
  );
  final entry = response.data is Map ? (response.data as Map)['entry'] : null;
  return entry is Map ? ThemeEntry.fromJson(entry) : null;
}

String _entryPath(ThemeEntry entry) =>
    '/themes/${entry.themeId}/entries/${entry.id}';

/// Author only: lets the photo reach other members' walls, or takes it off
/// every wall at once. Returns the saved entry.
Future<ThemeEntry> setThemeEntryFeaturing(
  Dio api, {
  required ThemeEntry entry,
  required bool allow,
}) async {
  final response = await api.post<dynamic>(
    '${_entryPath(entry)}/featuring',
    data: {'allow': allow},
  );
  return ThemeEntry.fromJson((response.data as Map)['entry'] as Map);
}

/// Identifies one photo for its comment thread.
typedef ThemeEntryRef = ({String theme, String entry});

/// Comments the viewer may see on one photo, oldest first. Photo comments
/// carry `entry_id`, which [BlogComment.postId] holds.
final themeEntryCommentsProvider = FutureProvider.autoDispose
    .family<List<BlogComment>, ThemeEntryRef>((ref, key) async {
      final user = ref.watch(authNotifierProvider.select((s) => s.userId));
      if (user == null) {
        throw StateError('Sign in to read comments.');
      }
      final response = await ref
          .watch(apiClientProvider)
          .get<dynamic>('/themes/${key.theme}/entries/${key.entry}/comments');
      return [
        for (final c in (response.data as Map)['comments'] as List? ?? const [])
          BlogComment.fromJson(c as Map),
      ];
    });

/// Sends a comment with a client-generated [commentId]; it starts pending.
Future<BlogComment> createThemeEntryComment(
  Dio api, {
  required ThemeEntry entry,
  required String commentId,
  required String body,
}) async {
  final response = await api.put<dynamic>(
    '${_entryPath(entry)}/comments/$commentId',
    data: {'body': body},
  );
  return BlogComment.fromJson((response.data as Map)['comment'] as Map);
}

/// Photo author only: approve or decline a pending comment.
Future<BlogComment> decideThemeEntryComment(
  Dio api, {
  required ThemeEntry entry,
  required String commentId,
  required bool approve,
}) async {
  final response = await api.post<dynamic>(
    '${_entryPath(entry)}/comments/$commentId/decision',
    data: {'decision': approve ? 'approve' : 'decline'},
  );
  return BlogComment.fromJson((response.data as Map)['comment'] as Map);
}

/// The comment writer or the photo author can delete a comment.
Future<void> deleteThemeEntryComment(
  Dio api, {
  required ThemeEntry entry,
  required String commentId,
}) => api.delete<dynamic>('${_entryPath(entry)}/comments/$commentId');

/// Optimistic likes on Photo Theme photos, shared by the gallery sheet and
/// the Today wall. Rolls back if the server does not confirm.
class PhotoLikes extends OptimisticLikes<ThemeEntry> {
  @override
  String idOf(ThemeEntry item) => item.id;

  @override
  BlogLikeState serverStateOf(ThemeEntry item) => BlogLikeState(
    liked: item.likedByMe,
    count: item.likeCount,
    reaction: item.likedByMe ? item.myReaction : '',
    reactions: item.reactions,
  );

  @override
  Future<BlogLikeState> send(
    ThemeEntry item, {
    required bool like,
    String? reaction,
  }) async {
    final api = ref.read(apiClientProvider);
    final path = '${_entryPath(item)}/like';
    final response = like
        ? await api.put<dynamic>(
            path,
            data: reaction == null ? null : {'reaction': reaction},
          )
        : await api.delete<dynamic>(path);
    return serverStateOf(
      ThemeEntry.fromJson((response.data as Map)['entry'] as Map),
    );
  }
}

final photoLikesProvider =
    NotifierProvider<PhotoLikes, Map<String, BlogLikeState>>(PhotoLikes.new);

/// `GET /themes/wall`: photos delivered to my Today wall, newest first.
final photoWallProvider = FutureProvider.autoDispose<List<ThemeEntry>>((
  ref,
) async {
  final user = ref.watch(authNotifierProvider.select((s) => s.userId));
  if (user == null) {
    throw _signedOut();
  }
  final response = await ref
      .watch(apiClientProvider)
      .get<dynamic>('/themes/wall');
  final data = response.data;
  return [
    for (final entry
        in (data is Map ? data['entries'] : null) as List? ?? const <dynamic>[])
      ThemeEntry.fromJson(entry as Map),
  ];
});
