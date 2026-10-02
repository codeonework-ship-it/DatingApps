import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/rich_text/rich_document.dart';
import '../auth/providers/auth_provider.dart';
import '../walls/reactions.dart';

export '../walls/reactions.dart' show BlogLikeState;

const blogAudiences = {
  'private': 'Only me',
  'friends': 'Friends',
  'community': 'Connect community',
};
const blogInvitations = {
  '': 'No invitation',
  'your_version': 'What would your version look like?',
  'teach_me': 'What could you teach me about this?',
  'what_next': 'What would you try next?',
};

class BlogPhoto {
  factory BlogPhoto.fromJson(Map<dynamic, dynamic> json) =>
      BlogPhoto(json['id'] as String, json['alt_text'] as String);
  const BlogPhoto(this.id, this.alt);
  final String id, alt;
}

class BlogPost {
  factory BlogPost.fromJson(Map<dynamic, dynamic> json) => BlogPost(
    id: json['id'] as String,
    authorId: json['author_id'] as String,
    authorName: json['author_name'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    content: RichDocument.tryParse(json['content']),
    audience: json['audience'] as String,
    invitation: json['invitation'] as String,
    version: json['version'] as int,
    moderation: json['moderation_state'] as String? ?? 'active',
    photos: (json['photos'] as List)
        .map((p) => BlogPhoto.fromJson(p as Map))
        .toList(),
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
    topic: json['topic'] as String? ?? '',
    topicTitle: json['topic_title'] as String? ?? '',
    authorSubscribed: json['author_subscribed'] == true,
    authorSubscriberCount: _count(json['author_subscriber_count']),
  );
  const BlogPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.body,
    required this.audience,
    required this.invitation,
    required this.version,
    required this.photos,
    this.content,
    this.moderation = 'active',
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
    this.topic = '',
    this.topicTitle = '',
    this.authorSubscribed = false,
    this.authorSubscriberCount = 0,
  });
  final String id, authorId, authorName, title, body, audience, invitation;

  /// Formatting, or null for a plain-text chapter. [body] is always its
  /// plain text (cards, excerpts and search keep using it).
  final RichDocument? content;
  final String moderation;
  final int version;
  final List<BlogPhoto> photos;

  /// Likes from members. A member can never like their own chapter.
  final int likeCount;
  final bool likedByMe;

  /// How this member reacted ("I hear you", ...); empty when not liked.
  final String myReaction;

  /// Every reader's reactions, counted per reaction id.
  final Map<String, int> reactions;

  /// Approved comments, visible to every reader of the chapter.
  final int commentCount;

  /// Comments waiting for the author. Always 0 for anyone but the author.
  final int pendingCommentCount;

  /// The author opted in to Featured Stories (community chapters only).
  final bool allowFeaturing;

  /// True while the chapter is on members' walls and featuring is allowed.
  final bool featured;

  /// How many members' Featured Stories walls the chapter is on now.
  final int wallReach;

  /// Unique members who opened the chapter (the author is never counted).
  final int viewCount;

  /// Author only, while featuring is allowed and a higher tier exists.
  final BlogNextTier? nextTier;

  /// Topic slug, or empty when the author chose none.
  final String topic;

  /// Display title of [topic], from the server.
  final String topicTitle;

  /// Whether the viewer follows (subscribes to) this chapter's writer.
  final bool authorSubscribed;

  /// How many members follow this chapter's writer.
  final int authorSubscriberCount;
}

/// A chapter topic. Chapters have at most one, and it is optional.
class BlogTopic {
  factory BlogTopic.fromJson(Map<dynamic, dynamic> json) => BlogTopic(
    slug: json['slug'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    postCount: _count(json['post_count']),
  );
  const BlogTopic({
    required this.slug,
    required this.title,
    this.description = '',
    this.postCount = 0,
  });
  final String slug, title, description;
  final int postCount;
}

/// A writer the viewer follows, from `GET /blog/subscriptions`.
class BlogWriter {
  factory BlogWriter.fromJson(Map<dynamic, dynamic> json) => BlogWriter(
    authorId: json['author_id'] as String? ?? '',
    name: json['name'] as String? ?? 'A member',
    subscriberCount: _count(json['subscriber_count']),
    latestTitle: json['latest_title'] as String? ?? '',
    latestPostId: json['latest_post_id'] as String? ?? '',
  );
  const BlogWriter({
    required this.authorId,
    required this.name,
    this.subscriberCount = 0,
    this.latestTitle = '',
    this.latestPostId = '',
  });
  final String authorId, name, latestTitle, latestPostId;
  final int subscriberCount;
}

/// The next reach tier for a chapter and what it still needs to get there.
/// Tiers are configured on the server, so nothing here assumes 50 or 100.
class BlogNextTier {
  factory BlogNextTier.fromJson(Map<dynamic, dynamic> json) => BlogNextTier(
    likes: _count(json['likes']),
    comments: _count(json['comments']),
    reach: _count(json['reach']),
    likesNeeded: _count(json['likes_needed']),
    commentsNeeded: _count(json['comments_needed']),
  );
  const BlogNextTier({
    required this.likes,
    required this.comments,
    required this.reach,
    required this.likesNeeded,
    required this.commentsNeeded,
  });
  final int likes, comments, reach, likesNeeded, commentsNeeded;

