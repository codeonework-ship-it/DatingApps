import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';
import '../first_chapter/chapter_provider.dart';
import 'blog_connections.dart';
import 'blog_data.dart';
import 'blog_screen.dart';

String blogShareUrl(String id) => Uri.parse(
  chapterShareUrl(id),
).replace(path: '/story.html', queryParameters: {'id': id}).toString();
Future<void> copyBlogLink(BuildContext context, String id) async {
  final url = blogShareUrl(id);
  final l10n = AppLocalizations.of(context);
  try {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.blogLinkCopied)));
  } on Object {
    if (context.mounted)
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l10n.blogYourPublicLink),
          content: SelectableText(url),
        ),
      );
  }
}

class BlogShareScreen extends ConsumerStatefulWidget {
  const BlogShareScreen({super.key, required this.post, this.exchange});
  final BlogPost post;
  final Map<String, dynamic>? exchange;
  @override
  ConsumerState<BlogShareScreen> createState() => _BlogShareState();
}

class _BlogShareState extends ConsumerState<BlogShareScreen> {
  late final String? user = ref.read(authNotifierProvider).userId;
  final id = const Uuid().v4();
  late final TextEditingController excerpt;
  final selected = <String>{};
  bool approved = false, busy = false, finished = false;
  String? error;
  bool get joint => widget.exchange != null;
  @override
  void initState() {
    super.initState();
    final v = widget.exchange;
    excerpt = TextEditingController(
      text: v == null
          ? String.fromCharCodes(widget.post.body.runes.take(1500))
          : v['incoming'] == true
          ? '${v['my_story']}\n\n${v['partner_story']}'
          : '${v['partner_story']}\n\n${v['my_story']}',
    );
  }

  @override
  void dispose() {
    excerpt.dispose();
    super.dispose();
  }

  AppLocalizations get l10n => AppLocalizations.of(context);

  Future<void> share() async {
    if (!approved || busy || ref.read(authNotifierProvider).userId != user)
      return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(apiClientProvider)
          .post<dynamic>(
            '/blog/publications',
            data: {
              'id': id,
              'post_id': widget.post.id,
              'expected_version': widget.post.version,
              'approved': true,
              if (joint) 'response_id': widget.exchange!['id'],
              'excerpt': excerpt.text.trim(),
              'photo_ids': selected.toList(),
            },
          );
      if (mounted) {
        ref.invalidate(blogHubProvider);
        setState(() => finished = true);
      }
    } on Object catch (e) {
      if (mounted)
        setState(
          () => error = apiErrorMessage(e, fallback: l10n.blogShareUnconfirmed),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null ||
        ref.watch(authNotifierProvider.select((s) => s.userId)) != user)
      return Scaffold(body: Center(child: Text(l10n.blogSignInAgain)));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          joint ? l10n.blogSharedJournalPage : l10n.blogYourPublicPreview,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                joint
                    ? l10n.blogShareJointHeadline
                    : l10n.blogShareSoloHeadline,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(joint ? l10n.blogShareJointBody : l10n.blogShareSoloBody),
              const SizedBox(height: 12),
              Text(l10n.blogShareIdentityNote),
              const SizedBox(height: 24),
              Text(
                widget.post.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (joint || finished)
                SelectableText(excerpt.text)
              else
                TextField(
                  controller: excerpt,
                  enabled: !busy,
                  maxLength: 1500,
                  minLines: 6,
                  maxLines: 14,
                  onChanged: (_) => setState(() => approved = false),
                  decoration: InputDecoration(
                    labelText: l10n.blogExcerptLabel,
                    alignLabelWithHint: true,
                  ),
                ),
              if (!joint && !finished)
                for (final photo in widget.post.photos)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          BlogImage(post: widget.post, photo: photo),
                          CheckboxListTile(
                            title: Text(l10n.blogIncludePhoto(photo.alt)),
                            value: selected.contains(photo.id),
                            onChanged: busy
                                ? null
                                : (v) => setState(() {
                                    approved = false;
                                    if (v == true) {
                                      selected.add(photo.id);
                                    } else {
                                      selected.remove(photo.id);
                                    }
                                  }),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Semantics(liveRegion: true, child: Text(error!)),
                ),
              if (!finished) ...[
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.blogApproveCopy),
                  subtitle: Text(l10n.blogApproveCopyNote),
                  value: approved,
                  onChanged: busy
                      ? null
                      : (v) => setState(() => approved = v ?? false),
                ),
                FilledButton(
                  onPressed: approved && !busy ? share : null,
                  child: Text(
                    busy
                        ? l10n.blogSaving
                        : joint
                        ? l10n.blogRequestOtherApproval
                        : l10n.blogCreatePublicLink,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 20),
                Text(
                  joint
                      ? l10n.blogJointApprovalRecorded
                      : l10n.blogPublicCopyReady,
                ),
                if (!joint)
                  FilledButton.icon(
                    onPressed: () => copyBlogLink(context, id),
                    icon: const Icon(Icons.copy),
                    label: Text(l10n.blogCopyPublicLink),
                  ),
                OutlinedButton(
                  onPressed: () =>
                      openBlogConnections(context, section: 'publications'),
                  child: Text(l10n.blogManageSharedLinks),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
