import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/providers/safety_actions_provider.dart';
import '../auth/providers/auth_provider.dart';
import '../common/widgets/report_user_sheet.dart';
import '../first_chapter/chapter_studio_screen.dart';
import '../plans/screens/propose_date_plan_sheet.dart';
import 'blog_data.dart';
import 'blog_screen.dart';
import 'blog_sharing.dart';

final blogHubProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, path) async {
      if (ref.watch(authNotifierProvider.select((s) => s.userId)) == null)
        throw StateError('Sign in to continue.');
      final response = await ref.watch(apiClientProvider).get<dynamic>(path);
      return (response.data as Map<dynamic, dynamic>).cast<String, dynamic>();
    });
void openBlogConnections(BuildContext context, {String section = 'responses'}) {
  Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => BlogConnectionsScreen(section: section)),
  );
}

Future<void> respondToChapter(BuildContext context, BlogPost post) async {
  final result = await Navigator.of(context).push<Map<String, dynamic>>(
    MaterialPageRoute(
      builder: (_) => BlogTextCommandScreen(
        title: 'A private response',
        help:
            '${blogInvitations[post.invitation]}\n\nOnly the author receives this response. They can accept or decline an optional exchange. Up to five new responses per day, and one to the same author.',
        label: 'Send private response',
        path: '/blog/responses',
        payload: {'post_id': post.id},
        maxLength: 600,
      ),
    ),
  );
  if (context.mounted && result != null) openBlogConnections(context);
}

class BlogTextCommandScreen extends ConsumerStatefulWidget {
  const BlogTextCommandScreen({
    super.key,
    required this.title,
    required this.help,
    required this.label,
    required this.path,
    required this.payload,
    required this.maxLength,
  });
  final String title, help, label, path;
  final Map<String, dynamic> payload;
  final int maxLength;
  @override
  ConsumerState<BlogTextCommandScreen> createState() => _BlogTextCommandState();
}

