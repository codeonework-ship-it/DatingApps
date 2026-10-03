// Test names carry literal catalog case ids, which can be long.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_about_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_preview_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_shared_widgets.dart';

import '../../support/qa_api.dart';
import 'support/profile_bff.dart';

// Control-level tests for "About you" (SetupAboutScreen): every control's
// action reaches PATCH /profile/{id}/draft with the value the member chose,
// and failures are explained without losing their edits.

const _bio = ValueKey('qa.setup.about.bio_field');
const _profession = ValueKey('qa.setup.about.profession_field');
const _save = ValueKey('qa.setup.about.save_button');
const _continue = ValueKey('qa.setup.about.continue_button');

final _en = qaL10n(const Locale('en'));

Future<List<Object?>> _open(
  WidgetTester tester,
  QaApi api, {
  bool setupFlow = false,
  Locale? locale,
}) => pumpQa(
  tester,
  api,
  SetupAboutScreen(isSetupFlow: setupFlow),
  launcher: true,
  locale: locale,
  extra: qaMasterDataOverrides(),
);

/// Brings Save into view (after a focused field has finished scrolling
/// itself into view) and taps it.
Future<void> _scrollToSave(WidgetTester tester, {Key key = _save}) async {
  await qaSettle(tester, frames: 3);
  await tester.ensureVisible(find.byKey(key));
  await qaSettle(tester, frames: 3);
}

Future<void> _tapSave(WidgetTester tester, {Key key = _save}) async {
  await _scrollToSave(tester, key: key);
  await tester.tap(find.byKey(key));
  await qaSettle(tester);
}

/// Opens a [GlassDropdown] by key and picks the option labelled [option].
Future<void> _pick(WidgetTester tester, Key dropdown, String option) async {
  await tester.ensureVisible(find.byKey(dropdown));
  await tester.pump();
  await tester.tap(find.byKey(dropdown));
  await qaSettle(tester, frames: 5);
  await tester.tap(find.text(option).last);
  await qaSettle(tester, frames: 5);
}

/// The dropdown showing [hint] (income and religion have no key).
Finder _dropdownAfter(String hint) => find.ancestor(
  of: find.text(hint),
  matching: find.byType(GlassDropdown<String>),
);

Map<String, dynamic> _aboutPatch(ProfileBff bff) =>
    bff.patches.firstWhere((p) => p.containsKey('bio'));
Map<String, dynamic> _lifestylePatch(ProfileBff bff) =>
    bff.patches.firstWhere((p) => p.containsKey('drinking'));

