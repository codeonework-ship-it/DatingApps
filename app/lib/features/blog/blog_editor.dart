import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/providers/auth_provider.dart';
import 'blog_data.dart';
import 'blog_follow.dart';
import 'blog_screen.dart';

/// A stable post ID and expected version survive retries for the lifetime of the
/// editor. A failed save never discards local text or silently publishes it.
class BlogEditor extends ConsumerStatefulWidget {
  const BlogEditor({super.key, this.initial});
  final BlogPost? initial;
  @override
  ConsumerState<BlogEditor> createState() => _BlogEditorState();
}

class _BlogEditorState extends ConsumerState<BlogEditor> {
  late final TextEditingController title, body;
  late final String id;
  late final String? user;
  BlogPost? saved;
  String audience = 'private', invitation = '';
  // Optional topic slug; empty means none.
  String topic = '';
  bool busy = false, preview = false, dirty = false, uncertain = false;
  // Opt-in to Featured Stories. Only ever sent as true for community chapters.
  bool allowFeaturing = false;
  String? error, notice;
  @override
  void initState() {
    super.initState();
    saved = widget.initial;
    id = saved?.id ?? const Uuid().v4();
    user = ref.read(authNotifierProvider).userId;
    title = TextEditingController(text: saved?.title ?? '');
    body = TextEditingController(text: saved?.body ?? '');
    audience = saved?.audience ?? 'private';
    invitation = saved?.invitation ?? '';
    topic = saved?.topic ?? '';
    allowFeaturing = saved?.allowFeaturing ?? false;
    title.addListener(changed);
    body.addListener(changed);
  }