class _BlogTextCommandState extends ConsumerState<BlogTextCommandScreen> {
  final text = TextEditingController();
  final id = const Uuid().v4();
  late final String? user = ref.read(authNotifierProvider).userId;
  bool busy = false, leaving = false;
  String? error;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (text.text.trim().isEmpty ||
        busy ||
        ref.read(authNotifierProvider).userId != user)
      return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .post<dynamic>(
            widget.path,
            data: {
              ...widget.payload,
              'text': text.text.trim(),
              if (widget.path == '/blog/responses') 'id': id,
            },
          );
      if (!mounted) return;
      ref.invalidate(blogHubProvider);
      setState(() => leaving = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted)
          Navigator.of(context).pop(
            (response.data as Map<dynamic, dynamic>).cast<String, dynamic>(),
          );
      });
    } on Object catch (e) {
      if (mounted)
        setState(
          () => error = apiErrorMessage(
            e,
            fallback:
                'Could not confirm the save. Your words are still here; retry or reload the saved exchange.',
          ),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(authNotifierProvider.select((s) => s.userId)) != user ||
        user == null)
      return const Scaffold(
        body: Center(child: Text('Sign in again to continue.')),
      );
    return PopScope(
      canPop: leaving || (!busy && text.text.isEmpty),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || busy) return;
        if (await confirmBlogAction(
              context,
              'Leave without sending?',
              'Your unsent words will be discarded.',
              'Leave',
            ) &&
            mounted) {
          setState(() => leaving = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(widget.help, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                TextField(
                  controller: text,
                  enabled: !busy,
                  onChanged: (_) => setState(() {}),
                  minLines: 5,
                  maxLines: 12,
                  maxLength: widget.maxLength,
                  decoration: const InputDecoration(
                    labelText: 'In your own words',
                    alignLabelWithHint: true,
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Semantics(liveRegion: true, child: Text(error!)),
                  ),
                FilledButton(
                  onPressed: busy || text.text.trim().isEmpty ? null : submit,
                  child: Text(busy ? 'Sending…' : widget.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BlogConnectionsScreen extends ConsumerStatefulWidget {
  const BlogConnectionsScreen({super.key, this.section = 'responses'});
  final String section;
  @override
  ConsumerState<BlogConnectionsScreen> createState() => _BlogConnectionsState();
}

class _BlogConnectionsState extends ConsumerState<BlogConnectionsScreen> {
  late String section = widget.section;
  String cursor = '';
  final previous = <String>[];
  bool busy = false;
  String? error;
  Future<void> mutate(
    String path,
    Map<String, dynamic> data, {
    bool remove = false,
  }) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      if (remove) {
        await dio.delete<dynamic>(path);
      } else {
        await dio.post<dynamic>(path, data: data);
      }
      if (mounted) ref.invalidate(blogHubProvider);
    } on Object catch (e) {
      if (mounted)
        setState(
          () => error = apiErrorMessage(
            e,
            fallback: 'Could not confirm the change. Refresh to check.',
          ),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    final path = '/blog/$section${cursor.isEmpty ? '' : '?before=$cursor'}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Chapter connections'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(blogHubProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Sign in to continue.'))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text('Good stories leave room for someone else.'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final e in {
                          'responses': 'Private responses',
                          'publications': 'Shared links',
                          'notices': 'Review notices',
                        }.entries)
                          ChoiceChip(
                            label: Text(e.value),
                            selected: section == e.key,
                            onSelected: busy
                                ? null
                                : (_) => setState(() {
                                    section = e.key;
                                    cursor = '';
                                    previous.clear();
                                    error = null;
                                  }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (error != null) Text(error!),
                    ref
                        .watch(blogHubProvider(path))
                        .when(
                          skipLoadingOnRefresh: false,
                          skipLoadingOnReload: false,
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => BlogError(
                            message: apiErrorMessage(
                              e,
                              fallback: 'Could not load your connections.',
                            ),
                            retry: () => ref.invalidate(blogHubProvider(path)),
                          ),
                          data: (data) {
                            final items = (data[section] as List? ?? [])
                                .cast<Map<String, dynamic>>();
                            final next = data['next_cursor']?.toString() ?? '';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (items.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      section == 'responses'
                                          ? 'Responses to your chapters and the ones you send will appear here. Nothing needs an instant answer.'
                                          : section == 'publications'
                                          ? 'Your public previews and jointly approved links will appear here.'
                                          : 'No review notices to show.',
                                    ),
                                  ),
                                for (final item in items)
                                  Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: section == 'responses'
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['partner_name']
                                                      as String,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.titleLarge,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  item['text'] as String,
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  item['revealed'] == true
                                                      ? 'Your shared chapter is ready'
                                                      : item['status'] ==
                                                            'pending'
                                                      ? (item['incoming'] ==
                                                                true
                                                            ? 'A response for you'
                                                            : 'Sent · their choice, their pace')
                                                      : item['status'] ==
                                                            'accepted'
                                                      ? 'An exchange, at your pace'
                                                      : 'This exchange is closed',
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.push<void>(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              BlogExchangeScreen(
                                                                id:
                                                                    item['id']
                                                                        as String,
                                                              ),
                                                        ),
                                                      ),
                                                  child: const Text(
                                                    'Open private exchange',
                                                  ),
                                                ),
                                              ],
                                            )
                                          : section == 'publications'
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['title'] as String,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.titleLarge,
                                                ),
                                                const SizedBox(height: 12),
                                                SelectableText(
                                                  item['excerpt'] as String,
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  item['published'] == true
                                                      ? 'Live public copy'
                                                      : item['moderation_state'] ==
                                                            'removed'
                                                      ? 'Removed by moderation'
                                                      : item['joint'] == true
                                                      ? 'Requires both approvals and a current source chapter'
                                                      : 'Source changed · create a new preview to share again',
                                                ),
                                                const SizedBox(height: 12),
                                                Wrap(
                                                  spacing: 10,
                                                  runSpacing: 10,
                                                  children: [
                                                    if (item['joint'] == true &&
                                                        item['my_approval'] !=
                                                            true &&
                                                        item['title'] !=
                                                            'Sharing unavailable')
                                                      FilledButton(
                                                        onPressed: busy
                                                            ? null
                                                            : () async {
                                                                if (await confirmBlogAction(
                                                                  context,
                                                                  'Approve this public copy?',
                                                                  'The exact words above will be available to anyone with the link. Both people can withdraw sharing. No names are added automatically, but the words may identify you.',
                                                                  'Approve public copy',
                                                                ))
                                                                  await mutate(
                                                                    '/blog/publications/${item['id']}',
                                                                    {
                                                                      'action':
                                                                          'approve',
                                                                      'approved':
                                                                          true,
                                                                      'expected_version':
                                                                          item['version'],
                                                                    },
                                                                  );
                                                              },
                                                        child: const Text(
                                                          'Approve exact public copy',
                                                        ),
                                                      ),
                                                    if (item['published'] ==
                                                        true)
                                                      OutlinedButton.icon(
                                                        onPressed: () =>
                                                            copyBlogLink(
                                                              context,
                                                              item['id']
                                                                  as String,
                                                            ),
                                                        icon: const Icon(
                                                          Icons.copy,
                                                        ),
                                                        label: const Text(
                                                          'Copy link',
                                                        ),
                                                      ),
                                                    TextButton(
                                                      onPressed: busy
                                                          ? null
                                                          : () async {
                                                              if (await confirmBlogAction(
                                                                context,
                                                                'Withdraw this link?',
                                                                'The public copy will become unavailable. Copies already saved by someone else cannot be recalled.',
                                                                'Withdraw link',
                                                              ))
                                                                await mutate(
                                                                  '/blog/publications/${item['id']}',
                                                                  {},
                                                                  remove: true,
                                                                );
                                                            },
                                                      child: const Text(
                                                        'Withdraw link',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            )
                                          : Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${item['content_type']} · ${item['status']}',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.titleMedium,
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  item['decision_note']
                                                      as String,
                                                ),
                                                if ((item['appeal'] as String)
                                                    .isNotEmpty) ...[
                                                  const SizedBox(height: 12),
                                                  const Text('Your appeal'),
                                                  Text(
                                                    item['appeal'] as String,
                                                  ),
                                                ],
                                                if (item['can_appeal'] == true)
                                                  TextButton(
                                                    onPressed: () => Navigator.push<void>(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => BlogTextCommandScreen(
                                                          title:
                                                              'Request another review',
                                                          help:
                                                              'Explain what the reviewer should reconsider. Your appeal goes privately to the trust team. Removed content stays hidden during review.',
                                                          label:
                                                              'Submit appeal',
                                                          path:
                                                              '/blog/notices/${item['id']}/appeal',
                                                          payload: {
                                                            'expected_version':
                                                                item['version'],
                                                          },
                                                          maxLength: 1000,
                                                        ),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Appeal this decision',
                                                    ),
                                                  ),
                                              ],
                                            ),
                                    ),
                                  ),
                                Wrap(
                                  spacing: 12,
                                  children: [
                                    if (previous.isNotEmpty)
                                      OutlinedButton(
                                        onPressed: () => setState(
                                          () => cursor = previous.removeLast(),
                                        ),
                                        child: const Text('Previous'),
                                      ),
                                    if (next.isNotEmpty)
                                      OutlinedButton(
                                        onPressed: () => setState(() {
                                          previous.add(cursor);
                                          cursor = next;
                                        }),
                                        child: const Text('More'),
                                      ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                  ],
                ),
              ),
            ),
    );
  }
}

