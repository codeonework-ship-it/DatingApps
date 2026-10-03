import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/celebrations/reward_burst.dart';
import 'package:verified_dating_app/features/celebrations/reward_ledger.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';

// The reward burst card in every language, and its Close control.

/// A level-up burst worded in [l], the way diffRewards words one.
RewardBurst _levelUp(AppLocalizations l) => RewardBurst(
  kind: RewardBurstKind.levelUp,
  title: l.rewardLevelReached(4),
  xp: 35,
  lines: [
    l.rewardSourceXpLine(rewardSourceLabel('story_published', l), 25),
    l.rewardSourceXpLine(rewardSourceLabel('like_received', l), 10),
  ],
);

void main() {
  tearDown(debugResetRewardBursts);

  testWidgets('the reward card renders in every locale with no English left '
      '[case:celebrations.reward_burst.l10n]', (tester) async {
    var closed = 0;
    await qaExpectRendersInAllLocales(
      tester,
      QaApi(),
      () => Builder(
        builder: (context) => RewardBurstOverlay(
          burst: _levelUp(AppLocalizations.of(context)),
          onDone: () => closed++,
          lingerFor: const Duration(minutes: 1),
        ),
      ),
      expected: [
        (l) => l.rewardLevelReached(4),
        (l) => l.rewardXpPill(35),
        (l) => l.rewardSourceXpLine(l.rewardSourceStoryPublished, 25),
      ],
      // Every locale writes the pill "+N XP" (app_*.arb rewardXpPill).
      allow: {'+35 XP'},
      prepare: (tester, l) async {
        // Close is labelled in the member's language.
        expect(find.byTooltip(l.commonClose), findsOneWidget);
      },
    );
    // The same card worded through the claim factory, in German.
    final de = qaL10n(const Locale('de'));
    final claimed = RewardBurst.rewardClaimed('Starter accent', l10n: de);
    expect(claimed.title, de.rewardClaimedTitle);
    expect(claimed.title, isNot(qaL10n(const Locale('en')).rewardClaimedTitle));
    expect(closed, 0, reason: 'nothing closed the card while rendering');
  });

  testWidgets('Close removes the card at once, completes the burst and lets '
      'the next queued one show '
      '[case:celebrations.reward_burst.reward_burst_close_done.action]', (
    tester,
  ) async {
    late BuildContext ctx;
    await pumpQa(
      tester,
      QaApi(),
      Builder(
        builder: (context) {
          ctx = context;
          return const Scaffold(body: SizedBox.expand());
        },
      ),
    );
    final en = qaL10n(const Locale('en'));
    var firstDone = false;
    unawaited(showRewardBurst(ctx, _levelUp(en)).then((_) => firstDone = true));
    unawaited(
      showRewardBurst(ctx, RewardBurst.rewardClaimed('Starter accent')),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(en.rewardLevelReached(4)), findsOneWidget);
    expect(find.text(en.rewardClaimedTitle), findsNothing);

    await tester.tap(find.byKey(const ValueKey('qa.reward_burst.close')));
    await tester.pump();
    expect(firstDone, isTrue);
    expect(find.text(en.rewardLevelReached(4)), findsNothing);
    expect(find.text(en.rewardClaimedTitle), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.byKey(const ValueKey('qa.reward_burst.close')));
    await tester.pump();
    expect(find.byType(RewardBurstOverlay), findsNothing);
    await tester.pump(const Duration(seconds: 4));
  });
}
