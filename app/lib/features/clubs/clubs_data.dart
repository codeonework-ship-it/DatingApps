import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/api_client_provider.dart';
import '../auth/providers/auth_provider.dart';

/// Club and list kinds as the API names them. Labels come from
/// `clubKindLabel` in club_widgets.dart.
const clubKinds = ['book', 'film'];

/// Who can see a list or review, as the API names it. Labels come from
/// `clubAudienceLabel` in club_widgets.dart.
const clubAudiences = ['private', 'friends', 'community'];

String _str(Object? value) => value is String ? value : '';
int _int(Object? value) => value is num ? value.toInt() : 0;
bool _bool(Object? value) => value is bool && value;
List<dynamic> _list(Object? value) => value is List ? value : const [];

/// A book or film in the shared catalogue.
class Title {
  const Title({
    required this.id,
    required this.kind,
    required this.title,
    required this.creator,
    required this.reviewCount,
    this.releaseYear,
    this.averageRating,
  });
  factory Title.fromJson(Map<dynamic, dynamic> json) => Title(
    id: _str(json['id']),
    kind: _str(json['kind']),
    title: _str(json['title']),
    creator: _str(json['creator']),
    releaseYear: (json['release_year'] as num?)?.toInt(),
    averageRating: (json['average_rating'] as num?)?.toDouble(),
    reviewCount: _int(json['review_count']),
  );
  final String id, kind, title, creator;
  final int? releaseYear;
  final double? averageRating;
  final int reviewCount;

  /// "Creator · 2019", leaving out whichever part is unknown.
  String get byline => [
    if (creator.isNotEmpty) creator,
    if (releaseYear != null) '$releaseYear',
  ].join(' · ');
}

/// A club's pick for the week starting [weekStart] (a Monday).
class Selection {
  const Selection({
    required this.id,
    required this.weekStart,
    required this.note,
    required this.title,
    required this.postCount,
  });
  factory Selection.fromJson(Map<dynamic, dynamic> json) => Selection(
    id: _str(json['id']),
    weekStart: _str(json['week_start']),
    note: _str(json['note']),
    title: Title.fromJson(json['title'] as Map? ?? const {}),
    postCount: _int(json['post_count']),
  );
  final String id, weekStart, note;
  final Title title;
  final int postCount;
}

class Club {
  const Club({
    required this.id,
    required this.kind,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.memberCount,
    required this.myRole,
    required this.version,
    this.moderationState = 'active',
    this.currentSelection,
  });
  factory Club.fromJson(Map<dynamic, dynamic> json) => Club(
    id: _str(json['id']),
    kind: _str(json['kind']),
    name: _str(json['name']),
    description: _str(json['description']),
    ownerId: _str(json['owner_id']),
    memberCount: _int(json['member_count']),
    myRole: _str(json['my_role']),
    version: _int(json['version']),
    moderationState: json['moderation_state'] as String? ?? 'active',
    currentSelection: json['current_selection'] is Map
        ? Selection.fromJson(json['current_selection'] as Map)
        : null,
  );
  final String id, kind, name, description, ownerId, myRole, moderationState;
  final int memberCount, version;
  final Selection? currentSelection;

  bool get isMember => myRole.isNotEmpty;
  bool get isOwner => myRole == 'owner';

  /// Owners and moderators set picks, hide posts and remove members.
  bool get canModerate => myRole == 'owner' || myRole == 'moderator';
}

class ClubMember {
  const ClubMember({
    required this.userId,
    required this.name,
    required this.role,
    this.joinedAt,
  });
  factory ClubMember.fromJson(Map<dynamic, dynamic> json) => ClubMember(
    userId: _str(json['user_id']),
    name: _str(json['name']),
    role: _str(json['role']),
    joinedAt: DateTime.tryParse(_str(json['joined_at'])),
  );
  final String userId, name, role;
  final DateTime? joinedAt;
}

class ClubPost {
  const ClubPost({
    required this.id,
    required this.clubId,
    required this.selectionId,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.hasSpoilers,
    required this.mine,
    required this.hidden,
    this.createdAt,
  });
  factory ClubPost.fromJson(Map<dynamic, dynamic> json) => ClubPost(
    id: _str(json['id']),
    clubId: _str(json['club_id']),
    selectionId: _str(json['selection_id']),
    authorId: _str(json['author_id']),
    authorName: _str(json['author_name']),
    body: _str(json['body']),
    hasSpoilers: _bool(json['has_spoilers']),
    createdAt: DateTime.tryParse(_str(json['created_at'])),
    mine: _bool(json['mine']),
    hidden: _bool(json['hidden']),
  );
  final String id, clubId, selectionId, authorId, authorName, body;
  final bool hasSpoilers, mine, hidden;
  final DateTime? createdAt;
}

