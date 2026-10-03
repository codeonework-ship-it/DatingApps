import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/rich_text/rich_document.dart';
import '../../core/rich_text/rich_document_view.dart';
import '../../core/rich_text/rich_text_controller.dart';
import '../../core/rich_text/rich_text_editor.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';

const storyPrompts = <String, String>{
  'little_joy': 'A small thing I always make time for',
  'weekend': 'A weekend worth sharing',
  'first_hello': 'A first hello I would love',
  'learning': 'Something I am learning, just for me',
  'care': 'A small way I show I care',
};

/// The story prompts in [storyPrompts] order, labelled in the member's
/// language. The ids are what the server stores and must not change.
Map<String, String> localizedStoryPrompts(AppLocalizations l10n) => {
  for (final id in storyPrompts.keys) id: storyPromptLabel(l10n, id)!,
};

/// The localized label for a story prompt id, or null for an unknown id.
String? storyPromptLabel(AppLocalizations l10n, Object? id) => switch (id) {
  'little_joy' => l10n.storiesPromptLittleJoy,
  'weekend' => l10n.storiesPromptWeekend,
  'first_hello' => l10n.storiesPromptFirstHello,
  'learning' => l10n.storiesPromptLearning,
  'care' => l10n.storiesPromptCare,
  _ => null,
};
final profileStoriesProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, user) async {
      ref.watch(authNotifierProvider.select((s) => s.userId));
      final response = await ref
          .read(apiClientProvider)
          .get<dynamic>('/profile/$user/stories');
      return (response.data as Map).cast<String, dynamic>();
    });

Future<void> openProfileStories(BuildContext context) => Navigator.of(
  context,
).push<void>(MaterialPageRoute(builder: (_) => const ProfileStoriesScreen()));

class ProfileStoriesScreen extends ConsumerWidget {
  const ProfileStoriesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).userId;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.storiesScreenTitle)),
      body: user == null
          ? Center(child: Text(l10n.storiesSignIn))
          : ref
                .watch(profileStoriesProvider(user))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.storiesLoadFailed),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(profileStoriesProvider(user)),
                          child: Text(l10n.storiesTryAgain),
                        ),
                      ],
                    ),
                  ),
                  data: (data) => _StoryEditor(
                    key: ValueKey('$user:${data['version']}'),
                    user: user,
                    initial: data,
                  ),
                ),
    );
  }
}

class _StoryEditor extends ConsumerStatefulWidget {
  const _StoryEditor({super.key, required this.user, required this.initial});
  final String user;
  final Map<String, dynamic> initial;
  @override
  ConsumerState<_StoryEditor> createState() => _StoryEditorState();
}

class _StoryEditorState extends ConsumerState<_StoryEditor> {
  final form = GlobalKey<FormState>();
  late List<Map<String, dynamic>> stories;
  late bool published;
  bool saving = false, preview = false;
  int sequence = 0;
  String? error;

  /// One formatted editor per story, keyed by the story's local `_key`.
  final editors = <Object?, RichTextController>{};
  RichTextController editorFor(Map<String, dynamic> story) =>
      editors.putIfAbsent(
        story['_key'],
        () => RichTextController(
          document: storyDocument(story),
          style: defaultStoryStyle,
        ),
      );