  /// 0..1 progress, with likes and comments weighted by their targets.
  double get progress {
    final total = likes + comments;
    if (total == 0) return 1;
    final have =
        (likes - likesNeeded).clamp(0, likes) +
        (comments - commentsNeeded).clamp(0, comments);
    return (have / total).clamp(0.0, 1.0);
  }
}

int _count(Object? value) => value is num && value > 0 ? value.toInt() : 0;

/// A reader's comment on a chapter or a Photo Theme photo. Comments start
/// `pending` and are visible only to their writer and the author until the
/// author approves them. Photo comments carry `entry_id` instead of
/// `post_id`; either one lands in [postId], the ID of what was commented on.
class BlogComment {
  factory BlogComment.fromJson(Map<dynamic, dynamic> json) => BlogComment(
    id: json['id'] as String,
    postId: json['post_id'] as String? ?? json['entry_id'] as String? ?? '',
    authorId: json['author_id'] as String? ?? '',
    authorName: json['author_name'] as String? ?? 'A member',
    body: json['body'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
    mine: json['mine'] == true,
    canModerate: json['can_moderate'] == true,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );
  const BlogComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.status,
    this.mine = false,
    this.canModerate = false,
    this.createdAt,
  });
  final String id, postId, authorId, authorName, body, status;
  final bool mine, canModerate;
  final DateTime? createdAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isDeclined => status == 'declined';
}

/// How a comment list is shown to one viewer.
typedef BlogCommentGroups = ({
  /// Approved comments: everyone who can read the chapter sees these.
  List<BlogComment> approved,

  /// Pending comments the viewer, as chapter author, can approve or decline.
  List<BlogComment> awaitingMyApproval,

  /// The viewer's own comments still waiting for the author.
  List<BlogComment> mineSent,

  /// The viewer's own comments the author chose not to show.
  List<BlogComment> mineDeclined,
});

/// Groups comments for a viewer. Pending comments from other members are only
/// ever surfaced to the chapter author, even if the server returned them.
BlogCommentGroups groupBlogComments(
  List<BlogComment> comments, {
  required bool viewerIsAuthor,
}) => (
  approved: [
    for (final c in comments)
      if (c.isApproved) c,
  ],
  awaitingMyApproval: [
    if (viewerIsAuthor)
      for (final c in comments)
        if (c.isPending && !c.mine) c,
  ],
  mineSent: [
    for (final c in comments)
      if (c.isPending && c.mine) c,
  ],
  mineDeclined: [
    for (final c in comments)
      if (c.isDeclined && c.mine) c,
  ],
);

class BlogPage {
  const BlogPage(this.posts, this.next);
  final List<BlogPost> posts;
  final String next;
}

