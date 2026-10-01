import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verified_dating_app/features/celebrations/reward_ledger.dart';
import 'package:verified_dating_app/features/engagement/providers/level_progression_provider.dart';
import 'package:verified_dating_app/features/engagement/providers/trust_badges_provider.dart';

final _now = DateTime.utc(2026, 10, 1, 12);

XPEntry _xp(
  int sequence,
  String source,
  int xp, {
  Duration ago = Duration.zero,
}) => XPEntry(
  sequence: sequence,
  source: source,
  awardedXp: xp,
  multiplier: 1,
  occurredAt: _now.subtract(ago),
);

TrustBadgeItem _badge(String code, String label) =>
    TrustBadgeItem(code: code, label: label, status: 'active', awardedAt: '');

void main() {
  group('first look', () {
    test('an old backlog becomes the baseline, never a burst', () {
      final diff = diffRewards(
        seen: const RewardSeenState(),
        snapshot: RewardSnapshot(
          ledger: [
            for (var i = 1; i <= 12; i++)
              _xp(i, 'like_received', 2, ago: const Duration(days: 3)),
          ],
          level: 3,
          badges: [_badge('respectful', 'Respectful Communicator')],
        ),
        now: _now,
      );
      expect(diff.burst, isNull);
      expect(diff.next.xpSequence, 12);
      expect(diff.next.level, 3);
      expect(diff.next.badges, {'respectful'});
    });

    test("today's rewards play as a single summary", () {
      final diff = diffRewards(
        seen: const RewardSeenState(),
        snapshot: RewardSnapshot(
          ledger: [
            _xp(9, 'story_published', 25, ago: const Duration(hours: 2)),
            _xp(8, 'like_received', 2, ago: const Duration(hours: 5)),
            _xp(7, 'like_received', 2, ago: const Duration(days: 4)),
          ],
          level: 2,
        ),
        now: _now,
      );
      expect(diff.burst?.title, 'Your rewards today');
      expect(diff.burst?.xp, 27);
      expect(diff.burst?.lines, hasLength(2));
      expect(diff.next.xpSequence, 9);
    });
  });

  test('celebrates only entries newer than the last one seen, once', () {
    const seen = RewardSeenState(xpSequence: 4, level: 2, badges: {});
    final snapshot = RewardSnapshot(
      ledger: [
        _xp(5, 'story_published', 25),
        _xp(4, 'like_received', 2),
        _xp(3, 'like_received', 2),
      ],
      level: 2,
      badges: const [],
    );
    final first = diffRewards(seen: seen, snapshot: snapshot, now: _now);
    expect(first.burst?.kind, RewardBurstKind.xp);
    expect(first.burst?.title, 'Chapter published');
    expect(first.burst?.xp, 25);
    expect(first.next.xpSequence, 5);

    final again = diffRewards(seen: first.next, snapshot: snapshot, now: _now);
    expect(again.burst, isNull);
  });

  test('several new rewards are grouped into one summary', () {
    final diff = diffRewards(
      seen: const RewardSeenState(xpSequence: 10),
      snapshot: RewardSnapshot(
        ledger: [
          for (var i = 11; i <= 16; i++) _xp(i, 'like_received', 2),
          _xp(17, 'subscriber_gained', 10),
        ],
      ),
      now: _now,
    );
    expect(diff.burst?.title, '7 new rewards');
    expect(diff.burst?.xp, 22);
    expect(diff.burst?.lines.first, 'New subscriber +10 XP');
    expect(diff.burst?.lines.last, 'and 4 more');
  });

  test('clawbacks and wall-tier XP are not announced as XP bursts', () {
    final diff = diffRewards(
      seen: const RewardSeenState(xpSequence: 1),
      snapshot: RewardSnapshot(
        ledger: [
          _xp(2, 'like_received', -2),
          _xp(3, 'wall_tier_reached', 50),
          _xp(4, 'cover_of_week', 150),
        ],
      ),
      now: _now,
    );
    expect(diff.burst, isNull);
    expect(diff.next.xpSequence, 4);
  });

  test('a level-up leads the burst and carries the XP and badges', () {
    final diff = diffRewards(
      seen: const RewardSeenState(xpSequence: 1, level: 3, badges: {'a'}),
      snapshot: RewardSnapshot(
        ledger: [_xp(2, 'photo_shared', 20)],
        level: 4,
        levelName: 'Conversation Builder',
        badges: [_badge('a', 'A'), _badge('b', 'Bright Spark')],
      ),
      now: _now,
    );
    expect(diff.burst?.kind, RewardBurstKind.levelUp);
    expect(diff.burst?.title, 'Level 4 reached');
    expect(diff.burst?.subtitle, 'Conversation Builder');
    expect(diff.burst?.xp, 20);
    expect(diff.burst?.lines, ['Badge: Bright Spark', 'Photo shared +20 XP']);
    expect(diff.next.level, 4);
  });

  test('a badge plays once, even if it lapses and returns', () {
    const seen = RewardSeenState(badges: {'a'});
    final earned = diffRewards(
      seen: seen,
      snapshot: RewardSnapshot(badges: [_badge('a', 'A'), _badge('b', 'Bee')]),
      now: _now,
    );
    expect(earned.burst?.kind, RewardBurstKind.badge);
    expect(earned.burst?.subtitle, 'Bee');

    final lapsed = diffRewards(
      seen: earned.next,
      snapshot: RewardSnapshot(badges: [_badge('a', 'A')]),
      now: _now,
    );
    expect(lapsed.burst, isNull);
    final back = diffRewards(
      seen: lapsed.next,
      snapshot: RewardSnapshot(badges: [_badge('a', 'A'), _badge('b', 'Bee')]),
      now: _now,
    );
    expect(back.burst, isNull);
  });

  test('a part that failed to load is left untouched', () {
    const seen = RewardSeenState(xpSequence: 7, level: 2, badges: {'a'});
    final diff = diffRewards(
      seen: seen,
      snapshot: const RewardSnapshot(),
      now: _now,
    );
    expect(diff.burst, isNull);
    expect(diff.next.toJson(), seen.toJson());
  });

  test('a lower level after a review updates silently', () {
    final diff = diffRewards(
      seen: const RewardSeenState(level: 5),
      snapshot: const RewardSnapshot(level: 4),
      now: _now,
    );
    expect(diff.burst, isNull);
    expect(diff.next.level, 4);
  });

  test(
    'the seen state is stored per member and survives a round trip',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      const store = RewardSeenStore();
      await store.write(
        'u1',
        const RewardSeenState(xpSequence: 3, level: 2, badges: {'b', 'a'}),
      );
      final back = await store.read('u1');
      expect(back.xpSequence, 3);
      expect(back.level, 2);
      expect(back.badges, {'a', 'b'});
      final other = await store.read('u2');
      expect(other.xpSequence, isNull);
      expect(other.badges, isNull);
    },
  );

  test('friendly labels for every XP source', () {
    expect(rewardSourceLabel('story_published'), 'Chapter published');
    expect(rewardSourceLabel('cover_of_week'), 'Cover of the Week');
    expect(rewardSourceLabel('some_new_thing'), 'Some New Thing');
    expect(
      RewardBurst.rewardClaimed('Starter accent').announcement,
      'Reward claimed. Starter accent',
    );
  });
}
