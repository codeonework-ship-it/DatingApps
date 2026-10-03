// Test names carry literal catalog case ids, which can be long.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';
import 'package:verified_dating_app/features/common/screens/main_navigation_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_preferences_screen.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_quality.dart';
import 'support/profile_bff.dart';

// Control-level tests for preferences (SetupPreferencesScreen) on the real
// draft notifier: every control's value is asserted in the body of
// PATCH /profile/{id}/draft (preferences part, then lifestyle part), and
// save/back failures are explained without losing the member's edits.

const _save = ValueKey('qa.setup.preferences.save_button');
const _finish = ValueKey('qa.setup.preferences.finish_button');
const _back = ValueKey('qa.setup.preferences.back_button');
ValueKey<String> _k(String id) => ValueKey('qa.setup.preferences.$id');

final _en = qaL10n(const Locale('en'));

/// A 240-character entry: no field truncates what the member wrote.
final _long = List.filled(24, 'longtext! ').join().trim();

Future<List<Object?>> _open(
  WidgetTester tester,
  QaApi api, {
  bool setupFlow = false,
  Locale? locale,
  bool advanced = false,
}) async {
  final results = await pumpQa(
    tester,
    api,
    SetupPreferencesScreen(isSetupFlow: setupFlow),
    launcher: true,
    locale: locale,
    extra: qaMasterDataOverrides(),
  );
  if (advanced) {
    await tester.tap(find.text(_en.profileSetupTabAdvanced));
    await qaSettle(tester, frames: 5);
  }
  return results;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await qaSettle(tester, frames: 2);
  await tester.ensureVisible(finder);
  await qaSettle(tester, frames: 2);
  await tester.tap(finder);
  await qaSettle(tester);
}

Map<String, dynamic> _prefs(ProfileBff bff) =>
    bff.patches.firstWhere((p) => p.containsKey('seeking_genders'));
Map<String, dynamic> _lifestyle(ProfileBff bff) =>
    bff.patches.firstWhere((p) => p.containsKey('drinking'));

/// Picks [option] in the dropdown with QA id [id] (Advanced tab).
Future<void> _choose(WidgetTester tester, String id, String option) async {
  await tester.ensureVisible(find.byKey(_k(id)));
  await qaSettle(tester, frames: 2);
  await tester.tap(find.byKey(_k(id)));
  await qaSettle(tester, frames: 5);
  await tester.tap(find.text(option).last);
  await qaSettle(tester, frames: 5);
}

String? _shown(WidgetTester tester, String id) =>
    tester.state<FormFieldState<String>>(find.byKey(_k(id))).value;