/// Feed scopes: `community` (For you), `top` (Top rated), `subscriptions`
/// (Following), `friends` and `mine`. [topic] filters any scope when set.
typedef BlogQuery = ({
  String scope,
  String author,
  String before,
  String topic,
});
final blogFeedProvider = FutureProvider.autoDispose.family<BlogPage, BlogQuery>(
  (ref, query) async {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    if (user == null) throw StateError('Sign in to read chapters.');
    final response = await ref
        .watch(apiClientProvider)
        .get<dynamic>(
          '/blog/posts',
          queryParameters: {
            'scope': query.scope,
            if (query.author.isNotEmpty) 'author_id': query.author,
            if (query.before.isNotEmpty) 'before': query.before,
            if (query.topic.isNotEmpty) 'topic': query.topic,
          },
        );
    final data = response.data as Map;
    return BlogPage(
      (data['posts'] as List).map((p) => BlogPost.fromJson(p as Map)).toList(),
      data['next_cursor'] as String? ?? '',
    );
  },
);
final blogPostProvider = FutureProvider.autoDispose.family<BlogPost, String>((
  ref,
  id,
) async {
  final user = ref.watch(authNotifierProvider.select((s) => s.userId));
  if (user == null) throw StateError('Sign in to read chapters.');
  final response = await ref
      .watch(apiClientProvider)
      .get<dynamic>('/blog/posts/$id');
  return BlogPost.fromJson((response.data as Map)['post'] as Map);
});
typedef BlogPhotoKey = ({String user, String post, String photo, int version});
final blogPhotoProvider = FutureProvider.autoDispose
    .family<Uint8List, BlogPhotoKey>((ref, key) async {
      final user = ref.watch(authNotifierProvider.select((s) => s.userId));
      if (user == null || user != key.user) {
        throw StateError('Sign in to view this photo.');
      }
      final response = await ref
          .watch(apiClientProvider)
          .get<List<int>>(
            '/blog/posts/${key.post}/photos/${key.photo}',
            options: Options(responseType: ResponseType.bytes),
          );
      return Uint8List.fromList(response.data!);
    });
void invalidateBlog(WidgetRef ref, String id) {
  ref.invalidate(blogFeedProvider);
  ref.invalidate(blogPostProvider(id));
  ref.invalidate(blogPhotoProvider);
  ref.invalidate(blogFeaturedProvider);
  ref.invalidate(blogCommentsProvider(id));
}

/// Featured Stories: community chapters readers loved, newest wall first.
final blogFeaturedProvider = FutureProvider.autoDispose<List<BlogPost>>((
  ref,
) async {
  final user = ref.watch(authNotifierProvider.select((s) => s.userId));
  if (user == null) throw StateError('Sign in to read chapters.');
  final response = await ref
      .watch(apiClientProvider)
      .get<dynamic>('/blog/featured');
  return ((response.data as Map)['posts'] as List)
      .map((p) => BlogPost.fromJson(p as Map))
      .toList();
});

/// Comments the viewer may see on one chapter, oldest first.
final blogCommentsProvider = FutureProvider.autoDispose
    .family<List<BlogComment>, String>((ref, postId) async {
      final user = ref.watch(authNotifierProvider.select((s) => s.userId));
      if (user == null) throw StateError('Sign in to read comments.');
      final response = await ref
          .watch(apiClientProvider)
          .get<dynamic>('/blog/posts/$postId/comments');
      return ((response.data as Map)['comments'] as List)
          .map((c) => BlogComment.fromJson(c as Map))
          .toList();
    });

const blogCommentMaxLength = 500;

/// Sends a comment with a client-generated [commentId] so a retry of the same
/// text cannot create a duplicate. The comment starts pending.
Future<BlogComment> createBlogComment(
  Dio api, {
  required String postId,
  required String commentId,
  required String body,
}) async {
  final response = await api.put<dynamic>(
    '/blog/posts/$postId/comments/$commentId',
    data: {'body': body},
  );
  return BlogComment.fromJson((response.data as Map)['comment'] as Map);
}

/// Chapter author only: approve or decline a pending comment.
Future<BlogComment> decideBlogComment(
  Dio api, {
  required String postId,
  required String commentId,
  required bool approve,
}) async {
  final response = await api.post<dynamic>(
    '/blog/posts/$postId/comments/$commentId/decision',
    data: {'decision': approve ? 'approve' : 'decline'},
  );
  return BlogComment.fromJson((response.data as Map)['comment'] as Map);
}

/// The comment writer or the chapter author can delete a comment.
Future<void> deleteBlogComment(
  Dio api, {
  required String postId,
  required String commentId,
}) => api.delete<dynamic>('/blog/posts/$postId/comments/$commentId');

/// Optimistic like state for anything members can like (chapters, Photo
/// Theme photos), shared by every place the item appears so a like on one
/// surface shows on the others. Entries only exist for items this member
/// toggled; everything else comes from the server payload. Signing in as
/// someone else starts over.
abstract class OptimisticLikes<T> extends Notifier<Map<String, BlogLikeState>> {
  final _inFlight = <String>{};

  @override
  Map<String, BlogLikeState> build() {
    ref.watch(authNotifierProvider.select((s) => s.userId));
    _inFlight.clear();
    return const {};
  }

