import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/rich_text/rich_document.dart';
import '../../core/rich_text/rich_document_view.dart';
import '../../core/rich_text/rich_text_controller.dart';
import '../../core/rich_text/rich_text_editor.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
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
  late final TextEditingController title;

  /// Formatted story. Its text is the plain body the server stores.
  late final RichTextController body;
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
    body = RichTextController(document: _documentOf(saved));
    audience = saved?.audience ?? 'private';
    invitation = saved?.invitation ?? '';
    topic = saved?.topic ?? '';
    allowFeaturing = saved?.allowFeaturing ?? false;
    title.addListener(changed);
    body.addListener(changed);
  }

  /// Plain-text chapters open as paragraphs, so they save back unchanged.
  static RichDocument _documentOf(BlogPost? post) =>
      post?.content ??
      RichDocument.fromPlainText(post?.body ?? '', style: defaultChapterStyle);

  AppLocalizations get l10n => AppLocalizations.of(context);

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
        error = l10n.blogEditorMissingFields;
      });
      return null;
    }
    if (confirm &&
        target != 'private' &&
        !await confirmBlogAction(
          context,
          l10n.blogPublishConfirmTitle(target),
          target == 'friends'
              ? l10n.blogPublishFriendsBody
              : l10n.blogPublishCommunityBody,
          l10n.blogPublishChapter,
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
              // The server derives body from content; body serves old servers.
              'body': body.text.trim(),
              'content': body.document.toJson(),
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
            ? l10n.blogSavedOnlyMe
            : l10n.blogPublishedTo(target);
      });
      if (firstShare) {
        // The snack bar outlives the editor when the member leaves first,
        // so its action opens the level screen from the navigator.
        final navigator = Navigator.of(context);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              key: const ValueKey('blog.shared_snack'),
              content: Text(l10n.blogSharedSnack),
              // Flutter keeps snack bars with an action up until tapped;
              // let this one time out so it never covers the screen.
              persist: false,
              action: SnackBarAction(
                label: l10n.blogSeeMyLevel,
                onPressed: () => openMyLevel(navigator.context),
              ),
            ),
          );
      }
      return post;
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          uncertain = true;
          error = l10n.blogEditsStillHere(
            apiErrorMessage(e, fallback: l10n.blogSaveUnconfirmed),
          );
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
            key: const ValueKey('qa.blog.editor.saved_version_sheet'),
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                l10n.blogSavedVersionTitle(
                  blogAudienceLabel(l10n, remote.audience),
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SelectableText(remote.title),
              const SizedBox(height: 12),
              RichBody(
                document: remote.content,
                plainText: remote.body,
                legacyStyle: Theme.of(context).textTheme.bodyMedium,
              ),
              for (final photo in remote.photos)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: BlogImage(post: remote, photo: photo),
                ),
              const SizedBox(height: 20),
              Text(l10n.blogSavedVersionNote),
              const SizedBox(height: 16),
              OutlinedButton(
                key: const ValueKey('qa.blog.editor.keep_edits'),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    saved = remote;
                    dirty = true;
                    uncertain = false;
                  });
                },
                child: Text(l10n.blogKeepMyEdits),
              ),
              OutlinedButton(
                key: const ValueKey('qa.blog.editor.use_saved'),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    saved = remote;
                    title.text = remote.title;
                    body.load(_documentOf(remote));
                    audience = remote.audience;
                    invitation = remote.invitation;
                    topic = remote.topic;
                    allowFeaturing = remote.allowFeaturing;
                    dirty = false;
                    uncertain = false;
                  });
                },
                child: Text(l10n.blogUseSavedVersion),
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
            fallback: l10n.blogSavedVersionLoadFailed,
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
      // The add button stays disabled until there is a description, rather
      // than looking ready and ignoring the tap.
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.blogDescribePhotoTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.blogDescribePhotoBody),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('qa.blog.editor.photo_alt'),
                onChanged: (value) => setDialogState(() => altText = value),
                maxLength: 160,
                decoration: InputDecoration(
                  labelText: l10n.blogDescribePhotoLabel,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              key: const ValueKey('qa.blog.editor.photo_cancel'),
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.blogCancel),
            ),
            FilledButton(
              key: const ValueKey('qa.blog.editor.photo_add'),
              onPressed: altText.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, altText.trim()),
              child: Text(l10n.blogAddToPrivateDraft),
            ),
          ],
        ),
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
        notice = l10n.blogPhotoAdded;
      });
      invalidateBlog(ref, id);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          uncertain = true;
          error = l10n.blogCheckSavedBeforeRetrying(
            apiErrorMessage(e, fallback: l10n.blogPhotoAddFailed),
          );
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
          error = apiErrorMessage(e, fallback: l10n.blogRemoveUnconfirmed);
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
      return Scaffold(body: Center(child: Text(l10n.blogSignInAsAuthor)));
    }
    return PopScope(
      canPop: !busy && !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || busy) return;
        if (await confirmBlogAction(
              context,
              l10n.blogLeaveEditorTitle,
              l10n.blogLeaveEditorMessage,
              l10n.blogLeaveEditor,
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
          title: Text(
            preview ? l10n.blogEditorPreviewTitle : l10n.blogEditorTitle,
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 64),
              children: [
                Text(
                  l10n.blogEditorHeadline,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontFamily: AppTheme.displayFamily,
                  ),
                ),
                const SizedBox(height: 8),
                Text(l10n.blogEditorIntro),
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
                            ? l10n.blogNotSavedDefault
                            : l10n.blogSavedFor(saved!.audience),
                      ),
                    ),
                    TextButton.icon(
                      key: const ValueKey('qa.blog.editor.preview'),
                      onPressed: busy
                          ? null
                          : () => setState(() => preview = !preview),
                      icon: Icon(
                        preview
                            ? Icons.edit_outlined
                            : Icons.visibility_outlined,
                      ),
                      label: Text(
                        preview ? l10n.blogKeepWriting : l10n.blogPreview,
                      ),
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
                      key: const ValueKey('qa.blog.editor.check_saved'),
                      onPressed: busy ? null : checkSaved,
                      child: Text(l10n.blogCheckSavedVersion),
                    ),
                  ),
                const SizedBox(height: 16),
                if (preview) ...[
                  Text(
                    l10n.blogPreviewNotSaved(blogAudienceLabel(l10n, audience)),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title.text.isEmpty ? l10n.blogUntitled : title.text,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  if (body.text.trim().isEmpty)
                    Text(
                      l10n.blogStoryPlaceholder,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.65),
                    )
                  else
                    RichDocumentView(
                      key: const ValueKey('blog.editor.preview'),
                      document: body.document,
                    ),
                  if (invitation.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(blogInvitationLabel(l10n, invitation)),
                    ),
                ] else ...[
                  TextField(
                    key: const ValueKey('qa.blog.editor.title'),
                    controller: title,
                    enabled: !busy,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.blogChapterTitleLabel,
                      hintText: l10n.blogChapterTitleHint,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichTextEditor(
                    controller: body,
                    enabled: !busy,
                    maxLength: 8000,
                    keyPrefix: 'blog.editor',
                    label: l10n.blogStoryLabel,
                    hint: l10n.blogStoryHint,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    key: ValueKey(invitation),
                    initialValue: invitation,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.blogInvitationLabel,
                    ),
                    items: [
                      for (final id in blogInvitations)
                        DropdownMenuItem(
                          value: id,
                          child: Text(
                            blogInvitationLabel(l10n, id),
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
                  Text(l10n.blogInvitationHelp),
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
                            key: ValueKey(
                              'qa.blog.editor.remove_photo.${photo.id}',
                            ),
                            onPressed: busy || uncertain
                                ? null
                                : () => removePhoto(photo),
                            icon: const Icon(Icons.delete_outline),
                            label: Text(l10n.blogRemovePhoto),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                if (!preview) ...[
                  OutlinedButton.icon(
                    key: const ValueKey('qa.blog.editor.add_photo'),
                    onPressed:
                        busy ||
                            uncertain ||
                            (saved?.photos.length ?? 0) >= 6 ||
                            (saved != null && saved!.audience != 'private')
                        ? null
                        : addPhoto,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(l10n.blogAddPhoto),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.blogPhotoRules),
                  const SizedBox(height: 24),
                  Text(
                    l10n.blogWhoFor,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final id in blogAudiences)
                        ChoiceChip(
                          key: ValueKey('qa.blog.editor.audience.$id'),
                          label: Text(blogAudienceLabel(l10n, id)),
                          selected: audience == id,
                          onSelected: busy
                              ? null
                              : (_) => setState(() {
                                  audience = id;
                                  dirty = true;
                                }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    audience == 'private'
                        ? l10n.blogAudiencePrivateHelp
                        : audience == 'friends'
                        ? l10n.blogAudienceFriendsHelp
                        : l10n.blogAudienceCommunityHelp,
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
                      title: Text(l10n.blogAllowFeaturing),
                      subtitle: Text(l10n.blogAllowFeaturingHelp),
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
                            ? l10n.blogSaveOnlyForMe
                            : l10n.blogPublishTo(audience),
                      ),
                    ),
                    if (audience != 'private')
                      OutlinedButton(
                        key: const ValueKey('qa.blog.editor.save_private'),
                        onPressed: busy ? null : () => save(target: 'private'),
                        child: Text(l10n.blogSaveAsOnlyMe),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(l10n.blogSaveNote),
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
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        key: const ValueKey('blog.editor.topics'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.blogTopicOptional,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(l10n.blogTopicHelp),
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
