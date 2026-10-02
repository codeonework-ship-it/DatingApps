import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../matching/screens/match_notification_screen.dart';
import '../../payment/screens/subscription_screen.dart';
import '../discover_l10n.dart';
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

  /// Returns true when the answer was saved.
  Future<bool> _answer(DiscoveryProfile profile, {required bool like}) async {
    final result = await ref
        .read(likedMeProvider.notifier)
        .answer(profile, like: like);
    if (!mounted) {
      return result.error == null && result.dailyLimit == null;
    }
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final l10n = AppLocalizations.of(context);
    if (result.dailyLimit != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.dailyLimit!.localizedHeadline(l10n)),
          // Flutter keeps snack bars with an action up until tapped;
          // let this one time out so it never covers the screen.
          persist: false,
          action: SnackBarAction(
            label: l10n.discoverSeePlans,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SubscriptionScreen(),
              ),
            ),
          ),
        ),
      );
      return false;
    }
    if (result.error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(localizeDiscoverMessage(l10n, result.error!))),
      );
      return false;
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
      return true;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          like
              ? l10n.discoverLikedBack(profile.name)
              : l10n.discoverPassedOn(profile.name),
        ),
      ),
    );
    return true;
  }

  Future<void> _openProfile(DiscoveryProfile profile) async {
    unawaited(
      ref.read(swipeNotifierProvider.notifier).recordProfileView(profile.id),
    );
    // They already liked the member: Love and Message both answer with a
    // like back (which makes the match), on the profile page itself.
    await Navigator.of(context).push<ProfileDetailsAction>(
      MaterialPageRoute<ProfileDetailsAction>(
        builder: (_) => ProfileDetailsScreen(
          profile: profile,
          onLove: (_) => _answer(profile, like: true),
          onMessage: (_) => _answer(profile, like: true),
        ),
      ),
    );
  }

  /// Pull to refresh. With people already listed a failed reload leaves
  /// them on screen, so say it failed instead of ending the spinner silently.
  Future<void> _refresh() async {
    await ref.read(likedMeProvider.notifier).load();
    if (!mounted) return;
    final state = ref.read(likedMeProvider);
    final error = state.error;
    if (error == null || state.entries.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            localizeDiscoverMessage(AppLocalizations.of(context), error),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(likedMeProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    Widget body;
    if (state.isLoading && state.entries.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null && state.entries.isEmpty) {
      body = _MessagePane(
        icon: Icons.cloud_off_rounded,
        title: l10n.discoverLikedMeLoadFailedTitle,
        message: localizeDiscoverMessage(l10n, state.error!),
        action: FilledButton(
          key: const ValueKey('qa.liked_me.retry'),
          onPressed: () => ref.read(likedMeProvider.notifier).load(),
          child: Text(l10n.commonRetry),
        ),
      );
    } else if (state.entries.isEmpty) {
      body = _MessagePane(
        icon: Icons.favorite_border_rounded,
        title: l10n.discoverLikedMeEmptyTitle,
        message: l10n.discoverLikedMeEmptyBody,
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
                l10n.discoverLikedMeIntro,
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
          state.count > 0
              ? l10n.discoverLikedMeTitleCount(state.count)
              : l10n.discoverLikedMeTitle,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
      ),
      body: PostLoginBackdrop(
        child: RefreshIndicator(
          key: const ValueKey('qa.liked_me.refresh'),
          onRefresh: _refresh,
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
    final l10n = AppLocalizations.of(context);
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
              key: ValueKey('qa.liked_me.open.${profile.id}'),
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
                                semanticLabel: l10n.memberProfileVerified,
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
                                _likedAtLabel(context, likedAt),
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
                    label: Text(l10n.discoverPass),
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
                    label: Text(l10n.discoverLikeBack),
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

/// Same buckets as `DateTime.getTimeAgo` (minutes, hours, days, weeks, then
/// a date after a month), worded in the member's language.
String _likedAtLabel(BuildContext context, DateTime? likedAt) {
  final l10n = AppLocalizations.of(context);
  if (likedAt == null) {
    return l10n.discoverLikedMeTitle;
  }
  final local = likedAt.toLocal();
  final difference = DateTime.now().difference(local);
  if (difference.inSeconds < 60) {
    return l10n.discoverLikedJustNow;
  }
  if (difference.inMinutes < 60) {
    return l10n.discoverLikedMinutesAgo(difference.inMinutes);
  }
  if (difference.inHours < 24) {
    return l10n.discoverLikedHoursAgo(difference.inHours);
  }
  if (difference.inDays < 7) {
    return l10n.discoverLikedDaysAgo(difference.inDays);
  }
  if (difference.inDays < 30) {
    return l10n.discoverLikedWeeksAgo((difference.inDays / 7).floor());
  }
  final locale = Localizations.localeOf(context).toString();
  return l10n.discoverLikedOnDate(DateFormat.yMd(locale).format(local));
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
