import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engagement/providers/level_progression_provider.dart';
import '../engagement/providers/trust_badges_provider.dart';

/// What kind of moment a reward burst celebrates. The card's icon and wording
/// follow it; the particles follow the member's look.
enum RewardBurstKind { xp, levelUp, rewardClaimed, badge, wallTier }

/// One celebration: a headline, an optional line under it, the XP it brought
/// and up to three detail lines when several rewards arrive together.
class RewardBurst {
  const RewardBurst({
    required this.kind,
    required this.title,
    this.subtitle = '',
    this.xp = 0,
    this.lines = const <String>[],
  });

  /// A reward the member just claimed on the Level & XP screen.
  factory RewardBurst.rewardClaimed(String name, {String description = ''}) =>
      RewardBurst(
        kind: RewardBurstKind.rewardClaimed,
        title: 'Reward claimed',
        subtitle: description.isEmpty ? name : '$name · $description',
      );

  final RewardBurstKind kind;
  final String title;
  final String subtitle;

  /// XP gained, shown as a "+N XP" pill when above zero.
  final int xp;
  final List<String> lines;

  /// One sentence for screen readers.
  String get announcement => [
    title,
    if (subtitle.isNotEmpty) subtitle,
    if (xp > 0) 'plus $xp XP',
    ...lines,
  ].join('. ');
}

/// The reward state the app last saw, read from the server. Any part is null
/// when it could not be loaded; a null part is left untouched by the diff.
class RewardSnapshot {
  const RewardSnapshot({this.ledger, this.level, this.levelName, this.badges});

  final List<XPEntry>? ledger;
  final int? level;
  final String? levelName;

  /// Active badges only.
  final List<TrustBadgeItem>? badges;
}

/// Places that already load reward data (the Level & XP provider, including
/// the reload after a reward is claimed) report it here, so the burst host can
/// celebrate the moment the screen shows something new without fetching it
/// again. Listening has no side effects.
final rewardSnapshotReportsProvider = StateProvider<RewardSnapshot?>(
  (ref) => null,
);

/// What has already been celebrated for one member, kept on the device.
///
/// Each part starts unknown (null). The first time a part is seen it becomes
/// the baseline instead of a celebration, so a fresh install never replays a
/// member's whole history.
class RewardSeenState {
  const RewardSeenState({this.xpSequence, this.level, this.badges});

  factory RewardSeenState.fromJson(Map<String, dynamic> json) =>
      RewardSeenState(
        xpSequence: (json['xp_sequence'] as num?)?.toInt(),
        level: (json['level'] as num?)?.toInt(),
        badges: (json['badges'] as List?)?.map((e) => e.toString()).toSet(),
      );

  /// Highest XP ledger sequence already celebrated (or baselined).
  final int? xpSequence;
  final int? level;

  /// Every badge code ever celebrated, so a badge that lapses and returns
  /// does not play twice.
  final Set<String>? badges;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (xpSequence != null) 'xp_sequence': xpSequence,
    if (level != null) 'level': level,
    if (badges != null) 'badges': badges!.toList()..sort(),
  };
}

class RewardDiff {
  const RewardDiff({required this.next, this.burst});

  final RewardSeenState next;

  /// Null when there is nothing new to celebrate.
  final RewardBurst? burst;
}

/// How far back a first look at the ledger still celebrates: rewards earned
/// in the last day get one summary card; anything older becomes baseline.
const Duration kFirstLookWindow = Duration(hours: 24);

/// XP sources that already have their own celebration card (the wall tier
/// and Cover of the Week shower, which is itself theme-aware), so the XP
/// they bring is not announced twice.
const Set<String> kSourcesCelebratedElsewhere = {
  'wall_tier_reached',
  'cover_of_week',
};

bool _celebratesHere(XPEntry e) =>
    e.awardedXp > 0 && !kSourcesCelebratedElsewhere.contains(e.source);

/// Compares [snapshot] with what was already celebrated and returns the next
/// seen state plus, at most, one burst that summarises everything new.
RewardDiff diffRewards({
  required RewardSeenState seen,
  required RewardSnapshot snapshot,
  required DateTime now,
}) {
  var xpSequence = seen.xpSequence;
  var level = seen.level;
  var badges = seen.badges;

  final fresh = <XPEntry>[];
  var firstLook = false;
  final ledger = snapshot.ledger;
  if (ledger != null) {
    final top = ledger.fold<int>(
      xpSequence ?? 0,
      (best, e) => e.sequence > best ? e.sequence : best,
    );
    if (xpSequence == null) {
      firstLook = true;
      fresh.addAll(
        ledger.where(
          (e) =>
              _celebratesHere(e) &&
              e.occurredAt != null &&
              now.difference(e.occurredAt!).abs() <= kFirstLookWindow,
        ),
      );
    } else {
      final last = xpSequence;
      fresh.addAll(
        ledger.where((e) => e.sequence > last && _celebratesHere(e)),
      );
    }
    xpSequence = top;
  }

  int? levelUp;
  final newLevel = snapshot.level;
  if (newLevel != null) {
    if (level != null && newLevel > level) {
      levelUp = newLevel;
    }
    level = newLevel;
  }

  final newBadges = <TrustBadgeItem>[];
  final active = snapshot.badges;
  if (active != null) {
    final known = badges;
    if (known != null) {
      newBadges.addAll(active.where((b) => !known.contains(b.code)));
    }
    badges = {...?known, ...active.map((b) => b.code)};
  }

  final next = RewardSeenState(
    xpSequence: xpSequence,
    level: level,
    badges: badges,
  );
  fresh.sort((a, b) => b.sequence.compareTo(a.sequence));
  final xp = fresh.fold<int>(0, (sum, e) => sum + e.awardedXp);
  final xpLines = [
    for (final e in fresh.take(3))
      '${rewardSourceLabel(e.source)} +${e.awardedXp} XP',
    if (fresh.length > 3) 'and ${fresh.length - 3} more',
  ];
  final badgeLines = [for (final b in newBadges) 'Badge: ${b.label}'];

  if (levelUp != null) {
    final name = snapshot.levelName?.trim() ?? '';
    return RewardDiff(
      next: next,
      burst: RewardBurst(
        kind: RewardBurstKind.levelUp,
        title: 'Level $levelUp reached',
        subtitle: name,
        xp: xp,
        lines: [...badgeLines, ...xpLines].take(4).toList(),
      ),
    );
  }
  if (newBadges.isNotEmpty) {
    return RewardDiff(
      next: next,
      burst: RewardBurst(
        kind: RewardBurstKind.badge,
        title: newBadges.length == 1
            ? 'Badge earned'
            : '${newBadges.length} badges earned',
        subtitle: newBadges.length == 1 ? newBadges.single.label : '',
        xp: xp,
        lines: [
          if (newBadges.length > 1) ...badgeLines,
          ...xpLines,
        ].take(4).toList(),
      ),
    );
  }
  if (fresh.isEmpty) {
    return RewardDiff(next: next);
  }
  if (fresh.length == 1 && !firstLook) {
    final only = fresh.single;
    return RewardDiff(
      next: next,
      burst: RewardBurst(
        kind: RewardBurstKind.xp,
        title: rewardSourceLabel(only.source),
        subtitle: rewardSourceLine(only.source),
        xp: only.awardedXp,
      ),
    );
  }
  return RewardDiff(
    next: next,
    burst: RewardBurst(
      kind: RewardBurstKind.xp,
      title: firstLook ? 'Your rewards today' : '${fresh.length} new rewards',
      xp: xp,
      lines: xpLines,
    ),
  );
}

