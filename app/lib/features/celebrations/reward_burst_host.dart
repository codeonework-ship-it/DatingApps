import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/providers/api_client_provider.dart';
import '../auth/providers/auth_provider.dart';
import 'reward_burst.dart';
import 'reward_ledger.dart';

/// Celebrates every new reward and achievement with a theme-aware burst.
///
/// Place it once inside the signed-in shell, next to the rose rain host. It
/// reads level, recent XP and active badges when it mounts, whenever the app
/// returns to the foreground and every [pollInterval] while the app is open,
/// and also hears the Level & XP screen's own loads (including the reload
/// after a reward is claimed). Whatever is new since the last look plays as
/// one burst; what was celebrated is remembered per member on the device, so
/// nothing replays. It renders nothing itself.
class RewardBurstHost extends ConsumerStatefulWidget {
  const RewardBurstHost({
    this.pollInterval = const Duration(seconds: 60),
    this.store = const RewardSeenStore(),
    this.clock = DateTime.now,
    super.key,
  });

  final Duration pollInterval;
  final RewardSeenStore store;
  final DateTime Function() clock;

  @override
  ConsumerState<RewardBurstHost> createState() => _RewardBurstHostState();
}

class _RewardBurstHostState extends ConsumerState<RewardBurstHost>
    with WidgetsBindingObserver {
  Timer? _poll;
  bool _foreground = true;
  bool _fetching = false;
  Future<void> _chain = Future<void>.value();
  String? _cachedUser;
  RewardSeenState? _cached;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _poll = Timer.periodic(widget.pollInterval, (_) {
      if (_foreground) {
        _refresh();
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
        _refresh();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _foreground = false;
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _refresh() async {
    if (_fetching || !mounted) {
      return;
    }
    final userId = _userId();
    if (userId == null) {
      return;
    }
    _fetching = true;
    try {
      final snapshot = await fetchRewardSnapshot(
        ref.read(apiClientProvider),
        userId,
      );
      _ingest(userId, snapshot);
    } finally {
      _fetching = false;
    }
  }

  String? _userId() {
    final id = ref.read(authNotifierProvider).userId?.trim() ?? '';
    return id.isEmpty ? null : id;
  }

  /// Diffs one snapshot at a time, so two sources reporting together can
  /// never celebrate the same reward twice.
  void _ingest(String userId, RewardSnapshot snapshot) {
    _chain = _chain
        .then((_) => _apply(userId, snapshot))
        .catchError((Object _) {});
  }

  Future<void> _apply(String userId, RewardSnapshot snapshot) async {
    final seen = _cachedUser == userId && _cached != null
        ? _cached!
        : await widget.store.read(userId);
    final diff = diffRewards(
      seen: seen,
      snapshot: snapshot,
      now: widget.clock(),
      // The member's language as shown, so the card matches the app.
      l10n: mounted ? l10nOrEnglish(context) : null,
    );
    _cachedUser = userId;
    _cached = diff.next;
    // Saved before the burst plays: closing the app mid-burst never replays.
    await widget.store.write(userId, diff.next);
    final burst = diff.burst;
    if (burst != null && mounted) {
      unawaited(showRewardBurst(context, burst));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RewardSnapshot?>(rewardSnapshotReportsProvider, (_, next) {
      final userId = _userId();
      if (next != null && userId != null) {
        _ingest(userId, next);
      }
    });
    return const SizedBox.shrink();
  }
}
