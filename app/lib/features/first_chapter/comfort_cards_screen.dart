import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/network/api_error_message.dart';
import '../../l10n/app_localizations.dart';
import 'chapter_provider.dart';

class ComfortCardText extends StatelessWidget {
  const ComfortCardText({super.key, required this.card});
  final Map<String, dynamic> card;

  /// Topic ids in the order they are offered.
  static const topics = ['pace', 'dates', 'language', 'family'];

  /// The display name of a topic id; unknown ids fall back to "In my words".
  static String topicLabel(AppLocalizations l10n, Object? topic) =>
      switch (topic) {
        'pace' => l10n.firstChapterTopicPace,
        'dates' => l10n.firstChapterTopicDates,
        'language' => l10n.firstChapterTopicLanguage,
        'family' => l10n.firstChapterTopicFamily,
        _ => l10n.firstChapterInMyWords,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          topicLabel(l10n, card['topic']),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(l10n.firstChapterComfortOriginal(card['language'].toString())),
        Text(
          card['original'].toString(),
          textDirection: _direction(card['language'].toString()),
        ),
        if ((card['translation'] ?? '') != '') ...[
          const SizedBox(height: 12),
          Text(
            l10n.firstChapterComfortMemberTranslation(
              card['translation_language'].toString(),
            ),
          ),
          Text(
            card['translation'].toString(),
            textDirection: _direction(card['translation_language'].toString()),
          ),
        ],
      ],
    );
  }

  TextDirection? _direction(String language) =>
      [
        'arabic',
        'hebrew',
        'urdu',
        'فارسی',
        'العربية',
        'עברית',
        'اردو',
        'ar',
        'he',
        'ur',
        'fa',
      ].contains(language.toLowerCase())
      ? TextDirection.rtl
      : null;
}

class ComfortCardsScreen extends ConsumerStatefulWidget {
  const ComfortCardsScreen({super.key});
  @override
  ConsumerState<ComfortCardsScreen> createState() => _ComfortCardsState();
}

class _ComfortCardsState extends ConsumerState<ComfortCardsScreen> {
  static const path = '/chapters/comfort';
  final original = TextEditingController(),
      language = TextEditingController(text: 'English'),
      translation = TextEditingController(),
      translatedLanguage = TextEditingController();
  String topic = 'pace';
  List<Map<String, dynamic>>? cards;
  bool? shared;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    original.dispose();
    language.dispose();
    translation.dispose();
    translatedLanguage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.firstChapterInMyWords),
        actions: [
          IconButton(
            tooltip: l10n.firstChapterComfortReloadSaved,
            onPressed: busy
                ? null
                : () => ref.invalidate(chapterResourceProvider(path)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ref
              .watch(chapterResourceProvider(path))
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => TextButton(
                  onPressed: () =>
                      ref.invalidate(chapterResourceProvider(path)),
                  child: Text(l10n.firstChapterComfortReloadCards),
                ),
                data: (data) {
                  final current =
                      cards ??
                      (data['cards'] as List? ?? [])
                          .map((c) => Map<String, dynamic>.from(c as Map))
                          .toList();
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        l10n.firstChapterComfortHeadline,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(l10n.firstChapterComfortIntro),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.firstChapterComfortShareTitle),
                        subtitle: Text(l10n.firstChapterComfortShareSubtitle),
                        value: shared ?? data['shared'] == true,
                        onChanged: busy
                            ? null
                            : (v) => setState(() => shared = v),
                      ),
                      for (final card in current)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ComfortCardText(card: card),
                                TextButton(
                                  onPressed: busy
                                      ? null
                                      : () => setState(
                                          () => cards = current
                                              .where(
                                                (c) =>
                                                    c['topic'] != card['topic'],
                                              )
                                              .toList(),
                                        ),
                                  child: Text(
                                    l10n.firstChapterComfortRemoveFromDraft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        initialValue: topic,
                        decoration: InputDecoration(
                          labelText: l10n.firstChapterComfortTopicLabel,
                        ),
                        items: [
                          for (final id in ComfortCardText.topics)
                            DropdownMenuItem(
                              value: id,
                              child: Text(ComfortCardText.topicLabel(l10n, id)),
                            ),
                        ],
                        onChanged: busy
                            ? null
                            : (v) => setState(() => topic = v!),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: language,
                        maxLength: 35,
                        decoration: InputDecoration(
                          labelText: l10n.firstChapterComfortOriginalLanguage,
                        ),
                      ),
                      TextField(
                        controller: original,
                        maxLength: 280,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: l10n.firstChapterComfortOwnWords,
                          hintText: l10n.firstChapterComfortOwnWordsHint,
                        ),
                      ),
                      TextField(
                        controller: translation,
                        maxLength: 280,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: l10n.firstChapterComfortTranslation,
                        ),
                      ),
                      TextField(
                        controller: translatedLanguage,
                        maxLength: 35,
                        decoration: InputDecoration(
                          labelText:
                              l10n.firstChapterComfortTranslationLanguage,
                        ),
                      ),
                      Text(l10n.firstChapterComfortTranslationNote),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () {
                                if (original.text.trim().isEmpty ||
                                    language.text.trim().length < 2 ||
                                    (translation.text.isNotEmpty &&
                                        translatedLanguage.text.trim().length <
                                            2)) {
                                  setState(
                                    () => error =
                                        l10n.firstChapterComfortMissingFields,
                                  );
                                  return;
                                }
                                setState(() {
                                  cards = [
                                    ...current.where(
                                      (c) => c['topic'] != topic,
                                    ),
                                    {
                                      'topic': topic,
                                      'original': original.text.trim(),
                                      'language': language.text.trim(),
                                      'translation': translation.text.trim(),
                                      'translation_language':
                                          translation.text.trim().isEmpty
                                          ? ''
                                          : translatedLanguage.text.trim(),
                                    },
                                  ];
                                  error = null;
                                });
                                original.clear();
                                translation.clear();
                                translatedLanguage.clear();
                              },
                        child: Text(l10n.firstChapterComfortAddCard),
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      FilledButton(
                        onPressed: busy
                            ? null
                            : () async {
                                if (original.text.trim().isNotEmpty) {
                                  setState(
                                    () => error =
                                        l10n.firstChapterComfortUnaddedCard,
                                  );
                                  return;
                                }
                                setState(() {
                                  busy = true;
                                  error = null;
                                });
                                try {
                                  await ref
                                      .read(apiClientProvider)
                                      .put<dynamic>(
                                        path,
                                        data: {
                                          'cards': current,
                                          'shared':
                                              shared ?? data['shared'] == true,
                                          'version': data['version'],
                                        },
                                      );
                                  ref.invalidate(chapterResourceProvider(path));
                                  if (mounted) Navigator.pop(context);
                                } catch (e) {
                                  if (mounted)
                                    setState(
                                      () => error = apiErrorMessage(
                                        e,
                                        fallback:
                                            l10n.firstChapterComfortSaveFailed,
                                      ),
                                    );
                                } finally {
                                  if (mounted) setState(() => busy = false);
                                }
                              },
                        child: Text(
                          busy
                              ? l10n.firstChapterSaving
                              : l10n.firstChapterComfortSave,
                        ),
                      ),
                    ],
                  );
                },
              ),
        ),
      ),
    );
  }
}
