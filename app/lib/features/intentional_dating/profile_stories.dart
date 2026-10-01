import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/providers/auth_provider.dart';

const storyPrompts = <String, String>{
  'little_joy': 'A small thing I always make time for',
  'weekend': 'A weekend worth sharing',
  'first_hello': 'A first hello I would love',
  'learning': 'Something I am learning, just for me',
  'care': 'A small way I show I care',
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
    return Scaffold(
      appBar: AppBar(title: const Text('A little more you')),
      body: user == null
          ? const Center(child: Text('Sign in to edit your stories.'))
          : ref
                .watch(profileStoriesProvider(user))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Your stories couldn’t load.'),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(profileStoriesProvider(user)),
                          child: const Text('Try again'),
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
    final invalid = stories.any(
      (s) =>
          (s['text'] as String? ?? '').trim().isEmpty ||
          ((s['photo_id'] as String? ?? '').isNotEmpty &&
              (s['photo_description'] as String? ?? '').trim().isEmpty),
    );
    if (invalid || !form.currentState!.validate()) {
      setState(() {
        preview = false;
        error =
            'Add words to each story and a description for each photo, or remove the unfinished story.';
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
                  .map(
                    (s) => {
                      'prompt_id': s['prompt_id'],
                      'text': s['text'] ?? '',
                      if ((s['photo_id'] as String? ?? '').isNotEmpty)
                        'photo_id': s['photo_id'],
                      if ((s['photo_id'] as String? ?? '').isNotEmpty)
                        'photo_description': s['photo_description'] ?? '',
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
                ? 'Your profile stories are published.'
                : 'Saved privately. Your stories are hidden from other members.',
          ),
        ),
      );
      ref.invalidate(profileStoriesProvider(widget.user));
    } on Object catch (e) {
      if (mounted)
        setState(
          () => error = apiErrorMessage(
            e,
            fallback:
                'We couldn’t confirm the save. Your edits are still here; reload saved stories to check.',
          ),
        );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Let someone meet\nthe everyday you.',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontFamily: AppTheme.displayFamily,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'A small ritual, a story behind a photo, a first hello you would enjoy. Share up to three moments, in your own words.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Optional, with no score or completion requirement. Avoid contact details or precise locations you do not want to share.',
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              key: const ValueKey('qa.stories.publish'),
              title: const Text('Show these stories on my profile'),
              subtitle: const Text(
                'Starts off. Visible to eligible members when your profile is published and available. You can hide them at any time.',
              ),
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
                label: Text(preview ? 'Back to editing' : 'Preview my stories'),
              ),
            if (preview) ...[
              const Text('PREVIEW · THIS DOES NOT PUBLISH'),
              const SizedBox(height: 12),
              for (final story in stories) StoryMomentCard(story: story),
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
                  label: const Text('Add a story'),
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
                    : () => ref.invalidate(profileStoriesProvider(widget.user)),
                child: const Text('Reload saved stories · discard edits'),
              ),
            ],
            FilledButton(
              key: const ValueKey('qa.stories.save'),
              onPressed: saving ? null : save,
              child: Text(
                saving
                    ? 'Saving…'
                    : published && stories.isNotEmpty
                    ? 'Publish stories'
                    : 'Save privately',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Photos come from your approved profile gallery. Stories and photos remain subject to member reporting and safety policies.',
            ),
          ],
        ),
      ),
    ),
  );
  Widget _editor(Map<String, dynamic> story, int index) => Card(
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
                  'MOMENT ${index + 1}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                tooltip: 'Remove story ${index + 1}',
                onPressed: saving
                    ? null
                    : () => setState(() => stories.remove(story)),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: story['prompt_id'] as String,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'A starting point'),
            items: storyPrompts.entries
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
          TextFormField(
            key: ValueKey('qa.stories.text.${story['_key']}'),
            initialValue: story['text'] as String? ?? '',
            minLines: 3,
            maxLines: 7,
            maxLength: 400,
            enabled: !saving,
            decoration: const InputDecoration(
              labelText: 'In your words',
              hintText: 'A real detail makes it yours.',
            ),
            validator: (v) => (v ?? '').trim().isEmpty
                ? 'Add a few words, or remove this story.'
                : null,
            onChanged: (v) => story['text'] = v,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: story['photo_id'] as String? ?? '',
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'A photo, if you like',
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Words only')),
              for (var p = 0; p < photos.length; p++)
                DropdownMenuItem(
                  value: photos[p]['id'] as String,
                  child: Text('Profile photo ${p + 1}'),
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
              maxLength: 160,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'Describe this photo',
                helperText: 'Helps people using screen readers.',
              ),
              validator: (v) => (v ?? '').trim().isEmpty
                  ? 'Add a short photo description.'
                  : null,
              onChanged: (v) => story['photo_description'] = v,
            ),
          ],
        ],
      ),
    ),
  );
}

class StoryMomentCard extends StatelessWidget {
  const StoryMomentCard({super.key, required this.story});
  final Map<String, dynamic> story;
  @override
  Widget build(BuildContext context) {
    final photo = story['photo_url'] as String? ?? '';
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photo.isNotEmpty)
            Semantics(
              image: true,
              label:
                  story['photo_description'] as String? ??
                  'Profile story photo',
              child: ExcludeSemantics(
                child: AspectRatio(
                  aspectRatio: 1.5,
                  child: Image.network(
                    photo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storyPrompts[story['prompt_id']] ?? 'A little more me',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  story['text'] as String? ?? '',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

class ProfileStoriesSection extends ConsumerWidget {
  const ProfileStoriesSection({super.key, required this.userId});
  final String userId;
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
                child: const Text('Try loading stories again'),
              ),
        data: (data) {
          final stories = (data['stories'] as List? ?? [])
              .whereType<Map<dynamic, dynamic>>()
              .toList();
          if (stories.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'A little more me',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              for (final story in stories)
                StoryMomentCard(story: story.cast<String, dynamic>()),
            ],
          );
        },
      );
}
