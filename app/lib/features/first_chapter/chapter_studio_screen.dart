import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../matching/providers/match_provider.dart';
import '../plans/screens/propose_date_plan_sheet.dart';
import '../../l10n/app_localizations.dart';
import 'chapter_provider.dart';
import 'comfort_cards_screen.dart';

void openChapterStudio(
  BuildContext context, {
  String? matchId,
  String? partnerName,
}) {
  Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) =>
          ChapterStudioScreen(matchId: matchId, partnerName: partnerName),
    ),
  );
}

class ChapterStudioScreen extends ConsumerStatefulWidget {
  const ChapterStudioScreen({super.key, this.matchId, this.partnerName});
  final String? matchId;

  /// The match's name; null shows a localized "your match".
  final String? partnerName;
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
  AppLocalizations get l10n => AppLocalizations.of(context);
  String get partnerName => widget.partnerName ?? l10n.firstChapterYourMatch;
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
            fallback: l10n.firstChapterSaveUnconfirmed,
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
          joint
              ? l10n.firstChapterJointPreviewTitle
              : l10n.firstChapterSoloPreviewTitle,
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
              if (joint)
                Text(
                  l10n.firstChapterThenSurprise(chapter['surprise'].toString()),
                ),
              const SizedBox(height: 16),
              Text(
                joint
                    ? l10n.firstChapterJointPreviewBody
                    : l10n.firstChapterSoloPreviewBody,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.firstChapterKeepPrivate),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              joint
                  ? l10n.firstChapterApproveMyHalf
                  : l10n.firstChapterCreateShareLink,
            ),
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
        title: Text(l10n.firstChapterStudioTitle),
        actions: [
          IconButton(
            tooltip: l10n.firstChapterRefresh,
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
                      l10n.firstChapterHeroEyebrow,
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 2,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.firstChapterHeroTitle,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.matchId == null
                          ? l10n.firstChapterHeroSolo
                          : l10n.firstChapterHeroPair(partnerName),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.firstChapterHeroPace,
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
                      Text(l10n.firstChapterLoadFailed),
                      TextButton(
                        onPressed: () => ref.invalidate(
                          chapterResourceProvider(
                            widget.matchId == null
                                ? '/chapters/catalogue'
                                : pairPath,
                          ),
                        ),
                        child: Text(l10n.firstChapterTryAgain),
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
                        title(l10n.firstChapterStepChooseScene),
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
                          title(l10n.firstChapterStepWriteBeginning),
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
                                  label: Text(l10n.firstChapterStartOurChapter),
                                ),
                              OutlinedButton.icon(
                                onPressed: busy || beginning == null
                                    ? null
                                    : () => previewShare(selected, beginning!),
                                icon: const Icon(Icons.ios_share),
                                label: Text(l10n.firstChapterPassTheChapter),
                              ),
                            ],
                          ),
                        ],
                      ] else if (selected != null) ...[
                        title(l10n.firstChapterYourFirstChapter),
                        panel(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selected['title'].toString(),
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 16),
                              Text(l10n.firstChapterItBeginsWith),
                              Text(
                                chapter['beginning'].toString(),
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: 20),
                              if (chapter['surprise'] != '') ...[
                                Text(l10n.firstChapterAndThen),
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
                                          partnerName: partnerName,
                                          initialNote: l10n
                                              .firstChapterDateIdeaNote(
                                                chapter['beginning'].toString(),
                                                chapter['surprise'].toString(),
                                              ),
                                          initialVenueCategory:
                                              selected['venue'].toString(),
                                        ),
                                  icon: const Icon(Icons.event_available),
                                  label: Text(l10n.firstChapterMakeDateIdea),
                                ),
                                const SizedBox(height: 8),
                                Text(l10n.firstChapterDateIdeaHint),
                              ] else if (chapter['my_turn'] == true) ...[
                                Text(l10n.firstChapterYourTurn),
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
                                Text(l10n.firstChapterBeginningSaved),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () => send(pairPath, {
                                        'action': 'close',
                                        'id': chapter['id'],
                                        'version': chapter['version'],
                                      }),
                                child: Text(l10n.firstChapterClose),
                              ),
                            ],
                          ),
                        ),
                        if (data['can_give_back'] == true &&
                            chapter['surprise'] != '') ...[
                          title(l10n.firstChapterGiveBackTitle),
                          panel(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.firstChapterGiveBackBody),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: busy
                                      ? null
                                      : () => previewShare(
                                          selected,
                                          chapter['beginning'].toString(),
                                          chapter: chapter,
                                        ),
                                  child: Text(
                                    l10n.firstChapterPreviewAnonymous,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                      if (widget.matchId != null) ...[
                        title(l10n.firstChapterGreenLightTitle),
                        panel(_greenLight(data)),
                        if ((data['comfort'] as List? ?? []).isNotEmpty) ...[
                          title(l10n.firstChapterInTheirWords),
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
              title(l10n.firstChapterInMyWords),
              panel(
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.chat_outlined),
                  title: Text(l10n.firstChapterMakeRoomTitle),
                  subtitle: Text(l10n.firstChapterMakeRoomSubtitle),
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
                title(l10n.firstChapterCreateWithConnection),
                ...ref
                    .watch(matchNotifierProvider)
                    .matches
                    .map(
                      (m) => panel(
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(m.userName),
                          subtitle: Text(l10n.firstChapterCreateTogether),
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
                  Text(l10n.firstChapterMatchesAppearHere),
              ],
              title(l10n.firstChapterSharedChapters),
              ref
                  .watch(chapterResourceProvider(publicationsPath))
                  .when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => TextButton(
                      onPressed: () => ref.invalidate(
                        chapterResourceProvider(publicationsPath),
                      ),
                      child: Text(l10n.firstChapterReloadShared),
                    ),
                    data: (data) {
                      final publications = data['publications'] as List? ?? [];
                      if (publications.isEmpty)
                        return Text(l10n.firstChapterNothingPublic);
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
    final labels = {
      'chat': l10n.firstChapterGreenChat,
      'call': l10n.firstChapterGreenCall,
      'date': l10n.firstChapterGreenDate,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.firstChapterGreenLightIntro),
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
          child: Text(l10n.firstChapterSavePrivately),
        ),
        const SizedBox(height: 16),
        Text(
          mutual.isEmpty
              ? l10n.firstChapterGreenLightNone
              : l10n.firstChapterGreenLightMutual(
                  mutual.map((v) => labels[v]).join(' · '),
                ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(l10n.firstChapterGreenLightNote),
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
        if (p['surprise'] != '')
          Text(l10n.firstChapterThenSurprise(p['surprise'].toString())),
        const SizedBox(height: 10),
        Text(
          p['revoked'] == true
              ? l10n.firstChapterLinkRevoked
              : p['published'] == true
              ? l10n.firstChapterPublicScene
              : l10n.firstChapterPrivateUntilBoth,
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
                        SnackBar(content: Text(l10n.firstChapterLinkCopied)),
                      );
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(l10n.firstChapterCopyLink),
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
                  child: Text(l10n.firstChapterApproveStory),
                ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => send(
                        '$publicationsPath/${p['id']}',
                        {},
                        delete: true,
                      ),
                child: Text(l10n.firstChapterRevokeLink),
              ),
            ],
          ),
      ],
    ),
  );
}
