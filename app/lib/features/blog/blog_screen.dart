import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/providers/safety_actions_provider.dart';
import '../../core/rich_text/rich_document_view.dart';
import '../../core/theme/app_theme.dart';
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
const blogScopes = {
  'community': 'For you',
  'top': 'Top rated',
  'subscriptions': 'Following',
  'friends': 'Friends',
  'mine': 'Mine',
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

  String get scopeCaption => switch (scope) {
    'mine' =>
      'Your drafts and published chapters. You choose the audience for each one.',
    'friends' => 'Chapters shared by your accepted Connect friends.',
    'top' =>
      'Ranked by likes, approved comments and readers, from the last 30 days.',
    'subscriptions' => 'The newest chapters from writers you follow.',
    _ =>
      'For eligible, signed-in Connect members. These chapters are not public on the web.',
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
    final scopes = {
      for (final e in blogScopes.entries)
        if (widget.authorId == null ||
            e.key == 'community' ||
            e.key == 'friends')
          e.key: e.value,
    };
    final topics = user == null
        ? const <BlogTopic>[]
        : ref
              .watch(blogTopicsProvider)
              .maybeWhen(data: (t) => t, orElse: () => const <BlogTopic>[]);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Chapters'),
        actions: [
          IconButton(
            key: const ValueKey('blog.rewards'),
            tooltip: 'How rewards work',
            onPressed: () => showBlogRewardsSheet(context),
            icon: const Icon(Icons.info_outline_rounded),
          ),
          IconButton(
            key: const ValueKey('blog.writers'),
            tooltip: 'Writers you follow',
            onPressed: () => openBlogWriters(context),
            icon: const Icon(Icons.favorite_border_rounded),
          ),
          IconButton(
            tooltip: 'Private responses, sharing and notices',
            onPressed: () => openBlogConnections(context),
            icon: const Icon(Icons.mark_email_unread_outlined),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Sign in to read and write chapters.'))
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
                        'A life worth\ngetting to know.',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontFamily: AppTheme.displayFamily,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'The story behind a photo. A small obsession. Something you’re still learning. Let your everyday life do the talking.',
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          key: const ValueKey('blog.new'),
                          icon: const Icon(Icons.edit_note_rounded),
                          label: const Text('Write a chapter'),
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
                            label: const Text('Private responses'),
                          ),
                          TextButton.icon(
                            onPressed: () => openBlogConnections(
                              context,
                              section: 'publications',
                            ),
                            icon: const Icon(Icons.ios_share_outlined),
                            label: const Text('Shared links'),
                          ),
                          TextButton.icon(
                            onPressed: () => openBlogConnections(
                              context,
                              section: 'notices',
                            ),
                            icon: const Icon(Icons.shield_outlined),
                            label: const Text('Review notices'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        key: const ValueKey('blog.scopes'),
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final entry in scopes.entries)
                            ChoiceChip(
                              key: ValueKey('blog.scope.${entry.key}'),
                              label: Text(entry.value),
                              selected: scope == entry.key,
                              onSelected: (_) => select(scope: entry.key),
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
                                const BlogTopic(slug: '', title: 'All'),
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
                      Text(scopeCaption, style: theme.textTheme.bodySmall),
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
                                fallback: 'Chapters could not load.',
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
                                        child: const Text('Previous page'),
                                      ),
                                    if (page.next.isNotEmpty)
                                      OutlinedButton(
                                        onPressed: () => setState(
                                          () => cursors.add(page.next),
                                        ),
                                        child: const Text('More chapters'),
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
    final (IconData icon, String title, String body) = switch (scope) {
      'mine' => (
        Icons.menu_book_outlined,
        'Your next chapter starts here.',
        'Start with a moment you would love someone to ask about. Your first draft is only for you.',
      ),
      'top' => (
        Icons.trending_up_rounded,
        'When chapters move people, they rise here.',
        filtered
            ? 'Nothing has risen in this topic yet. Try All, or share a chapter of your own.'
            : 'Chapters readers love from the last 30 days will appear here.',
      ),
      'subscriptions' => (
        Icons.favorite_border_rounded,
        filtered
            ? 'Nothing new in this topic yet.'
            : 'Writers you follow will appear here.',
        'When a chapter speaks to you, open it and tap Follow their chapters. Their new chapters will gather here, so you never miss what they share next.',
      ),
      _ => (
        Icons.menu_book_outlined,
        'A little quiet here, for now.',
        'Chapters appear here when members choose to share with this audience.',
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
                label: const Text('Find writers in Top rated'),
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
                    message: 'Number $rank in Top rated',
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
                post.title.isEmpty ? 'An untitled chapter' : post.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: AppTheme.displayFamily,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                post.body.isEmpty
                    ? 'A private draft, waiting for your words.'
                    : post.body,
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
                post.authorId == user ? 'Read & edit →' : 'Read chapter →',
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
        label: Text(blogAudiences[post.audience]!),
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
                      label: const Text('Photo unavailable · Retry'),
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
        OutlinedButton(onPressed: retry, child: const Text('Try again')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('A chapter')),
      body: user == null
          ? const Center(child: Text('Sign in to read chapters.'))
          : ref
                .watch(blogPostProvider(id))
                .when(
                  skipLoadingOnRefresh: false,
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => BlogError(
                    message: apiErrorMessage(
                      e,
                      fallback:
                          'This chapter is unavailable or its audience has changed.',
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
                            post.title.isEmpty
                                ? 'An untitled chapter'
                                : post.title,
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
                                child: Text(blogInvitations[post.invitation]!),
                              ),
                            ),
                          if (post.authorId != user &&
                              post.invitation.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: FilledButton.icon(
                                icon: const Icon(Icons.mail_outline),
                                label: const Text('Respond privately'),
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
                                label: const Text('Create a public preview'),
                                onPressed: () => Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlogShareScreen(post: post),
                                  ),
                                ),
                              ),
                            ),
                          if (post.moderation == 'removed')
                            const Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: Text(
                                'Removed by moderation. Open Review notices to read the decision or request another review.',
                              ),
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
                                  label: const Text('Edit chapter'),
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
                                  label: const Text('Delete chapter'),
                                  onPressed: () async {
                                    if (!await confirmBlogAction(
                                      context,
                                      'Delete this chapter?',
                                      'It will disappear from all audiences. This cannot be undone.',
                                      'Delete chapter',
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
                                                fallback:
                                                    'Could not confirm deletion. Reload the chapter before retrying.',
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
                              label: const Text('Report chapter'),
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
                                            fallback:
                                                'Report could not be submitted.',
                                          ),
                                        );
                                      }
                                    },
                              ),
                            ),
                          if (post.authorId != user)
                            TextButton.icon(
                              icon: const Icon(Icons.block_outlined),
                              label: const Text('Block this member'),
                              onPressed: () async {
                                if (!await confirmBlogAction(
                                  context,
                                  'Block this member?',
                                  'You will no longer see each other’s chapters. This also blocks contact through Connect.',
                                  'Block member',
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
                                            fallback:
                                                'Could not block this member. Please retry.',
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
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;
