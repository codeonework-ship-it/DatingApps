import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../auth/providers/auth_provider.dart';
import '../blog/blog_data.dart';
import '../blog/blog_social.dart';
import '../common/widgets/community_actions.dart';
import '../walls/today_wall_data.dart';
import 'photo_themes_data.dart';

/// Loads an entry's photo through the authenticated API.
class ThemeEntryPhoto extends ConsumerWidget {
  const ThemeEntryPhoto({
    required this.entry,
    super.key,
    this.fit = BoxFit.cover,
  });
  final ThemeEntry entry;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    if (user == null) {
      return const SizedBox.shrink();
    }
    final provider = themeEntryPhotoProvider((
      user: user,
      theme: entry.themeId,
      entry: entry.id,
    ));
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: ref
          .watch(provider)
          .when(
            skipLoadingOnRefresh: false,
            data: (bytes) => Image.memory(
              bytes,
              fit: fit,
              width: double.infinity,
              height: double.infinity,
              semanticLabel: entry.altText,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: IconButton(
                tooltip: 'Photo unavailable. Retry',
                onPressed: () => ref.invalidate(provider),
                icon: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
    );
  }
}

/// A rounded photo tile with the caption and author over a soft scrim.
class ThemeEntryTile extends StatelessWidget {
  const ThemeEntryTile({required this.entry, required this.onTap, super.key});
  final ThemeEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scrim = Theme.of(context).colorScheme.scrim;
    return Semantics(
      button: true,
      label: 'Open ${entry.authorName}’s photo',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ThemeEntryPhoto(entry: entry),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        scrim.withValues(alpha: 0),
                        scrim.withValues(alpha: 0.78),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.mine ? 'You' : entry.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelLarge?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: onTap),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The larger photo with its caption and the actions that fit the viewer.
/// Counts a unique view for the wall ranking (fire-and-forget).
Future<void> showThemeEntrySheet(
  BuildContext context, {
  required ThemeEntry entry,
}) {
  recordWallViewFrom(context, kind: WallKind.photo, id: entry.id);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => ThemeEntrySheet(entry: entry),
  );
}

/// How reach to other members' walls works, shown wherever a member turns it
/// on or off.
const photoWallHelp =
    'If members love it, your photo can reach their Today walls: 50 likes '
    'and 5 comments reach 50 walls, 100 likes and 10 comments reach 100. '
    'You can turn this off any time.';

/// Heart toggle for a photo. Optimistic, with rollback; disabled with a
/// tooltip on the member's own photo.
class PhotoLikeButton extends ConsumerWidget {
  const PhotoLikeButton({required this.entry, super.key});
  final ThemeEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    ref.watch(photoLikesProvider);
    final likes = ref.read(photoLikesProvider.notifier);
    return SocialLikeButton(
      buttonKey: ValueKey('photo.like.${entry.id}'),
      noun: 'photo',
      state: likes.of(entry),
      own: entry.mine || entry.authorId == user,
      enabled: user != null,
      onToggle: () => likes.toggle(entry),
      onReact: (reaction) => likes.react(entry, reaction),
    );
  }
}

/// The photo, its caption, likes and comments, and for the author the
/// switch that lets it reach other members' walls.
class ThemeEntrySheet extends ConsumerStatefulWidget {
  const ThemeEntrySheet({required this.entry, super.key});
  final ThemeEntry entry;

  @override
  ConsumerState<ThemeEntrySheet> createState() => _ThemeEntrySheetState();
}

class _ThemeEntrySheetState extends ConsumerState<ThemeEntrySheet> {
  bool busy = false;
  bool savingReach = false;
  late ThemeEntry entry = widget.entry;

  ThemeEntryRef get thread => (theme: entry.themeId, entry: entry.id);

