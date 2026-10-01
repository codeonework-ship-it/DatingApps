import 'package:flutter/material.dart' hide Title;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../common/widgets/activity_visuals.dart';
import '../common/widgets/community_actions.dart';
import 'clubs_data.dart';

/// The discussion for one weekly pick, oldest post first.
class ClubDiscussion extends ConsumerStatefulWidget {
  const ClubDiscussion({
    required this.club,
    required this.selection,
    super.key,
  });
  final Club club;
  final Selection selection;

  @override
  ConsumerState<ClubDiscussion> createState() => _ClubDiscussionState();
}

class _ClubDiscussionState extends ConsumerState<ClubDiscussion> {
  final cursors = <String>[''];
  final body = TextEditingController();
  String postId = const Uuid().v4();
  bool spoilers = false, busy = false;

  @override
  void didUpdateWidget(ClubDiscussion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection.id != widget.selection.id) {
      cursors
        ..clear()
        ..add('');
    }
  }

  @override
  void dispose() {
    body.dispose();
    super.dispose();
  }

  ClubPostsQuery query(String before) =>
      (club: widget.club.id, selection: widget.selection.id, before: before);

  void reload() {
    ref
      ..invalidate(clubPostsProvider)
      ..invalidate(clubDetailProvider(widget.club.id));
    setState(() {
      cursors
        ..clear()
        ..add('');
    });
  }

  Future<void> send() async {
    final text = body.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() => busy = true);
    try {
      await ref
          .read(apiClientProvider)
          .put<dynamic>(
            '/clubs/${widget.club.id}/posts/$postId',
            data: {
              'selection_id': widget.selection.id,
              'body': text,
              'has_spoilers': spoilers,
            },
          );
      body.clear();
      postId = const Uuid().v4();
      spoilers = false;
      reload();
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(e, fallback: 'Your post could not be sent.'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      for (final cursor in cursors) ref.watch(clubPostsProvider(query(cursor))),
    ];
    final seen = <String>{};
    final posts = [
      for (final page in pages)
        for (final post in page.valueOrNull?.posts ?? const <ClubPost>[])
          if (seen.add(post.id)) post,
    ]..sort(_oldestFirst);
    final loading = pages.any((p) => p.isLoading);
    final failed = pages.where((p) => p.hasError).firstOrNull;
    final next = pages.last.valueOrNull?.next ?? '';
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Discussion · ${widget.selection.title.title}',
          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (failed != null && posts.isEmpty)
          ActivityNotice(
            icon: Icons.forum_outlined,
            title: 'The discussion could not load',
            message: apiErrorMessage(
              failed.error!,
              fallback: 'Please check your connection.',
            ),
            actionLabel: 'Try again',
            onAction: reload,
          )
        else if (posts.isEmpty && !loading)
          const ActivityNotice(
            icon: Icons.forum_outlined,
            title: 'Start the conversation',
            message:
                'What did you think so far? Your post could be the one '
                'that gets everyone talking.',
          ),
        for (final post in posts)
          ClubPostTile(club: widget.club, post: post, onChanged: reload),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (next.isNotEmpty)
          Center(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => cursors.add(next)),
              icon: const Icon(Icons.expand_more),
              label: const Text('Load more posts'),
            ),
          ),
        const SizedBox(height: 16),
        _Composer(
          controller: body,
          spoilers: spoilers,
          busy: busy,
          onSpoilers: (value) => setState(() => spoilers = value),
          onSend: send,
        ),
      ],
    );
  }
}

int _oldestFirst(ClubPost a, ClubPost b) {
  final x = a.createdAt, y = b.createdAt;
  if (x == null || y == null) {
    return 0;
  }
  return x.compareTo(y);
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.spoilers,
    required this.busy,
    required this.onSpoilers,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool spoilers, busy;
  final ValueChanged<bool> onSpoilers;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            maxLength: 2000,
            maxLines: 5,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Add to the discussion',
              hintText: 'Favourite moment? Biggest surprise?',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: spoilers,
            onChanged: busy ? null : onSpoilers,
            title: const Text('Contains spoilers'),
            subtitle: const Text('Others tap to reveal it.'),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: busy ? null : onSend,
              icon: const Icon(Icons.send_rounded),
              label: Text(busy ? 'Posting…' : 'Post'),
            ),
          ),
        ],
      ),
    ),
  );
}

/// One discussion post with the actions the viewer is allowed to take.
class ClubPostTile extends ConsumerWidget {
  const ClubPostTile({
    required this.club,
    required this.post,
    required this.onChanged,
    super.key,
  });
  final Club club;
  final ClubPost post;
  final VoidCallback onChanged;

  Future<void> act(BuildContext context, WidgetRef ref, String action) async {
    final api = ref.read(apiClientProvider);
    try {
      switch (action) {
        case 'delete':
          if (!await confirmCommunityAction(
            context,
            title: 'Delete your post?',
            message: 'It is removed from the discussion for everyone.',
            action: 'Delete',
          )) {
            return;
          }
          await api.delete<dynamic>('/clubs/${club.id}/posts/${post.id}');
        case 'hide' || 'unhide':
          await api.post<dynamic>(
            '/clubs/${club.id}/posts/${post.id}/visibility',
            data: {'hidden': action == 'hide'},
          );
        case 'report':
          await reportCommunityItem(
            context,
            ref,
            kind: 'club_post',
            id: post.id,
          );
          return;
      }
      onChanged();
    } on Object catch (e) {
      if (context.mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(e, fallback: 'That action could not be completed.'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final actions = [
      if (post.mine) ('delete', 'Delete'),
      if (club.canModerate && !post.hidden) ('hide', 'Hide from members'),
      if (club.canModerate && post.hidden) ('unhide', 'Show to members'),
      if (!post.mine) ('report', 'Report'),
    ];
    final created = post.createdAt?.toLocal();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        post.mine ? 'You' : post.authorName,
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (created != null)
                        Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatShortDate(created),
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      if (post.hidden)
                        const CountPill(
                          icon: Icons.visibility_off_outlined,
                          label: 'Hidden',
                        ),
                    ],
                  ),
                ),
                if (actions.isNotEmpty)
                  PopupMenuButton<String>(
                    tooltip: 'Post actions',
                    onSelected: (action) => act(context, ref, action),
                    itemBuilder: (_) => [
                      for (final (value, label) in actions)
                        PopupMenuItem(value: value, child: Text(label)),
                    ],
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SpoilerReveal(
                spoiler: post.hasSpoilers && !post.mine,
                child: Text(post.body, style: text.bodyLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
