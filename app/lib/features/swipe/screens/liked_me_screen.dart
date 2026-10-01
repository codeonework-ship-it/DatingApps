import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/extensions/date_time_extensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../matching/screens/match_notification_screen.dart';
import '../../payment/screens/subscription_screen.dart';
import '../models/discovery_profile.dart';
import '../providers/liked_me_provider.dart';
import '../providers/swipe_provider.dart';
import 'profile_details_screen.dart';

/// Who liked me: members who liked the caller and are waiting on an answer.
/// A like back creates the match; a pass is never shown to the other member.
class LikedMeScreen extends ConsumerStatefulWidget {
  const LikedMeScreen({super.key});

  @override
  ConsumerState<LikedMeScreen> createState() => _LikedMeScreenState();
}

class _LikedMeScreenState extends ConsumerState<LikedMeScreen> {
  @override
  void initState() {
    super.initState();
    // Opening the screen always shows the current list, not the one loaded
    // when Discover first appeared.
    Future<void>.microtask(() => ref.read(likedMeProvider.notifier).load());
  }

  Future<void> _answer(DiscoveryProfile profile, {required bool like}) async {
    final result = await ref
        .read(likedMeProvider.notifier)
        .answer(profile, like: like);
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (result.dailyLimit != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.dailyLimit!.headline),
          action: SnackBarAction(
            label: 'See plans',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SubscriptionScreen(),
              ),
            ),
          ),
        ),
      );
      return;
    }
    if (result.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }
    final matchId = result.matchId;
    if (like && matchId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => MatchNotificationScreen(
            matchId: matchId,
            otherUserId: profile.id,
            otherUserName: profile.name,
            otherUserPhotoUrl: profile.photoUrls.isNotEmpty
                ? profile.photoUrls.first
                : AppRuntimeConfig.placeholderProfileImageUrl,
          ),
        ),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          like ? 'You liked ${profile.name} back' : 'Passed on ${profile.name}',
        ),
      ),
    );
  }

  Future<void> _openProfile(DiscoveryProfile profile) async {
    unawaited(
      ref.read(swipeNotifierProvider.notifier).recordProfileView(profile.id),
    );
    final action = await Navigator.of(context).push<ProfileDetailsAction>(
      MaterialPageRoute<ProfileDetailsAction>(
        builder: (_) => ProfileDetailsScreen(profile: profile),
      ),
    );
    if (!mounted) {
      return;
    }
    // Messaging needs a match, so both actions answer with a like back.
    if (action == ProfileDetailsAction.love ||
        action == ProfileDetailsAction.message) {
      await _answer(profile, like: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(likedMeProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget body;
    if (state.isLoading && state.entries.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null && state.entries.isEmpty) {
      body = _MessagePane(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load your likes',
        message: state.error!,
        action: FilledButton(
          onPressed: () => ref.read(likedMeProvider.notifier).load(),
          child: const Text('Retry'),
        ),
      );
    } else if (state.entries.isEmpty) {
      body = const _MessagePane(
        icon: Icons.favorite_border_rounded,
        title: 'No new likes yet',
        message:
            'When someone likes you, they show up here. Like them back and '
            "it's a match.",
      );
    } else {
      body = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: state.entries.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Text(
                'They already like you. Like back to match, or pass. '
                'Passing is private.',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            );
          }
          final entry = state.entries[index - 1];
          return _LikedMeCard(
            key: ValueKey('qa.liked_me.card.${entry.profile.id}'),
            entry: entry,
            busy: state.answering.contains(entry.profile.id),
            onOpen: () => _openProfile(entry.profile),
            onPass: () => _answer(entry.profile, like: false),
            onLikeBack: () => _answer(entry.profile, like: true),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.count > 0 ? 'Liked you · ${state.count}' : 'Liked you',
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
      ),
      body: PostLoginBackdrop(
        child: RefreshIndicator(
          onRefresh: () => ref.read(likedMeProvider.notifier).load(),
          child: body,
        ),
      ),
    );
  }
}

class _LikedMeCard extends StatelessWidget {
  const _LikedMeCard({
    required this.entry,
    required this.busy,
    required this.onOpen,
    required this.onPass,
    required this.onLikeBack,
    super.key,
  });

  final LikedMeEntry entry;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onPass;
  final VoidCallback onLikeBack;

  @override
  Widget build(BuildContext context) {
    final profile = entry.profile;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final photoUrl = profile.photoUrls.isNotEmpty
        ? profile.photoUrls.first
        : '';
    final subtitle = profile.subtitle.trim();
    final bio = profile.quickBio;
    final likedAt = entry.likedAt;

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    child: SizedBox(
                      width: 84,
                      height: 108,
                      // The placeholder stays underneath, so a slow or
                      // failed photo never leaves an empty box.
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _PhotoFallback(color: scheme.surfaceContainerHighest),
                          if (photoUrl.isNotEmpty)
                            Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                profile.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleMedium?.copyWith(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (profile.isVerified) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.verified_rounded,
                                size: 18,
                                color: scheme.primary,
                                semanticLabel: 'Verified',
                              ),
                            ],
                          ],
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 14,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _likedAtLabel(likedAt),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.labelMedium?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (bio.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            bio,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: ValueKey('qa.liked_me.pass.${profile.id}'),
                    onPressed: busy ? null : onPass,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Pass'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    key: ValueKey('qa.liked_me.like_back.${profile.id}'),
                    onPressed: busy ? null : onLikeBack,
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.favorite_rounded, size: 18),
                    label: const Text('Like back'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _likedAtLabel(DateTime? likedAt) {
  if (likedAt == null) {
    return 'Liked you';
  }
  final ago = likedAt.toLocal().getTimeAgo();
  if (ago == 'Just now') {
    return 'Liked you just now';
  }
  // getTimeAgo falls back to a plain date after a month.
  return ago.endsWith('ago') ? 'Liked you $ago' : 'Liked you on $ago';
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: color,
    child: Icon(
      Icons.person_rounded,
      size: 36,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

class _MessagePane extends StatelessWidget {
  const _MessagePane({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // A scrollable so pull-to-refresh works on the empty and error states.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
      children: [
        Icon(icon, size: 56, color: scheme.primary),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (action != null) ...[
          const SizedBox(height: 20),
          Center(child: action),
        ],
      ],
    );
  }
}
