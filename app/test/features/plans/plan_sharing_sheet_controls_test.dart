import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/plans/models/date_plan.dart';
import 'package:verified_dating_app/features/plans/screens/plan_sharing_sheet.dart';

import '../../support/qa_api.dart';
import '../swipe/qa_screen_checks.dart';
import 'plans_qa_world.dart';

// Contact sharing for one plan, opened the way the app opens it
// (showPlanSharingSheet) from a launcher page. The fake BFF keeps the
// shared contact list and its version, so a save changes what the next GET
// returns.

final _en = qaL10n(const Locale('en'));

const _sharing = '/matches/match-1/plans/plan-1/sharing';

PlansWorld _world({List<String>? sharedWith}) => PlansWorld(
  plan: planJson(status: 'accepted', nextAction: 'upcoming'),
  contacts: [
    {'id': 'meera', 'name': 'Meera'},
    {'id': 'dev', 'name': 'Dev'},
    {'id': 'quiet'},
  ],
  sharedWith: sharedWith,
);

Future<List<Object?>> _openSheet(
  WidgetTester tester,
  PlansWorld world, {
  Locale? locale,
}) async {
  final results = <Object?>[];
  final plan = DatePlan.fromJson(world.plan!);
  await pumpQa(
    tester,
    world.api,
    SheetLauncher(
      open: (context) => showPlanSharingSheet(context, plan),
      results: results,
    ),
    locale: locale,
  );
  await tester.tap(byKey('qa.test.open_sheet'));
  await settle(tester);
  return results;
}

bool _checked(WidgetTester tester, String id) =>
    tester.widget<CheckboxListTile>(byKey('qa.plan.contact.$id')).value ??
    false;

Map<String, dynamic> _saved(PlansWorld world) =>
    world.api.sent('POST', _sharing).last.body;

