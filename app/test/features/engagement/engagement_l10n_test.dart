import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/i18n/app_locale_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/engagement/providers/level_progression_provider.dart';
import 'package:verified_dating_app/features/engagement/providers/moderation_appeals_provider.dart';
import 'package:verified_dating_app/features/engagement/screens/level_progression_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _SignedOut extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

class _FakeLevels extends LevelProgressionNotifier {
  _FakeLevels(super.ref) {
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
        levels: <LevelDefinition>[],
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

  @override
  Future<void> load() async {}
}

void main() {
  testWidgets('Level & XP screen renders in German', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [levelProgressionProvider.overrideWith(_FakeLevels.new)],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LevelProgressionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Level-Pfad'), findsOneWidget);
    expect(find.text('Belohnungen'), findsOneWidget);
    // Server content (level and reward names) stays as sent.
    expect(find.text('Reliable Participant'), findsOneWidget);
    expect(find.text('Starter accent'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Tagesimpuls beantwortet'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Tagesimpuls beantwortet'), findsOneWidget);
    expect(find.text('Standardvergabe'), findsOneWidget);
    expect(find.text('Level path'), findsNothing);
  });

  test('provider fallback messages follow the chosen language', () async {
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(_SignedOut.new),
        appLocaleProvider.overrideWith(
          (ref) => AppLocaleNotifier(ref, initial: const Locale('de')),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(levelProgressionProvider);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(levelProgressionProvider).error,
      'Melde dich an, um deinen Level-Fortschritt zu sehen.',
    );
  });

  test('appeal status labels are localized when strings are passed', () {
    final de = lookupAppLocalizations(const Locale('de'));
    expect(appealStatusLabel('under_review', de), 'In Prüfung');
    expect(appealStatusLabel('under_review'), 'Under review');
    expect(appealStatusLabel('custom_status', de), 'custom_status');
  });
}