  /// The key the like state is stored under.
  String idOf(T item);

  /// The like state the server sent with [item].
  BlogLikeState serverStateOf(T item);

  /// Likes or unlikes [item] on the server and returns the confirmed state.
  /// [reaction] is sent with a like when the member picked one.
  Future<BlogLikeState> send(T item, {required bool like, String? reaction});

  BlogLikeState of(T item) => state[idOf(item)] ?? serverStateOf(item);

  bool busy(String id) => _inFlight.contains(id);

  /// Flips the like immediately, then confirms with the server. On failure the
  /// previous state is restored and the error is rethrown for the caller to
  /// explain. Taps while a request is in flight are ignored.
  Future<void> toggle(T item) => _change(item, like: !of(item).liked);

  /// Likes [item] with an empathetic [reaction], or switches to it when
  /// already liked. Still one like; optimistic with rollback like [toggle].
  Future<void> react(T item, String reaction) =>
      _change(item, like: true, reaction: reaction);

  Future<void> _change(T item, {required bool like, String? reaction}) async {
    final id = idOf(item);
    if (!_inFlight.add(id)) return;
    final previous = state[id];
    final current = of(item);
    final optimistic = current.next(like: like, reaction: reaction);
    if (optimistic == current) {
      _inFlight.remove(id);
      return;
    }
    state = {...state, id: optimistic};
    try {
      final confirmed = await send(item, like: like, reaction: reaction);
      state = {...state, id: confirmed};
    } on Object {
      final restored = {...state};
      if (previous == null) {
        restored.remove(id);
      } else {
        restored[id] = previous;
      }
      state = restored;
      rethrow;
    } finally {
      _inFlight.remove(id);
    }
  }
}

/// Likes on chapters (feed, detail, Featured Stories).
class BlogLikes extends OptimisticLikes<BlogPost> {
  @override
  String idOf(BlogPost item) => item.id;

  @override
  BlogLikeState serverStateOf(BlogPost item) => BlogLikeState(
    liked: item.likedByMe,
    count: item.likeCount,
    reaction: item.likedByMe ? item.myReaction : '',
    reactions: item.reactions,
  );

  @override
  Future<BlogLikeState> send(
    BlogPost item, {
    required bool like,
    String? reaction,
  }) async {
    final api = ref.read(apiClientProvider);
    final path = '/blog/posts/${item.id}/like';
    final response = like
        ? await api.put<dynamic>(
            path,
            data: reaction == null ? null : {'reaction': reaction},
          )
        : await api.delete<dynamic>(path);
    final updated = BlogPost.fromJson((response.data as Map)['post'] as Map);
    return serverStateOf(updated);
  }
}

final blogLikesProvider =
    NotifierProvider<BlogLikes, Map<String, BlogLikeState>>(BlogLikes.new);

/// The topics members can file chapters under.
final blogTopicsProvider = FutureProvider.autoDispose<List<BlogTopic>>((
  ref,
) async {
  final user = ref.watch(authNotifierProvider.select((s) => s.userId));
  if (user == null) throw StateError('Sign in to read chapters.');
  final response = await ref
      .watch(apiClientProvider)
      .get<dynamic>('/blog/topics');
  final topics = (response.data as Map?)?['topics'];
  return [
    if (topics is List)
      for (final t in topics)
        if (t is Map) BlogTopic.fromJson(t),
  ].where((t) => t.slug.isNotEmpty && t.title.isNotEmpty).toList();
});

/// Writers the viewer follows.
final blogSubscriptionsProvider = FutureProvider.autoDispose<List<BlogWriter>>((
  ref,
) async {
  final user = ref.watch(authNotifierProvider.select((s) => s.userId));
  if (user == null) throw StateError('Sign in to see writers you follow.');
  final response = await ref
      .watch(apiClientProvider)
      .get<dynamic>('/blog/subscriptions');
  final writers = (response.data as Map?)?['writers'];
  return [
    if (writers is List)
      for (final w in writers)
        if (w is Map) BlogWriter.fromJson(w),
  ];
});

typedef BlogFollowState = ({bool subscribed, int count});

/// Follows (subscribes to) a writer. Returns the confirmed state.
Future<BlogFollowState> subscribeToWriter(Dio api, String authorId) async {
  final response = await api.put<dynamic>(
    '/blog/authors/$authorId/subscription',
  );
  return _followState(response.data, subscribed: true);
}