class BlogExchangeScreen extends ConsumerStatefulWidget {
  const BlogExchangeScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<BlogExchangeScreen> createState() => _BlogExchangeState();
}

class _BlogExchangeState extends ConsumerState<BlogExchangeScreen> {
  late final String? user = ref.read(authNotifierProvider).userId;
  late final Timer timer;
  bool busy = false;
  String? error;
  String get path => '/blog/responses/${widget.id}';
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (mounted && !busy) ref.invalidate(blogHubProvider(path));
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Future<void> command(Map<String, dynamic> item, String action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      if (action == 'withdraw') {
        await dio.delete<dynamic>(path);
        if (mounted) Navigator.pop(context);
      } else {
        await dio.post<dynamic>(
          path,
          data: {'action': action, 'expected_version': item['version']},
        );
      }
      if (mounted) ref.invalidate(blogHubProvider);
    } on Object catch (e) {
      if (mounted)
        setState(
          () => error = apiErrorMessage(
            e,
            fallback: 'Could not confirm this change. Refresh and retry.',
          ),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null ||
        ref.watch(authNotifierProvider.select((s) => s.userId)) != user)
      return const Scaffold(
        body: Center(child: Text('Sign in again to continue.')),
      );
    return Scaffold(
      appBar: AppBar(
        title: const Text('A private Chapter exchange'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(blogHubProvider(path)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ref
          .watch(blogHubProvider(path))
          .when(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => BlogError(
              message: apiErrorMessage(
                e,
                fallback: 'This exchange is no longer available.',
              ),
              retry: () => ref.invalidate(blogHubProvider(path)),
            ),
            data: (data) {
              final v = (data['response'] as Map<dynamic, dynamic>)
                  .cast<String, dynamic>();
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        'With ${v['partner_name']}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'A response is an invitation, never an obligation. This exchange does not create a match or unlock chat.',
                      ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(v['text'] as String),
                        ),
                      ),
                      if (error != null) Text(error!),
                      if (v['status'] == 'pending' && v['incoming'] == true)
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            FilledButton(
                              onPressed: busy
                                  ? null
                                  : () => command(v, 'accept'),
                              child: const Text('Accept an exchange'),
                            ),
                            OutlinedButton(
                              onPressed: busy
                                  ? null
                                  : () => command(v, 'decline'),
                              child: const Text('Decline kindly'),
                            ),
                          ],
                        ),
                      if (v['status'] == 'pending' && v['incoming'] != true)
                        const Text(
                          'Your response has been sent. There is no countdown and no need to follow up.',
                        ),
                      if (v['status'] == 'declined')
                        const Text(
                          'This exchange is closed. Make room for another connection at your own pace.',
                        ),
                      if (v['status'] == 'accepted') ...[
                        const SizedBox(height: 20),
                        Text(
                          'One small story each.',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add a tiny continuation, a memory, or your version of the moment. Both contributions appear together, only after both people submit.',
                        ),
                        if ((v['my_story'] as String).isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: FilledButton(
                              onPressed: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlogTextCommandScreen(
                                    title: 'Your side of the chapter',
                                    help:
                                        'Share up to 1,000 characters. Your partner cannot read this until they also contribute. Once submitted, the words cannot be edited; you can withdraw the exchange at any time.',
                                    label: 'Submit my contribution',
                                    path: path,
                                    payload: {
                                      'action': 'contribute',
                                      'expected_version': v['version'],
                                    },
                                    maxLength: 1000,
                                  ),
                                ),
                              ),
                              child: const Text('Add my contribution'),
                            ),
                          )
                        else ...[
                          const SizedBox(height: 16),
                          const Text('Your contribution'),
                          SelectableText(v['my_story'] as String),
                        ],
                        if (v['revealed'] == true) ...[
                          const SizedBox(height: 24),
                          Text(
                            '${v['partner_name']}’s contribution',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          SelectableText(v['partner_story'] as String),
                          const SizedBox(height: 24),
                          if (v['can_plan'] == true)
                            FilledButton.icon(
                              icon: const Icon(Icons.event_available_outlined),
                              label: const Text('Shape a date together'),
                              onPressed: () => showProposeDatePlanSheet(
                                context: context,
                                matchId: v['match_id'] as String,
                                partnerName: v['partner_name'] as String,
                                initialNote:
                                    'Inspired by our Chapter exchange.',
                                sourceBlogResponseId: widget.id,
                              ),
                            ),
                          if ((v['match_id'] as String? ?? '').isNotEmpty)
                            OutlinedButton(
                              onPressed: () => openChapterStudio(
                                context,
                                matchId: v['match_id'] as String,
                                partnerName: v['partner_name'] as String,
                              ),
                              child: const Text('Try First Chapter Studio'),
                            ),
                          if (v['can_plan'] != true)
                            const Text(
                              'Date planning becomes available if you have an active match and your conversation is unlocked.',
                            ),
                          if (v['can_joint_share'] == true)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.menu_book_outlined),
                              label: const Text(
                                'Propose a shared journal page',
                              ),
                              onPressed: () async {
                                try {
                                  final post = await ref.read(
                                    blogPostProvider(
                                      v['post_id'] as String,
                                    ).future,
                                  );
                                  if (context.mounted)
                                    Navigator.push<void>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BlogShareScreen(
                                          post: post,
                                          exchange: v,
                                        ),
                                      ),
                                    );
                                } on Object catch (e) {
                                  if (mounted)
                                    setState(
                                      () => error = apiErrorMessage(
                                        e,
                                        fallback:
                                            'The source chapter is unavailable.',
                                      ),
                                    );
                                }
                              },
                            ),
                        ] else if ((v['my_story'] as String).isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text(
                              'Your contribution is saved privately. The reveal happens when both of you are ready.',
                            ),
                          ),
                      ],
                      const SizedBox(height: 28),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          TextButton(
                            onPressed: busy
                                ? null
                                : () async {
                                    if (await confirmBlogAction(
                                      context,
                                      'Withdraw this exchange?',
                                      'The response and contributions will no longer be available to either of you. Joint public links will also stop working.',
                                      'Withdraw exchange',
                                    ))
                                      await command(v, 'withdraw');
                                  },
                            child: const Text('Withdraw exchange'),
                          ),
                          TextButton(
                            onPressed: () => showReportUserSheet(
                              context: context,
                              onSubmit: ({required reason, description}) async {
                                final result = await ref
                                    .read(apiClientProvider)
                                    .post<dynamic>(
                                      '/blog/reports/response/${widget.id}',
                                      data: {
                                        'reason': reason,
                                        'description': description ?? '',
                                      },
                                    );
                                return ((result.data
                                            as Map<dynamic, dynamic>)['report']
                                        as Map?)?['id']
                                    ?.toString();
                              },
                            ),
                            child: const Text('Report exchange'),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (!await confirmBlogAction(
                                context,
                                'Block this member?',
                                'Contact and access to each other’s chapters will stop.',
                                'Block member',
                              ))
                                return;
                              try {
                                await ref
                                    .read(safetyActionsProvider)
                                    .blockUser(
                                      blockedUserId: v['partner_id'] as String,
                                    );
                                if (mounted) {
                                  ref.invalidate(blogHubProvider);
                                  invalidateBlog(ref, v['post_id'] as String);
                                  Navigator.pop(context);
                                }
                              } on Object catch (e) {
                                if (mounted)
                                  setState(
                                    () => error = apiErrorMessage(
                                      e,
                                      fallback: 'Could not block this member.',
                                    ),
                                  );
                              }
                            },
                            child: const Text('Block member'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}