  void changed() {
    if (mounted) {
      setState(() {
        dirty = true;
        notice = null;
      });
    }
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  Future<BlogPost?> save({required String target, bool confirm = true}) async {
    if (busy || ref.read(authNotifierProvider).userId != user) return null;
    if (target != 'private' &&
        (title.text.trim().isEmpty || body.text.trim().isEmpty)) {
      setState(() {
        preview = false;
        error = 'Add a title and story before publishing.';
      });
      return null;
    }
    if (confirm &&
        target != 'private' &&
        !await confirmBlogAction(
          context,
          'Publish to ${blogAudiences[target]}?',
          target == 'friends'
              ? 'Your accepted Connect friends can read the words and photos in this chapter. You can change the audience later.'
              : 'Eligible, signed-in Connect members can read this chapter. It will not appear on the public web. You can change the audience later.',
          'Publish chapter',
        )) {
      return null;
    }
    if (!mounted) return null;
    setState(() {
      busy = true;
      error = null;
      notice = null;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .put<dynamic>(
            '/blog/posts/$id',
            data: {
              'title': title.text.trim(),
              'body': body.text.trim(),
              'audience': target,
              'invitation': invitation,
              'expected_version': saved?.version ?? 0,
              'allow_featuring': target == 'community' && allowFeaturing,
              'topic': topic,
            },
          );
      final post = BlogPost.fromJson((response.data as Map)['post'] as Map);
      if (!mounted) return null;
      // Sharing beyond Only me for the first time is what earns XP.
      final firstShare =
          target != 'private' &&
          (saved == null || saved!.audience == 'private');
      invalidateBlog(ref, id);
      setState(() {
        saved = post;
        audience = target;
        dirty = false;
        uncertain = false;
        notice = target == 'private'
            ? 'Saved. Only you can read this chapter.'
            : 'Published to ${blogAudiences[target]}.';
      });
      if (firstShare) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              key: const ValueKey('blog.shared_snack'),
              content: const Text(
                'Shared. Readers’ likes and comments earn you XP.',
              ),
              action: SnackBarAction(
                label: 'See my level',
                onPressed: () => openMyLevel(context),
              ),
            ),
          );
      }
      return post;
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          uncertain = true;
          error =
              '${apiErrorMessage(e, fallback: 'We could not confirm the save.')} Your edits are still here. Check the saved version before continuing.';
        });
      }
      return null;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> checkSaved() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .get<dynamic>('/blog/posts/$id');
      final remote = BlogPost.fromJson((response.data as Map)['post'] as Map);
      if (!mounted) return;
      setState(() => busy = false);
      // Show remote content separately. Never overwrite either version silently.
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => FractionallySizedBox(
          heightFactor: .85,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Saved version · ${blogAudiences[remote.audience]}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SelectableText(remote.title),
              const SizedBox(height: 12),
              SelectableText(remote.body),
              for (final photo in remote.photos)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: BlogImage(post: remote, photo: photo),
                ),
              const SizedBox(height: 20),
              const Text(
                'Your current edits remain in the editor. Close this sheet to keep them, or replace them with this saved version.',
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    saved = remote;
                    dirty = true;
                    uncertain = false;
                  });
                },
                child: const Text('Keep my edits for the next save'),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    saved = remote;
                    title.text = remote.title;
                    body.text = remote.body;
                    audience = remote.audience;
                    invitation = remote.invitation;
                    topic = remote.topic;
                    allowFeaturing = remote.allowFeaturing;
                    dirty = false;
                    uncertain = false;
                  });
                },
                child: const Text('Use saved version'),
              ),
            ],
          ),
        ),
      );
    } on Object catch (e) {
      if (mounted) {
        setState(
          () => error = apiErrorMessage(
            e,
            fallback:
                'The saved version could not load. Your edits remain here.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> addPhoto() async {
    if (busy || (saved != null && saved!.audience != 'private')) return;
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 88,
    );
    if (file == null || !mounted) return;
    var altText = '';
    final alt = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Describe your photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'A short description makes your chapter accessible. Adding the photo saves your words as an Only me draft.',
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (value) => altText = value,
              maxLength: 160,
              decoration: const InputDecoration(
                labelText: 'What is in this photo?',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (altText.trim().isNotEmpty) {
                Navigator.pop(context, altText.trim());
              }
            },
            child: const Text('Add to private draft'),
          ),
        ],
      ),
    );
    if (alt == null || !mounted) return;
    final draft = await save(target: 'private', confirm: false);
    if (draft == null || !mounted) return;
    setState(() {
      busy = true;
      error = null;
      notice = null;
    });
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > 10 * 1024 * 1024) {
        throw StateError('Photo exceeds 10 MB.');
      }
      final response = await ref
          .read(apiClientProvider)
          .put<dynamic>(
            '/blog/posts/$id/photos/${const Uuid().v4()}',
            data: FormData.fromMap({
              'expected_version': draft.version.toString(),
              'alt_text': alt,
              'image': MultipartFile.fromBytes(bytes, filename: file.name),
            }),
          );
      if (!mounted) return;
      setState(() {
        saved = BlogPost.fromJson((response.data as Map)['post'] as Map);
        notice = 'Photo added to your private draft.';
      });
      invalidateBlog(ref, id);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          uncertain = true;
          error =
              '${apiErrorMessage(e, fallback: 'The photo could not be added. Use a JPEG or PNG up to 10 MB.')} Check the saved version before retrying.';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> removePhoto(BlogPhoto photo) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .delete<dynamic>(
            '/blog/posts/$id/photos/${photo.id}',
            data: {'expected_version': saved!.version},
          );
      if (!mounted) return;
      setState(
        () => saved = BlogPost.fromJson((response.data as Map)['post'] as Map),
      );
      invalidateBlog(ref, id);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          uncertain = true;
          error = apiErrorMessage(
            e,
            fallback: 'Could not confirm removal. Check the saved version.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authNotifierProvider.select((s) => s.userId));
    if (currentUser == null ||
        currentUser != user ||
        (saved != null && saved!.authorId != user)) {
      return const Scaffold(
        body: Center(
          child: Text('Sign in as the author to edit this chapter.'),
        ),
      );
    }
    return PopScope(
      canPop: !busy && !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || busy) return;
        if (await confirmBlogAction(
              context,
              'Leave without saving?',
              'Your unsaved edits will be lost. Your last saved chapter will remain.',
              'Leave editor',
            ) &&
            context.mounted) {
          setState(() => dirty = false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(preview ? 'Chapter preview' : 'Your next chapter'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 64),
              children: [
                Text(
                  'A little more you.',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontFamily: AppTheme.displayFamily,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Small stories are welcome. A meal you made. A place that changed your mind. The photo with a story behind it.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.visibility_outlined, size: 16),
                      label: Text(
                        saved == null
                            ? 'Not saved · Only me by default'
                            : 'Saved for ${blogAudiences[saved!.audience]}',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: busy
                          ? null
                          : () => setState(() => preview = !preview),
                      icon: Icon(
                        preview
                            ? Icons.edit_outlined
                            : Icons.visibility_outlined,
                      ),
                      label: Text(preview ? 'Keep writing' : 'Preview'),
                    ),
                  ],
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                if (notice != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Semantics(liveRegion: true, child: Text(notice!)),
                  ),
                if (uncertain)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: busy ? null : checkSaved,
                      child: const Text('Check saved version'),
                    ),
                  ),
                const SizedBox(height: 16),
                if (preview) ...[
                  Text(
                    'Preview · ${blogAudiences[audience]} · Not yet saved',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title.text.isEmpty ? 'An untitled chapter' : title.text,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    body.text.isEmpty
                        ? 'Your story will appear here.'
                        : body.text,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(height: 1.65),
                  ),
                  if (invitation.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(blogInvitations[invitation]!),
                    ),
                ] else ...[
                  TextField(
                    controller: title,
                    enabled: !busy,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Chapter title',
                      hintText: 'The Sunday I learned to slow down',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: body,
                    enabled: !busy,
                    minLines: 8,
                    maxLines: 18,
                    maxLength: 8000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Your story',
                      alignLabelWithHint: true,
                      hintText: 'Start anywhere. Make it yours.',
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    key: ValueKey(invitation),
                    initialValue: invitation,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'End with an invitation (optional)',
                    ),
                    items: [
                      for (final e in blogInvitations.entries)
                        DropdownMenuItem(
                          value: e.key,
                          child: Text(
                            e.value,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: busy
                        ? null
                        : (v) => setState(() {
                            invitation = v!;
                            dirty = true;
                          }),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Leave a question that helps someone get to know you.',
                  ),
                  _TopicPicker(
                    selected: topic,
                    enabled: !busy,
                    onChanged: (slug) => setState(() {
                      topic = slug;
                      dirty = true;
                    }),
                  ),
                ],
                for (final photo in saved?.photos ?? <BlogPhoto>[])
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BlogImage(post: saved!, photo: photo),
                        if (!preview && saved!.audience == 'private')
                          TextButton.icon(
                            onPressed: busy || uncertain
                                ? null
                                : () => removePhoto(photo),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove photo'),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                if (!preview) ...[
                  OutlinedButton.icon(
                    onPressed:
                        busy ||
                            uncertain ||
                            (saved?.photos.length ?? 0) >= 6 ||
                            (saved != null && saved!.audience != 'private')
                        ? null
                        : addPhoto,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Add a photo'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Up to 6 JPEG or PNG photos, 10 MB each. Photos need approval. Save as Only me before changing photos on a published chapter.',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Who is this chapter for?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in blogAudiences.entries)
                        ChoiceChip(
                          label: Text(e.value),
                          selected: audience == e.key,
                          onSelected: busy
                              ? null
                              : (_) => setState(() {
                                  audience = e.key;
                                  dirty = true;
                                }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    audience == 'private'
                        ? 'Only you can read this chapter. Friends and matches cannot see it.'
                        : audience == 'friends'
                        ? 'Only accepted Connect friends can read it. A match alone does not give access.'
                        : 'Eligible signed-in members can read it. Complete your profile with two approved profile photos to publish here. This is not public web sharing.',
                  ),
                  if (audience == 'community') ...[
                    const SizedBox(height: 8),
                    SwitchListTile(
                      key: const ValueKey('blog.allow_featuring'),
                      contentPadding: EdgeInsets.zero,
                      value: allowFeaturing,
                      onChanged: busy
                          ? null
                          : (v) => setState(() {
                              allowFeaturing = v;
                              dirty = true;
                            }),
                      title: const Text('Allow featuring'),
                      subtitle: const Text(
                        'If readers love it, your chapter can reach other members’ walls: 50 likes and 5 comments reach 50 walls, 100 likes and 10 comments reach 100. You can turn this off any time.',
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('blog.save'),
                      onPressed: busy ? null : () => save(target: audience),
                      icon: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              audience == 'private'
                                  ? Icons.lock_outline
                                  : Icons.publish_outlined,
                            ),
                      label: Text(
                        audience == 'private'
                            ? 'Save only for me'
                            : 'Publish to ${blogAudiences[audience]}',
                      ),
                    ),
                    if (audience != 'private')
                      OutlinedButton(
                        onPressed: busy ? null : () => save(target: 'private'),
                        child: const Text('Save as Only me'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your words are saved when you choose Save or Publish. Preview does not publish anything.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Optional, single-choice topic. Tapping the chosen topic again clears it.
/// Shows nothing while topics load or if they cannot load; the chapter's
/// current topic is kept either way.
class _TopicPicker extends ConsumerWidget {
  const _TopicPicker({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });
  final String selected;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref
        .watch(blogTopicsProvider)
        .maybeWhen(data: (t) => t, orElse: () => const <BlogTopic>[]);
    if (topics.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        key: const ValueKey('blog.editor.topics'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Topic (optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text('Help readers who care about this find your chapter.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in topics)
                ChoiceChip(
                  key: ValueKey('blog.editor.topic.${t.slug}'),
                  label: Text(t.title),
                  selected: selected == t.slug,
                  onSelected: enabled
                      ? (on) => onChanged(on ? t.slug : '')
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