  @override
  void dispose() {
    for (final c in editors.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// The story as the server will store it (text derived from the editor).
  Map<String, dynamic> current(Map<String, dynamic> story) {
    final editor = editorFor(story);
    return {
      ...story,
      'text': editor.text.trim(),
      'content': editor.document.toJson(),
    };
  }

  List<Map<String, dynamic>> get photos =>
      (widget.initial['photos'] as List? ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map((v) => v.cast<String, dynamic>())
          .toList();
  @override
  void initState() {
    super.initState();
    stories = (widget.initial['stories'] as List? ?? [])
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (v) => <String, dynamic>{
            ...v.cast<String, dynamic>(),
            '_key': sequence++,
          },
        )
        .toList();
    published = widget.initial['published'] == true;
  }

  Future<void> save() async {
    final l10n = AppLocalizations.of(context);
    final invalid = stories.any(
      (s) =>
          editorFor(s).text.trim().isEmpty ||
          ((s['photo_id'] as String? ?? '').isNotEmpty &&
              (s['photo_description'] as String? ?? '').trim().isEmpty),
    );
    // Validate every field even when the check above already failed, so
    // the member sees which field needs words.
    final fieldsValid = form.currentState!.validate();
    if (invalid || !fieldsValid) {
      setState(() {
        preview = false;
        error = l10n.storiesIncomplete;
      });
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await ref
          .read(apiClientProvider)
          .put<dynamic>(
            '/profile/${widget.user}/stories',
            data: {
              'expected_version': widget.initial['version'] ?? 0,
              'published': stories.isNotEmpty && published,
              'stories': stories
                  .map(current)
                  .map(
                    (s) => {
                      'prompt_id': s['prompt_id'],
                      // Derived from content on the server.
                      'text': s['text'] ?? '',
                      'content': s['content'],
                      if ((s['photo_id'] as String? ?? '').isNotEmpty)
                        'photo_id': s['photo_id'],
                      if ((s['photo_id'] as String? ?? '').isNotEmpty)
                        'photo_description':
                            (s['photo_description'] as String? ?? '').trim(),
                    },
                  )
                  .toList(),
            },
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            published && stories.isNotEmpty
                ? l10n.storiesPublished
                : l10n.storiesSavedPrivately,
          ),
        ),
      );
      ref.invalidate(profileStoriesProvider(widget.user));
    } on Object catch (e) {
      if (mounted)
        setState(
          () =>
              error = apiErrorMessage(e, fallback: l10n.storiesSaveUnconfirmed),
        );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                l10n.storiesHeadline,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontFamily: AppTheme.displayFamily,
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.storiesIntro),
              const SizedBox(height: 12),
              Text(l10n.storiesOptionalNote),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                key: const ValueKey('qa.stories.publish'),
                title: Text(l10n.storiesPublishSwitch),
                subtitle: Text(l10n.storiesPublishSwitchHint),
                value: published,
                onChanged: saving ? null : (v) => setState(() => published = v),
              ),
              if (stories.isNotEmpty)
                TextButton.icon(
                  onPressed: saving
                      ? null
                      : () => setState(() => preview = !preview),
                  icon: Icon(
                    preview ? Icons.edit_outlined : Icons.visibility_outlined,
                  ),
                  label: Text(
                    preview ? l10n.storiesBackToEditing : l10n.storiesPreview,
                  ),
                ),
              if (preview) ...[
                Text(l10n.storiesPreviewBanner),
                const SizedBox(height: 12),
                for (final story in stories)
                  StoryMomentCard(story: current(story)),
              ] else ...[
                for (var i = 0; i < stories.length; i++) _editor(stories[i], i),
                if (stories.length < 3)
                  OutlinedButton.icon(
                    key: const ValueKey('qa.stories.add'),
                    onPressed: saving
                        ? null
                        : () => setState(() {
                            stories.add({
                              '_key': sequence++,
                              'prompt_id': storyPrompts.keys.firstWhere(
                                (p) => !stories.any((s) => s['prompt_id'] == p),
                              ),
                              'text': '',
                            });
                          }),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.storiesAdd),
                  ),
              ],
              const SizedBox(height: 20),
              if (error != null) ...[
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton(
                  onPressed: saving
                      ? null
                      : () =>
                            ref.invalidate(profileStoriesProvider(widget.user)),
                  child: Text(l10n.storiesReloadDiscard),
                ),
              ],
              FilledButton(
                key: const ValueKey('qa.stories.save'),
                onPressed: saving ? null : save,
                child: Text(
                  saving
                      ? l10n.storiesSaving
                      : published && stories.isNotEmpty
                      ? l10n.storiesPublishButton
                      : l10n.storiesSavePrivatelyButton,
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.storiesPolicyNote),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editor(Map<String, dynamic> story, int index) {
    final l10n = AppLocalizations.of(context);
    return Card(
      key: ValueKey(story['_key']),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.storiesMomentLabel(index + 1),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                IconButton(
                  tooltip: l10n.storiesRemoveTooltip(index + 1),
                  onPressed: saving
                      ? null
                      : () => setState(() {
                          stories.remove(story);
                          editors.remove(story['_key'])?.dispose();
                        }),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: story['prompt_id'] as String,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.storiesPromptLabel),
              items: localizedStoryPrompts(l10n).entries
                  .where(
                    (e) =>
                        e.key == story['prompt_id'] ||
                        !stories.any((s) => s['prompt_id'] == e.key),
                  )
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(
                        e.value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: saving
                  ? null
                  : (v) => setState(() => story['prompt_id'] = v),
            ),
            const SizedBox(height: 16),
            RichTextEditor(
              controller: editorFor(story),
              fieldKey: ValueKey('qa.stories.text.${story['_key']}'),
              keyPrefix: 'stories.editor.${story['_key']}',
              minLines: 3,
              maxLines: 7,
              maxLength: 400,
              enabled: !saving,
              label: l10n.storiesTextLabel,
              hint: l10n.storiesTextHint,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.storiesTextRequired : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: story['photo_id'] as String? ?? '',
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.storiesPhotoLabel),
              items: [
                DropdownMenuItem(value: '', child: Text(l10n.storiesWordsOnly)),
                for (var p = 0; p < photos.length; p++)
                  DropdownMenuItem(
                    value: photos[p]['id'] as String,
                    child: Text(l10n.storiesProfilePhoto(p + 1)),
                  ),
              ],
              onChanged: saving
                  ? null
                  : (id) => setState(() {
                      story['photo_id'] = id;
                      story['photo_url'] = id == ''
                          ? ''
                          : photos.firstWhere((p) => p['id'] == id)['url'];
                    }),
            ),
            if ((story['photo_id'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              TextFormField(
                initialValue: story['photo_description'] as String? ?? '',
                maxLength: storyPhotoDescriptionMax,
                // maxLength counts what the eye sees (a family emoji is one);
                // the server counts code points, so cap those too.
                inputFormatters: const [
                  CodePointLimitFormatter(storyPhotoDescriptionMax),
                ],
                enabled: !saving,
                decoration: InputDecoration(
                  labelText: l10n.storiesPhotoDescriptionLabel,
                  helperText: l10n.storiesPhotoDescriptionHelper,
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? l10n.storiesPhotoDescriptionRequired
                    : null,
                onChanged: (v) => story['photo_description'] = v,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The longest photo description the server accepts, in code points.
const storyPhotoDescriptionMax = 160;

/// Caps text at [max] Unicode code points (runes), the unit the server
/// counts. A longer paste is cut at the limit, on a whole character, so a
/// joined emoji is never left half.
class CodePointLimitFormatter extends TextInputFormatter {
  const CodePointLimitFormatter(this.max);
  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.runes.length <= max) {
      return newValue;
    }
    final kept = StringBuffer();
    var count = 0;
    for (final character in newValue.text.characters) {
      final runes = character.runes.length;
      if (count + runes > max) {
        break;
      }
      kept.write(character);
      count += runes;
    }
    final text = kept.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// A story's formatting. With [plainFallback], plain-text stories open as
/// paragraphs in the default story style (for editing); otherwise null.
RichDocument? storyDocument(
  Map<String, dynamic> story, {
  bool plainFallback = true,
}) =>
    RichDocument.tryParse(story['content'], fallbackStyle: defaultStoryStyle) ??
    (plainFallback
        ? RichDocument.fromPlainText(
            story['text'] as String? ?? '',
            style: defaultStoryStyle,
          )
        : null);

/// One story as a scene card: a widescreen still (when the story has a
/// photo), the prompt as a small title and the member's words in their
/// writing style.
class StoryMomentCard extends StatelessWidget {
  const StoryMomentCard({required this.story, super.key});
  final Map<String, dynamic> story;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final photo = story['photo_url'] as String? ?? '';
    final description = (story['photo_description'] as String? ?? '').trim();
    final l10n = AppLocalizations.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (photo.isNotEmpty)
            Semantics(
              image: true,
              label: description.isEmpty
                  ? l10n.storiesPhotoSemantics
                  : description,
              child: ExcludeSemantics(
                child: AspectRatio(
                  // A widescreen still, like a frame from the member's day.
                  aspectRatio: 1.85,
                  child: Image.network(
                    photo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            scheme.primaryContainer,
                            scheme.tertiaryContainer,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.photo_camera_back_outlined,
                          size: 32,
                          color: scheme.onPrimaryContainer.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, right: 8),
                      child: Container(
                        width: 16,
                        height: 2,
                        color: scheme.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        storyPromptLabel(l10n, story['prompt_id']) ??
                            l10n.storiesSectionTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Formatted stories use their writing style; plain stories
                // keep the original look.
                RichBody(
                  document: storyDocument(story, plainFallback: false),
                  plainText: story['text'] as String? ?? '',
                  selectable: false,
                  scale: 1.2,
                  legacyStyle: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: AppTheme.displayFamily,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A member's published stories on their profile. Renders nothing while
/// loading, when there are none, or when they are not published (so a
/// member previewing their own profile sees what others see).
///
/// [frame] wraps the cards in the host's own section styling; by default
/// they sit under a "A little more me" heading.
class ProfileStoriesSection extends ConsumerWidget {
  const ProfileStoriesSection({required this.userId, super.key, this.frame});
  final String userId;
  final Widget Function(BuildContext context, Widget stories)? frame;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(profileStoriesProvider(userId))
      .when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) =>
            e is DioException && [403, 404].contains(e.response?.statusCode)
            ? const SizedBox.shrink()
            : TextButton(
                onPressed: () => ref.invalidate(profileStoriesProvider(userId)),
                child: Text(AppLocalizations.of(context).storiesRetryLoad),
              ),
        data: (data) {
          final stories = (data['stories'] as List? ?? [])
              .whereType<Map<dynamic, dynamic>>()
              .toList();
          if (stories.isEmpty || data['published'] == false) {
            return const SizedBox.shrink();
          }
          final cards = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final story in stories)
                StoryMomentCard(story: story.cast<String, dynamic>()),
            ],
          );
          final framed = frame;
          if (framed != null) {
            return framed(context, cards);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).storiesSectionTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: AppTheme.displayFamily,
                ),
              ),
              const SizedBox(height: 12),
              cards,
            ],
          );
        },
      );
}