  Future<void> remove() async {
    final confirmed = await confirmCommunityAction(
      context,
      title: 'Remove your photo?',
      message:
          'It disappears from this theme for everyone. You can share a '
          'new one afterwards.',
      action: 'Remove photo',
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => busy = true);
    try {
      await ref
          .read(apiClientProvider)
          .delete<dynamic>('/themes/${entry.themeId}/entries/${entry.id}');
      invalidatePhotoThemes(ref);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(e, fallback: 'Your photo could not be removed.'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> block() async {
    if (await blockCommunityMember(
      context,
      ref,
      userId: entry.authorId,
      name: entry.authorName,
    )) {
      invalidatePhotoThemes(ref);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> setReach({required bool allow}) async {
    setState(() => savingReach = true);
    try {
      final saved = await setThemeEntryFeaturing(
        ref.read(apiClientProvider),
        entry: entry,
        allow: allow,
      );
      if (!mounted) {
        return;
      }
      setState(() => entry = saved);
      invalidatePhotoThemes(ref);
      showCommunitySnack(
        context,
        allow
            ? 'Your photo can now reach members’ walls when they love it.'
            : 'Your photo is off every wall.',
      );
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(e, fallback: 'That didn’t save. Please try again.'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => savingReach = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    final isAuthor = entry.mine || entry.authorId == user;
    var comments = entry.commentCount;
    var waiting = isAuthor ? entry.pendingCommentCount : 0;
    final loaded = ref.watch(themeEntryCommentsProvider(thread)).valueOrNull;
    if (loaded != null) {
      final groups = groupBlogComments(loaded, viewerIsAuthor: isAuthor);
      comments = groups.approved.length;
      waiting = groups.awaitingMyApproval.length;
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.55,
              ),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: ThemeEntryPhoto(entry: entry, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (entry.themeTitle.isNotEmpty) ...[
            Text(
              entry.themeTitle,
              style: text.labelLarge?.copyWith(color: scheme.primary),
            ),
            const SizedBox(height: 4),
          ],
          Text(entry.caption, style: text.titleMedium),
          const SizedBox(height: 8),
          Text(
            entry.mine ? 'Shared by you' : 'Shared by ${entry.authorName}',
            style: text.bodyMedium,
          ),
          if (entry.altText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Photo description: ${entry.altText}', style: text.bodyMedium),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SocialEngagementRow(
                  likeButton: PhotoLikeButton(entry: entry),
                  reactions: ref
                      .watch(photoLikesProvider.notifier)
                      .of(entry)
                      .reactions,
                  comments: comments,
                  waiting: waiting,
                ),
              ),
              if (entry.featured) const BlogFeaturedChip(),
            ],
          ),
          if (isAuthor) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              key: ValueKey('photo.featuring.${entry.id}'),
              contentPadding: EdgeInsets.zero,
              value: entry.allowFeaturing,
              onChanged: savingReach ? null : (allow) => setReach(allow: allow),
              title: const Text('Let it reach other members’ walls'),
              subtitle: const Text(photoWallHelp),
            ),
            const SizedBox(height: 8),
            WallReachCard(
              cardKey: ValueKey('photo.reach.${entry.id}'),
              visible: entry.allowFeaturing,
              wallReach: entry.wallReach,
              nextTier: entry.nextTier,
              idleTitle: 'Members can carry this photo further',
              liveCaption: 'Members are seeing it on their Today walls now.',
            ),
          ],
          const SizedBox(height: 16),
          if (busy) const LinearProgressIndicator(),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: entry.mine
                ? [
                    OutlinedButton.icon(
                      onPressed: busy ? null : remove,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove my photo'),
                    ),
                  ]
                : [
                    OutlinedButton.icon(
                      onPressed: () => reportCommunityItem(
                        context,
                        ref,
                        kind: 'theme_entry',
                        id: entry.id,
                      ),
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Report'),
                    ),
                    TextButton.icon(
                      onPressed: block,
                      icon: const Icon(Icons.block_outlined),
                      label: Text('Block ${entry.authorName}'),
                    ),
                  ],
          ),
          const SizedBox(height: 24),
          CommentThreadSection(
            thread: CommentThread(
              keyPrefix: 'photo',
              noun: 'photo',
              authorId: entry.authorId,
              open: true,
              comments: themeEntryCommentsProvider(thread),
              reportKind: 'photo_comment',
              hint: 'What does it make you think of?',
              approvedNotice:
                  'Approved. Everyone who can see this photo can see it now.',
              create: (api, id, body) => createThemeEntryComment(
                api,
                entry: entry,
                commentId: id,
                body: body,
              ),
              decide: (api, id, {required approve}) => decideThemeEntryComment(
                api,
                entry: entry,
                commentId: id,
                approve: approve,
              ),
              delete: (api, id) =>
                  deleteThemeEntryComment(api, entry: entry, commentId: id),
              onChanged: (ref) => ref
                ..invalidate(themeEntriesProvider)
                ..invalidate(photoWallProvider),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the member wrote about the photo, plus whether it may reach other
/// members' walls.
typedef ThemeEntryDetails = ({String caption, String alt, bool allowFeaturing});

/// Caption and photo description, both required before sharing, and the
/// opt-in to reach other members' walls (off by default).
Future<ThemeEntryDetails?> askEntryDetails(BuildContext context) =>
    showDialog<ThemeEntryDetails>(
      context: context,
      builder: (_) => const _EntryDetailsDialog(),
    );

class _EntryDetailsDialog extends StatefulWidget {
  const _EntryDetailsDialog();

  @override
  State<_EntryDetailsDialog> createState() => _EntryDetailsDialogState();
}

class _EntryDetailsDialogState extends State<_EntryDetailsDialog> {
  final caption = TextEditingController();
  final alt = TextEditingController();
  bool allowFeaturing = false;

  @override
  void dispose() {
    caption.dispose();
    alt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = caption.text.trim().isNotEmpty && alt.text.trim().isNotEmpty;
    return AlertDialog(
      title: const Text('Tell us about it'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: caption,
            maxLength: 280,
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Caption',
              hintText: 'Pancakes, then nowhere to be.',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: alt,
            maxLength: 160,
            maxLines: 2,
            minLines: 1,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Describe the photo',
              helperText: 'Helps members who use a screen reader.',
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const ValueKey('photo.upload.allow_featuring'),
            contentPadding: EdgeInsets.zero,
            value: allowFeaturing,
            onChanged: (value) => setState(() => allowFeaturing = value),
            title: const Text('Let it reach other members’ walls'),
            subtitle: const Text(photoWallHelp),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: ready
              ? () => Navigator.pop(context, (
                  caption: caption.text.trim(),
                  alt: alt.text.trim(),
                  allowFeaturing: allowFeaturing,
                ))
              : null,
          child: const Text('Share'),
        ),
      ],
    );
  }
}
