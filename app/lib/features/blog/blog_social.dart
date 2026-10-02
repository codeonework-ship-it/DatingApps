import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';
import '../common/widgets/report_user_sheet.dart';
import 'blog_data.dart';
import 'blog_screen.dart';
import '../walls/reaction_widgets.dart';
import '../walls/reactions.dart';

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Heart toggle with the like count plus empathetic reactions, shared by
/// chapters and Photo Theme photos. Tapping the heart likes or unlikes; the
/// react button (or a long press on the heart) opens the reaction picker
/// ("I hear you", "Me too", ...). The caller owns the optimistic [state],
/// [onToggle] and [onReact]; failures are explained in a snack bar. Authors
/// cannot react to their own [noun], so the controls stay visible but
/// disabled, with a tooltip.
class SocialLikeButton extends StatelessWidget {
  const SocialLikeButton({
    super.key,
    required this.buttonKey,
    required this.noun,
    required this.state,
    required this.own,
    required this.enabled,
    required this.onToggle,
    required this.onReact,
  });

  /// Key on the heart button, e.g. `blog.like.{id}`. The react button uses
  /// the same key's value with `.react` appended.
  final ValueKey<String> buttonKey;

  /// What is being liked, e.g. "chapter" or "photo".
  final String noun;
  final BlogLikeState state;
  final bool own, enabled;
  final Future<void> Function() onToggle;
  final Future<void> Function(String reaction) onReact;

  Future<void> _guard(BuildContext context, Future<void> Function() run) async {
    try {
      await run();
    } on Object catch (e) {
      if (context.mounted) {
        _snack(
          context,
          apiErrorMessage(
            e,
            fallback: AppLocalizations.of(context).blogReactionFailed,
          ),
        );
      }
    }
  }

  Future<void> _pick(BuildContext context) async {
    final choice = await showReactionPicker(
      context,
      current: state.liked ? state.reaction : '',
      noun: noun,
    );
    if (choice == null || !context.mounted) return;
    if (choice.isEmpty) {
      if (state.liked) await _guard(context, onToggle);
      return;
    }
    await _guard(context, () => onReact(choice));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final active = enabled && !own;
    final mine = state.liked ? empathyReaction(state.reaction) : null;
    final heart = mine == null || mine.id == 'love';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: own
              ? l10n.blogCannotLikeOwn(noun)
              : mine != null
              ? l10n.blogYouReacted(mine.label)
              : l10n.blogLikeThis(noun),
          child: TextButton.icon(
            key: buttonKey,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: state.liked
                  ? colors.primary
                  : colors.onSurfaceVariant,
            ),
            onPressed: active ? () => _guard(context, onToggle) : null,
            onLongPress: active ? () => _pick(context) : null,
            icon: heart
                ? Icon(
                    state.liked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                  )
                : Text(mine.emoji, style: const TextStyle(fontSize: 20)),
            label: Text('${state.count}'),
          ),
        ),
        IconButton(
          key: ValueKey('${buttonKey.value}.react'),
          tooltip: own ? l10n.blogCannotReactOwn(noun) : l10n.blogReactTooltip,
          onPressed: active ? () => _pick(context) : null,
          color: colors.onSurfaceVariant,
          icon: const Icon(Icons.add_reaction_outlined),
        ),
      ],
    );
  }
}

/// Heart and reactions for a chapter. Optimistic: the heart flips at once and
/// rolls back if the server does not confirm.
class BlogLikeButton extends ConsumerWidget {
  const BlogLikeButton({super.key, required this.post});
  final BlogPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    ref.watch(blogLikesProvider);
    final likes = ref.read(blogLikesProvider.notifier);
    return SocialLikeButton(
      buttonKey: ValueKey('blog.like.${post.id}'),
      noun: 'chapter',
      state: likes.of(post),
      own: post.authorId == user,
      enabled: user != null && post.moderation == 'active',
      onToggle: () => likes.toggle(post),
      onReact: (reaction) => likes.react(post, reaction),
    );
  }
}

/// Like button plus the comment count. When [live] is true (the detail page),
/// counts follow the loaded comment list so approvals show up at once.
class BlogEngagementRow extends ConsumerWidget {
  const BlogEngagementRow({super.key, required this.post, this.live = false});
  final BlogPost post;
  final bool live;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    final isAuthor = post.authorId == user;
    var comments = post.commentCount;
    var waiting = isAuthor ? post.pendingCommentCount : 0;
    if (live) {
      final loaded = ref.watch(blogCommentsProvider(post.id)).valueOrNull;
      if (loaded != null) {
        final groups = groupBlogComments(loaded, viewerIsAuthor: isAuthor);
        comments = groups.approved.length;
        waiting = groups.awaitingMyApproval.length;
      }
    }
    ref.watch(blogLikesProvider);
    return SocialEngagementRow(
      likeButton: BlogLikeButton(post: post),
      reactions: ref.read(blogLikesProvider.notifier).of(post).reactions,
      comments: comments,
      waiting: waiting,
    );
  }
}