void main() {
  // Regression (2026-10-02): closing the screen after Save re-sent both
  // PATCHes from the back handler (four writes per save).
  testWidgets('Save About sends the about and lifestyle fields once, then '
      'closes [case:profile.setup_about.save_about_onsave.action]', (
    tester,
  ) async {
    final api = QaApi();
    final bff = ProfileBff(api);
    final results = await _open(tester, api);

    await tester.enterText(
      find.byKey(_bio),
      '  I sketch strangers on trains.  ',
    );
    await tester.enterText(find.byKey(_profession), 'Architect');
    await _tapSave(tester);

    expect(api.writeLines, [
      'PATCH /profile/me/draft',
      'PATCH /profile/me/draft',
    ]);
    expect(bff.patches.first, {
      'bio': 'I sketch strangers on trains.',
      'height_cm': null,
      'education': null,
      'profession': 'Architect',
      'income_range': null,
    });
    expect(bff.patches.last, {
      'drinking': 'Never',
      'smoking': 'Never',
      'religion': null,
    });
    expect(find.byType(SetupAboutScreen), findsNothing);
    expect(results, [null]);
  });

  testWidgets('Continue in the setup flow saves and opens the preview '
      '[case:profile.setup_about.save_about_onsave.action]', (tester) async {
    final api = QaApi();
    final bff = ProfileBff(api);
    await _open(tester, api, setupFlow: true);
    await tester.enterText(find.byKey(_bio), 'Weekend hiker and coffee snob.');
    await _tapSave(tester, key: _continue);
    expect(_aboutPatch(bff)['bio'], 'Weekend hiker and coffee snob.');
    expect(find.byType(SetupPreviewScreen), findsOneWidget);
  });

  testWidgets('a failed save explains, keeps the edits and re-enables Save; '
      'retry sends once '
      '[case:profile.setup_about.save_about_onsave.api_failure]', (
    tester,
  ) async {
    final api = QaApi();
    final bff = ProfileBff(api);
    api.fail('PATCH /profile/*/draft', message: 'Draft store unavailable');
    final results = await _open(tester, api);
    await tester.enterText(find.byKey(_bio), 'Edited bio that must survive.');
    await _tapSave(tester);

    expect(qaSnackText(tester), _en.profileSetupSaveFailed);
    expect(api.sent('PATCH', '/profile/*/draft'), hasLength(1));
    expect(find.byType(SetupAboutScreen), findsOneWidget);
    expect(results, isEmpty);
    expect(
      tester.widget<TextField>(find.byKey(_bio)).controller!.text,
      'Edited bio that must survive.',
    );
    final button = tester.widget<GlassButton>(find.byKey(_save));
    expect(button.onPressed, isNotNull);
    expect(button.isLoading, isFalse);

    // The server recovers: one retry saves both parts and closes.
    bff.install();
    api.calls.clear();
    await _tapSave(tester);
    expect(api.writeLines, [
      'PATCH /profile/me/draft',
      'PATCH /profile/me/draft',
    ]);
    expect(_aboutPatch(bff)['bio'], 'Edited bio that must survive.');
    expect(results, [null]);
  });

  testWidgets('offline save shows the same message and sends nothing more '
      '[case:profile.setup_about.save_about_onsave.api_failure]', (
    tester,
  ) async {
    final api = QaApi();
    ProfileBff(api);
    api.offline('PATCH /profile/*/draft');
    await _open(tester, api);
    await _tapSave(tester);
    expect(qaSnackText(tester), _en.profileSetupSaveFailed);
    expect(api.writes, hasLength(1));
  });

  // Regression (2026-10-02): two taps before the button rebuilt saved twice.
  testWidgets('a double tap on Save sends one save, not two '
      '[case:profile.setup_about.save_about_onsave.action]', (tester) async {
    final api = QaApi();
    final bff = ProfileBff(api);
    api.on(
      'PATCH /profile/*/draft',
      (c) => QaReply(200, {
        'draft': {...bff.draft, ...c.body},
      }, delay: const Duration(milliseconds: 300)),
    );
    await _open(tester, api);
    await _scrollToSave(tester);
    await tester.tap(find.byKey(_save));
    await tester.tap(find.byKey(_save), warnIfMissed: false);
    await qaSettle(tester);
    expect(api.writeLines, [
      'PATCH /profile/me/draft',
      'PATCH /profile/me/draft',
    ]);
    expect(bff.patches.where((p) => p.containsKey('bio')), hasLength(1));
  });

  testWidgets('bio shorter than the minimum is blocked with the localized '
      'message; unicode is kept as typed '
      '[case:profile.setup_about.setup_about_bio_field_input.validation]', (
    tester,
  ) async {
    final api = QaApi();
    final bff = ProfileBff(api);
    await _open(tester, api);
    await tester.enterText(find.byKey(_bio), '  short  ');
    await _tapSave(tester);
    expect(qaSnackText(tester), _en.profileSetupBioTooShort(10));
    expect(api.writes, isEmpty);

    const unicode = 'Café au lait ☕, 東京の夜, नमस्ते — that is me.';
    await tester.enterText(find.byKey(_bio), unicode);
    await _tapSave(tester);
    expect(_aboutPatch(bff)['bio'], unicode);
  });

  testWidgets('typing in the bio lands in the saved draft '
      '[case:profile.setup_about.setup_about_bio_field_input.action]', (
    tester,
  ) async {
    final api = QaApi();
    final bff = ProfileBff(api);
    await _open(tester, api);
    expect(
      tester.widget<TextField>(find.byKey(_bio)).controller!.text,
      'This is a sufficiently long bio for tests.',
      reason: 'the field starts from the saved draft',
    );
    await tester.enterText(find.byKey(_bio), 'New bio about weekend climbs.');
    await _tapSave(tester);
    expect(_aboutPatch(bff)['bio'], 'New bio about weekend climbs.');
    expect(bff.draft['bio'], 'New bio about weekend climbs.');
  });

  testWidgets('profession is saved trimmed '
      '[case:profile.setup_about.setup_about_profession_field_input.action]', (
    tester,
  ) async {
    final api = QaApi();
    final bff = ProfileBff(api);
    await _open(tester, api);
    await tester.enterText(find.byKey(_profession), '  Product Designer ');
    await _tapSave(tester);
    expect(_aboutPatch(bff)['profession'], 'Product Designer');
  });

  testWidgets(
    'blank profession clears it; unicode is preserved '
    '[case:profile.setup_about.setup_about_profession_field_input.validation]',
    (tester) async {
      final api = QaApi();
      final bff = ProfileBff(
        api,
        draft: qaDraftJson(extra: {'profession': 'Teacher'}),
      );
      await _open(tester, api);
      await tester.enterText(find.byKey(_profession), '    ');
      await _tapSave(tester);
      expect(_aboutPatch(bff).containsKey('profession'), isTrue);
      expect(_aboutPatch(bff)['profession'], isNull);

      // Reopen with a unicode job title.
      api.calls.clear();
      await tester.tap(find.byKey(const ValueKey('qa.test.launcher')));
      await qaSettle(tester);
      await tester.enterText(
        find.byKey(_profession),
        'Ingénieure logicielle — 開発者',
      );
      await _tapSave(tester);
      expect(_aboutPatch(bff)['profession'], 'Ingénieure logicielle — 開発者');
    },
  );

  testWidgets(
    'height picked from the menu is saved in cm '
    '[case:profile.setup_about.setup_about_height_dropdown_heightchanged.action]',
    (tester) async {
      final api = QaApi();
      final bff = ProfileBff(
        api,
        draft: qaDraftJson(extra: {'height_cm': 168}),
      );
      await _open(tester, api);
      await _pick(
        tester,
        const ValueKey('qa.setup.about.height_dropdown'),
        _en.profileSetupHeightValue(170),
      );
      expect(find.text(_en.profileSetupHeightValue(170)), findsOneWidget);
      await _tapSave(tester);
      expect(_aboutPatch(bff)['height_cm'], 170);
    },
  );

  testWidgets(
    'education picked from the menu is saved '
    '[case:profile.setup_about.setup_about_education_dropdown_educationchanged.action]',
    (tester) async {
      final api = QaApi();
      final bff = ProfileBff(api);
      await _open(tester, api);
      await _pick(
        tester,
        const ValueKey('qa.setup.about.education_dropdown'),
        _en.profileSetupEducationMasters,
      );
      await _tapSave(tester);
      expect(_aboutPatch(bff)['education'], "Master's");
    },
  );

  testWidgets('income range picked under "Prefer not to say" is saved '
      '[case:profile.setup_about.prefer_not_to_say_onincomechanged.action]', (
    tester,
  ) async {
    final api = QaApi();
    final bff = ProfileBff(api);
    await _open(tester, api);
    final income = _dropdownAfter(_en.profileSetupPreferNotToSay).first;
    await tester.ensureVisible(income);
    await tester.pump();
    await tester.tap(income);
    await qaSettle(tester, frames: 5);
    await tester.tap(find.text('₹10L – ₹20L').last);
    await qaSettle(tester, frames: 5);
    await _tapSave(tester);
    expect(_aboutPatch(bff)['income_range'], '₹10L – ₹20L');
  });

  testWidgets('religion is saved with the lifestyle part '
      '[case:profile.setup_about.prefer_not_to_say_onreligionchanged.action]', (
    tester,
  ) async {
    final api = QaApi();
    final bff = ProfileBff(
      api,
      draft: qaDraftJson(extra: {'income_range': 'Prefer not to say'}),
    );
    await _open(tester, api);
    // Income now shows its value, so the only hint left is religion's.
    final religion = _dropdownAfter(_en.profileSetupPreferNotToSay).last;
    await tester.ensureVisible(religion);
    await tester.pump();
    await tester.tap(religion);
    await qaSettle(tester, frames: 5);
    await tester.tap(find.text('Christian').last);
    await qaSettle(tester, frames: 5);
    await _tapSave(tester);
    expect(_lifestylePatch(bff)['religion'], 'Christian');
  });

  testWidgets(
    'drinking choice is saved '
    '[case:profile.setup_about.setup_about_drinking_dropdown_drinkingchanged.action]',
    (tester) async {
      final api = QaApi();
      final bff = ProfileBff(api);
      await _open(tester, api);
      await _pick(
        tester,
        const ValueKey('qa.setup.about.drinking_dropdown'),
        _en.profileSetupFrequencySocially,
      );
      await _tapSave(tester);
      expect(_lifestylePatch(bff)['drinking'], 'Socially');
      expect(_lifestylePatch(bff)['smoking'], 'Never');
    },
  );

  testWidgets(
    'smoking choice is saved '
    '[case:profile.setup_about.setup_about_smoking_dropdown_smokingchanged.action]',
    (tester) async {
      final api = QaApi();
      final bff = ProfileBff(api);
      await _open(tester, api);
      await _pick(
        tester,
        const ValueKey('qa.setup.about.smoking_dropdown'),
        _en.profileSetupFrequencyOccasionally,
      );
      await _tapSave(tester);
      expect(_lifestylePatch(bff)['smoking'], 'Occasionally');
    },
  );

  testWidgets('Back closes and keeps the edits in the draft '
      '[case:profile.setup_about.back_onback.action]', (tester) async {
    final api = QaApi();
    final bff = ProfileBff(api);
    final results = await _open(tester, api);
    await tester.enterText(find.byKey(_bio), 'Typed, then went back.');
    await tester.tap(find.byTooltip(_en.profileSetupBackTooltip));
    await qaSettle(tester);
    expect(find.byType(SetupAboutScreen), findsNothing);
    expect(results, [null]);
    expect(_aboutPatch(bff)['bio'], 'Typed, then went back.');
    expect(bff.draft['bio'], 'Typed, then went back.');
  });

  testWidgets('Retry reloads a draft that failed to load '
      '[case:profile.setup_about.something_went_wrong_please_try_onretry.action]', (tester) async {
    final api = QaApi();
    final bff = ProfileBff(api);
    api.fail('GET /profile/*/draft');
    await _open(tester, api);
    expect(find.text(_en.profileSetupLoadErrorTitle), findsOneWidget);
    expect(find.byKey(_bio), findsNothing);

    bff.install();
    await tester.tap(find.text(_en.profileSetupRetry));
    await qaSettle(tester);
    expect(api.sent('GET', '/profile/me/draft'), hasLength(2));
    expect(find.byKey(_bio), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byKey(_bio)).controller!.text,
      'This is a sufficiently long bio for tests.',
    );
  });

  testWidgets('renders translated in every locale '
      '[case:profile.setup_about.l10n]', (tester) async {
    for (final locale in qaLocales) {
      await tester.pumpWidget(const SizedBox());
      final api = QaApi();
      ProfileBff(api);
      await _open(tester, api, locale: locale);
      final l10n = qaL10n(locale);
      expect(
        find.text(l10n.profileSetupAboutTitle),
        findsOneWidget,
        reason: '$locale',
      );
      expect(
        find.text(l10n.profileSetupBioLabel),
        findsOneWidget,
        reason: '$locale',
      );
      await _scrollToSave(tester);
      expect(
        find.text(l10n.profileSetupSaveAbout),
        findsOneWidget,
        reason: '$locale',
      );
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });
}
