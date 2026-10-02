import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/providers/safety_actions_provider.dart';
import '../../core/rich_text/rich_document_view.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';
import '../common/widgets/report_user_sheet.dart';
import '../walls/today_wall_data.dart';
import 'blog_data.dart';
import 'blog_editor.dart';
import 'blog_connections.dart';
import 'blog_follow.dart';
import 'blog_sharing.dart';
import 'blog_social.dart';
import 'blog_writers_screen.dart';

Future<void> openBlog(BuildContext context, {String? authorId}) => Navigator.of(
  context,
).push<void>(MaterialPageRoute(builder: (_) => BlogScreen(authorId: authorId)));

/// Opens one chapter. Used by the feed, Featured Stories and Today. Counts a
/// unique view for the wall ranking (fire-and-forget).
Future<void> openBlogPost(BuildContext context, String id) {
  recordWallViewFrom(context, kind: WallKind.chapter, id: id);
  return Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => BlogDetailScreen(id: id)));
}

class BlogScreen extends ConsumerStatefulWidget {
  const BlogScreen({super.key, this.authorId});
  final String? authorId;
  @override
  ConsumerState<BlogScreen> createState() => _BlogScreenState();
}

/// Feed scopes in tab order. `top` and `subscriptions` are not offered while
/// reading one writer's chapters.
const blogScopes = ['community', 'top', 'subscriptions', 'friends', 'mine'];

/// The tab label of a feed scope.
String blogScopeLabel(AppLocalizations l10n, String scope) => switch (scope) {
  'community' => l10n.blogScopeForYou,
  'top' => l10n.blogScopeTopRated,
  'subscriptions' => l10n.blogScopeFollowing,
  'friends' => l10n.blogAudienceFriends,
  'mine' => l10n.blogScopeMine,
  _ => scope,
};

class _BlogScreenState extends ConsumerState<BlogScreen> {
  String scope = 'community';
  String topic = '';
  final cursors = <String>[''];

  void select({String? scope, String? topic}) => setState(() {
    if (scope != null) this.scope = scope;
    if (topic != null) this.topic = topic;
    cursors
      ..clear()
      ..add('');
  });

