import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../matching/providers/match_provider.dart';
import '../plans/screens/propose_date_plan_sheet.dart';
import 'chapter_provider.dart';
import 'comfort_cards_screen.dart';

void openChapterStudio(
  BuildContext context, {
  String? matchId,
  String partnerName = 'your match',
}) {
  Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) =>
          ChapterStudioScreen(matchId: matchId, partnerName: partnerName),
    ),
  );
}

class ChapterStudioScreen extends ConsumerStatefulWidget {
  const ChapterStudioScreen({
    super.key,
    this.matchId,
    this.partnerName = 'your match',
  });
  final String? matchId;
  final String partnerName;
  @override
  ConsumerState<ChapterStudioScreen> createState() => _ChapterStudioState();
}

class _ChapterStudioState extends ConsumerState<ChapterStudioScreen> {
  bool busy = false;
  String? error, sceneId, beginning;
  String pendingChapterId = const Uuid().v4();
  Set<String>? greenDraft;
  int? greenDraftVersion;
  final publicationIds = <String, String>{};
  late final Timer timer;
  String get pairPath => '/matches/${widget.matchId}/chapter';
  static const publicationsPath = '/chapters/publications';
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!busy && mounted) {
        if (widget.matchId != null)
          ref.invalidate(chapterResourceProvider(pairPath));
        ref.invalidate(chapterResourceProvider(publicationsPath));
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>?> send(
    String path,
    Map<String, dynamic> data, {
    bool put = false,
    bool delete = false,
  }) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      final response = delete
          ? await dio.delete<dynamic>(path)
          : put
          ? await dio.put<dynamic>(path, data: data)
          : await dio.post<dynamic>(path, data: data);
      ref.invalidate(chapterResourceProvider(pairPath));
      ref.invalidate(chapterResourceProvider(publicationsPath));
      return (response.data as Map).cast<String, dynamic>();
    } catch (e) {
      if (mounted)
        setState(
          () => error = apiErrorMessage(
            e,
            fallback:
                'We could not confirm the save. Refresh to check before retrying.',
          ),
        );
      return null;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget title(String text) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
  Widget panel(Widget child) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
  Widget choices(
    List<dynamic> options,
    String? selected,
    void Function(String) select,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final option in options)
        ChoiceChip(
          label: Text(option.toString()),
          selected: option == selected,
          onSelected: busy ? null : (_) => select(option.toString()),
        ),
    ],
  );
  Future<void> previewShare(
    Map<dynamic, dynamic> scene,
    String start, {
    Map<dynamic, dynamic>? chapter,
  }) async {
    final joint = chapter != null;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          joint ? 'A story you both approve' : 'Preview your public chapter',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scene['title'].toString(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(start),
              if (joint) Text('Then… ${chapter['surprise']}'),
              const SizedBox(height: 16),
              Text(
                joint
                    ? 'Your approval is one half. The link works only after your partner also approves this exact card. Either of you can revoke it.'
                    : 'Only this scene and your selected beginning are public. No names, photos, private chat, location or partner contribution. You can revoke the link.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep private'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(joint ? 'Approve my half' : 'Create share link'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    // Keep the same ID if the response is lost and this preview is retried.
    final signature = '${chapter?['id'] ?? 'solo'}:${scene['id']}:$start';
    final result = await send(publicationsPath, {
      'action': 'create',
      'id': publicationIds.putIfAbsent(signature, () => const Uuid().v4()),
      'scene': scene['id'],
      'beginning': start,
      if (joint) ...{'chapter_id': chapter['id'], 'match_id': widget.matchId},
    });
    if (result != null) publicationIds.remove(signature);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = Theme.of(context).colorScheme;
    final resource = ref.watch(
      chapterResourceProvider(
        widget.matchId == null ? '/chapters/catalogue' : pairPath,
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('First Chapter Studio'),
        actions: [
          IconButton(
            tooltip: 'Refresh chapter',
            onPressed: busy
                ? null
                : () {
                    ref.invalidate(chapterResourceProvider(pairPath));
                    ref.invalidate(
                      chapterResourceProvider('/chapters/catalogue'),
                    );
                    ref.invalidate(chapterResourceProvider(publicationsPath));
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 56),
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A SMALL ADVENTURE. TWO AUTHORS.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 2,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'What happens\nnext is yours.',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.matchId == null
                          ? 'Make a scene. Pass it to a friend. Or create a first chapter with someone you have matched with.'
                          : 'You and ${widget.partnerName}. One beginning, one unexpected turn, and a story you can make real.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Optional, at your pace. Chat is always a choice.',
                      style: TextStyle(color: colors.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(error!, style: TextStyle(color: colors.error)),
                ),
              resource.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => panel(
                  Column(
                    children: [
                      const Text('Your chapter could not be loaded.'),
                      TextButton(
                        onPressed: () => ref.invalidate(
                          chapterResourceProvider(
                            widget.matchId == null
                                ? '/chapters/catalogue'
                                : pairPath,
                          ),
                        ),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
                data: (data) {
                  final scenes = (data['scenes'] as List? ?? [])
                      .cast<Map<dynamic, dynamic>>();
                  final chapter = data['chapter'] as Map?;
                  final selected = scenes
                      .where((s) => s['id'] == (chapter?['scene'] ?? sceneId))
                      .firstOrNull;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (chapter == null) ...[
                        title('01 / Choose your scene'),
                        for (final scene in scenes)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: OutlinedButton(
                              onPressed: busy
                                  ? null
                                  : () => setState(() {
                                      sceneId = scene['id'].toString();
                                      beginning = null;
                                    }),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      sceneId == scene['id']
                                          ? Icons.check_circle
                                          : Icons.auto_stories_outlined,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            scene['title'].toString(),
                                            style: theme.textTheme.titleMedium,
                                          ),
                                          Text(scene['prompt'].toString()),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (selected != null) ...[
                          title('02 / Write the beginning'),
                          choices(
                            selected['beginnings'] as List,
                            beginning,
                            (value) => setState(() => beginning = value),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              if (widget.matchId != null)
                                FilledButton.icon(
                                  onPressed: busy || beginning == null
                                      ? null
                                      : () async {
                                          final result = await send(pairPath, {
                                            'action': 'start',
                                            'id': pendingChapterId,
                                            'scene': sceneId,
                                            'choice': beginning,
                                          });
                                          if (result != null)
                                            pendingChapterId = const Uuid()
                                                .v4();
                                        },
                                  icon: const Icon(Icons.auto_awesome),
                                  label: const Text('Start our chapter'),
                                ),
                              OutlinedButton.icon(
                                onPressed: busy || beginning == null
                                    ? null
                                    : () => previewShare(selected, beginning!),
                                icon: const Icon(Icons.ios_share),
                                label: const Text('Pass the Chapter'),
                              ),
                            ],
                          ),
                        ],
                      ] else if (selected != null) ...[
                        title('Your first chapter'),
                        panel(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selected['title'].toString(),
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 16),
                              const Text('IT BEGINS WITH'),
                              Text(
                                chapter['beginning'].toString(),
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 20),
                              if (chapter['surprise'] != '') ...[
                                const Text('AND THEN…'),
                                Text(
                                  chapter['surprise'].toString(),
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  onPressed: busy
                                      ? null
                                      : () => showProposeDatePlanSheet(
                                          context: context,
                                          matchId: widget.matchId!,
                                          partnerName: widget.partnerName,
                                          initialNote:
                                              '${chapter['beginning']}. Then ${chapter['surprise']}.',
                                          initialVenueCategory:
                                              selected['venue'].toString(),
                                        ),
                                  icon: const Icon(Icons.event_available),
                                  label: const Text('Make this a date idea'),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'A suggestion to shape together. No date is booked or accepted automatically.',
                                ),
                              ] else if (chapter['my_turn'] == true) ...[
                                const Text('Your turn: add a surprise.'),
                                const SizedBox(height: 12),
                                for (final choice
                                    in selected['surprises'] as List)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: OutlinedButton(
                                      onPressed: busy
                                          ? null
                                          : () => send(pairPath, {
                                              'action': 'surprise',
                                              'id': chapter['id'],
                                              'version': chapter['version'],
                                              'choice': choice,
                                            }),
                                      child: Text(choice.toString()),
                                    ),
                                  ),
                              ] else
                                const Text(
                                  'Your beginning is saved. Your match can add a surprise whenever they like. You can keep chatting.',
                                ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () => send(pairPath, {
                                        'action': 'close',
                                        'id': chapter['id'],
                                        'version': chapter['version'],
                                      }),
                                child: const Text('Close this chapter'),
                              ),
                            ],
                          ),
                        ),
                        if (data['can_give_back'] == true &&
                            chapter['surprise'] != '') ...[
                          title('Stories that give back'),
                          panel(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your connection can inspire a new beginning. Share only this anonymous date idea, with both of your approvals.',
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: busy
                                      ? null
                                      : () => previewShare(
                                          selected,
                                          chapter['beginning'].toString(),
                                          chapter: chapter,
                                        ),
                                  child: const Text(
                                    'Preview our anonymous story',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                      if (widget.matchId != null) ...[
                        title('A private green light'),
                        panel(_greenLight(data)),
                        if ((data['comfort'] as List? ?? []).isNotEmpty) ...[
                          title('In their words'),
                          for (final c in data['comfort'] as List)
                            panel(
                              ComfortCardText(
                                card: Map<String, dynamic>.from(c as Map),
                              ),
                            ),
                        ],
                      ],
                    ],
                  );
                },
              ),
              title('In my words'),
              panel(
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.chat_outlined),
                  title: const Text('Make room for what matters to you'),
                  subtitle: const Text(
                    'Your pace, languages, dates and family expectations. Your words, shared only when you choose.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ComfortCardsScreen(),
                    ),
                  ),
                ),
              ),
              if (widget.matchId == null) ...[
                title('Create with a connection'),
                ...ref
                    .watch(matchNotifierProvider)
                    .matches
                    .map(
                      (m) => panel(
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(m.userName),
                          subtitle: const Text(
                            'Create a first chapter together',
                          ),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () => openChapterStudio(
                            context,
                            matchId: m.id,
                            partnerName: m.userName,
                          ),
                        ),
                      ),
                    ),
                if (ref.watch(matchNotifierProvider).matches.isEmpty)
                  const Text(
                    'Your mutual matches appear here. You can try and share a solo scene now.',
                  ),
              ],
              title('Your shared chapters'),
              ref
                  .watch(chapterResourceProvider(publicationsPath))
                  .when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => TextButton(
                      onPressed: () => ref.invalidate(
                        chapterResourceProvider(publicationsPath),
                      ),
                      child: const Text('Reload shared chapters'),
                    ),
                    data: (data) {
                      final publications = data['publications'] as List? ?? [];
                      if (publications.isEmpty)
                        return const Text(
                          'Nothing public until you choose to share.',
                        );
                      return Column(
                        children: [
                          for (final raw in publications)
                            _publication(Map<String, dynamic>.from(raw as Map)),
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

  Widget _greenLight(Map<dynamic, dynamic> data) {
    final mine = data['mine'] as Map? ?? {};
    final selected =
        greenDraft ?? (mine['choices'] as List? ?? []).cast<String>().toSet();
    final mutual = (data['mutual'] as List? ?? []).cast<String>();
    const labels = {
      'chat': 'Keep chatting',
      'call': 'Try a call',
      'date': 'Suggest a date',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Only a shared choice is revealed. Nobody sees an unanswered request. Choices expire after seven days; clear them to withdraw.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in labels.entries)
              FilterChip(
                label: Text(entry.value),
                selected: selected.contains(entry.key),
                onSelected: busy
                    ? null
                    : (yes) => setState(() {
                        greenDraftVersion ??=
                            (mine['version'] as num?)?.toInt() ?? 0;
                        greenDraft = {...selected};
                        if (yes) {
                          greenDraft!.add(entry.key);
                        } else {
                          greenDraft!.remove(entry.key);
                        }
                      }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  final result = await send('$pairPath/green-light', {
                    'choices': selected.toList(),
                    'version': greenDraftVersion ?? mine['version'] ?? 0,
                  }, put: true);
                  if (result != null && mounted)
                    setState(() {
                      greenDraft = null;
                      greenDraftVersion = null;
                    });
                },
          child: const Text('Save privately'),
        ),
        const SizedBox(height: 16),
        Text(
          mutual.isEmpty
              ? 'Any shared next step will appear here.'
              : 'You both feel comfortable with: ${mutual.map((v) => labels[v]).join(' · ')}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'A green light is permission to suggest. A call or date still needs a separate agreement.',
        ),
      ],
    );
  }

  Widget _publication(Map<String, dynamic> p) => panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p['beginning'].toString(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (p['surprise'] != '') Text('Then… ${p['surprise']}'),
        const SizedBox(height: 10),
        Text(
          p['revoked'] == true
              ? 'Link revoked'
              : p['published'] == true
              ? 'Public, anonymous scene'
              : 'Private until both approve',
        ),
        if (p['revoked'] != true)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (p['published'] == true)
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: chapterShareUrl(p['id'].toString())),
                    );
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Chapter link copied. Share it wherever you choose.',
                          ),
                        ),
                      );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy link'),
                ),
              if (p['my_approval'] != true)
                TextButton(
                  onPressed: busy
                      ? null
                      : () => send(publicationsPath, {
                          'action': 'approve',
                          'id': p['id'],
                          'version': p['version'],
                        }),
                  child: const Text('Approve this exact story'),
                ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => send(
                        '$publicationsPath/${p['id']}',
                        {},
                        delete: true,
                      ),
                child: const Text('Revoke link'),
              ),
            ],
          ),
      ],
    ),
  );
}