/// A friendly name for an XP ledger source.
String rewardSourceLabel(String source) => switch (source) {
  'story_published' => 'Chapter published',
  'photo_shared' => 'Photo shared',
  'like_received' => 'A member liked your work',
  'comment_received' => 'New comment on your work',
  'comment_approved' => 'Your comment was approved',
  'subscriber_gained' => 'New subscriber',
  'wall_tier_reached' => 'Wall tier reached',
  'cover_of_week' => 'Cover of the Week',
  'daily_prompt_submitted' => 'Daily prompt answered',
  _ =>
    source
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' '),
};

/// The line under a single reward's headline.
String rewardSourceLine(String source) => switch (source) {
  'story_published' => 'Your chapter is out in the world.',
  'photo_shared' => 'Your photo joined the theme.',
  'like_received' => 'Someone loved what you shared.',
  'comment_received' => 'A reader joined the conversation.',
  'subscriber_gained' => 'Someone wants your next chapter.',
  'wall_tier_reached' => 'Your work reached more walls.',
  'cover_of_week' => 'Everyone sees it on Today this week.',
  _ => 'Earned for meaningful activity.',
};

/// Keeps [RewardSeenState] per signed-in member in shared preferences.
class RewardSeenStore {
  const RewardSeenStore();

  static String keyFor(String userId) => 'reward_burst.seen.v1.$userId';

  Future<RewardSeenState> read(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(keyFor(userId));
      if (raw == null || raw.isEmpty) {
        return const RewardSeenState();
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return RewardSeenState.fromJson(decoded);
      }
    } on Object {
      // A corrupt record starts a new baseline rather than replaying.
    }
    return const RewardSeenState();
  }

  Future<void> write(String userId, RewardSeenState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyFor(userId), jsonEncode(state.toJson()));
    } on Object {
      // Best effort; the worst case is one repeated card.
    }
  }
}

/// Reads level, recent XP and active badges in one go. Each part that fails
/// comes back null so a flaky endpoint never resets or replays anything.
Future<RewardSnapshot> fetchRewardSnapshot(Dio api, String userId) async {
  Future<Map<String, dynamic>?> get(
    String path, [
    Map<String, dynamic>? query,
  ]) async {
    try {
      final response = await api.get<dynamic>(path, queryParameters: query);
      return (response.data as Map?)?.cast<String, dynamic>();
    } on Object {
      return null;
    }
  }

  final results = await Future.wait([
    get('/progression/$userId'),
    get('/progression/$userId/ledger', const {'limit': 30}),
    get('/users/$userId/trust-badges'),
  ]);
  final progression = (results[0]?['progression'] as Map?)
      ?.cast<String, dynamic>();
  final ledgerRaw = results[1]?['entries'];
  final badgesRaw = results[2]?['badges'];
  return RewardSnapshot(
    level: (progression?['current_level'] as num?)?.toInt(),
    levelName: progression?['level_name']?.toString(),
    ledger: ledgerRaw is List
        ? ledgerRaw
              .whereType<Map<dynamic, dynamic>>()
              .map((e) => XPEntry.fromJson(e.cast()))
              .toList()
        : null,
    badges: badgesRaw is List
        ? activeBadges(
            badgesRaw.whereType<Map<dynamic, dynamic>>().map((e) {
              final map = e.cast<String, dynamic>();
              return TrustBadgeItem(
                code: map['badge_code']?.toString() ?? '',
                label: map['badge_label']?.toString() ?? 'New badge',
                status: map['status']?.toString() ?? 'inactive',
                awardedAt: map['awarded_at']?.toString() ?? '',
              );
            }),
          )
        : null,
  );
}

/// Badges that count as earned right now.
List<TrustBadgeItem> activeBadges(Iterable<TrustBadgeItem> badges) => badges
    .where((b) => b.code.isNotEmpty && b.status.toLowerCase() == 'active')
    .toList();
