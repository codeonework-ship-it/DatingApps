import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/network/api_error_message.dart';
import 'chapter_provider.dart';

class ComfortCardText extends StatelessWidget {
  const ComfortCardText({super.key, required this.card});
  final Map<String, dynamic> card;
  static const topics = {
    'pace': 'Communication pace',
    'dates': 'Dating comfort',
    'language': 'Languages',
    'family': 'Family involvement',
  };
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        topics[card['topic']] ?? 'In my words',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      Text('Original · ${card['language']}'),
      Text(
        card['original'].toString(),
        textDirection: _direction(card['language'].toString()),
      ),
      if ((card['translation'] ?? '') != '') ...[
        const SizedBox(height: 12),
        Text('Member-provided translation · ${card['translation_language']}'),
        Text(
          card['translation'].toString(),
          textDirection: _direction(card['translation_language'].toString()),
        ),
      ],
    ],
  );
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('In my words'),
      actions: [
        IconButton(
          tooltip: 'Reload saved version',
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
                onPressed: () => ref.invalidate(chapterResourceProvider(path)),
                child: const Text('Reload comfort cards'),
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
                      'Your words. Your boundaries.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Optional context for people you have matched with. Nothing is inferred from your background. Write in the language that feels like you.',
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Share these cards with my matches'),
                      subtitle: const Text('Off keeps every card private.'),
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
                                child: const Text('Remove from draft'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: topic,
                      decoration: const InputDecoration(
                        labelText: 'A little context about',
                      ),
                      items: [
                        for (final entry in ComfortCardText.topics.entries)
                          DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
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
                      decoration: const InputDecoration(
                        labelText: 'Original language',
                      ),
                    ),
                    TextField(
                      controller: original,
                      maxLength: 280,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'In your own words',
                        hintText:
                            'For example: I enjoy daytime dates and a little time to get comfortable.',
                      ),
                    ),
                    TextField(
                      controller: translation,
                      maxLength: 280,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Your translation (optional)',
                      ),
                    ),
                    TextField(
                      controller: translatedLanguage,
                      maxLength: 35,
                      decoration: const InputDecoration(
                        labelText: 'Translation language (if added)',
                      ),
                    ),
                    const Text(
                      'Translations are labelled as member-provided. Your original words are always preserved.',
                    ),
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
                                      'Add your words and language. A translation also needs its language.',
                                );
                                return;
                              }
                              setState(() {
                                cards = [
                                  ...current.where((c) => c['topic'] != topic),
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
                      child: const Text('Add / replace this card in draft'),
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
                                      'Add your written card to the draft before saving.',
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
                                          'Your draft is still here. Reload to check the latest saved version before retrying.',
                                    ),
                                  );
                              } finally {
                                if (mounted) setState(() => busy = false);
                              }
                            },
                      child: Text(busy ? 'Saving…' : 'Save my choices'),
                    ),
                  ],
                );
              },
            ),
      ),
    ),
  );
}
