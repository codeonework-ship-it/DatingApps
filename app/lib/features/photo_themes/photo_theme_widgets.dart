import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/widgets/sheet_close_bar.dart';
import '../../l10n/app_localizations.dart';
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
                tooltip: AppLocalizations.of(
                  context,
                ).photoThemesPhotoUnavailable,
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
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.photoThemesOpenPhoto(entry.authorName),
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
                          entry.mine ? l10n.photoThemesYou : entry.authorName,
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

  AppLocalizations get l10n => AppLocalizations.of(context);

  Future<void> remove() async {
    final confirmed = await confirmCommunityAction(
      context,
      title: l10n.photoThemesRemoveTitle,
      message: l10n.photoThemesRemoveMessage,
      action: l10n.photoThemesRemoveAction,
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
          apiErrorMessage(e, fallback: l10n.photoThemesRemoveFailed),
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
        allow ? l10n.photoThemesReachOn : l10n.photoThemesReachOff,
      );
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(e, fallback: l10n.photoThemesSaveFailed),
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
    // Watch the like state itself (the notifier never changes), so the
    // reaction summary follows the member's reaction at once.
    ref.watch(photoLikesProvider);
    final reactions = ref.read(photoLikesProvider.notifier).of(entry).reactions;
    // The sheet opens full height, so the close button stays pinned above
    // the scrolling content (Android back also closes it).
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SheetCloseBar(closeKey: ValueKey('qa.photo_entry.close')),
        Flexible(
          child: SingleChildScrollView(
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
                  entry.mine
                      ? l10n.photoThemesSharedByYou
                      : l10n.photoThemesSharedBy(entry.authorName),
                  style: text.bodyMedium,
                ),
                if (entry.altText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.photoThemesPhotoDescription(entry.altText),
                    style: text.bodyMedium,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SocialEngagementRow(
                        likeButton: PhotoLikeButton(entry: entry),
                        reactions: reactions,
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
                    onChanged: savingReach
                        ? null
                        : (allow) => setReach(allow: allow),
                    title: Text(l10n.photoThemesReachSwitch),
                    subtitle: Text(l10n.photoThemesWallHelp),
                  ),
                  const SizedBox(height: 8),
                  WallReachCard(
                    cardKey: ValueKey('photo.reach.${entry.id}'),
                    visible: entry.allowFeaturing,
                    wallReach: entry.wallReach,
                    nextTier: entry.nextTier,
                    idleTitle: l10n.photoThemesReachIdle,
                    liveCaption: l10n.photoThemesReachLive,
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
                            label: Text(l10n.photoThemesRemoveMine),
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
                            label: Text(l10n.photoThemesReport),
                          ),
                          TextButton.icon(
                            onPressed: block,
                            icon: const Icon(Icons.block_outlined),
                            label: Text(
                              l10n.photoThemesBlock(entry.authorName),
                            ),
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
                    hint: l10n.photoThemesCommentHint,
                    approvedNotice: l10n.photoThemesCommentApproved,
                    create: (api, id, body) => createThemeEntryComment(
                      api,
                      entry: entry,
                      commentId: id,
                      body: body,
                    ),
                    decide: (api, id, {required approve}) =>
                        decideThemeEntryComment(
                          api,
                          entry: entry,
                          commentId: id,
                          approve: approve,
                        ),
                    delete: (api, id) => deleteThemeEntryComment(
                      api,
                      entry: entry,
                      commentId: id,
                    ),
                    onChanged: (ref) => ref
                      ..invalidate(themeEntriesProvider)
                      ..invalidate(photoWallProvider),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.photoThemesDetailsTitle),
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
            decoration: InputDecoration(
              labelText: l10n.photoThemesCaption,
              hintText: l10n.photoThemesCaptionHint,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: alt,
            maxLength: 160,
            maxLines: 2,
            minLines: 1,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.photoThemesDescribe,
              helperText: l10n.photoThemesDescribeHelper,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const ValueKey('photo.upload.allow_featuring'),
            contentPadding: EdgeInsets.zero,
            value: allowFeaturing,
            onChanged: (value) => setState(() => allowFeaturing = value),
            title: Text(l10n.photoThemesReachSwitch),
            subtitle: Text(l10n.photoThemesWallHelp),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.photoThemesCancel),
        ),
        FilledButton(
          onPressed: ready
              ? () => Navigator.pop(context, (
                  caption: caption.text.trim(),
                  alt: alt.text.trim(),
                  allowFeaturing: allowFeaturing,
                ))
              : null,
          child: Text(l10n.photoThemesShare),
        ),
      ],
    );
  }
}
