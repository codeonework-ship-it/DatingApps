import 'package:flutter/material.dart' hide Title;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/widgets/glass_widgets.dart';
import '../auth/providers/auth_provider.dart';
import '../common/widgets/activity_visuals.dart';
import '../common/widgets/community_actions.dart';
import 'club_widgets.dart';
import 'clubs_data.dart';
import 'review_sheets.dart';

/// A book or film: its average rating, the member's own review and the
/// reviews they are allowed to see.
class TitleDetailScreen extends ConsumerWidget {
  const TitleDetailScreen({required this.titleId, super.key});
  final String titleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    final detail = user == null
        ? null
        : ref.watch(titleDetailProvider(titleId));
    return Scaffold(
      appBar: AppBar(title: Text(detail?.valueOrNull?.title.title ?? 'Title')),
      body: PostLoginBackdrop(
        child: detail == null
            ? const Center(child: Text('Sign in to see reviews.'))
            : detail.when(
                skipLoadingOnRefresh: false,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ActivityNotice(
                      icon: Icons.cloud_off_outlined,
                      title: 'This title could not load',
                      message: apiErrorMessage(
                        e,
                        fallback: 'Please check your connection.',
                      ),
                      actionLabel: 'Try again',
                      onAction: () =>
                          ref.invalidate(titleDetailProvider(titleId)),
                    ),
                  ),
                ),
                data: (data) => RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(titleDetailProvider(titleId));
                    await ref.read(titleDetailProvider(titleId).future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                    children: [
                      _TitleHeader(title: data.title),
                      const SizedBox(height: 16),
                      _MyReview(detail: data),
                      const SizedBox(height: 24),
                      Text(
                        'Reviews',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (data.reviews.where((r) => !r.mine).isEmpty)
                        const ActivityNotice(
                          icon: Icons.rate_review_outlined,
                          title: 'No other reviews yet',
                          message:
                              'When members you can see share a review, '
                              'it shows up here.',
                        ),
                      for (final review in data.reviews.where((r) => !r.mine))
                        ReviewCard(review: review),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _TitleHeader extends StatelessWidget {
  const _TitleHeader({required this.title});
  final Title title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: kindGradient(scheme, title.kind),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KindBadge(kind: title.kind, suffix: ''),
            const SizedBox(height: 12),
            Text(
              title.title,
              style: text.headlineSmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (title.byline.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                title.byline,
                style: text.bodyLarge?.copyWith(color: scheme.onSurface),
              ),
            ],
            const SizedBox(height: 12),
            RatingSummary(title: title),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => showAddToListSheet(context, title),
              icon: const Icon(Icons.playlist_add),
              label: const Text('Add to a list'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyReview extends ConsumerWidget {
  const _MyReview({required this.detail});
  final TitleDetail detail;

  Future<void> edit(BuildContext context, WidgetRef ref) async {
    final saved = await showReviewSheet(
      context,
      title: detail.title,
      existing: detail.myReview,
    );
    if (saved != null) {
      invalidateTitle(ref, detail.title.id);
    }
  }

  Future<void> delete(BuildContext context, WidgetRef ref) async {
    final review = detail.myReview!;
    if (!await confirmCommunityAction(
      context,
      title: 'Delete your review?',
      message: 'Your rating and words are removed for everyone.',
      action: 'Delete review',
    )) {
      return;
    }
    try {
      await ref
          .read(apiClientProvider)
          .delete<dynamic>(
            '/clubs/reviews/${review.id}',
            data: {'expected_version': review.version},
          );
      invalidateTitle(ref, detail.title.id);
    } on Object catch (e) {
      if (context.mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(
            e,
            fallback: 'Your review could not be deleted. Reload and retry.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = detail.myReview;
    final text = Theme.of(context).textTheme;
    if (review == null) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What did you think?',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Rate it and say why. You choose who sees it.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => edit(context, ref),
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Write a review'),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your review',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StarRating(rating: review.rating.toDouble(), size: 24),
                CountPill(
                  icon: review.audience == 'private'
                      ? Icons.lock_outline
                      : review.audience == 'friends'
                      ? Icons.people_outline
                      : Icons.public,
                  label: clubAudiences[review.audience] ?? 'Only me',
                ),
                if (review.hasSpoilers)
                  const CountPill(
                    icon: Icons.warning_amber_outlined,
                    label: 'Spoilers',
                  ),
              ],
            ),
            if (review.body.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(review.body, style: text.bodyLarge),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => edit(context, ref),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => delete(context, ref),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Another member's review, with spoilers collapsed and a report action.
class ReviewCard extends ConsumerWidget {
  const ReviewCard({required this.review, super.key});
  final TitleReview review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        review.authorName,
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      StarRating(rating: review.rating.toDouble()),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Report this review',
                  onPressed: () => reportCommunityItem(
                    context,
                    ref,
                    kind: 'review',
                    id: review.id,
                  ),
                  icon: const Icon(Icons.flag_outlined),
                ),
              ],
            ),
            if (review.body.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SpoilerReveal(
                  spoiler: review.hasSpoilers,
                  child: Text(review.body, style: text.bodyLarge),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