class TitleReview {
  const TitleReview({
    required this.id,
    required this.titleId,
    required this.authorId,
    required this.authorName,
    required this.rating,
    required this.body,
    required this.hasSpoilers,
    required this.audience,
    required this.version,
    required this.mine,
    this.createdAt,
    this.updatedAt,
  });
  factory TitleReview.fromJson(Map<dynamic, dynamic> json) => TitleReview(
    id: _str(json['id']),
    titleId: _str(json['title_id']),
    authorId: _str(json['author_id']),
    authorName: _str(json['author_name']),
    rating: _int(json['rating']),
    body: _str(json['body']),
    hasSpoilers: _bool(json['has_spoilers']),
    audience: json['audience'] as String? ?? 'private',
    version: _int(json['version']),
    createdAt: DateTime.tryParse(_str(json['created_at'])),
    updatedAt: DateTime.tryParse(_str(json['updated_at'])),
    mine: _bool(json['mine']),
  );
  final String id, titleId, authorId, authorName, body, audience;
  final int rating, version;
  final bool hasSpoilers, mine;
  final DateTime? createdAt, updatedAt;
}

class ListItem {
  const ListItem({
    required this.title,
    required this.note,
    required this.position,
  });
  factory ListItem.fromJson(Map<dynamic, dynamic> json) => ListItem(
    title: Title.fromJson(json['title'] as Map? ?? const {}),
    note: _str(json['note']),
    position: _int(json['position']),
  );
  final Title title;
  final String note;
  final int position;
}

class MemberList {
  const MemberList({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.name,
    required this.kind,
    required this.audience,
    required this.version,
    required this.mine,
    required this.items,
  });
  factory MemberList.fromJson(Map<dynamic, dynamic> json) => MemberList(
    id: _str(json['id']),
    ownerId: _str(json['owner_id']),
    ownerName: _str(json['owner_name']),
    name: _str(json['name']),
    kind: _str(json['kind']),
    audience: json['audience'] as String? ?? 'private',
    version: _int(json['version']),
    mine: _bool(json['mine']),
    items: [
      for (final item in _list(json['items'])) ListItem.fromJson(item as Map),
    ]..sort((a, b) => a.position.compareTo(b.position)),
  );
  final String id, ownerId, ownerName, name, kind, audience;
  final int version;
  final bool mine;
  final List<ListItem> items;

  /// The note on [titleId] when it is already on this list, else ''.
  ///
  /// Adding a title sends this back: the server's PUT replaces the note.
  String noteFor(String titleId) =>
      items.where((i) => i.title.id == titleId).firstOrNull?.note ?? '';
}

class ClubsPage {
  const ClubsPage({required this.clubs, required this.eligible});
  factory ClubsPage.fromJson(Map<dynamic, dynamic> json) => ClubsPage(
    clubs: [for (final c in _list(json['clubs'])) Club.fromJson(c as Map)],
    eligible: _bool(json['eligible']),
  );
  final List<Club> clubs;
  final bool eligible;
}

class ClubDetail {
  const ClubDetail({required this.club, required this.selections});
  factory ClubDetail.fromJson(Map<dynamic, dynamic> json) => ClubDetail(
    club: Club.fromJson(_map(json['club'], 'club')),
    selections: [
      for (final s in _list(json['selections'])) Selection.fromJson(s as Map),
    ],
  );
  final Club club;

  /// The latest picks, newest first.
  final List<Selection> selections;
}

class ClubPostPage {
  const ClubPostPage({required this.posts, required this.next});
  factory ClubPostPage.fromJson(Map<dynamic, dynamic> json) => ClubPostPage(
    posts: [for (final p in _list(json['posts'])) ClubPost.fromJson(p as Map)],
    next: _str(json['next_cursor']),
  );
  final List<ClubPost> posts;
  final String next;
}

class TitleDetail {
  const TitleDetail({
    required this.title,
    required this.reviews,
    this.myReview,
  });
  factory TitleDetail.fromJson(Map<dynamic, dynamic> json) => TitleDetail(
    title: Title.fromJson(_map(json['title'], 'title')),
    myReview: json['my_review'] is Map
        ? TitleReview.fromJson(json['my_review'] as Map)
        : null,
    reviews: [
      for (final r in _list(json['reviews'])) TitleReview.fromJson(r as Map),
    ],
  );
  final Title title;
  final TitleReview? myReview;
  final List<TitleReview> reviews;
}