void main() {
  group('Save Preferences', () {
    testWidgets('sends the preferences then the lifestyle part, returns to '
        'Discover and closes '
        '[case:profile.setup_preferences.save_preferences.action]', (
      tester,
    ) async {
      final api = QaApi();
      final bff = ProfileBff(api);
      final results = await _open(tester, api);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SetupPreferencesScreen)),
      );
      container.read(mainNavigationIndexProvider.notifier).state = 4;
      await _tap(tester, find.byKey(_save));

      expect(api.writeLines, [
        'PATCH /profile/me/draft',
        'PATCH /profile/me/draft',
      ]);
      final prefs = bff.patches.first;
      expect(prefs['seeking_genders'], unorderedEquals(['M', 'F']));
      expect(prefs['min_age_years'], 21);
      expect(prefs['max_age_years'], 40);
      expect(prefs['max_distance_km'], 50);
      expect(prefs['serious_only'], true);
      expect(prefs['verified_only'], false);
      expect(prefs['hookup_only'], false);
      expect(bff.patches.last, {
        'drinking': 'Never',
        'smoking': 'Never',
        'religion': null,
      });
      expect(results, [null]);
      expect(find.byType(SetupPreferencesScreen), findsNothing);
      expect(container.read(mainNavigationIndexProvider), 0);
    });

    testWidgets(
      'Finish in the setup flow saves, completes the profile and '
      'opens the app [case:profile.setup_preferences.save_preferences.action]',
      (tester) async {
        final api = QaApi();
        ProfileBff(api);
        await _open(tester, api, setupFlow: true);
        await _tap(tester, find.byKey(_finish));
        expect(api.writeLines, [
          'PATCH /profile/me/draft',
          'PATCH /profile/me/draft',
          'POST /profile/me/complete',
        ]);
        expect(find.byType(MainNavigationScreen), findsOneWidget);
        expect(find.byType(SetupPreferencesScreen), findsNothing);
        // The app shell starts its own loading; it is not under test here.
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('a failed save explains, stays, re-enables Save and keeps the '
        'edits for one retry '
        '[case:profile.setup_preferences.save_preferences.api_failure]', (
      tester,
    ) async {
      final api = QaApi();
      final bff = ProfileBff(api);
      api.fail('PATCH /profile/*/draft', message: 'Draft store unavailable');
      final results = await _open(tester, api);
      await _tap(tester, find.byKey(_k('seeking_M')));
      await _tap(tester, find.byKey(_save));

      expect(qaSnackText(tester), _en.profileSetupPreferencesSaveFailed);
      expect(api.writes, hasLength(1), reason: 'lifestyle is not attempted');
      expect(results, isEmpty);
      expect(find.byType(SetupPreferencesScreen), findsOneWidget);
      final button = tester.widget<GlassButton>(find.byKey(_save));
      expect(button.onPressed, isNotNull);
      expect(button.isLoading, isFalse);

      bff.install();
      api.calls.clear();
      // The message sits over the button until it times out.
      await tester.pump(const Duration(seconds: 5));
      await qaSettle(tester, frames: 5);
      await _tap(tester, find.byKey(_save));
      expect(api.writes, hasLength(2));
      expect(_prefs(bff)['seeking_genders'], ['F']);
      expect(results, [null]);
    });

    testWidgets('a failed completion in the setup flow explains and stays '
        '[case:profile.setup_preferences.save_preferences.api_failure]', (
      tester,
    ) async {
      final api = QaApi();
      ProfileBff(api);
      api.fail('POST /profile/*/complete', status: 400, message: 'Too few');
      await _open(tester, api, setupFlow: true);
      await _tap(tester, find.byKey(_finish));
      expect(qaSnackText(tester), _en.profileSetupFinishFailed);
      expect(api.sent('POST', '/profile/*/complete'), hasLength(1));
      expect(find.byType(SetupPreferencesScreen), findsOneWidget);
      expect(
        tester.widget<GlassButton>(find.byKey(_finish)).onPressed,
        isNotNull,
      );
    });

    // Regression (2026-10-02): two taps before the button rebuilt sent the
    // whole save twice (four PATCHes).
    testWidgets('a double tap on Save saves once '
        '[case:profile.setup_preferences.save_preferences.action]', (
      tester,
    ) async {
      final api = QaApi();
      final bff = ProfileBff(api);
      api.on(
        'PATCH /profile/*/draft',
        (c) => QaReply(200, {
          'draft': {...bff.draft, ...c.body},
        }, delay: const Duration(milliseconds: 300)),
      );
      await _open(tester, api);
      await tester.tap(find.byKey(_save));
      await tester.tap(find.byKey(_save), warnIfMissed: false);
      await qaSettle(tester);
      expect(api.writes, hasLength(2));
    });
  });

  group('Back', () {
    testWidgets(
      'setup Back saves what was chosen, then goes back '
      '[case:profile.setup_preferences.setup_preferences_back_button.action]',
      (tester) async {
        final api = QaApi();
        final bff = ProfileBff(api);
        final results = await _open(tester, api, setupFlow: true);
        await _tap(tester, find.byKey(_k('verified_only_toggle')));
        await _tap(tester, find.byKey(_back));
        expect(api.writes, hasLength(2));
        expect(_prefs(bff)['verified_only'], true);
        expect(results, [null]);
        expect(api.sent('POST', '/profile/*/complete'), isEmpty);
      },
    );

    testWidgets(
      'setup Back that cannot save explains and keeps the screen '
      '[case:profile.setup_preferences.setup_preferences_back_button.api_failure]',
      (tester) async {
        final api = QaApi();
        ProfileBff(api);
        api.offline('PATCH /profile/*/draft');
        final results = await _open(tester, api, setupFlow: true);
        await _tap(tester, find.byKey(_back));
        expect(qaSnackText(tester), _en.profileSetupCouldNotSaveChanges);
        expect(api.writes, hasLength(1));
        expect(results, isEmpty);
        expect(find.text(_en.profileSetupYourPreferences), findsOneWidget);
        expect(
          tester.widget<IconButton>(find.byKey(_back)).onPressed,
          isNotNull,
        );
      },
    );

    testWidgets(
      'Back while editing closes without saving '
      '[case:profile.setup_preferences.setup_preferences_back_button.action]',
      (tester) async {
        final api = QaApi();
        ProfileBff(api);
        final results = await _open(tester, api);
        await _tap(tester, find.byKey(_back));
        expect(api.writes, isEmpty);
        expect(results, [null]);
      },
    );
  });

  group('Basic tab', () {
    testWidgets(
      'dragging the age thumbs saves the new range '
      '[case:profile.setup_preferences.setup_preferences_age_range_agechanged.action]',
      (tester) async {
        final api = QaApi();
        final bff = ProfileBff(api);
        await _open(tester, api);
        final slider = find.byKey(_k('age_range'));
        final box = tester.getRect(slider);
        const pad = 24.0; // the thumb overlay radius at each end of the track
        final width = box.width - 2 * pad;
        double x(num age) => box.left + pad + (age - 18) / 62 * width;
        // Start thumb 21 -> ~27, end thumb 40 -> ~60.
        await tester.dragFrom(
          Offset(x(21), box.center.dy),
          Offset(x(27) - x(21), 0),
        );
        await qaSettle(tester, frames: 3);
        await tester.dragFrom(
          Offset(x(40), box.center.dy),
          Offset(x(60) - x(40), 0),
        );
        await qaSettle(tester, frames: 3);
        final values = tester.widget<RangeSlider>(slider).values;
        expect(values.start, greaterThan(21));
        expect(values.end, greaterThan(40));
        expect(
          find.text(
            _en.profileSetupAgeRangeTitle(
              values.start.round(),
              values.end.round(),
            ),
          ),
          findsOneWidget,
        );
        await _tap(tester, find.byKey(_save));
        expect(_prefs(bff)['min_age_years'], values.start.round());
        expect(_prefs(bff)['max_age_years'], values.end.round());
      },
    );

    testWidgets(
      'tapping the distance track saves that distance '
      '[case:profile.setup_preferences.setup_preferences_distance_distancechanged.action]',
      (tester) async {
        final api = QaApi();
        final bff = ProfileBff(api);
        await _open(tester, api);
        final slider = find.byKey(_k('distance'));
        final box = tester.getRect(slider);
        await tester.tapAt(Offset(box.left + box.width * 0.75, box.center.dy));
        await qaSettle(tester, frames: 3);
        final km = tester.widget<Slider>(slider).value.round();
        expect(km, greaterThan(300));
        expect(find.text(_en.profileSetupMaxDistanceTitle(km)), findsOneWidget);
        await _tap(tester, find.byKey(_save));
        expect(_prefs(bff)['max_distance_km'], km);
      },
    );

    testWidgets(
      'Men toggles off and on, and the choice is saved '
      '[case:profile.setup_preferences.setup_preferences_seeking_x_seekingtoggled.action]',
      (tester) async {
        final api = QaApi();
        final bff = ProfileBff(api);
        await _open(tester, api);
        await _tap(tester, find.byKey(_k('seeking_M')));
        await _tap(tester, find.byKey(_k('seeking_Other')));
        await _tap(tester, find.byKey(_save));
        expect(_prefs(bff)['seeking_genders'], unorderedEquals(['F', 'Other']));
      },
    );

    testWidgets(
      'no gender selected is blocked with the localized message '
      '[case:profile.setup_preferences.setup_preferences_seeking_x_seekingtoggled.validation]',
      (tester) async {
        final api = QaApi();
        ProfileBff(api);
        await _open(tester, api);
        await _tap(tester, find.byKey(_k('seeking_M')));
        await _tap(tester, find.byKey(_k('seeking_F')));
        await _tap(tester, find.byKey(_save));
        expect(qaSnackText(tester), _en.profileSetupSelectGenderPreference);
        expect(api.writes, isEmpty);
      },
    );

    // The case id's middle (slug) is a literal here so the coverage scanner
    // expands the interpolated tag below.
    for (final (slug, toggle, field, from) in [
      (
        'serious_relationship_only_onseriouschanged',
        'serious_only_toggle',
        'serious_only',
        true,
      ),
      (
        'verified_profiles_only_onverifiedchanged',
        'verified_only_toggle',
        'verified_only',
        false,
      ),
      (
        'hookups_only_onhookupchanged',
        'hookup_only_toggle',
        'hookup_only',
        false,
      ),
    ]) {
      testWidgets('$toggle flips and lands in the draft '
          '[case:profile.setup_preferences.$slug.action]', (tester) async {
        final api = QaApi();
        final bff = ProfileBff(api);
        await _open(tester, api);
        expect(tester.widget<Switch>(find.byKey(_k(toggle))).value, from);
        await _tap(tester, find.byKey(_k(toggle)));
        expect(tester.widget<Switch>(find.byKey(_k(toggle))).value, !from);
        await _tap(tester, find.byKey(_save));
        expect(_prefs(bff)[field], !from);
        expect(bff.draft[field], !from);
      });
    }

    testWidgets('the Basic and Advanced tabs switch by tap and by swipe '
        '[case:profile.setup_preferences.basic_onswipe.action]', (
      tester,
    ) async {
      final api = QaApi();
      ProfileBff(api);
      await _open(tester, api);
      final tabs = tester.widget<TabBar>(find.byType(TabBar)).controller!;
      expect(tabs.index, 0);
      expect(find.byKey(_k('age_range')), findsOneWidget);
      await _tap(tester, find.text(_en.profileSetupTabAdvanced));
      expect(tabs.index, 1);
      expect(find.byKey(_k('country')), findsOneWidget);
      await tester.fling(find.byType(TabBarView), const Offset(400, 0), 1500);
      await qaSettle(tester);
      expect(tabs.index, 0);
      expect(find.byKey(_k('age_range')), findsOneWidget);
    });
  });

  group('Advanced tab dropdowns', () {
    // slug: the case id's tail after `setup_preferences_x_`, a literal so the
    // coverage scanner expands the interpolated tag below.
    for (final (slug, id, field, option, lifestyle) in [
      ('countrychanged', 'country', 'country', 'Canada', false),
      ('statechanged', 'state', 'state', 'Karnataka', false),
      ('citychanged', 'city', 'city', 'Bengaluru', false),
      ('religionchanged', 'religion', 'religion', 'Hindu', true),
      (
        'mothertonguechanged',
        'mother_tongue',
        'mother_tongue',
        'Kannada',
        false,
      ),
      ('languagechanged', 'language', 'language_tags', 'English', false),
      (
        'dietpreferencechange',
        'diet_preference',
        'diet_preference',
        'Veg',
        false,
      ),
      (
        'workoutfrequencychan',
        'workout_frequency',
        'workout_frequency',
        'Often',
        false,
      ),
      ('diettypechanged', 'diet_type', 'diet_type', 'Balanced', false),
      (
        'sleepschedulechanged',
        'sleep_schedule',
        'sleep_schedule',
        'Early bird',
        false,
      ),
      (
        'travelstylechanged',
        'travel_style',
        'travel_style',
        'Adventurous',
        false,
      ),
      (
        'politicalcomfortrang',
        'political_comfort_range',
        'political_comfort_range',
        'Moderate',
        false,
      ),
    ]) {
      testWidgets('$id: "$option" is shown and saved '
          '[case:profile.setup_preferences.setup_preferences_x_$slug.action]', (
        tester,
      ) async {
        final api = QaApi();
        final bff = ProfileBff(
          api,
          draft: qaDraftJson(
            extra: {'country': 'India', if (id == 'city') 'state': 'Karnataka'},
          ),
        );
        await _open(tester, api, advanced: true);
        final saved = field == 'language_tags' ? [option] : option;
        expect(_shown(tester, id), isNot(option), reason: 'starts elsewhere');
        await _choose(tester, id, option);
        expect(_shown(tester, id), option);
        await _tap(tester, find.byKey(_save));
        final sent = lifestyle ? _lifestyle(bff) : _prefs(bff);
        expect(sent[field], saved);
        expect(bff.draft[field], saved, reason: 'the server kept it');
        expect(find.byType(SetupPreferencesScreen), findsNothing);

        // Reopened, the screen shows the saved choice from the server.
        await tester.tap(find.byKey(const ValueKey('qa.test.launcher')));
        await qaSettle(tester);
        await tester.tap(find.text(_en.profileSetupTabAdvanced));
        await qaSettle(tester, frames: 5);
        await tester.ensureVisible(find.byKey(_k(id)));
        expect(_shown(tester, id), option);
      });
    }

    testWidgets(
      'changing country clears state and city on screen and in the '
      'draft [case:profile.setup_preferences.setup_preferences_x_countrychanged.action]',
      (tester) async {
        final api = QaApi();
        final bff = ProfileBff(
          api,
          draft: qaDraftJson(
            extra: {
              'country': 'India',
              'state': 'Karnataka',
              'city': 'Bengaluru',
            },
          ),
        );
        await _open(tester, api, advanced: true);
        expect(_shown(tester, 'city'), 'Bengaluru');
        await _choose(tester, 'country', 'Canada');
        expect(_shown(tester, 'state'), isNull);
        expect(_shown(tester, 'city'), isNull);
        await _tap(tester, find.byKey(_save));
        expect(_prefs(bff)['country'], 'Canada');
        expect(_prefs(bff)['state'], isNull);
        expect(_prefs(bff)['city'], isNull);
      },
    );
  });

  group('Advanced tab text fields', () {
    // id is both the field's QA id and the middle of its case ids
    // (setup_preferences_<id>_input.*), so the interpolated tags expand.
    for (final (id, field, isList) in [
      ('instagram_field', 'instagram_handle', false),
      ('intent_tags_field', 'intent_tags', true),
      ('hobbies_field', 'hobbies', true),
      ('books_field', 'favorite_books', true),
      ('novels_field', 'favorite_novels', true),
      ('songs_field', 'favorite_songs', true),
      ('extra_curriculars_field', 'extra_curriculars', true),
      ('additional_info_field', 'additional_info', false),
      ('pet_preference_field', 'pet_preference', false),
      ('deal_breakers_field', 'deal_breaker_tags', true),
    ]) {
      testWidgets(
        '$id: typed text is saved trimmed '
        '[case:profile.setup_preferences.setup_preferences_${id}_input.action]',
        (tester) async {
          final api = QaApi();
          final bff = ProfileBff(api);
          await _open(tester, api, advanced: true);
          await tester.ensureVisible(find.byKey(_k(id)));
          await tester.enterText(
            find.byKey(_k(id)),
            isList ? ' hiking, jazz , ' : '  maya.draws  ',
          );
          await _tap(tester, find.byKey(_save));
          expect(
            _prefs(bff)[field],
            isList ? ['hiking', 'jazz'] : 'maya.draws',
          );
          expect(bff.draft[field], isList ? ['hiking', 'jazz'] : 'maya.draws');
        },
      );

      testWidgets(
        '$id: blanks are dropped, duplicates collapse, emoji, RTL '
        'and long text are kept whole '
        '[case:profile.setup_preferences.setup_preferences_${id}_input.validation]',
        (tester) async {
          final api = QaApi();
          final bff = ProfileBff(
            api,
            draft: qaDraftJson(
              extra: {
                field: isList ? ['old'] : 'old',
              },
            ),
          );
          await _open(tester, api, advanced: true);
          await tester.ensureVisible(find.byKey(_k(id)));
          // Only spaces and commas: nothing is stored, not an empty string.
          await tester.enterText(
            find.byKey(_k(id)),
            isList ? ' , ,  ' : '    ',
          );
          await _tap(tester, find.byKey(_save));
          expect(_prefs(bff).containsKey(field), isTrue);
          expect(_prefs(bff)[field], isList ? isEmpty : isNull);

          // Reopen: unicode and repeated entries.
          api.calls.clear();
          await tester.tap(find.byKey(const ValueKey('qa.test.launcher')));
          await qaSettle(tester);
          await tester.tap(find.text(_en.profileSetupTabAdvanced));
          await qaSettle(tester, frames: 5);
          await tester.ensureVisible(find.byKey(_k(id)));
          await tester.enterText(
            find.byKey(_k(id)),
            isList
                ? 'Café, 東京, नमस्ते, مرحبا بك, 🎸🌊, $_long, Café, 🎸🌊'
                : ' Ünïcødé 東京 नमस्ते مرحبا بك 🎸🌊 $_long ',
          );
          await _tap(tester, find.byKey(_save));
          final expected = isList
              ? ['Café', '東京', 'नमस्ते', 'مرحبا بك', '🎸🌊', _long]
              : 'Ünïcødé 東京 नमस्ते مرحبا بك 🎸🌊 $_long';
          expect(_prefs(bff)[field], expected);
          expect(bff.draft[field], expected);

          // Reopened, the field shows exactly what the server kept.
          await tester.tap(find.byKey(const ValueKey('qa.test.launcher')));
          await qaSettle(tester);
          await tester.tap(find.text(_en.profileSetupTabAdvanced));
          await qaSettle(tester, frames: 5);
          await tester.ensureVisible(find.byKey(_k(id)));
          final shown = tester
              .widget<TextField>(find.byKey(_k(id)))
              .controller!
              .text;
          expect(
            isList ? shown.split(',').map((t) => t.trim()).toList() : shown,
            expected,
          );
        },
      );
    }

    testWidgets(
      'a leading @ on the Instagram handle is dropped, as the '
      'field label asks '
      '[case:profile.setup_preferences.setup_preferences_instagram_field_input.validation]',
      (tester) async {
        final api = QaApi();
        final bff = ProfileBff(api);
        await _open(tester, api, advanced: true);
        await tester.ensureVisible(find.byKey(_k('instagram_field')));
        await tester.enterText(
          find.byKey(_k('instagram_field')),
          ' @maya.draws ',
        );
        await _tap(tester, find.byKey(_save));
        expect(_prefs(bff)['instagram_handle'], 'maya.draws');

        // Only an @ is no handle at all.
        await tester.tap(find.byKey(const ValueKey('qa.test.launcher')));
        await qaSettle(tester);
        await tester.tap(find.text(_en.profileSetupTabAdvanced));
        await qaSettle(tester, frames: 5);
        await tester.ensureVisible(find.byKey(_k('instagram_field')));
        expect(
          tester
              .widget<TextField>(find.byKey(_k('instagram_field')))
              .controller!
              .text,
          'maya.draws',
        );
        await tester.enterText(find.byKey(_k('instagram_field')), '@');
        await _tap(tester, find.byKey(_save));
        expect(
          bff.patches.lastWhere(
            (p) => p.containsKey('seeking_genders'),
          )['instagram_handle'],
          isNull,
        );
      },
    );
  });

  testWidgets(
    'Retry reloads preferences that failed to load '
    '[case:profile.setup_preferences.setup_preferences_retry_button.action]',
    (tester) async {
      final api = QaApi();
      final bff = ProfileBff(api);
      api.fail('GET /profile/*/draft');
      await _open(tester, api);
      expect(find.text(_en.profileSetupPreferencesLoadFailed), findsOneWidget);
      bff.install();
      await _tap(tester, find.byKey(_k('retry_button')));
      expect(api.sent('GET', '/profile/me/draft'), hasLength(2));
      expect(find.byKey(_k('age_range')), findsOneWidget);
      expect(find.text(_en.profileSetupAgeRangeTitle(21, 40)), findsOneWidget);
    },
  );

  testWidgets('renders translated in every locale '
      '[case:profile.setup_preferences.l10n]', (tester) async {
    for (final locale in qaLocales) {
      await tester.pumpWidget(const SizedBox());
      final api = QaApi();
      ProfileBff(api);
      await _open(tester, api, locale: locale);
      final l10n = qaL10n(locale);
      expect(find.text(l10n.profileSetupEditPreferencesTitle), findsOneWidget);
      expect(find.text(l10n.profileSetupTabBasic), findsOneWidget);
      expect(find.text(l10n.profileSetupSavePreferences), findsOneWidget);
      expect(find.text(l10n.profileSetupAgeRangeTitle(21, 40)), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });

  group('screen quality', () {
    // A member who filled in every preference, so both tabs are full.
    QaApi server() {
      final api = QaApi();
      ProfileBff(
        api,
        draft: qaDraftJson(
          extra: const {
            'country': 'India',
            'state': 'Karnataka',
            'city': 'Bengaluru',
            'religion': 'Hindu',
            'mother_tongue': 'Kannada',
            'language_tags': ['English'],
            'diet_preference': 'Veg',
            'workout_frequency': 'Often',
            'diet_type': 'Balanced',
            'sleep_schedule': 'Early bird',
            'travel_style': 'Adventurous',
            'political_comfort_range': 'Moderate',
            'instagram_handle': 'ananya.makes',
            'intent_tags': ['long-term', 'marriage'],
            'hobbies': ['pottery', 'trail running', 'jazz'],
            'favorite_books': ['The God of Small Things'],
            'favorite_novels': ['A Suitable Boy'],
            'favorite_songs': ['Kun Faya Kun'],
            'extra_curriculars': ['choir', 'debate'],
            'additional_info':
                'Happiest outdoors; I will always say yes to a long walk '
                'and a good filter coffee afterwards.',
            'pet_preference': 'Dogs',
            'deal_breaker_tags': ['smoking', 'rudeness to waiters'],
          },
        ),
      );
      return api;
    }

    // The age range only renders, with the member's 21-40, once the draft
    // arrived.
    Finder loaded() =>
        find.text(_en.profileSetupAgeRangeTitle(21, 40), skipOffstage: false);

    Future<void> showAdvanced(WidgetTester tester) async {
      await tester.tap(find.text(_en.profileSetupTabAdvanced));
      await qaSettle(tester, frames: 5);
      expect(_shown(tester, 'city'), 'Bengaluru', reason: 'Advanced loaded');
    }

    testWidgets('preferences with every field filled lay out on phone and '
        'tablet in both themes, on both tabs '
        '[case:profile.setup_preferences.layout_matrix]', (tester) async {
      for (final setupFlow in [true, false]) {
        await qaExpectLaysOutOnPhoneAndTablet(
          tester,
          api: server,
          build: () => SetupPreferencesScreen(isSetupFlow: setupFlow),
          extra: qaMasterDataOverrides,
          loaded: loaded,
        );
      }
      // The Advanced tab, scrolled through to the deal-breakers.
      for (final theme in qaQualityThemes.entries) {
        for (final device in qaQualitySizes.entries) {
          final where = 'Advanced ${device.key} [${theme.key}]';
          await qaQualityPump(
            tester,
            server(),
            const SetupPreferencesScreen(),
            theme: theme.value,
            size: device.value,
            extra: qaMasterDataOverrides(),
          );
          await showAdvanced(tester);
          expect(tester.takeException(), isNull, reason: where);
          await qaScrollThrough(
            tester,
            onStep: () => expect(tester.takeException(), isNull, reason: where),
          );
          expect(
            find.byKey(_k('deal_breakers_field')),
            findsOneWidget,
            reason: 'scrolled to the end on $where',
          );
          await qaQualityUnmount(tester);
        }
      }
    });

    testWidgets('preferences meet tap-target, label and contrast guidelines '
        'on both tabs [case:profile.setup_preferences.a11y_guidelines]', (
      tester,
    ) async {
      for (final setupFlow in [true, false]) {
        await qaExpectMeetsA11yGuidelines(
          tester,
          api: server,
          build: () => SetupPreferencesScreen(isSetupFlow: setupFlow),
          extra: qaMasterDataOverrides,
          loaded: loaded,
        );
      }
      final semantics = tester.ensureSemantics();
      for (final theme in qaQualityThemes.entries) {
        await qaQualityPump(
          tester,
          server(),
          const SetupPreferencesScreen(),
          theme: theme.value,
          extra: qaMasterDataOverrides(),
        );
        await showAdvanced(tester);
        Future<void> check(String part) async {
          for (final guideline in [
            androidTapTargetGuideline,
            labeledTapTargetGuideline,
            textContrastGuideline,
          ]) {
            final result = await guideline.evaluate(tester);
            expect(
              result.passed,
              isTrue,
              reason:
                  'Advanced$part: ${guideline.description} '
                  '[${theme.key}]:\n${result.reason}',
            );
          }
        }

        // Every viewport of the Advanced tab, top to the deal-breakers.
        await check('');
        var step = 0;
        await qaScrollThrough(
          tester,
          onStep: () async => check(', scrolled x${++step}'),
        );
        expect(find.byKey(_k('deal_breakers_field')), findsOneWidget);
        await qaQualityUnmount(tester);
      }
      semantics.dispose();
    });

    testWidgets('Back on preferences returns to the screen that opened it '
        '[case:profile.setup_preferences.back_affordance]', (tester) async {
      final api = server();
      await qaExpectBackReturnsToOpener(
        tester,
        api: api,
        build: () => const SetupPreferencesScreen(),
        extra: qaMasterDataOverrides(),
        screen: find.byType(SetupPreferencesScreen),
        back: find.byKey(_back),
        loaded: loaded(),
      );
      expect(api.writes, isEmpty, reason: 'editing Back does not save');
    });
  });
}