/// A like button, the approved comment count and, for the author, how many
/// comments wait for approval. Shared by chapters and Photo Theme photos.
class SocialEngagementRow extends StatelessWidget {
  const SocialEngagementRow({
    super.key,
    required this.likeButton,
    required this.comments,
    this.waiting = 0,
    this.reactions = const {},
  });
  final Widget likeButton;
  final int comments, waiting;

  /// Reaction counts shown as a summary beside the like button.
  final Map<String, int> reactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        likeButton,
        if (reactions.isNotEmpty) ReactionSummary(reactions: reactions),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 20,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.blogCommentCount(comments),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (waiting > 0)
          Text(
            l10n.blogWaitingForYou(waiting),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

/// The small "Featured" marker used on bylines and Featured Stories cards.
class BlogFeaturedChip extends StatelessWidget {
  const BlogFeaturedChip({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(
        Icons.auto_awesome_rounded,
        size: 16,
        color: colors.onTertiaryContainer,
      ),
      label: Text(AppLocalizations.of(context).blogFeatured),
      labelStyle: TextStyle(color: colors.onTertiaryContainer),
      backgroundColor: colors.tertiaryContainer,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// What a tier still needs, e.g. "38 more likes and 4 more comments to
/// reach 50 walls".
String blogTierNeeds(AppLocalizations l10n, BlogNextTier tier) {
  final likes = tier.likesNeeded, comments = tier.commentsNeeded;
  if (likes > 0 && comments > 0) {
    return l10n.blogTierNeedsBoth(likes, comments, tier.reach);
  }
  if (likes > 0) return l10n.blogTierNeedsLikes(likes, tier.reach);
  if (comments > 0) return l10n.blogTierNeedsComments(comments, tier.reach);
  return l10n.blogTierAlmostThere(tier.reach);
}

/// Author-only: how far the chapter reaches and how close the next tier is.
/// Renders nothing for readers or when there is nothing to report.
class BlogReachCard extends ConsumerWidget {
  const BlogReachCard({super.key, required this.post});
  final BlogPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    final l10n = AppLocalizations.of(context);
    return WallReachCard(
      cardKey: ValueKey('blog.reach.${post.id}'),
      visible: post.authorId == user,
      wallReach: post.wallReach,
      nextTier: post.nextTier,
      idleTitle: l10n.blogReachIdle,
      liveCaption: l10n.blogReachLive,
    );
  }
}

/// How far something reaches on members' walls ("On 50 walls") and a bar
/// toward the next tier. Shared by chapters and Photo Theme photos. Renders
/// nothing unless [visible] (the author is viewing) and there is something
/// to report.
class WallReachCard extends StatelessWidget {
  const WallReachCard({
    super.key,
    required this.cardKey,
    required this.visible,
    required this.wallReach,
    required this.nextTier,
    required this.idleTitle,
    required this.liveCaption,
  });
  final Key cardKey;
  final bool visible;
  final int wallReach;
  final BlogNextTier? nextTier;

  /// Title while not on any wall yet.
  final String idleTitle;

  /// Line under "On N walls" once it reaches members.
  final String liveCaption;

  @override
  Widget build(BuildContext context) {
    final tier = nextTier;
    if (!visible || (wallReach == 0 && tier == null)) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final onCard = colors.onSecondaryContainer;
    return Card(
      key: cardKey,
      margin: EdgeInsets.zero,
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: onCard),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    wallReach > 0 ? l10n.blogOnWalls(wallReach) : idleTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: onCard,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (wallReach > 0) ...[
              const SizedBox(height: 4),
              Text(
                liveCaption,
                style: theme.textTheme.bodySmall?.copyWith(color: onCard),
              ),
            ],
            if (tier != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: tier.progress,
                  minHeight: 8,
                  color: colors.primary,
                  backgroundColor: colors.surface,
                  semanticsLabel: l10n.blogProgressToward(tier.reach),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                blogTierNeeds(l10n, tier),
                style: theme.textTheme.bodySmall?.copyWith(color: onCard),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Featured Stories as a horizontal rail. Renders nothing while loading, when
/// the wall is empty, or when the request fails, so the surfaces that host it
/// never show an error for this optional extra.
class BlogFeaturedRail extends ConsumerWidget {
  const BlogFeaturedRail({
    super.key,
    this.title,
    this.caption,
    this.limit,
    this.compact = false,
    this.padding = EdgeInsets.zero,
  });

  /// Rail title and caption; null uses "Featured Stories" and its default
  /// caption in the app's language.
  final String? title, caption;
  final int? limit;
  final bool compact;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref
        .watch(blogFeaturedProvider)
        .maybeWhen(data: (posts) => posts, orElse: () => const <BlogPost>[]);
    final shown = limit == null ? posts : posts.take(limit!).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      key: const ValueKey('blog.featured_rail'),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title ?? l10n.blogFeaturedStories,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            caption ?? l10n.blogFeaturedCaption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < shown.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        right: i == shown.length - 1 ? 0 : 12,
                      ),
                      child: SizedBox(
                        width: compact ? 220 : 260,
                        child: BlogFeaturedCard(
                          post: shown[i],
                          compact: compact,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BlogFeaturedCard extends ConsumerWidget {
  const BlogFeaturedCard({super.key, required this.post, this.compact = false});
  final BlogPost post;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final likes =
        ref.watch(blogLikesProvider)[post.id]?.count ?? post.likeCount;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final l10n = AppLocalizations.of(context);
    return Card(
      key: ValueKey('blog.featured.${post.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openBlogPost(context, post.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BlogFeaturedChip(),
              const SizedBox(height: 8),
              Text(
                post.title.isEmpty ? l10n.blogUntitled : post.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.blogByAuthor(post.authorName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
              if (!compact && post.body.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  post.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    size: 16,
                    color: colors.primary,
                    semanticLabel: l10n.blogLikes,
                  ),
                  const SizedBox(width: 4),
                  Text('$likes', style: muted),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: colors.onSurfaceVariant,
                    semanticLabel: l10n.blogComments,
                  ),
                  const SizedBox(width: 4),
                  Text('${post.commentCount}', style: muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Comments on a chapter. Every comment waits for the chapter author: readers
/// see approved comments plus their own pending ones; the author also sees a
/// "Waiting for your approval" group with Approve and Decline.
class BlogCommentsSection extends ConsumerWidget {
  const BlogCommentsSection({super.key, required this.post});
  final BlogPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) => CommentThreadSection(
    thread: CommentThread(
      keyPrefix: 'blog',
      noun: 'chapter',
      authorId: post.authorId,
      open: post.moderation == 'active' && post.audience != 'private',
      comments: blogCommentsProvider(post.id),
      reportKind: 'comment',
      hint: AppLocalizations.of(context).blogCommentHint,
      approvedNotice: AppLocalizations.of(context).blogCommentApproved,
      create: (api, id, body) =>
          createBlogComment(api, postId: post.id, commentId: id, body: body),
      decide: (api, id, {required approve}) => decideBlogComment(
        api,
        postId: post.id,
        commentId: id,
        approve: approve,
      ),
      delete: (api, id) =>
          deleteBlogComment(api, postId: post.id, commentId: id),
      onChanged: (ref) => ref
        ..invalidate(blogFeedProvider)
        ..invalidate(blogFeaturedProvider),
    ),
  );
}

/// Where a comment thread lives and how to reach it, so chapters and Photo
/// Theme photos share one comments section with the same approval rules.
class CommentThread {
  const CommentThread({
    required this.keyPrefix,
    required this.noun,
    required this.authorId,
    required this.open,
    required this.comments,
    required this.reportKind,
    required this.hint,
    required this.approvedNotice,
    required this.create,
    required this.decide,
    required this.delete,
    this.onChanged,
  });

  /// Prefix for widget keys, e.g. `blog` gives `blog.comment.field`.
  final String keyPrefix;

  /// What is commented on: "chapter" or "photo" (selects the wording).
  final String noun;

  /// The member who approves comments.
  final String authorId;

  /// Whether readers may comment at all (the item is active and shared).
  final bool open;

  /// The comments the viewer may see, oldest first.
  final AutoDisposeFutureProvider<List<BlogComment>> comments;

  /// Report kind for `POST /blog/reports/{kind}/{commentID}`.
  final String reportKind;

  /// Composer hint.
  final String hint;

  /// Snack bar shown after the author approves a comment.
  final String approvedNotice;

  /// Sends a comment with a client-generated ID.
  final Future<void> Function(Dio api, String commentId, String body) create;

  /// Author only: approve or decline a pending comment.
  final Future<void> Function(
    Dio api,
    String commentId, {
    required bool approve,
  })
  decide;

  /// The comment writer or the author removes a comment.
  final Future<void> Function(Dio api, String commentId) delete;

  /// Refreshes whatever else shows counts after a comment changes.
  final void Function(WidgetRef ref)? onChanged;
}

/// Comments on a [CommentThread]. Every comment waits for the author: readers
/// see approved comments plus their own pending ones; the author also sees a
/// "Waiting for your approval" group with Approve and Decline.
class CommentThreadSection extends ConsumerStatefulWidget {
  const CommentThreadSection({super.key, required this.thread});
  final CommentThread thread;

  @override
  ConsumerState<CommentThreadSection> createState() =>
      _CommentThreadSectionState();
}

class _CommentThreadSectionState extends ConsumerState<CommentThreadSection> {
  final composer = TextEditingController();
  // One ID per piece of text, so retrying the same words never duplicates.
  String commentId = const Uuid().v4();
  String? idFor;
  bool sending = false;
  String? notice, error;
  final deciding = <String>{};

  CommentThread get thread => widget.thread;
  AppLocalizations get l10n => AppLocalizations.of(context);
  String get prefix => thread.keyPrefix;

  @override
  void dispose() {
    composer.dispose();
    super.dispose();
  }

  void refresh() {
    ref.invalidate(thread.comments);
    thread.onChanged?.call(ref);
  }

  Future<void> send() async {
    final text = composer.text.trim();
    // The server counts characters (runes), not UTF-16 units: an emoji is one.
    if (sending || text.isEmpty || text.runes.length > blogCommentMaxLength) {
      return;
    }
    if (idFor != text) {
      commentId = const Uuid().v4();
      idFor = text;
    }
    setState(() {
      sending = true;
      error = null;
      notice = null;
    });
    try {
      await thread.create(ref.read(apiClientProvider), commentId, text);
      if (!mounted) return;
      composer.clear();
      idFor = null;
      commentId = const Uuid().v4();
      setState(() => notice = l10n.blogCommentSent);
      refresh();
    } on Object catch (e) {
      if (mounted) {
        setState(
          () =>
              error = apiErrorMessage(e, fallback: l10n.blogCommentSendFailed),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> decide(BlogComment comment, {required bool approve}) async {
    if (!deciding.add(comment.id)) return;
    setState(() {});
    try {
      await thread.decide(
        ref.read(apiClientProvider),
        comment.id,
        approve: approve,
      );
      refresh();
      if (mounted) {
        _snack(
          context,
          approve
              ? thread.approvedNotice
              : l10n.blogCommentDeclined(thread.noun),
        );
      }
    } on Object catch (e) {
      if (mounted) {
        _snack(context, apiErrorMessage(e, fallback: l10n.blogSaveFailed));
      }
    } finally {
      deciding.remove(comment.id);
      if (mounted) setState(() {});
    }
  }

  Future<void> delete(BlogComment comment) async {
    if (!await confirmBlogAction(
      context,
      l10n.blogDeleteCommentTitle,
      l10n.blogDeleteCommentMessage,
      l10n.blogDeleteComment,
    )) {
      return;
    }
    try {
      await thread.delete(ref.read(apiClientProvider), comment.id);
      refresh();
      if (mounted) _snack(context, l10n.blogCommentDeleted);
    } on Object catch (e) {
      if (mounted) {
        _snack(
          context,
          apiErrorMessage(e, fallback: l10n.blogCommentDeleteFailed),
        );
      }
    }
  }

  Future<void> report(BlogComment comment) async {
    // The report id may legitimately be null, so only confirm what was sent.
    var submitted = false;
    await showReportUserSheet(
      context: context,
      onSubmit: ({required reason, description}) async {
        try {
          final response = await ref
              .read(apiClientProvider)
              .post<dynamic>(
                '/blog/reports/${thread.reportKind}/${comment.id}',
                data: {'reason': reason, 'description': description ?? ''},
              );
          submitted = true;
          return ((response.data as Map)['report'] as Map?)?['id']?.toString();
        } on Object catch (e) {
          throw Exception(apiErrorMessage(e, fallback: l10n.blogReportFailed));
        }
      },
    );
    // The sheet closes on success; say so, as the other report flows do.
    if (submitted && mounted) _snack(context, l10n.communityReportSubmitted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    final isAuthor = thread.authorId == user;
    final canComment = user != null && !isAuthor && thread.open;
    final length = composer.text.trim().runes.length;
    final comments = ref.watch(thread.comments);
    return Column(
      key: ValueKey('$prefix.comments'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.blogComments, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          isAuthor ? l10n.blogCommentsAuthorNote : l10n.blogCommentsReaderNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (canComment) ...[
          TextField(
            key: ValueKey('$prefix.comment.field'),
            controller: composer,
            enabled: !sending,
            minLines: 1,
            maxLines: 5,
            maxLength: blogCommentMaxLength,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {
              notice = null;
              error = null;
            }),
            decoration: InputDecoration(
              labelText: l10n.blogLeaveComment,
              hintText: thread.hint,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: ValueKey('$prefix.comment.send'),
              onPressed: sending || length == 0 || length > blogCommentMaxLength
                  ? null
                  : send,
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(l10n.blogSendToAuthor),
            ),
          ),
          if (notice != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Semantics(liveRegion: true, child: Text(notice!)),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Semantics(
                liveRegion: true,
                child: Text(error!, style: TextStyle(color: colors.error)),
              ),
            ),
          const SizedBox(height: 20),
        ],
        comments.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => BlogError(
            message: apiErrorMessage(e, fallback: l10n.blogCommentsLoadFailed),
            retry: () => ref.invalidate(thread.comments),
          ),
          data: (list) {
            final groups = groupBlogComments(list, viewerIsAuthor: isAuthor);
            final tile = _tileBuilder(isAuthor);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (groups.awaitingMyApproval.isNotEmpty) ...[
                  Text(
                    l10n.blogWaitingApproval,
                    key: ValueKey('$prefix.comments.awaiting'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final c in groups.awaitingMyApproval)
                    tile(c, decision: true),
                  const SizedBox(height: 16),
                ],
                if (groups.approved.isEmpty &&
                    groups.mineSent.isEmpty &&
                    groups.mineDeclined.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      canComment
                          ? l10n.blogNoCommentsInvite
                          : l10n.blogNoCommentsShared,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                for (final c in groups.approved) tile(c),
                for (final c in groups.mineSent)
                  tile(c, status: l10n.blogCommentSent),
                for (final c in groups.mineDeclined)
                  tile(c, status: l10n.blogCommentNotShared),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget Function(BlogComment, {bool decision, String? status}) _tileBuilder(
    bool isAuthor,
  ) =>
      (c, {decision = false, status}) => _BlogCommentTile(
        keyPrefix: prefix,
        comment: c,
        status: status,
        canDelete: c.mine || isAuthor || c.canModerate,
        canReport: !c.mine,
        busy: deciding.contains(c.id),
        onApprove: decision ? () => decide(c, approve: true) : null,
        onDecline: decision ? () => decide(c, approve: false) : null,
        onDelete: () => delete(c),
        onReport: () => report(c),
      );
}

class _BlogCommentTile extends StatelessWidget {
  const _BlogCommentTile({
    required this.keyPrefix,
    required this.comment,
    required this.canDelete,
    required this.canReport,
    required this.busy,
    required this.onDelete,
    required this.onReport,
    this.status,
    this.onApprove,
    this.onDecline,
  });
  final String keyPrefix;
  final BlogComment comment;
  final String? status;
  final bool canDelete, canReport, busy;
  final VoidCallback onDelete, onReport;
  final VoidCallback? onApprove, onDecline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Card(
      key: ValueKey('$keyPrefix.comment.${comment.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    comment.mine ? l10n.blogYou : comment.authorName,
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                if (canDelete || canReport)
                  PopupMenuButton<String>(
                    key: ValueKey(
                      'qa.$keyPrefix.comment.options.${comment.id}',
                    ),
                    tooltip: l10n.blogCommentOptions,
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (v) => v == 'delete' ? onDelete() : onReport(),
                    itemBuilder: (_) => [
                      if (canDelete)
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(l10n.blogDeleteComment),
                        ),
                      if (canReport)
                        PopupMenuItem(
                          value: 'report',
                          child: Text(l10n.blogReportComment),
                        ),
                    ],
                  )
                else
                  const SizedBox(height: 48),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SelectableText(comment.body),
            ),
            if (status != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (onApprove != null && onDecline != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    key: ValueKey('$keyPrefix.comment.approve.${comment.id}'),
                    onPressed: busy ? null : onApprove,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(l10n.blogApprove),
                  ),
                  OutlinedButton.icon(
                    key: ValueKey('$keyPrefix.comment.decline.${comment.id}'),
                    onPressed: busy ? null : onDecline,
                    icon: const Icon(Icons.close_rounded),
                    label: Text(l10n.blogDecline),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