Map<dynamic, dynamic> _map(Object? value, String field) {
  if (value is Map) {
    return value;
  }
  throw FormatException('The response is missing "$field".');
}

/// The ISO date (YYYY-MM-DD) of the Monday that starts [day]'s week.
String mondayOf(DateTime day) {
  final monday = DateTime(day.year, day.month, day.day - (day.weekday - 1));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${monday.year.toString().padLeft(4, '0')}-'
      '${two(monday.month)}-${two(monday.day)}';
}

String _requireUser(Ref<Object?> ref) {
  final user = ref.watch(authNotifierProvider.select((s) => s.userId));
  if (user == null) {
    throw StateError('Sign in to see clubs.');
  }
  return user;
}

typedef ClubsQuery = ({String scope, String kind});
final clubsProvider = FutureProvider.autoDispose.family<ClubsPage, ClubsQuery>((
  ref,
  query,
) async {
  _requireUser(ref);
  final response = await ref
      .watch(apiClientProvider)
      .get<dynamic>(
        '/clubs',
        queryParameters: {
          'scope': query.scope,
          if (query.kind.isNotEmpty) 'kind': query.kind,
        },
      );
  return ClubsPage.fromJson(response.data as Map? ?? const {});
});

final clubDetailProvider = FutureProvider.autoDispose
    .family<ClubDetail, String>((ref, id) async {
      _requireUser(ref);
      final response = await ref
          .watch(apiClientProvider)
          .get<dynamic>('/clubs/$id');
      return ClubDetail.fromJson(response.data as Map? ?? const {});
    });

final clubMembersProvider = FutureProvider.autoDispose
    .family<List<ClubMember>, String>((ref, id) async {
      _requireUser(ref);
      final response = await ref
          .watch(apiClientProvider)
          .get<dynamic>('/clubs/$id/members');
      return membersFromJson(response.data);
    });

/// Parses `{"members": [Member]}`, the shape of both member endpoints.
List<ClubMember> membersFromJson(Object? data) => [
  for (final m in _list(data is Map ? data['members'] : null))
    ClubMember.fromJson(m as Map),
];

typedef ClubPostsQuery = ({String club, String selection, String before});
final clubPostsProvider = FutureProvider.autoDispose
    .family<ClubPostPage, ClubPostsQuery>((ref, query) async {
      _requireUser(ref);
      final response = await ref
          .watch(apiClientProvider)
          .get<dynamic>(
            '/clubs/${query.club}/posts',
            queryParameters: {
              'selection_id': query.selection,
              if (query.before.isNotEmpty) 'before': query.before,
            },
          );
      return ClubPostPage.fromJson(response.data as Map? ?? const {});
    });

typedef TitleSearchQuery = ({String kind, String q});
final titleSearchProvider = FutureProvider.autoDispose
    .family<List<Title>, TitleSearchQuery>((ref, query) async {
      _requireUser(ref);
      final q = query.q.trim();
      if (q.length < 2) {
        return const [];
      }
      final response = await ref
          .watch(apiClientProvider)
          .get<dynamic>(
            '/clubs/titles',
            queryParameters: {
              if (query.kind.isNotEmpty) 'kind': query.kind,
              'q': q,
            },
          );
      final data = response.data;
      return [
        for (final t in _list(data is Map ? data['titles'] : null))
          Title.fromJson(t as Map),
      ];
    });

final titleDetailProvider = FutureProvider.autoDispose
    .family<TitleDetail, String>((ref, id) async {
      _requireUser(ref);
      final response = await ref
          .watch(apiClientProvider)
          .get<dynamic>('/clubs/titles/$id');
      return TitleDetail.fromJson(response.data as Map? ?? const {});
    });

final myListsProvider = FutureProvider.autoDispose<List<MemberList>>((
  ref,
) async {
  _requireUser(ref);
  final response = await ref
      .watch(apiClientProvider)
      .get<dynamic>('/clubs/lists');
  final data = response.data;
  return [
    for (final l in _list(data is Map ? data['lists'] : null))
      MemberList.fromJson(l as Map),
  ];
});

/// Refreshes everything about one club (list cards, detail, members, posts).
void invalidateClub(WidgetRef ref, String clubId) {
  ref
    ..invalidate(clubsProvider)
    ..invalidate(clubDetailProvider(clubId))
    ..invalidate(clubMembersProvider(clubId))
    ..invalidate(clubPostsProvider);
}

/// Refreshes a title's reviews and anything that shows its rating.
void invalidateTitle(WidgetRef ref, String titleId) {
  ref
    ..invalidate(titleDetailProvider(titleId))
    ..invalidate(myListsProvider)
    ..invalidate(clubDetailProvider);
}