  String scopeCaption(AppLocalizations l10n) => switch (scope) {
    'mine' => l10n.blogScopeCaptionMine,
    'friends' => l10n.blogScopeCaptionFriends,
    'top' => l10n.blogScopeCaptionTop,
    'subscriptions' => l10n.blogScopeCaptionFollowing,
    _ => l10n.blogScopeCaptionCommunity,
  };

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    final query = (
      scope: scope,
      author: widget.authorId ?? '',
      before: cursors.last,
      topic: topic,
    );
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final scopes = [
      for (final s in blogScopes)
        if (widget.authorId == null || s == 'community' || s == 'friends') s,
    ];
    final topics = user == null
        ? const <BlogTopic>[]
        : ref
              .watch(blogTopicsProvider)
              .maybeWhen(data: (t) => t, orElse: () => const <BlogTopic>[]);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.blogTitle),
        actions: [
          IconButton(
            key: const ValueKey('blog.rewards'),
            tooltip: l10n.blogRewardsTitle,
            onPressed: () => showBlogRewardsSheet(context),
            icon: const Icon(Icons.info_outline_rounded),
          ),
          IconButton(
            key: const ValueKey('blog.writers'),
            tooltip: l10n.blogWritersTitle,
            onPressed: () => openBlogWriters(context),
            icon: const Icon(Icons.favorite_border_rounded),
          ),
          IconButton(
            tooltip: l10n.blogConnectionsTooltip,
            onPressed: () => openBlogConnections(context),
            icon: const Icon(Icons.mark_email_unread_outlined),
          ),
        ],
      ),
      body: user == null
          ? Center(child: Text(l10n.blogSignInReadWrite))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(blogFeedProvider(query));
                    await ref.read(blogFeedProvider(query).future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 112),
                    children: [
                      Text(
                        l10n.blogHeroTitle,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontFamily: AppTheme.displayFamily,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(l10n.blogHeroBody),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          key: const ValueKey('blog.new'),
                          icon: const Icon(Icons.edit_note_rounded),
                          label: Text(l10n.blogWriteChapter),
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => BlogEditor(key: ValueKey(user)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: () => openBlogConnections(context),
                            icon: const Icon(Icons.forum_outlined),
                            label: Text(l10n.blogPrivateResponses),
                          ),
                          TextButton.icon(
                            onPressed: () => openBlogConnections(
                              context,
                              section: 'publications',
                            ),
                            icon: const Icon(Icons.ios_share_outlined),
                            label: Text(l10n.blogSharedLinks),
                          ),
                          TextButton.icon(
                            onPressed: () => openBlogConnections(
                              context,
                              section: 'notices',
                            ),
                            icon: const Icon(Icons.shield_outlined),
                            label: Text(l10n.blogReviewNotices),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        key: const ValueKey('blog.scopes'),
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in scopes)
                            ChoiceChip(
                              key: ValueKey('blog.scope.$s'),
                              label: Text(blogScopeLabel(l10n, s)),
                              selected: scope == s,
                              onSelected: (_) => select(scope: s),
                            ),
                        ],
                      ),
                      if (topics.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          key: const ValueKey('blog.topics'),
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final t in [
                                BlogTopic(slug: '', title: l10n.blogTopicAll),
                                ...topics,
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    key: ValueKey(
                                      'blog.topic.${t.slug.isEmpty ? 'all' : t.slug}',
                                    ),
                                    label: Text(t.title),
                                    selected: topic == t.slug,
                                    onSelected: (_) => select(topic: t.slug),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        scopeCaption(l10n),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      if (scope == 'community' &&
                          topic.isEmpty &&
                          widget.authorId == null)
                        const BlogFeaturedRail(
                          padding: EdgeInsets.only(bottom: 24),
                        ),
                      ref
                          .watch(blogFeedProvider(query))
                          .when(
                            skipLoadingOnRefresh: false,
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (e, _) => BlogError(
                              message: apiErrorMessage(
                                e,
                                fallback: l10n.blogFeedLoadFailed,
                              ),
                              retry: () =>
                                  ref.invalidate(blogFeedProvider(query)),
                            ),
                            data: (page) => Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (page.posts.isEmpty)
                                  _BlogEmptyState(
                                    scope: scope,
                                    filtered: topic.isNotEmpty,
                                    onSeeTopRated: () => select(scope: 'top'),
                                  ),
                                for (var i = 0; i < page.posts.length; i++)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: BlogPostCard(
                                      post: page.posts[i],
                                      user: user,
                                      rank: scope == 'top' ? i + 1 : null,
                                    ),
                                  ),
                                Wrap(
                                  spacing: 12,
                                  children: [
                                    if (cursors.length > 1)
                                      OutlinedButton(
                                        onPressed: () => setState(
                                          () => cursors.removeLast(),
                                        ),
                                        child: Text(l10n.blogPreviousPage),
                                      ),
                                    if (page.next.isNotEmpty)
                                      OutlinedButton(
                                        onPressed: () => setState(
                                          () => cursors.add(page.next),
                                        ),
                                        child: Text(l10n.blogMoreChapters),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _BlogEmptyState extends StatelessWidget {
  const _BlogEmptyState({
    required this.scope,
    required this.filtered,
    required this.onSeeTopRated,
  });
  final String scope;
  final bool filtered;
  final VoidCallback onSeeTopRated;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (IconData icon, String title, String body) = switch (scope) {
      'mine' => (
        Icons.menu_book_outlined,
        l10n.blogEmptyMineTitle,
        l10n.blogEmptyMineBody,
      ),
      'top' => (
        Icons.trending_up_rounded,
        l10n.blogEmptyTopTitle,
        filtered ? l10n.blogEmptyTopFilteredBody : l10n.blogEmptyTopBody,
      ),
      'subscriptions' => (
        Icons.favorite_border_rounded,
        filtered
            ? l10n.blogEmptyFollowingFilteredTitle
            : l10n.blogEmptyFollowingTitle,
        l10n.blogEmptyFollowingBody,
      ),
      _ => (
        Icons.menu_book_outlined,
        l10n.blogEmptyCommunityTitle,
        l10n.blogEmptyCommunityBody,
      ),
    };
    return Card(
      key: ValueKey('blog.empty.$scope'),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
            if (scope == 'subscriptions') ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                key: const ValueKey('blog.following.see_top'),
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: onSeeTopRated,
                icon: const Icon(Icons.trending_up_rounded),
                label: Text(l10n.blogFindWritersTopRated),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One chapter in a feed. In Top rated, [rank] shows its place (1, 2, 3…).
class BlogPostCard extends StatelessWidget {
  const BlogPostCard({
    super.key,
    required this.post,
    required this.user,
    this.rank,
  });
  final BlogPost post;
  final String? user;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openBlogPost(context, post.id),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (rank != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Tooltip(
                    message: l10n.blogRankTooltip(rank!),
                    child: Container(
                      key: ValueKey('blog.rank.${post.id}'),
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rank! <= 3
                            ? colors.primaryContainer
                            : colors.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$rank',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: rank! <= 3
                                ? colors.onPrimaryContainer
                                : colors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              BlogByline(post: post),
              const SizedBox(height: 16),
              if (post.photos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: BlogImage(post: post, photo: post.photos.first),
                ),
              Text(
                post.title.isEmpty ? l10n.blogUntitled : post.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: AppTheme.displayFamily,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                post.body.isEmpty ? l10n.blogDraftPlaceholder : post.body,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              if (post.audience != 'private')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: BlogEngagementRow(post: post),
                ),
              if (post.authorId == user &&
                  (post.wallReach > 0 || post.nextTier != null))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: BlogReachCard(post: post),
                ),
              const SizedBox(height: 16),
              Text(
                post.authorId == user
                    ? l10n.blogReadEdit
                    : l10n.blogReadChapter,
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BlogByline extends StatelessWidget {
  const BlogByline({super.key, required this.post, this.showAuthor = true});
  final BlogPost post;

  /// False where the writer has their own row (the chapter page).
  final bool showAuthor;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (showAuthor)
        Text(post.authorName, style: Theme.of(context).textTheme.labelLarge),
      Chip(
        avatar: Icon(
          post.audience == 'private'
              ? Icons.lock_outline
              : post.audience == 'friends'
              ? Icons.people_outline
              : Icons.public,
          size: 16,
        ),
        label: Text(
          blogAudienceLabel(AppLocalizations.of(context), post.audience),
        ),
        visualDensity: VisualDensity.compact,
      ),
      if (post.topicTitle.isNotEmpty)
        BlogTopicChip(
          key: ValueKey('blog.post_topic.${post.id}'),
          title: post.topicTitle,
        ),
      if (post.featured) const BlogFeaturedChip(),
    ],
  );
}

class BlogImage extends ConsumerWidget {
  const BlogImage({super.key, required this.post, required this.photo});
  final BlogPost post;
  final BlogPhoto photo;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    if (user == null) return const SizedBox.shrink();
    final provider = blogPhotoProvider((
      user: user,
      post: post.id,
      photo: photo.id,
      version: post.version,
    ));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: ref
                .watch(provider)
                .when(
                  skipLoadingOnReload: false,
                  skipLoadingOnRefresh: false,
                  data: (bytes) => Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    semanticLabel: photo.alt,
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(
                    child: TextButton.icon(
                      onPressed: () => ref.invalidate(provider),
                      icon: const Icon(Icons.broken_image_outlined),
                      label: Text(
                        AppLocalizations.of(context).blogPhotoUnavailableRetry,
                      ),
                    ),
                  ),
                ),
          ),
        ),
        const SizedBox(height: 6),
        Text(photo.alt, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class BlogError extends StatelessWidget {
  const BlogError({super.key, required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Text(message),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: retry,
          child: Text(AppLocalizations.of(context).blogTryAgain),
        ),
      ],
    ),
  );
}

class BlogDetailScreen extends ConsumerWidget {
  const BlogDetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.blogDetailTitle)),
      body: user == null
          ? Center(child: Text(l10n.blogSignInRead))
          : ref
                .watch(blogPostProvider(id))
                .when(
                  skipLoadingOnRefresh: false,
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => BlogError(
                    message: apiErrorMessage(
                      e,
                      fallback: l10n.blogDetailUnavailable,
                    ),
                    retry: () => ref.invalidate(blogPostProvider(id)),
                  ),
                  data: (post) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          BlogByline(post: post, showAuthor: false),
                          const SizedBox(height: 20),
                          Text(
                            post.title.isEmpty ? l10n.blogUntitled : post.title,
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(fontFamily: AppTheme.displayFamily),
                          ),
                          const SizedBox(height: 16),
                          BlogAuthorRow(post: post),
                          const SizedBox(height: 20),
                          // Formatted chapters use the author's writing style;
                          // plain-text chapters render exactly as before.
                          RichBody(
                            key: const ValueKey('blog.detail.body'),
                            document: post.content,
                            plainText: post.body,
                            legacyStyle: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(height: 1.65),
                          ),
                          for (final photo in post.photos)
                            Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: BlogImage(post: post, photo: photo),
                            ),
                          if (post.audience != 'private')
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: BlogEngagementRow(post: post, live: true),
                            ),
                          if (post.authorId == user &&
                              (post.wallReach > 0 || post.nextTier != null))
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: BlogReachCard(post: post),
                            ),
                          if (post.invitation.isNotEmpty)
                            Card(
                              margin: const EdgeInsets.only(top: 24),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  blogInvitationLabel(l10n, post.invitation),
                                ),
                              ),
                            ),
                          if (post.authorId != user &&
                              post.invitation.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: FilledButton.icon(
                                icon: const Icon(Icons.mail_outline),
                                label: Text(l10n.blogRespondPrivately),
                                onPressed: () =>
                                    respondToChapter(context, post),
                              ),
                            ),
                          if (post.authorId == user &&
                              post.audience == 'community' &&
                              post.moderation == 'active')
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.ios_share_outlined),
                                label: Text(l10n.blogCreatePublicPreview),
                                onPressed: () => Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlogShareScreen(post: post),
                                  ),
                                ),
                              ),
                            ),
                          if (post.moderation == 'removed')
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(l10n.blogRemovedByModerationNote),
                            ),
                          if (post.audience != 'private') ...[
                            const SizedBox(height: 32),
                            BlogCommentsSection(post: post),
                          ],
                          const SizedBox(height: 28),
                          if (post.authorId == user)
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                FilledButton.icon(
                                  icon: const Icon(Icons.edit_outlined),
                                  label: Text(l10n.blogEditChapter),
                                  onPressed: () =>
                                      Navigator.of(context).push<void>(
                                        MaterialPageRoute(
                                          builder: (_) => BlogEditor(
                                            key: ValueKey(user),
                                            initial: post,
                                          ),
                                        ),
                                      ),
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.delete_outline),
                                  label: Text(l10n.blogDeleteChapter),
                                  onPressed: () async {
                                    if (!await confirmBlogAction(
                                      context,
                                      l10n.blogDeleteChapterTitle,
                                      l10n.blogDeleteChapterMessage,
                                      l10n.blogDeleteChapter,
                                    )) {
                                      return;
                                    }
                                    try {
                                      await ref
                                          .read(apiClientProvider)
                                          .delete<dynamic>(
                                            '/blog/posts/$id',
                                            data: {
                                              'expected_version': post.version,
                                            },
                                          );
                                      invalidateBlog(ref, id);
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    } on Object catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              apiErrorMessage(
                                                e,
                                                fallback: l10n
                                                    .blogDeleteChapterFailed,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            )
                          else
                            OutlinedButton.icon(
                              icon: const Icon(Icons.flag_outlined),
                              label: Text(l10n.blogReportChapter),
                              onPressed: () => showReportUserSheet(
                                context: context,
                                onSubmit:
                                    ({required reason, description}) async {
                                      try {
                                        final response = await ref
                                            .read(apiClientProvider)
                                            .post<dynamic>(
                                              '/blog/posts/$id/report',
                                              data: {
                                                'reason': reason,
                                                'description':
                                                    description ?? '',
                                              },
                                            );
                                        return ((response.data as Map)['report']
                                                as Map?)?['id']
                                            ?.toString();
                                      } on Object catch (e) {
                                        throw Exception(
                                          apiErrorMessage(
                                            e,
                                            fallback: l10n.blogReportFailed,
                                          ),
                                        );
                                      }
                                    },
                              ),
                            ),
                          if (post.authorId != user)
                            TextButton.icon(
                              icon: const Icon(Icons.block_outlined),
                              label: Text(l10n.blogBlockThisMember),
                              onPressed: () async {
                                if (!await confirmBlogAction(
                                  context,
                                  l10n.blogBlockTitle,
                                  l10n.blogBlockMessageChapter,
                                  l10n.blogBlockMember,
                                ))
                                  return;
                                try {
                                  await ref
                                      .read(safetyActionsProvider)
                                      .blockUser(blockedUserId: post.authorId);
                                  invalidateBlog(ref, id);
                                  if (context.mounted)
                                    Navigator.of(context).pop();
                                } on Object catch (e) {
                                  if (context.mounted)
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          apiErrorMessage(
                                            e,
                                            fallback: l10n.blogBlockRetryFailed,
                                          ),
                                        ),
                                      ),
                                    );
                                }
                              },
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

Future<bool> confirmBlogAction(
  BuildContext context,
  String title,
  String message,
  String action,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).blogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;