void main() {
  testWidgets(
    'showPlanSharingSheet opens contact sharing for the plan with the '
    "server's current choices "
    '[case:plans.plan_sharing_sheet.showmodalbottomsheet_open.action]',
    (tester) async {
      final world = _world(sharedWith: ['dev']);
      await _openSheet(tester, world);

      expect(find.byType(PlanSharingSheet), findsOneWidget);
      expect(
        tester.widget<PlanSharingSheet>(find.byType(PlanSharingSheet)).plan.id,
        'plan-1',
      );
      expect(find.text(_en.planSharingTitle), findsOneWidget);
      expect(world.api.sent('GET', _sharing), hasLength(1));
      expect(_checked(tester, 'dev'), isTrue);
      expect(_checked(tester, 'meera'), isFalse);
      expect(find.text(_en.planSharingPreviewCount(1)), findsOneWidget);
      expect(world.api.writes, isEmpty);
    },
  );

  testWidgets(
    'ticking a contact (a nameless one reads "A friend") adds them to the '
    'preview and to what is saved '
    '[case:plans.plan_sharing_sheet.plan_contact_contact.action]',
    (tester) async {
      final world = _world();
      await _openSheet(tester, world);
      expect(find.text(_en.planSharingFriendFallback), findsOneWidget);
      expect(find.text(_en.planSharingPreviewNone), findsOneWidget);

      await tapKey(tester, 'qa.plan.contact.quiet');
      await tapKey(tester, 'qa.plan.contact.meera');
      expect(_checked(tester, 'quiet'), isTrue);
      expect(_checked(tester, 'meera'), isTrue);
      expect(find.text(_en.planSharingPreviewCount(2)), findsOneWidget);
      expect(find.text(_en.planSharingShareSelected), findsOneWidget);

      await tapKey(tester, 'qa.plan.contact.meera');
      expect(_checked(tester, 'meera'), isFalse);
      expect(find.text(_en.planSharingPreviewCount(1)), findsOneWidget);

      await tapKey(tester, 'qa.plan.sharing.save');
      expect(_saved(world), {
        'contact_ids': ['quiet'],
        'expected_version': 3,
      });
    },
  );

  testWidgets('Close sharing closes the sheet without saving the changes '
      '[case:plans.plan_sharing_sheet.plan_sharing_close.action]', (
    tester,
  ) async {
    final world = _world();
    final results = await _openSheet(tester, world);
    await tapKey(tester, 'qa.plan.contact.meera');

    await tapKey(tester, 'qa.plan.sharing.close');

    expect(find.byType(PlanSharingSheet), findsNothing);
    expect(results, [null]);
    expect(world.api.writes, isEmpty);
    expect(world.sharedWith, isEmpty);
    expect(qaSnackText(tester), isNull);
  });

  testWidgets(
    'Deselect everyone clears every choice; saving then turns sharing off '
    '[case:plans.plan_sharing_sheet.plan_sharing_deselect_all.action]',
    (tester) async {
      final world = _world(sharedWith: ['meera', 'dev']);
      await _openSheet(tester, world);
      expect(find.text(_en.planSharingPreviewCount(2)), findsOneWidget);

      await tapKey(tester, 'qa.plan.sharing.deselect_all');

      expect(_checked(tester, 'meera'), isFalse);
      expect(_checked(tester, 'dev'), isFalse);
      expect(find.text(_en.planSharingPreviewNone), findsOneWidget);
      expect(find.text(_en.planSharingKeepOff), findsOneWidget);
      expect(byKey('qa.plan.sharing.deselect_all'), findsNothing);
      expect(world.api.writes, isEmpty);

      await tapKey(tester, 'qa.plan.sharing.save');
      expect(_saved(world), {'contact_ids': <String>[], 'expected_version': 3});
      expect(world.sharedWith, isEmpty);
      expect(qaSnackText(tester), _en.planSharingOffSnack);
      expect(find.byType(PlanSharingSheet), findsNothing);
    },
  );

  testWidgets(
    'Share with selected contacts saves the choice with its version, says '
    'so and closes [case:plans.plan_sharing_sheet.plan_sharing_save.action]',
    (tester) async {
      final world = _world()..commandDelay = const Duration(milliseconds: 300);
      await _openSheet(tester, world);
      await tapKey(tester, 'qa.plan.contact.dev');

      await tester.ensureVisible(byKey('qa.plan.sharing.save'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('qa.plan.sharing.save'));
      await tester.pump();
      expect(find.text(_en.planSharingSaving), findsOneWidget);
      expect(isEnabled(tester, 'qa.plan.sharing.save'), isFalse);
      expect(isEnabled(tester, 'qa.plan.sharing.close'), isFalse);
      await tester.tap(byKey('qa.plan.sharing.save'), warnIfMissed: false);
      await settle(tester);

      expect(world.api.writeLines, ['POST $_sharing']);
      expect(_saved(world), {
        'contact_ids': ['dev'],
        'expected_version': 3,
      });
      expect(world.sharedWith, ['dev']);
      expect(qaSnackText(tester), _en.planSharingSavedSnack);
      expect(find.byType(PlanSharingSheet), findsNothing);
    },
  );

  testWidgets(
    'a failed save explains (server message, fallback, offline), keeps the '
    'choices, never announces success, and a retry saves '
    '[case:plans.plan_sharing_sheet.plan_sharing_save.api_failure]',
    (tester) async {
      final world = _world();
      await _openSheet(tester, world);
      await tapKey(tester, 'qa.plan.contact.meera');

      world.api.fail(
        'POST $_sharing',
        status: 409,
        message: 'Sharing changed. Reload your choices.',
      );
      await tapKey(tester, 'qa.plan.sharing.save');
      expect(tester.takeException(), isNull);
      expect(
        find.text('Sharing changed. Reload your choices.'),
        findsOneWidget,
      );
      expect(byKey('qa.plan.sharing.reload'), findsOneWidget);

      world.api.on('POST $_sharing', (_) => const QaReply(500, ''));
      await tapKey(tester, 'qa.plan.sharing.save');
      expect(find.text(_en.planSharingSaveFailed), findsOneWidget);

      world.api.offline('POST $_sharing');
      await tapKey(tester, 'qa.plan.sharing.save');
      expect(find.text(_en.networkOfflineTryAgain), findsOneWidget);

      expect(qaSnackText(tester), isNull);
      expect(find.byType(PlanSharingSheet), findsOneWidget);
      expect(_checked(tester, 'meera'), isTrue);
      expect(find.text(_en.planSharingPreviewCount(1)), findsOneWidget);
      expect(world.sharedWith, isEmpty);

      world.serve();
      await tapKey(tester, 'qa.plan.sharing.save');
      expect(world.api.sent('POST', _sharing), hasLength(4));
      expect(_saved(world)['contact_ids'], ['meera']);
      expect(world.sharedWith, ['meera']);
      expect(qaSnackText(tester), _en.planSharingSavedSnack);
      expect(find.byType(PlanSharingSheet), findsNothing);
    },
  );

  testWidgets(
    'Reload sharing choices fetches the choices again after a failed load '
    'and the sheet works again '
    '[case:plans.plan_sharing_sheet.plan_sharing_reload.action]',
    (tester) async {
      final world = _world(sharedWith: ['meera']);
      world.api.on('GET $_sharing', (_) => const QaReply(500, ''));
      await _openSheet(tester, world);
      expect(find.text(_en.planSharingLoadFailed), findsOneWidget);
      expect(byKey('qa.plan.contact.meera'), findsNothing);
      expect(isEnabled(tester, 'qa.plan.sharing.save'), isFalse);

      world.serve();
      await tapKey(tester, 'qa.plan.sharing.reload');

      expect(world.api.sent('GET', _sharing), hasLength(2));
      expect(find.text(_en.planSharingLoadFailed), findsNothing);
      expect(byKey('qa.plan.sharing.reload'), findsNothing);
      expect(_checked(tester, 'meera'), isTrue);
      expect(isEnabled(tester, 'qa.plan.sharing.save'), isTrue);
    },
  );

  testWidgets(
    'a failed reload explains and keeps the list on screen; a retry brings '
    "the server's latest version for the next save "
    '[case:plans.plan_sharing_sheet.plan_sharing_reload.api_failure]',
    (tester) async {
      final world = _world();
      await _openSheet(tester, world);
      await tapKey(tester, 'qa.plan.contact.dev');
      // Someone else saved meanwhile: version moved on, the save conflicts.
      world.api.fail('POST $_sharing', status: 409, message: 'Reload first.');
      await tapKey(tester, 'qa.plan.sharing.save');
      expect(find.text('Reload first.'), findsOneWidget);

      world.api.fail('GET $_sharing', message: 'Sharing is resting.');
      await tapKey(tester, 'qa.plan.sharing.reload');
      expect(tester.takeException(), isNull);
      expect(find.text('Sharing is resting.'), findsOneWidget);
      expect(byKey('qa.plan.contact.meera'), findsOneWidget);
      expect(_checked(tester, 'dev'), isTrue);

      world.api.offline('GET $_sharing');
      await tapKey(tester, 'qa.plan.sharing.reload');
      expect(find.text(_en.networkOfflineTryAgain), findsOneWidget);
      expect(byKey('qa.plan.contact.meera'), findsOneWidget);

      world
        ..sharingVersion = 7
        ..sharedWith = ['meera']
        ..serve();
      await tapKey(tester, 'qa.plan.sharing.reload');
      expect(find.text(_en.networkOfflineTryAgain), findsNothing);
      expect(_checked(tester, 'meera'), isTrue);
      expect(_checked(tester, 'dev'), isFalse);

      await tapKey(tester, 'qa.plan.contact.dev');
      await tapKey(tester, 'qa.plan.sharing.save');
      expect(_saved(world), {
        'contact_ids': ['meera', 'dev'],
        'expected_version': 7,
      });
      expect(find.byType(PlanSharingSheet), findsNothing);
    },
  );

  testWidgets(
    'contact sharing renders translated in every locale with no English '
    'left [case:plans.plan_sharing_sheet.l10n]',
    (tester) async {
      const fixture = {'Meera', 'Dev', 'open sheet'};
      List<String>? english;
      for (final locale in [
        const Locale('en'),
        ...qaLocales.where((l) => l != const Locale('en')),
      ]) {
        final world = _world(sharedWith: ['meera']);
        await _openSheet(tester, world, locale: locale);
        final l10n = qaL10n(locale);
        expect(tester.takeException(), isNull, reason: '$locale');
        expect(find.text(l10n.planSharingTitle), findsOneWidget);
        expect(find.text(l10n.planSharingIntro), findsOneWidget);
        expect(find.text(l10n.planSharingPreviewCount(1)), findsOneWidget);
        expect(find.text(l10n.planSharingShareSelected), findsOneWidget);
        expect(find.text(l10n.planSharingFriendFallback), findsOneWidget);
        expect(find.text(l10n.planSharingDeselectAll), findsOneWidget);
        if (locale.languageCode != 'en') {
          qaExpectNoEnglishLeaks(tester, locale, allow: fixture);
        }
        final strings = qaVisibleStrings(tester);
        if (locale == const Locale('en')) {
          english = strings;
        } else if (locale == const Locale('de')) {
          expect(
            qaUntranslated(english!, strings, fixture: fixture),
            isEmpty,
            reason: 'hard-coded strings in the sharing sheet',
          );
        }
        await teardown(tester);
      }
    },
  );
}
