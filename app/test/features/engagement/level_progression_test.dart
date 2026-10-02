import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/engagement/providers/level_progression_provider.dart';
import 'package:verified_dating_app/features/engagement/screens/level_progression_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

void main() {
  test('parses projected level state, rewards, and trust controls', () {
    final view = LevelProgressionView.fromJson(<String, dynamic>{
      'total_xp': 275,
      'current_level': 3,
      'level_name': 'Reliable Participant',
      'current_level_xp': 25,
      'next_level_xp': 500,
      'progress_percent': 10,
      'trust_gate_satisfied': false,
      'progression_frozen': true,
      'projection_lag_seconds': 0.4,
      'levels': <dynamic>[
        <String, dynamic>{
          'level': 3,
          'name': 'Reliable Participant',
          'threshold_xp': 250,
          'trust_gate': false,
          'reward_summary': 'Weekly visibility micro-boost',
        },
      ],
      'rewards': <dynamic>[
        <String, dynamic>{
          'reward_key': 'starter_accent',
          'level': 2,
          'name': 'Starter accent',
          'description': 'Profile accent',
          'reward_type': 'cosmetic',
          'trust_required': false,
          'claimed': true,
        },
      ],
    });

    expect(view.totalXp, 275);
    expect(view.currentLevel, 3);
    expect(view.frozen, isTrue);
    expect(view.trustGateSatisfied, isFalse);
    expect(view.levels.single.thresholdXp, 250);
    expect(view.rewards.single.claimed, isTrue);
  });

  testWidgets('renders level, non-paywall copy, rewards, and ledger', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [levelProgressionProvider.overrideWith(_FakeNotifier.new)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LevelProgressionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Level & XP'), findsOneWidget);
    expect(find.text('Reliable Participant'), findsWidgets);
    expect(
      find.textContaining('Purchases never increase your level'),
      findsOneWidget,
    );
    expect(find.text('Starter accent'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Daily Prompt Submitted'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Daily Prompt Submitted'), findsOneWidget);
  });
}

class _FakeNotifier extends LevelProgressionNotifier {
  _FakeNotifier(Ref ref) : super(ref) {
    state = const LevelProgressionState(
      view: LevelProgressionView(
        totalXp: 320,
        currentLevel: 3,
        levelName: 'Reliable Participant',
        currentLevelXp: 70,
        nextLevelXp: 500,
        progressPercent: 28,
        trustGateSatisfied: true,
        frozen: false,
        projectionLagSeconds: 0,
        levels: <LevelDefinition>[
          LevelDefinition(
            level: 3,
            name: 'Reliable Participant',
            thresholdXp: 250,
            trustGate: false,
            rewardSummary: 'Weekly visibility micro-boost',
          ),
        ],
        rewards: <LevelReward>[
          LevelReward(
            key: 'starter_accent',
            level: 2,
            name: 'Starter accent',
            description: 'A profile accent earned through activity.',
            type: 'cosmetic',
            trustRequired: false,
            claimed: false,
          ),
        ],
      ),
      ledger: <XPEntry>[
        XPEntry(
          sequence: 1,
          source: 'daily_prompt_submitted',
          awardedXp: 20,
          multiplier: 1,
          occurredAt: null,
        ),
      ],
    );
  }

  Future<void> load() async {}
}