/// Stops following a writer. Returns the confirmed state.
Future<BlogFollowState> unsubscribeFromWriter(Dio api, String authorId) async {
  final response = await api.delete<dynamic>(
    '/blog/authors/$authorId/subscription',
  );
  return _followState(response.data, subscribed: false);
}

BlogFollowState _followState(Object? data, {required bool subscribed}) {
  final map = data is Map ? data : const <String, dynamic>{};
  return (
    subscribed: map['subscribed'] is bool
        ? map['subscribed'] as bool
        : subscribed,
    count: _count(map['subscriber_count']),
  );
}

/// Optimistic follow state per writer, shared by every place a writer
/// appears so following on a chapter shows in the list and vice versa.
/// Entries only exist for writers this member toggled; everything else comes
/// from the server payload. Signing in as someone else starts over.
class BlogFollows extends Notifier<Map<String, BlogFollowState>> {
  final _inFlight = <String>{};

  @override
  Map<String, BlogFollowState> build() {
    ref.watch(authNotifierProvider.select((s) => s.userId));
    _inFlight.clear();
    return const {};
  }

  /// The state to show for [authorId], given what the server last sent.
  BlogFollowState of(String authorId, BlogFollowState server) =>
      state[authorId] ?? server;

  bool busy(String authorId) => _inFlight.contains(authorId);

  /// Flips the follow immediately, then confirms with the server. On failure
  /// the previous state is restored and the error is rethrown for the caller
  /// to explain. Taps while a request is in flight are ignored.
  Future<void> toggle(String authorId, BlogFollowState server) async {
    if (!_inFlight.add(authorId)) return;
    final previous = state[authorId];
    final current = of(authorId, server);
    final follow = !current.subscribed;
    state = {
      ...state,
      authorId: (
        subscribed: follow,
        count: follow
            ? current.count + 1
            : current.count > 0
            ? current.count - 1
            : 0,
      ),
    };
    try {
      final api = ref.read(apiClientProvider);
      final confirmed = follow
          ? await subscribeToWriter(api, authorId)
          : await unsubscribeFromWriter(api, authorId);
      state = {...state, authorId: confirmed};
      ref.invalidate(blogSubscriptionsProvider);
    } on Object {
      final restored = {...state};
      if (previous == null) {
        restored.remove(authorId);
      } else {
        restored[authorId] = previous;
      }
      state = restored;
      rethrow;
    } finally {
      _inFlight.remove(authorId);
    }
  }
}

final blogFollowsProvider =
    NotifierProvider<BlogFollows, Map<String, BlogFollowState>>(
      BlogFollows.new,
    );

/// One row of the creator rewards table. Values mirror the server's
/// progression sources exactly; the server is the one that awards them.
typedef BlogReward = ({
  String source,
  String title,
  String who,
  int xp,
  int dailyCap,
});

const blogRewards = <BlogReward>[
  (
    source: 'story_published',
    title: 'Sharing a chapter',
    who: 'You, the first time a chapter is shared beyond Only me',
    xp: 25,
    dailyCap: 50,
  ),
  (
    source: 'photo_shared',
    title: 'Sharing a Photo Themes photo',
    who: 'You, for a photo you share in Photo Themes',
    xp: 20,
    dailyCap: 40,
  ),
  (
    source: 'like_received',
    title: 'A like on your chapter or photo',
    who: 'You, for each member who likes it',
    xp: 2,
    dailyCap: 40,
  ),
  (
    source: 'comment_received',
    title: 'A comment you approve',
    who: 'You, when you approve a reader’s comment',
    xp: 5,
    dailyCap: 50,
  ),
  (
    source: 'comment_approved',
    title: 'Your comment is approved',
    who: 'You, when an author approves your comment',
    xp: 5,
    dailyCap: 30,
  ),
  (
    source: 'subscriber_gained',
    title: 'A new follower',
    who: 'You, for each new member who follows your chapters',
    xp: 10,
    dailyCap: 100,
  ),
  (
    source: 'wall_tier_reached',
    title: 'Reaching more walls',
    who: 'You, each time a chapter reaches a new wall tier',
    xp: 50,
    dailyCap: 150,
  ),
  (
    source: 'cover_of_week',
    title: 'Cover of the Week',
    who: 'You, when your work is chosen as Cover of the Week',
    xp: 150,
    dailyCap: 150,
  ),
];
