// The Discover filter sheet of the app shell (MainNavigationScreen), driven
// from the member's real entry points (Today's "Discovery preferences", the
// Matches tab's "Filters") against the recording fake BFF: every control is
// changed the way a member changes it (tap, drag, pick), Apply is pressed, and
// the test asserts what reached the server — the trust filter save
// (PATCH /discovery/{me}/filters/trust) and the discovery reload
// (GET /discovery/{me} with the manual filters as query) — and what the
// member sees afterwards.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verified_dating_app/features/common/screens/main_navigation_screen.dart';
import 'package:verified_dating_app/features/matching/screens/matches_list_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_preferences_screen.dart';

import '../../support/qa_api.dart';

final _en = qaL10n(const Locale('en'));

Finder _k(String id) => find.byKey(ValueKey(id));

const _badges = <Map<String, String>>[
  {'badge_code': 'prompt_completer', 'badge_label': 'Prompt Completer'},
  {
    'badge_code': 'respectful_communicator',
    'badge_label': 'Respectful Communicator',
  },
  {'badge_code': 'consistent_profile', 'badge_label': 'Consistent Profile'},
  {'badge_code': 'verified_active', 'badge_label': 'Verified & Active'},
];

/// The member's saved dating preferences (GET /profile/{me}/draft).
Map<String, dynamic> _draft() => <String, dynamic>{
  'phone_number': '+919999999999',
  'name': 'Ananya',
  'date_of_birth': '1998-06-20',
  'gender': 'F',
  'photos': const <Object>[],
  'bio': 'This is a sufficiently long bio for tests.',
  'seeking_genders': const ['M'],
  'min_age_years': 21,
  'max_age_years': 40,
  'max_distance_km': 50,
  'serious_only': true,
  'verified_only': false,
  'hookup_only': false,
  'country': 'India',
  'state': 'Karnataka',
  'city': 'Bengaluru',
  'religion': 'Hindu',
  'mother_tongue': 'Kannada',
  'drinking': 'Never',
  'smoking': 'Never',
};

const _master = <String, dynamic>{
  'countries': ['India', 'Canada'],
  'states_by_country': {
    'India': ['Karnataka', 'Maharashtra'],
    'Canada': ['Ontario'],
  },
  'cities_by_state': {
    'Karnataka': ['Bengaluru', 'Mysuru'],
    'Maharashtra': ['Mumbai'],
    'Ontario': ['Toronto'],
  },
  'religions': ['Hindu', 'Buddhist'],
  'mother_tongues': ['Kannada', 'Hindi'],
};

Map<String, dynamic> _trust({
  bool enabled = false,
  int minimum = 0,
  List<String> codes = const [],
}) => <String, dynamic>{
  'trust_filter': <String, dynamic>{
    'enabled': enabled,
    'minimum_active_badges': minimum,
    'required_badge_codes': codes,
  },
  'available_badges': _badges,
};

