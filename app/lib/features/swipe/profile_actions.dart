import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_runtime_config.dart';
import '../../l10n/app_localizations.dart';
import '../matching/providers/match_provider.dart';
import '../matching/screens/match_notification_screen.dart';
import '../messaging/screens/chat_screen.dart';
import '../payment/screens/subscription_screen.dart';
import 'discover_l10n.dart';
import 'models/discovery_profile.dart';
import 'providers/curated_daily_set_provider.dart';
import 'providers/swipe_provider.dart';

/// Love, Message and Pass for one member, shared by every screen that shows
/// a member: the profile page, the deck, Spotlight, Today, the liked and
/// passed lists.
///
/// These used to be implemented by whichever screen opened the profile,
/// acting on the deck's current card; screens that forgot (or whose deck no
/// longer held the member) silently did nothing. Everything now acts on the
/// member passed in, and every outcome is visible: chat opens, the match
/// screen shows, or a message explains what happened.
abstract final class ProfileActions {
  /// Likes [profile]. Returns true when the like was saved.
  static Future<bool> love(
    BuildContext context,
    WidgetRef ref,
    DiscoveryProfile profile,
  ) async {
    final decision = await ref
        .read(swipeNotifierProvider.notifier)
        .decideOn(profile, like: true);
    if (!context.mounted) {
      return decision.recorded;
    }
    if (!_reportProblem(context, decision)) {
      return false;
    }
    ref.invalidate(curatedDailySetProvider);
    final matchId = decision.matchId;
    if (matchId != null) {
      await _showMatch(context, profile, matchId);
      return true;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.discoverSuperLikeSent(profile.name))),
      );
    return true;
  }

  /// Passes on [profile]. Returns true when the pass was saved.
  static Future<bool> pass(
    BuildContext context,
    WidgetRef ref,
    DiscoveryProfile profile,
  ) async {
    final decision = await ref
        .read(swipeNotifierProvider.notifier)
        .decideOn(profile, like: false);
    if (!context.mounted) {
      return decision.recorded;
    }
    return _reportProblem(context, decision);
  }

  /// Opens the chat with [profile]. Without a match yet, sends a like (a
  /// chat needs both people to say yes) and says so; when that like makes
  /// the match, the chat opens straight away.
  static Future<void> message(
    BuildContext context,
    WidgetRef ref,
    DiscoveryProfile profile,
  ) async {
    var match = _existingMatch(ref, profile.id);
    if (match == null) {
      await ref.read(matchNotifierProvider.notifier).refresh();
      match = _existingMatch(ref, profile.id);
    }
    if (!context.mounted) {
      return;
    }
    if (match != null) {
      await _openChat(context, match);
      return;
    }
    final decision = await ref
        .read(swipeNotifierProvider.notifier)
        .decideOn(profile, like: true);
    if (!context.mounted || !_reportProblem(context, decision)) {
      return;
    }
    ref.invalidate(curatedDailySetProvider);
    final l10n = AppLocalizations.of(context);
    final matchId = decision.matchId;
    if (matchId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.discoverMessageLikeSent(profile.name))),
        );
      return;
    }
    await ref.read(matchNotifierProvider.notifier).refresh();
    if (!context.mounted) {
      return;
    }
    await _openChat(
      context,
      _existingMatch(ref, profile.id) ??
          Match(
            id: matchId,
            userId: profile.id,
            userName: profile.name,
            userPhoto: profile.photoUrls.isNotEmpty
                ? profile.photoUrls.first
                : '',
            lastMessage: l10n.discoverMatchPlaceholderMessage,
            lastMessageTime: DateTime.now(),
            unreadCount: 0,
            isOnline: false,
          ),
    );
  }

  static Match? _existingMatch(WidgetRef ref, String userId) {
    for (final m in ref.read(matchNotifierProvider).matches) {
      if (m.userId == userId) {
        return m;
      }
    }
    return null;
  }

  /// Shows the daily-limit or error message; false when there was one.
  static bool _reportProblem(BuildContext context, ProfileDecision decision) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final limit = decision.dailyLimit;
    if (limit != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(limit.localizedHeadline(l10n)),
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
    final error = decision.error;
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(localizeDiscoverMessage(l10n, error))),
      );
      return false;
    }
    return true;
  }

  static Future<void> _showMatch(
    BuildContext context,
    DiscoveryProfile profile,
    String matchId,
  ) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => MatchNotificationScreen(
        matchId: matchId,
        otherUserId: profile.id,
        otherUserName: profile.name,
        otherUserPhotoUrl: profile.photoUrls.isEmpty
            ? AppRuntimeConfig.placeholderProfileImageUrl
            : profile.photoUrls.first,
      ),
    ),
  );

  static Future<void> _openChat(BuildContext context, Match match) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(
            matchId: match.id,
            otherUserId: match.userId,
            userName: match.userName,
            userPhotoUrl: match.userPhoto,
          ),
        ),
      );
}
