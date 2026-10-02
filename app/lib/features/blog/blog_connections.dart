import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/providers/safety_actions_provider.dart';
import '../../l10n/app_localizations.dart';
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
  final l10n = AppLocalizations.of(context);
  final result = await Navigator.of(context).push<Map<String, dynamic>>(
    MaterialPageRoute(
      builder: (_) => BlogTextCommandScreen(
        title: l10n.blogPrivateResponseTitle,
        help: l10n.blogPrivateResponseHelp(
          blogInvitationLabel(l10n, post.invitation),
        ),
        label: l10n.blogSendPrivateResponse,
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

  AppLocalizations get l10n => AppLocalizations.of(context);

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
            fallback: l10n.blogTextSaveUnconfirmed,
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
      return Scaffold(body: Center(child: Text(l10n.blogSignInAgain)));
    return PopScope(
      canPop: leaving || (!busy && text.text.isEmpty),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || busy) return;
        if (await confirmBlogAction(
              context,
              l10n.blogLeaveUnsentTitle,
              l10n.blogLeaveUnsentMessage,
              l10n.blogLeave,
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
                  key: const ValueKey('qa.blog.text_command.field'),
                  controller: text,
                  enabled: !busy,
                  onChanged: (_) => setState(() {}),
                  minLines: 5,
                  maxLines: 12,
                  maxLength: widget.maxLength,
                  decoration: InputDecoration(
                    labelText: l10n.blogOwnWordsLabel,
                    alignLabelWithHint: true,
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Semantics(liveRegion: true, child: Text(error!)),
                  ),
                FilledButton(
                  key: const ValueKey('qa.blog.text_command.submit'),
                  onPressed: busy || text.text.trim().isEmpty ? null : submit,
                  child: Text(busy ? l10n.blogSending : widget.label),
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
  AppLocalizations get l10n => AppLocalizations.of(context);

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
          () =>
              error = apiErrorMessage(e, fallback: l10n.blogChangeUnconfirmed),
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
        title: Text(l10n.blogConnectionsTitle),
        actions: [
          IconButton(
            key: const ValueKey('qa.blog.connections.refresh'),
            tooltip: l10n.blogRefresh,
            onPressed: () => ref.invalidate(blogHubProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: user == null
          ? Center(child: Text(l10n.blogSignInContinue))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(l10n.blogConnectionsIntro),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final e in {
                          'responses': l10n.blogPrivateResponses,
                          'publications': l10n.blogSharedLinks,
                          'notices': l10n.blogReviewNotices,
                        }.entries)
                          ChoiceChip(
                            key: ValueKey(
                              'qa.blog.connections.section.${e.key}',
                            ),
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
                              fallback: l10n.blogConnectionsLoadFailed,
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
                                          ? l10n.blogResponsesEmpty
                                          : section == 'publications'
                                          ? l10n.blogPublicationsEmpty
                                          : l10n.blogNoticesEmpty,
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
                                                      ? l10n.blogResponseRevealed
                                                      : item['status'] ==
                                                            'pending'
                                                      ? (item['incoming'] ==
                                                                true
                                                            ? l10n.blogResponseIncoming
                                                            : l10n.blogResponseSent)
                                                      : item['status'] ==
                                                            'accepted'
                                                      ? l10n.blogResponseAccepted
                                                      : l10n.blogResponseClosed,
                                                ),
                                                TextButton(
                                                  key: ValueKey(
                                                    'qa.blog.connections.open_exchange.${item['id']}',
                                                  ),
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
                                                  child: Text(
                                                    l10n.blogOpenExchange,
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
                                                  key: ValueKey(
                                                    'qa.blog.connections.excerpt.${item['id']}',
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  item['published'] == true
                                                      ? l10n.blogPublicationLive
                                                      : item['moderation_state'] ==
                                                            'removed'
                                                      ? l10n.blogPublicationRemoved
                                                      : item['joint'] == true
                                                      ? l10n.blogPublicationNeedsBoth
                                                      : l10n.blogPublicationSourceChanged,
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
                                                        key: ValueKey(
                                                          'qa.blog.connections.approve_copy.${item['id']}',
                                                        ),
                                                        onPressed: busy
                                                            ? null
                                                            : () async {
                                                                if (await confirmBlogAction(
                                                                  context,
                                                                  l10n.blogApprovePublicCopyTitle,
                                                                  l10n.blogApprovePublicCopyMessage,
                                                                  l10n.blogApprovePublicCopyAction,
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
                                                        child: Text(
                                                          l10n.blogApproveExactPublicCopy,
                                                        ),
                                                      ),
                                                    if (item['published'] ==
                                                        true)
                                                      OutlinedButton.icon(
                                                        key: ValueKey(
                                                          'qa.blog.connections.copy_link.${item['id']}',
                                                        ),
                                                        onPressed: () =>
                                                            copyBlogLink(
                                                              context,
                                                              item['id']
                                                                  as String,
                                                            ),
                                                        icon: const Icon(
                                                          Icons.copy,
                                                        ),
                                                        label: Text(
                                                          l10n.blogCopyLink,
                                                        ),
                                                      ),
                                                    TextButton(
                                                      key: ValueKey(
                                                        'qa.blog.connections.withdraw_link.${item['id']}',
                                                      ),
                                                      onPressed: busy
                                                          ? null
                                                          : () async {
                                                              if (await confirmBlogAction(
                                                                context,
                                                                l10n.blogWithdrawLinkTitle,
                                                                l10n.blogWithdrawLinkMessage,
                                                                l10n.blogWithdrawLink,
                                                              ))
                                                                await mutate(
                                                                  '/blog/publications/${item['id']}',
                                                                  {},
                                                                  remove: true,
                                                                );
                                                            },
                                                      child: Text(
                                                        l10n.blogWithdrawLink,
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
                                                  Text(l10n.blogYourAppeal),
                                                  Text(
                                                    item['appeal'] as String,
                                                  ),
                                                ],
                                                if (item['can_appeal'] == true)
                                                  TextButton(
                                                    key: ValueKey(
                                                      'qa.blog.connections.appeal.${item['id']}',
                                                    ),
                                                    onPressed: () => Navigator.push<void>(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => BlogTextCommandScreen(
                                                          title: l10n
                                                              .blogRequestReview,
                                                          help: l10n
                                                              .blogRequestReviewHelp,
                                                          label: l10n
                                                              .blogSubmitAppeal,
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
                                                    child: Text(
                                                      l10n.blogAppealDecision,
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
                                        key: const ValueKey(
                                          'qa.blog.connections.previous',
                                        ),
                                        onPressed: () => setState(
                                          () => cursor = previous.removeLast(),
                                        ),
                                        child: Text(l10n.blogPrevious),
                                      ),
                                    if (next.isNotEmpty)
                                      OutlinedButton(
                                        key: const ValueKey(
                                          'qa.blog.connections.more',
                                        ),
                                        onPressed: () => setState(() {
                                          previous.add(cursor);
                                          cursor = next;
                                        }),
                                        child: Text(l10n.blogMore),
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

  AppLocalizations get l10n => AppLocalizations.of(context);

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
            fallback: l10n.blogExchangeChangeFailed,
          ),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> report() async {
    // The report id may legitimately be null, so only confirm what was sent.
    var submitted = false;
    await showReportUserSheet(
      context: context,
      onSubmit: ({required reason, description}) async {
        final result = await ref
            .read(apiClientProvider)
            .post<dynamic>(
              '/blog/reports/response/${widget.id}',
              data: {'reason': reason, 'description': description ?? ''},
            );
        submitted = true;
        return ((result.data as Map<dynamic, dynamic>)['report'] as Map?)?['id']
            ?.toString();
      },
    );
    // The sheet closes on success; say so, as the other report flows do.
    if (submitted && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.communityReportSubmitted)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null ||
        ref.watch(authNotifierProvider.select((s) => s.userId)) != user)
      return Scaffold(body: Center(child: Text(l10n.blogSignInAgain)));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.blogExchangeTitle),
        actions: [
          IconButton(
            key: const ValueKey('qa.blog.exchange.refresh'),
            tooltip: l10n.blogRefresh,
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
                fallback: l10n.blogExchangeUnavailable,
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
                        l10n.blogExchangeWith(v['partner_name'].toString()),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(l10n.blogExchangeIntro),
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
                              key: const ValueKey('qa.blog.exchange.accept'),
                              onPressed: busy
                                  ? null
                                  : () => command(v, 'accept'),
                              child: Text(l10n.blogAcceptExchange),
                            ),
                            OutlinedButton(
                              key: const ValueKey('qa.blog.exchange.decline'),
                              onPressed: busy
                                  ? null
                                  : () => command(v, 'decline'),
                              child: Text(l10n.blogDeclineKindly),
                            ),
                          ],
                        ),
                      if (v['status'] == 'pending' && v['incoming'] != true)
                        Text(l10n.blogResponseSentNote),
                      if (v['status'] == 'declined')
                        Text(l10n.blogExchangeClosedNote),
                      if (v['status'] == 'accepted') ...[
                        const SizedBox(height: 20),
                        Text(
                          l10n.blogOneStoryEach,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.blogOneStoryEachBody),
                        if ((v['my_story'] as String).isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: FilledButton(
                              key: const ValueKey(
                                'qa.blog.exchange.contribute',
                              ),
                              onPressed: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlogTextCommandScreen(
                                    title: l10n.blogYourSideTitle,
                                    help: l10n.blogYourSideHelp,
                                    label: l10n.blogSubmitContribution,
                                    path: path,
                                    payload: {
                                      'action': 'contribute',
                                      'expected_version': v['version'],
                                    },
                                    maxLength: 1000,
                                  ),
                                ),
                              ),
                              child: Text(l10n.blogAddContribution),
                            ),
                          )
                        else ...[
                          const SizedBox(height: 16),
                          Text(l10n.blogYourContribution),
                          SelectableText(
                            v['my_story'] as String,
                            key: const ValueKey('qa.blog.exchange.my_story'),
                          ),
                        ],
                        if (v['revealed'] == true) ...[
                          const SizedBox(height: 24),
                          Text(
                            l10n.blogPartnerContribution(
                              v['partner_name'].toString(),
                            ),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            v['partner_story'] as String,
                            key: const ValueKey(
                              'qa.blog.exchange.partner_story',
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (v['can_plan'] == true)
                            FilledButton.icon(
                              key: const ValueKey(
                                'qa.blog.exchange.shape_date',
                              ),
                              icon: const Icon(Icons.event_available_outlined),
                              label: Text(l10n.blogShapeDate),
                              onPressed: () => showProposeDatePlanSheet(
                                context: context,
                                matchId: v['match_id'] as String,
                                partnerName: v['partner_name'] as String,
                                initialNote: l10n.blogInspiredNote,
                                sourceBlogResponseId: widget.id,
                              ),
                            ),
                          if ((v['match_id'] as String? ?? '').isNotEmpty)
                            OutlinedButton(
                              key: const ValueKey('qa.blog.exchange.studio'),
                              onPressed: () => openChapterStudio(
                                context,
                                matchId: v['match_id'] as String,
                                partnerName: v['partner_name'] as String,
                              ),
                              child: Text(l10n.blogTryStudio),
                            ),
                          if (v['can_plan'] != true)
                            Text(l10n.blogDatePlanningUnavailable),
                          if (v['can_joint_share'] == true)
                            OutlinedButton.icon(
                              key: const ValueKey(
                                'qa.blog.exchange.journal_page',
                              ),
                              icon: const Icon(Icons.menu_book_outlined),
                              label: Text(l10n.blogProposeJournalPage),
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
                                        fallback: l10n.blogSourceUnavailable,
                                      ),
                                    );
                                }
                              },
                            ),
                        ] else if ((v['my_story'] as String).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(l10n.blogContributionSaved),
                          ),
                      ],
                      const SizedBox(height: 28),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          TextButton(
                            key: const ValueKey('qa.blog.exchange.withdraw'),
                            onPressed: busy
                                ? null
                                : () async {
                                    if (await confirmBlogAction(
                                      context,
                                      l10n.blogWithdrawExchangeTitle,
                                      l10n.blogWithdrawExchangeMessage,
                                      l10n.blogWithdrawExchange,
                                    ))
                                      await command(v, 'withdraw');
                                  },
                            child: Text(l10n.blogWithdrawExchange),
                          ),
                          TextButton(
                            key: const ValueKey('qa.blog.exchange.report'),
                            onPressed: report,
                            child: Text(l10n.blogReportExchange),
                          ),
                          TextButton(
                            key: const ValueKey('qa.blog.exchange.block'),
                            onPressed: () async {
                              if (!await confirmBlogAction(
                                context,
                                l10n.blogBlockTitle,
                                l10n.blogBlockMessageExchange,
                                l10n.blogBlockMember,
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
                                      fallback: l10n.blogBlockFailed,
                                    ),
                                  );
                              }
                            },
                            child: Text(l10n.blogBlockMember),
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