/// The fake BFF: the routes the filter sheet uses, then permissive
/// catch-alls (registered last, so the specific routes win) for everything
/// the rest of the shell loads.
QaApi _server({bool trustEnabled = false}) {
  final api = QaApi()
    ..json('GET /profile/*/draft', {'draft': _draft()})
    ..json('GET /master-data/preferences', {'master_data': _master})
    ..json('GET /discovery/*/filters/trust', _trust(enabled: trustEnabled))
    // The server stores what it was sent and answers with it.
    ..on(
      'PATCH /discovery/*/filters/trust',
      (call) => qaOk({'trust_filter': call.body, 'available_badges': _badges}),
    )
    ..json('GET /discovery/*', {'candidates': const <Object>[]});
  for (var depth = 1; depth <= 6; depth++) {
    api.json('GET ${List.filled(depth, '/*').join()}', <String, dynamic>{});
  }
  return api;
}

Future<ProviderContainer> _mount(
  WidgetTester tester,
  QaApi api, {
  Map<String, bool> flags = const {},
}) async {
  SharedPreferences.setMockInitialValues({});
  // Tall enough that the whole sheet is laid out (every control hittable).
  await pumpQa(
    tester,
    api,
    const MainNavigationScreen(),
    flags: flags,
    size: const Size(430, 3200),
    extra: [idleNotificationsOverride()],
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(MainNavigationScreen)),
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Today's "Discovery preferences" button (intentional dating on).
Future<void> _openFromToday(WidgetTester tester) async {
  await tester.tap(find.byTooltip(_en.todayDiscoveryPreferences));
  await tester.pumpAndSettle();
  expect(_k('qa.filters.apply_button'), findsOneWidget);
}

/// The Matches tab's deck header "Filters".
Future<void> _openFromMatches(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text(_en.navMatches),
    ),
  );
  await tester.pumpAndSettle();
  await _tap(tester, _k('qa.discovery.filter_button').hitTestable());
  expect(_k('qa.filters.apply_button'), findsOneWidget);
}

Future<void> _pick(WidgetTester tester, String dropdown, String option) async {
  await _tap(tester, _k('qa.filters.${dropdown}_dropdown'));
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

String? _dropdownValue(WidgetTester tester, String dropdown) => tester
    .widget<DropdownButton<String>>(_k('qa.filters.${dropdown}_dropdown'))
    .value;

bool _switchOn(WidgetTester tester, String name) =>
    tester.widget<Switch>(_k('qa.filters.${name}_switch')).value;

Future<void> _apply(WidgetTester tester) =>
    _tap(tester, _k('qa.filters.apply_button'));

/// The trust filter saves the app sent.
List<Map<String, dynamic>> _trustSaves(QaApi api) => [
  for (final c in api.sent('PATCH', '/discovery/me/filters/trust')) c.body,
];

/// The discovery reloads the app sent (their query is the filter set).
List<Map<String, dynamic>> _reloads(QaApi api) => [
  for (final c in api.sent('GET', '/discovery/me')) c.query,
];

void _expectClosed() {
  expect(_k('qa.filters.apply_button'), findsNothing);
  expect(_k('qa.filters.close'), findsNothing);
}

void main() {
  group('opening the sheet', () {
    testWidgets(
      "Today's Discovery preferences opens the sheet on the saved preferences "
      'and Apply saves the trust filter and reloads discovery '
      '[case:common.main_navigation.discovery_preferences_onopenfilters.action] '
      '[case:common.main_navigation.showmodalbottomsheet_open.action] '
      '[case:common.main_navigation.filters_apply_button.action]',
      (tester) async {
        final api = _server();
        await _mount(tester, api);
        expect(_k('qa.filters.close'), findsNothing);

        await _openFromToday(tester);

        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text(_en.filterSheetTitle), findsOneWidget);
        // The sheet loaded the member's saved preferences and trust filter.
        expect(api.sent('GET', '/master-data/preferences'), isNotEmpty);
        expect(api.sent('GET', '/discovery/me/filters/trust'), hasLength(1));
        expect(find.text('21 – 40'), findsOneWidget);
        expect(find.text(_en.commonDistanceKm(50)), findsWidgets);
        expect(_dropdownValue(tester, 'country'), 'India');
        expect(_dropdownValue(tester, 'state'), 'Karnataka');
        expect(_dropdownValue(tester, 'city'), 'Bengaluru');
        expect(_dropdownValue(tester, 'religion'), 'Hindu');
        expect(_dropdownValue(tester, 'mother_tongue'), 'Kannada');
        final reloadsBefore = _reloads(api).length;
        api.calls.clear();

        await _apply(tester);

        expect(_trustSaves(api), [
          {
            'enabled': false,
            'minimum_active_badges': 0,
            'required_badge_codes': <String>[],
          },
        ]);
        expect(reloadsBefore, greaterThan(0));
        expect(_reloads(api), [
          {
            'limit': 50,
            'mode': 'all',
            'min_age': '21',
            'max_age': '40',
            'max_distance_km': '50',
            'verified_only': 'false',
            'religion': 'Hindu',
            'mother_tongue': 'Kannada',
            'country': 'India',
            'state': 'Karnataka',
            'city': 'Bengaluru',
            'smoking': 'Never',
            'drinking': 'Never',
          },
        ]);
        // The trust save went first, then the reload.
        expect(
          api.calls.indexWhere((c) => c.method == 'PATCH'),
          lessThan(api.calls.indexWhere((c) => c.path == '/discovery/me')),
        );
        _expectClosed();
        expect(
          qaSnackText(tester),
          _en.filterSavedSnack(21, 40, 50, 'false', 'false'),
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      "the Matches tab's Filters opens the same sheet and Apply reloads with "
      'the filters '
      '[case:common.main_navigation.discovery_preferences_onopenfilters_2.action] '
      '[case:common.main_navigation.showmodalbottomsheet_open.action]',
      (tester) async {
        final api = _server();
        final container = await _mount(tester, api);

        await _openFromMatches(tester);

        expect(container.read(mainNavigationIndexProvider), 1);
        expect(find.text(_en.filterSheetTitle), findsOneWidget);
        expect(find.text('21 – 40'), findsOneWidget);
        await _tap(tester, _k('qa.filters.verified_only_switch'));
        api.calls.clear();

        await _apply(tester);

        expect(_trustSaves(api), hasLength(1));
        expect(_reloads(api).single, containsPair('verified_only', 'true'));
        _expectClosed();
        expect(
          qaSnackText(tester),
          _en.filterSavedSnack(21, 40, 50, 'true', 'false'),
        );
        // Still on the Matches tab, back on its deck.
        expect(container.read(mainNavigationIndexProvider), 1);
        expect(find.byType(MatchesListScreen).hitTestable(), findsOneWidget);
      },
    );

    testWidgets(
      'when the saved trust filter cannot be loaded the sheet says so, and '
      'Retry loads it so Apply keeps it instead of switching it off '
      '[case:common.main_navigation.discovery_preferences_onopenfilters.api_failure] '
      '[case:common.main_navigation.filters_trust_retry.action]',
      (tester) async {
        final api = _server(trustEnabled: true)
          ..fail(
            'GET /discovery/me/filters/trust',
            status: 503,
            message: 'Trust filters are taking a break.',
          );
        await _mount(tester, api);

        await _openFromToday(tester);

        expect(find.text('Trust filters are taking a break.'), findsOneWidget);
        expect(_k('qa.filters.trust_retry'), findsOneWidget);
        // Nothing loaded, so the switch is only a default.
        expect(_switchOn(tester, 'trust'), isFalse);
        expect(_trustSaves(api), isEmpty);

        // The server is back.
        api.json('GET /discovery/me/filters/trust', _trust(enabled: true));
        await _tap(tester, _k('qa.filters.trust_retry'));

        expect(api.sent('GET', '/discovery/me/filters/trust'), hasLength(2));
        expect(find.text('Trust filters are taking a break.'), findsNothing);
        expect(_k('qa.filters.trust_retry'), findsNothing);
        expect(_switchOn(tester, 'trust'), isTrue);

        await _apply(tester);
        expect(_trustSaves(api).single['enabled'], isTrue);
        _expectClosed();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'a Retry that fails again keeps the error and a working Retry, sends '
      'one request per tap, and the next Retry loads the saved filter '
      '[case:common.main_navigation.filters_trust_retry.api_failure]',
      (tester) async {
        final api = _server(trustEnabled: true)
          ..fail('GET /discovery/me/filters/trust', status: 503);
        await _mount(tester, api);
        await _openFromToday(tester);
        expect(_k('qa.filters.trust_retry'), findsOneWidget);
        expect(api.sent('GET', '/discovery/me/filters/trust'), hasLength(1));

        // Still down, now with the server's reason.
        api.fail(
          'GET /discovery/me/filters/trust',
          status: 500,
          message: 'Trust filters are still resting.',
        );
        await _tap(tester, _k('qa.filters.trust_retry'));
        expect(api.sent('GET', '/discovery/me/filters/trust'), hasLength(2));
        expect(find.text('Trust filters are still resting.'), findsOneWidget);
        expect(_k('qa.filters.trust_retry'), findsOneWidget);
        expect(_switchOn(tester, 'trust'), isFalse);
        expect(_trustSaves(api), isEmpty);
        expect(tester.takeException(), isNull);

        // Back up: the next Retry loads the member's saved filter.
        api.json('GET /discovery/me/filters/trust', _trust(enabled: true));
        await _tap(tester, _k('qa.filters.trust_retry'));
        expect(api.sent('GET', '/discovery/me/filters/trust'), hasLength(3));
        expect(find.text('Trust filters are still resting.'), findsNothing);
        expect(_k('qa.filters.trust_retry'), findsNothing);
        expect(_switchOn(tester, 'trust'), isTrue);
      },
    );

    testWidgets(
      'when discovery cannot reload after Apply the Matches deck explains and '
      'Try again reloads with the same filters '
      '[case:common.main_navigation.discovery_preferences_onopenfilters_2.api_failure]',
      (tester) async {
        final api = _server();
        await _mount(tester, api);
        await _openFromMatches(tester);
        await _pick(tester, 'religion', 'Buddhist');
        api
          ..fail('GET /discovery/me', message: 'Discovery is resting.')
          ..calls.clear();

        await _apply(tester);

        // The filters were saved; only the reload failed.
        expect(_trustSaves(api), hasLength(1));
        expect(_reloads(api), hasLength(1));
        _expectClosed();
        expect(find.text(_en.discoverErrorTitle).hitTestable(), findsOneWidget);
        final tryAgain = find.text(_en.commonTryAgainTitle).hitTestable();
        expect(tryAgain, findsOneWidget);

        api
          ..json('GET /discovery/me', {'candidates': const <Object>[]})
          ..calls.clear();
        await _tap(tester, tryAgain);

        expect(_reloads(api).single, containsPair('religion', 'Buddhist'));
        expect(find.text(_en.discoverErrorTitle).hitTestable(), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('location and lifestyle pickers', () {
    testWidgets('Country picks a country and clears the state and city '
        '[case:common.main_navigation.country.action]', (tester) async {
      final api = _server();
      await _mount(tester, api);
      await _openFromToday(tester);

      await _pick(tester, 'country', 'Canada');

      expect(_dropdownValue(tester, 'country'), 'Canada');
      expect(_dropdownValue(tester, 'state'), isNull);
      expect(_dropdownValue(tester, 'city'), isNull);
      api.calls.clear();
      await _apply(tester);
      final query = _reloads(api).single;
      expect(query, containsPair('country', 'Canada'));
      expect(query.containsKey('state'), isFalse);
      expect(query.containsKey('city'), isFalse);
    });

    testWidgets('State offers the country\'s states and clears the city '
        '[case:common.main_navigation.state.action]', (tester) async {
      final api = _server();
      await _mount(tester, api);
      await _openFromToday(tester);

      await _pick(tester, 'state', 'Maharashtra');

      expect(_dropdownValue(tester, 'state'), 'Maharashtra');
      expect(_dropdownValue(tester, 'city'), isNull);
      api.calls.clear();
      await _apply(tester);
      final query = _reloads(api).single;
      expect(query, containsPair('country', 'India'));
      expect(query, containsPair('state', 'Maharashtra'));
      expect(query.containsKey('city'), isFalse);
    });

    testWidgets('City picks one of the state\'s cities '
        '[case:common.main_navigation.city.action]', (tester) async {
      final api = _server();
      await _mount(tester, api);
      await _openFromToday(tester);

      await _pick(tester, 'city', 'Mysuru');

      expect(_dropdownValue(tester, 'city'), 'Mysuru');
      api.calls.clear();
      await _apply(tester);
      expect(_reloads(api).single, containsPair('city', 'Mysuru'));
    });

    Future<void> pickAndApply(
      WidgetTester tester,
      String dropdown,
      String option,
      String queryKey,
    ) async {
      final api = _server();
      await _mount(tester, api);
      await _openFromToday(tester);

      await _pick(tester, dropdown, option);

      expect(_dropdownValue(tester, dropdown), option);
      api.calls.clear();
      await _apply(tester);
      expect(_reloads(api).single, containsPair(queryKey, option));
      _expectClosed();
      expect(tester.takeException(), isNull);
    }

    testWidgets('Mother Tongue filters discovery by the picked language '
        '[case:common.main_navigation.mother_tongue.action]', (tester) async {
      await pickAndApply(tester, 'mother_tongue', 'Hindi', 'mother_tongue');
    });

    testWidgets('Religion filters discovery by the picked religion '
        '[case:common.main_navigation.religion.action]', (tester) async {
      await pickAndApply(tester, 'religion', 'Buddhist', 'religion');
    });

    testWidgets('Relationship Status filters discovery by the picked status '
        '[case:common.main_navigation.relationship_status.action]', (
      tester,
    ) async {
      await pickAndApply(
        tester,
        'relationship_status',
        'Divorced',
        'relationship_status',
      );
    });

    testWidgets('Smoking filters discovery by the picked habit '
        '[case:common.main_navigation.smoking.action]', (tester) async {
      await pickAndApply(tester, 'smoking', 'Regularly', 'smoking');
    });

    testWidgets('Drinking filters discovery by the picked habit '
        '[case:common.main_navigation.drinking.action]', (tester) async {
      await pickAndApply(tester, 'drinking', 'Socially', 'drinking');
    });

    testWidgets('Personality Type filters discovery by the picked type '
        '[case:common.main_navigation.personality_type.action]', (
      tester,
    ) async {
      await pickAndApply(
        tester,
        'personality_type',
        'Introvert',
        'personality_type',
      );
    });

    testWidgets('picking Any removes that filter from the reload '
        '[case:common.main_navigation.religion.action]', (tester) async {
      final api = _server();
      await _mount(tester, api);
      await _openFromToday(tester);

      await _pick(tester, 'religion', _en.commonAny);

      expect(_dropdownValue(tester, 'religion'), isNull);
      api.calls.clear();
      await _apply(tester);
      expect(_reloads(api).single.containsKey('religion'), isFalse);
    });
  });

  group('sliders and switches', () {
    testWidgets('dragging the Age Range thumbs widens the range and the '
        'reload asks for it '
        '[case:common.main_navigation.filters_age_range_slider.action]', (
      tester,
    ) async {
      final api = _server();
      await _mount(tester, api);
      await _openFromToday(tester);
      final slider = _k('qa.filters.age_range_slider');
      final rect = tester.getRect(slider);

      // The upper thumb (40) is nearest the middle: drag it to the end.
      await tester.dragFrom(rect.center, Offset(rect.width, 0));
      await tester.pumpAndSettle();
      // Then the lower thumb, from left of it, to the start.
      await tester.dragFrom(
        Offset(rect.left + 30, rect.center.dy),
        Offset(-rect.width, 0),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<RangeSlider>(slider).values,
        const RangeValues(18, 80),
      );
      expect(find.text('18 – 80'), findsOneWidget);
      api.calls.clear();
      await _apply(tester);
      expect(
        _reloads(api).single,
        allOf(containsPair('min_age', '18'), containsPair('max_age', '80')),
      );
      expect(
        qaSnackText(tester),
        _en.filterSavedSnack(18, 80, 50, 'false', 'false'),
      );
    });

    testWidgets('dragging the distance slider changes the distance readout '
        'and the reload '
        '[case:common.main_navigation.filters_distance_slider.action]', (
      tester,
    ) async {
      final api = _server();
      await _mount(tester, api);
      await _openFromToday(tester);
      final slider = _k('qa.filters.distance_slider');
      final rect = tester.getRect(slider);

      await tester.dragFrom(rect.center, Offset(rect.width, 0));
      await tester.pumpAndSettle();

      expect(tester.widget<Slider>(slider).value, 500);
      expect(find.text(_en.commonDistanceKm(500)), findsWidgets);
      api.calls.clear();
      await _apply(tester);
      expect(_reloads(api).single, containsPair('max_distance_km', '500'));
      expect(
        qaSnackText(tester),
        _en.filterSavedSnack(21, 40, 500, 'false', 'false'),
      );
    });

    testWidgets('Party lover only turns on and the reload asks for party '
        'lovers '
        '[case:common.main_navigation.filters_party_lover_switch.action]', (
      tester,
    ) async {
      final api = _server();
      await _mount(tester, api);
      await _openFromToday(tester);
      expect(_switchOn(tester, 'party_lover'), isFalse);

      await _tap(tester, _k('qa.filters.party_lover_switch'));

      expect(_switchOn(tester, 'party_lover'), isTrue);
      api.calls.clear();
      await _apply(tester);
      expect(_reloads(api).single, containsPair('party_lover', 'true'));
    });

    testWidgets('Hookups only turns on and the reload asks for it '
        '[case:common.main_navigation.filters_hookup_switch.action]', (
      tester,
    ) async {
      final api = _server();
      await _mount(tester, api);
      await _openFromToday(tester);
      expect(_switchOn(tester, 'hookup'), isFalse);

      await _tap(tester, _k('qa.filters.hookup_switch'));

      expect(_switchOn(tester, 'hookup'), isTrue);
      api.calls.clear();
      await _apply(tester);
      expect(_reloads(api).single, containsPair('hookup_only', 'true'));
    });

    testWidgets('Show only verified profiles turns on, the reload asks for '
        'verified members and Today shows the filter as active '
        '[case:common.main_navigation.filters_verified_only_switch.action]', (
      tester,
    ) async {
      final api = _server();
      await _mount(tester, api);
      await _openFromToday(tester);

      await _tap(tester, _k('qa.filters.verified_only_switch'));

      expect(_switchOn(tester, 'verified_only'), isTrue);
      api.calls.clear();
      await _apply(tester);
      expect(_reloads(api).single, containsPair('verified_only', 'true'));
      expect(
        qaSnackText(tester),
        _en.filterSavedSnack(21, 40, 50, 'true', 'false'),
      );
      expect(
        find.widgetWithText(Chip, _en.filterVerifiedOnlyChip),
        findsOneWidget,
      );
    });

    testWidgets('Enable trust-based filtering unlocks the trust controls and '
        'Apply saves it on '
        '[case:common.main_navigation.filters_trust_switch.action]', (
      tester,
    ) async {
      final api = _server();
      await _mount(tester, api);
      await _openFromToday(tester);
      expect(
        tester.widget<Slider>(_k('qa.filters.trust_badge_slider')).onChanged,
        isNull,
      );
      expect(
        tester.widget<FilterChip>(find.byType(FilterChip).first).onSelected,
        isNull,
      );

      await _tap(tester, _k('qa.filters.trust_switch'));

      expect(_switchOn(tester, 'trust'), isTrue);
      expect(
        tester.widget<Slider>(_k('qa.filters.trust_badge_slider')).onChanged,
        isNotNull,
      );
      await _apply(tester);
      expect(_trustSaves(api), [
        {
          'enabled': true,
          'minimum_active_badges': 0,
          'required_badge_codes': <String>[],
        },
      ]);
      expect(
        qaSnackText(tester),
        _en.filterSavedSnack(21, 40, 50, 'false', 'true'),
      );
    });

    testWidgets('the minimum trust badges slider sets how many badges are '
        'required and Apply saves it '
        '[case:common.main_navigation.filters_trust_badge_slider.action]', (
      tester,
    ) async {
      final api = _server();
      await _mount(tester, api);
      await _openFromToday(tester);
      await _tap(tester, _k('qa.filters.trust_switch'));
      final slider = _k('qa.filters.trust_badge_slider');
      final rect = tester.getRect(slider);

      await tester.dragFrom(rect.center, Offset(rect.width, 0));
      await tester.pumpAndSettle();

      expect(tester.widget<Slider>(slider).value, 4);
      expect(find.text(_en.filterMinimumTrustBadges(4)), findsOneWidget);
      await _apply(tester);
      expect(_trustSaves(api).single, {
        'enabled': true,
        'minimum_active_badges': 4,
        'required_badge_codes': <String>[],
      });
    });

    testWidgets('trust badge chips toggle on and off and Apply saves the '
        'required badges '
        '[case:common.main_navigation.filterchip_onselected.action]', (
      tester,
    ) async {
      final api = _server();
      await _mount(tester, api);
      await _openFromToday(tester);
      await _tap(tester, _k('qa.filters.trust_switch'));
      Finder chip(String label) => find.widgetWithText(FilterChip, label);
      bool selected(String label) =>
          tester.widget<FilterChip>(chip(label)).selected;

      await _tap(tester, chip(_en.matchesTrustBadgeVerifiedActive));
      await _tap(tester, chip(_en.matchesTrustBadgePromptCompleter));
      await _tap(tester, chip(_en.matchesTrustBadgeConsistent));
      await _tap(tester, chip(_en.matchesTrustBadgeConsistent));

      expect(selected(_en.matchesTrustBadgeVerifiedActive), isTrue);
      expect(selected(_en.matchesTrustBadgePromptCompleter), isTrue);
      expect(selected(_en.matchesTrustBadgeConsistent), isFalse);
      expect(selected(_en.matchesTrustBadgeRespectful), isFalse);
      await _apply(tester);
      expect(_trustSaves(api).single['required_badge_codes'], [
        'prompt_completer',
        'verified_active',
      ]);
    });
  });

  group('Reset, Close, Apply failure, dating preferences', () {
    testWidgets('Reset returns every control to its default without saving, '
        'and Apply then sends the defaults '
        '[case:common.main_navigation.filters_reset_button.action]', (
      tester,
    ) async {
      final api = _server(trustEnabled: true);
      await _mount(tester, api);
      await _openFromToday(tester);
      expect(_switchOn(tester, 'trust'), isTrue);
      await _tap(tester, _k('qa.filters.verified_only_switch'));
      await _tap(tester, _k('qa.filters.hookup_switch'));
      await _pick(tester, 'personality_type', 'Extrovert');
      api.calls.clear();

      await _tap(tester, _k('qa.filters.reset_button'));

      expect(api.calls, isEmpty, reason: 'Reset alone sends nothing');
      expect(find.text('20 – 50'), findsOneWidget);
      expect(tester.widget<Slider>(_k('qa.filters.distance_slider')).value, 50);
      for (final name in ['verified_only', 'hookup', 'party_lover', 'trust']) {
        expect(_switchOn(tester, name), isFalse, reason: name);
      }
      for (final name in [
        'country',
        'state',
        'city',
        'religion',
        'mother_tongue',
        'smoking',
        'drinking',
        'personality_type',
        'relationship_status',
      ]) {
        expect(_dropdownValue(tester, name), isNull, reason: name);
      }
      expect(_k('qa.filters.apply_button'), findsOneWidget);

      await _apply(tester);
      expect(_trustSaves(api).single, {
        'enabled': false,
        'minimum_active_badges': 0,
        'required_badge_codes': <String>[],
      });
      expect(_reloads(api).single, {
        'limit': 50,
        'mode': 'all',
        'min_age': '20',
        'max_age': '50',
        'max_distance_km': '50',
        'verified_only': 'false',
      });
    });

    testWidgets('Close leaves without saving and discards the edits '
        '[case:common.main_navigation.filters_close.action]', (tester) async {
      final api = _server();
      await _mount(tester, api);
      await _openFromToday(tester);
      await _tap(tester, _k('qa.filters.verified_only_switch'));
      await _pick(tester, 'religion', 'Buddhist');
      api.calls.clear();

      await _tap(tester, _k('qa.filters.close'));

      _expectClosed();
      expect(api.writes, isEmpty);
      expect(_reloads(api), isEmpty);
      expect(qaSnackText(tester), isNull);
      // Nothing unsaved shows as an active filter.
      expect(
        find.widgetWithText(Chip, _en.filterVerifiedOnlyChip),
        findsNothing,
      );

      // Reopening shows the saved preferences again, not the dropped edits.
      await _openFromToday(tester);
      expect(_switchOn(tester, 'verified_only'), isFalse);
      expect(_dropdownValue(tester, 'religion'), 'Hindu');
      expect(find.text('21 – 40'), findsOneWidget);
    });

    testWidgets('a failed Apply explains, keeps the sheet and the edits, '
        're-enables Apply, and a retry saves once '
        '[case:common.main_navigation.filters_apply_button.api_failure] '
        '[case:common.main_navigation.filters_apply_button.action]', (
      tester,
    ) async {
      final api = _server()
        ..fail(
          'PATCH /discovery/me/filters/trust',
          message: 'Trust filters are taking a break.',
        );
      await _mount(tester, api);
      await _openFromToday(tester);
      await _tap(tester, _k('qa.filters.trust_switch'));
      await _tap(tester, _k('qa.filters.verified_only_switch'));
      api.calls.clear();

      await _apply(tester);

      expect(qaSnackText(tester), 'Trust filters are taking a break.');
      expect(_trustSaves(api), hasLength(1));
      expect(_reloads(api), isEmpty, reason: 'no partial filters applied');
      expect(_k('qa.filters.apply_button'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(_k('qa.filters.apply_button')).onPressed,
        isNotNull,
      );
      expect(_switchOn(tester, 'trust'), isTrue);
      expect(_switchOn(tester, 'verified_only'), isTrue);
      // A failed save is not mistaken for a failed load.
      expect(_k('qa.filters.trust_retry'), findsNothing);

      // The server is back; the message times out; the member retries.
      api.on(
        'PATCH /discovery/me/filters/trust',
        (call) => qaOk({'trust_filter': call.body}),
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      api.calls.clear();
      await _apply(tester);

      expect(_trustSaves(api), [
        {
          'enabled': true,
          'minimum_active_badges': 0,
          'required_badge_codes': <String>[],
        },
      ]);
      expect(_reloads(api).single, containsPair('verified_only', 'true'));
      _expectClosed();
      expect(
        qaSnackText(tester),
        _en.filterSavedSnack(21, 40, 50, 'true', 'true'),
      );
    });

    testWidgets('a failed Apply while offline explains in German '
        '[case:common.main_navigation.filters_apply_button.api_failure]', (
      tester,
    ) async {
      const de = Locale('de');
      final api = _server()..offline('PATCH /discovery/me/filters/trust');
      SharedPreferences.setMockInitialValues({});
      await pumpQa(
        tester,
        api,
        const MainNavigationScreen(),
        locale: de,
        size: const Size(430, 3200),
        extra: [idleNotificationsOverride()],
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(qaL10n(de).todayDiscoveryPreferences));
      await tester.pumpAndSettle();

      await _apply(tester);

      expect(qaSnackText(tester), qaL10n(de).matchesTrustErrorSave);
      expect(qaSnackText(tester), isNot(_en.matchesTrustErrorSave));
      expect(_k('qa.filters.apply_button'), findsOneWidget);
    });

    testWidgets('Open Dating Preferences closes the sheet and opens the '
        'dating preferences screen '
        '[case:common.main_navigation.open_dating_preferences.action]', (
      tester,
    ) async {
      final api = _server();
      await _mount(tester, api);
      await _openFromToday(tester);
      api.calls.clear();

      await _tap(tester, find.text(_en.filterOpenDatingPreferences));

      _expectClosed();
      expect(find.byType(SetupPreferencesScreen), findsOneWidget);
      expect(_trustSaves(api), isEmpty);
      // Its back button returns to the shell.
      await _tap(tester, _k('qa.setup.preferences.back_button'));
      expect(find.byType(SetupPreferencesScreen), findsNothing);
      expect(find.byType(MainNavigationScreen).hitTestable(), findsOneWidget);
    });
  });
}
