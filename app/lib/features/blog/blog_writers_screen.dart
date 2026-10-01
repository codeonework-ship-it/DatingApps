import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_error_message.dart';
import '../auth/providers/auth_provider.dart';
import 'blog_data.dart';
import 'blog_follow.dart';
import 'blog_screen.dart';

Future<void> openBlogWriters(BuildContext context) => Navigator.of(
  context,
).push<void>(MaterialPageRoute(builder: (_) => const BlogWritersScreen()));

/// Writers the member follows, with their latest chapter and an unfollow
/// button.
class BlogWritersScreen extends ConsumerWidget {
  const BlogWritersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Writers you follow')),
      body: user == null
          ? const Center(child: Text('Sign in to see writers you follow.'))
          : ref
                .watch(blogSubscriptionsProvider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: BlogError(
                      message: apiErrorMessage(
                        e,
                        fallback: 'Writers you follow could not load.',
                      ),
                      retry: () => ref.invalidate(blogSubscriptionsProvider),
                    ),
                  ),
                  data: (writers) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(blogSubscriptionsProvider);
                          await ref.read(blogSubscriptionsProvider.future);
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                          children: [
                            if (writers.isEmpty)
                              Card(
                                key: const ValueKey('blog.writers.empty'),
                                child: Padding(
                                  padding: const EdgeInsets.all(28),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.favorite_border_rounded,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No writers yet.',
                                        style: theme.textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'When a chapter speaks to you, tap Follow their chapters on it. Their new chapters will gather in Following.',
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            for (final writer in writers)
                              Card(
                                key: ValueKey('blog.writer.${writer.authorId}'),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        writer.name,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      Text(
                                        blogFollowerText(
                                          (ref.watch(
                                                    blogFollowsProvider,
                                                  )[writer.authorId] ??
                                                  (
                                                    subscribed: true,
                                                    count:
                                                        writer.subscriberCount,
                                                  ))
                                              .count,
                                        ),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      if (writer.latestPostId.isNotEmpty)
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            minimumSize: const Size(48, 48),
                                            padding: EdgeInsets.zero,
                                            alignment: Alignment.centerLeft,
                                          ),
                                          onPressed: () => openBlogPost(
                                            context,
                                            writer.latestPostId,
                                          ),
                                          child: Text(
                                            'Latest: ${writer.latestTitle.isEmpty ? 'An untitled chapter' : writer.latestTitle}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      BlogFollowButton(
                                        authorId: writer.authorId,
                                        server: (
                                          subscribed: true,
                                          count: writer.subscriberCount,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
