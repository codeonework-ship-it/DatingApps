// Trust Badges and Trust Filters: refresh, every filter control and Save,
// asserted against the recording fake BFF.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/engagement/screens/trust_badges_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/trust_filter_screen.dart';

import '../../support/qa_api.dart';
import 'engagement_qa.dart';

const _badgesPath = '/users/me/trust-badges';
const _filterPath = '/discovery/me/filters/trust';
const _enabled = ValueKey('qa.trust_filter.enabled');
const _minimum = ValueKey('qa.trust_filter.minimum');
const _save = ValueKey('qa.trust_filter.save');
const _verified = ValueKey('qa.trust_filter.badge.verified_active');
const _respectful = ValueKey('qa.trust_filter.badge.respectful_communicator');

const _emptyBadges = {
  'milestones': <String, dynamic>{},
  'badges': <Object>[],
  'history': <Object>[],
};

const _earnedBadges = {
  'milestones': {'communication_score': 81},
  'badges': [
    {
      'badge_code': 'respectful_communicator',
      'badge_label': 'Respectful Communicator',
      'status': 'active',
      'awarded_at': '2026-09-30T10:00:00Z',
    },
  ],
  'history': [
    {
      'badge_code': 'respectful_communicator',
      'action': 'awarded',
      'reason': 'Kind replies for two weeks.',
      'happened_at': '2026-09-30T10:00:00Z',
    },
  ],
};

Map<String, dynamic> _filter({
  bool enabled = false,
  int minimum = 0,
  List<String> required = const [],
}) => {
  'trust_filter': {
    'enabled': enabled,
    'minimum_active_badges': minimum,
    'required_badge_codes': required,
  },
  'available_badges': [
    {'badge_code': 'prompt_completer', 'badge_label': 'Prompt Completer'},
    {
      'badge_code': 'respectful_communicator',
      'badge_label': 'Respectful Communicator',
    },
    {'badge_code': 'consistent_profile', 'badge_label': 'Consistent Profile'},
    {'badge_code': 'verified_active', 'badge_label': 'Verified & Active'},
  ],
};

QaApi _filterApi() => QaApi()..json('GET $_filterPath', _filter());

Future<void> _openFilter(WidgetTester tester, QaApi api) =>
    pumpQa(tester, api, const TrustFilterScreen());

bool _switchOn(WidgetTester tester) =>
    tester.widget<SwitchListTile>(find.byKey(_enabled)).value;

bool _checked(WidgetTester tester, Key key) =>
    tester.widget<CheckboxListTile>(find.byKey(key)).value!;

double _slider(WidgetTester tester) =>
    tester.widget<Slider>(find.byKey(_minimum)).value;

/// Taps the minimum-badges slider at [value] (0-4).
Future<void> _setMinimum(WidgetTester tester, int value) async {
  final rect = tester.getRect(find.byKey(_minimum));
  const inset = 24.0; // the slider's track padding on each side
  final x = rect.left + inset + (rect.width - 2 * inset) * value / 4;
  await tester.tapAt(Offset(x, rect.center.dy));
  await tester.pump();
}

Future<void> _tapSave(WidgetTester tester) async {
  await qaScrollTo(tester, find.byKey(_save));
  await tester.tap(find.byKey(_save));
  await qaSettle(tester);
}

void main() {
  group('Trust Badges', () {
    testWidgets(
      'pull to refresh fetches my badges and history and shows them [case:engagement.trust_badges.no_trust_history_available_yet_onrefresh.action]',
      (tester) async {
        final api = QaApi()..json('GET $_badgesPath', _emptyBadges);
        await pumpQa(tester, api, const TrustBadgesScreen());
        expect(find.text(en.engagementTrustBadgesEmpty), findsOneWidget);
        expect(find.text(en.engagementTrustBadgesHistoryEmpty), findsOneWidget);
        expect(
          find.text(en.engagementTrustBadgesMilestoneUnavailable),
          findsOneWidget,
        );

        api.json('GET $_badgesPath', _earnedBadges);
        await qaPullToRefresh(tester);

        expect(api.sent('GET', _badgesPath), hasLength(2));
        expect(api.writes, isEmpty);
        expect(find.text(en.engagementTrustBadgesHistoryEmpty), findsNothing);
        expect(find.text(en.engagementTrustBadgesEmpty), findsNothing);
        expect(find.text('Respectful Communicator'), findsOneWidget);
        expect(
          find.text(
            en.engagementTrustBadgesDetails(
              'respectful_communicator',
              'active',
              '2026-09-30T10:00:00Z',
            ),
          ),
          findsOneWidget,
        );
        expect(find.text('communication_score: 81'), findsOneWidget);
        await qaScrollTo(tester, find.text('Kind replies for two weeks.'));
        expect(find.text('awarded'), findsOneWidget);
        expect(find.text('2026-09-30'), findsOneWidget);
      },
    );

    for (final (label, failure, message) in [
      (
        '500 with the server message',
        qaError(500, message: 'Badges are recalculating.'),
        'Badges are recalculating.',
      ),
      ('offline', qaOffline, 'Failed to load trust badges. Please try again.'),
    ]) {
      testWidgets(
        'a failed refresh ($label) shows the reason and keeps my badges; the next pull recovers [case:engagement.trust_badges.no_trust_history_available_yet_onrefresh.api_failure]',
        (tester) async {
          final api = QaApi()..json('GET $_badgesPath', _earnedBadges);
          await pumpQa(tester, api, const TrustBadgesScreen());
          api.on('GET $_badgesPath', (_) => failure);
          await qaPullToRefresh(tester);

          expect(find.text('Respectful Communicator'), findsOneWidget);
          await qaScrollTo(tester, find.text(message));
          expect(find.text(message), findsOneWidget);
          expect(tester.takeException(), isNull);

          api.json('GET $_badgesPath', _earnedBadges);
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, 2000),
          );
          await tester.pump();
          await qaPullToRefresh(tester);
          expect(find.text(message), findsNothing);
          expect(api.sent('GET', _badgesPath), hasLength(3));
        },
      );
    }

    testWidgets(
      'Trust badges render translated in every locale without overflow [case:engagement.trust_badges.l10n]',
      (tester) async {
        for (final locale in qaLocales) {
          final api = QaApi()..json('GET $_badgesPath', _earnedBadges);
          await pumpQa(tester, api, const TrustBadgesScreen(), locale: locale);
          final l = qaL10n(locale);
          expect(tester.takeException(), isNull, reason: '$locale');
          expect(find.text(l.settingsTrustBadgesTitle), findsOneWidget);
          expect(find.text(l.engagementTrustBadgesEarned), findsOneWidget);
          expect(find.text(l.matchesTrustBadgeRespectful), findsOneWidget);
          await qaUnmount(tester);
        }
      },
    );
  });

  group('Trust Filters', () {
    testWidgets(
      'pull to refresh reloads my saved filters into the controls [case:engagement.trust_filter.save_trust_filters_onrefresh.action]',
      (tester) async {
        final api = _filterApi();
        await _openFilter(tester, api);
        expect(_switchOn(tester), isFalse);
        expect(find.text(en.engagementTrustFiltersMinimum(0)), findsOneWidget);

        api.json(
          'GET $_filterPath',
          _filter(enabled: true, minimum: 2, required: ['verified_active']),
        );
        await qaPullToRefresh(tester);

        expect(api.sent('GET', _filterPath), hasLength(2));
        expect(api.writes, isEmpty);
        expect(_switchOn(tester), isTrue);
        expect(_slider(tester), 2);
        expect(find.text(en.engagementTrustFiltersMinimum(2)), findsOneWidget);
        await qaScrollTo(tester, find.byKey(_verified));
        expect(_checked(tester, _verified), isTrue);
        expect(_checked(tester, _respectful), isFalse);
      },
    );

    for (final (label, failure, message) in [
      (
        '500 with the server message',
        qaError(500, message: 'Filters are unavailable.'),
        'Filters are unavailable.',
      ),
      ('offline', qaOffline, 'Failed to load trust filters. Please try again.'),
    ]) {
      testWidgets(
        'a failed refresh ($label) shows the reason with the controls still there; the next pull recovers [case:engagement.trust_filter.save_trust_filters_onrefresh.api_failure]',
        (tester) async {
          final api = _filterApi();
          await _openFilter(tester, api);
          api.on('GET $_filterPath', (_) => failure);
          await qaPullToRefresh(tester);

          await qaScrollTo(tester, find.text(message));
          expect(find.text(message), findsOneWidget);
          expect(find.byKey(_save), findsOneWidget);
          expect(tester.takeException(), isNull);

          api.json('GET $_filterPath', _filter(enabled: true));
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, 2000),
          );
          await tester.pump();
          await qaPullToRefresh(tester);
          expect(find.text(message), findsNothing);
          expect(_switchOn(tester), isTrue);
        },
      );
    }

    testWidgets(
      'Enable trust filters toggles the switch locally; Save sends it [case:engagement.trust_filter.enable_trust_filters.action]',
      (tester) async {
        final api = _filterApi()
          ..json('PATCH $_filterPath', _filter(enabled: true));
        await _openFilter(tester, api);
        expect(find.text(en.engagementTrustFiltersEnable), findsOneWidget);

        await tester.tap(find.byKey(_enabled));
        await tester.pump();
        expect(_switchOn(tester), isTrue);
        await tester.tap(find.byKey(_enabled));
        await tester.pump();
        expect(_switchOn(tester), isFalse);
        await tester.tap(find.byKey(_enabled));
        await tester.pump();
        expect(api.writes, isEmpty, reason: 'nothing is saved until Save');

        await _tapSave(tester);
        expect(api.sent('PATCH', _filterPath).single.body['enabled'], isTrue);
        expect(_switchOn(tester), isTrue);
      },
    );

    testWidgets(
      'the minimum-badges slider updates the label locally; Save sends the value [case:engagement.trust_filter.slider_onchanged.action]',
      (tester) async {
        final api = _filterApi()
          ..json('PATCH $_filterPath', _filter(minimum: 3));
        await _openFilter(tester, api);

        await _setMinimum(tester, 3);
        expect(_slider(tester), 3);
        expect(find.text(en.engagementTrustFiltersMinimum(3)), findsOneWidget);
        await _setMinimum(tester, 1);
        expect(find.text(en.engagementTrustFiltersMinimum(1)), findsOneWidget);
        await _setMinimum(tester, 3);
        expect(api.writes, isEmpty);

        await _tapSave(tester);
        expect(
          api.sent('PATCH', _filterPath).single.body['minimum_active_badges'],
          3,
        );
        expect(find.text(en.engagementTrustFiltersMinimum(3)), findsOneWidget);
      },
    );

    testWidgets(
      'required-badge checkboxes toggle locally; Save sends the checked codes sorted [case:engagement.trust_filter.checkboxlisttile_onchanged.action]',
      (tester) async {
        final api = _filterApi()
          ..json(
            'PATCH $_filterPath',
            _filter(required: ['respectful_communicator', 'verified_active']),
          );
        await _openFilter(tester, api);

        await qaScrollTo(tester, find.byKey(_verified));
        await tester.tap(find.byKey(_verified));
        await tester.pump();
        expect(_checked(tester, _verified), isTrue);
        await tester.tap(find.byKey(_respectful));
        await tester.pump();
        expect(_checked(tester, _respectful), isTrue);
        const prompt = ValueKey('qa.trust_filter.badge.prompt_completer');
        await tester.tap(find.byKey(prompt));
        await tester.pump();
        await tester.tap(find.byKey(prompt));
        await tester.pump();
        expect(_checked(tester, prompt), isFalse);
        expect(api.writes, isEmpty);

        await _tapSave(tester);
        expect(
          api.sent('PATCH', _filterPath).single.body['required_badge_codes'],
          ['respectful_communicator', 'verified_active'],
        );
      },
    );

    testWidgets(
      'Save Trust Filters sends the complete filter, confirms and shows what the server saved [case:engagement.trust_filter.save_trust_filters.action]',
      (tester) async {
        final api = _filterApi()
          ..json(
            'PATCH $_filterPath',
            _filter(enabled: true, minimum: 4, required: ['verified_active']),
          );
        await _openFilter(tester, api);
        await tester.tap(find.byKey(_enabled));
        await tester.pump();
        await _setMinimum(tester, 4);
        await qaScrollTo(tester, find.byKey(_verified));
        await tester.tap(find.byKey(_verified));
        await tester.pump();

        await _tapSave(tester);

        final patches = api.sent('PATCH', _filterPath);
        expect(patches, hasLength(1));
        expect(patches.single.body, {
          'enabled': true,
          'minimum_active_badges': 4,
          'required_badge_codes': ['verified_active'],
        });
        expect(qaSnackText(tester), en.engagementTrustFiltersSaved);
        expect(qaEnabled(tester, find.byKey(_save)), isTrue);
        expect(_checked(tester, _verified), isTrue);
      },
    );

    for (final (label, failure, message) in [
      (
        '500 with the server message',
        qaError(500, message: 'Filter store is read-only.'),
        'Filter store is read-only.',
      ),
      ('offline', qaOffline, 'Failed to save trust filters. Please try again.'),
    ]) {
      testWidgets(
        'a failed save ($label) never claims success, keeps my choices and retries [case:engagement.trust_filter.save_trust_filters.api_failure]',
        (tester) async {
          final api = _filterApi()..on('PATCH $_filterPath', (_) => failure);
          await _openFilter(tester, api);
          await tester.tap(find.byKey(_enabled));
          await tester.pump();
          await _setMinimum(tester, 2);

          await _tapSave(tester);

          expect(find.text(message), findsOneWidget);
          expect(qaSnackText(tester), isNull);
          expect(find.text(en.engagementTrustFiltersSaved), findsNothing);
          expect(_switchOn(tester), isTrue);
          expect(_slider(tester), 2);
          expect(qaEnabled(tester, find.byKey(_save)), isTrue);
          expect(api.sent('PATCH', _filterPath), hasLength(1));

          api.json('PATCH $_filterPath', _filter(enabled: true, minimum: 2));
          await _tapSave(tester);
          expect(find.text(message), findsNothing);
          expect(qaSnackText(tester), en.engagementTrustFiltersSaved);
          expect(api.sent('PATCH', _filterPath), hasLength(2));
          expect(api.sent('PATCH', _filterPath).last.body, {
            'enabled': true,
            'minimum_active_badges': 2,
            'required_badge_codes': <String>[],
          });
        },
      );
    }

    testWidgets(
      'Trust filters render translated in every locale without overflow [case:engagement.trust_filter.l10n]',
      (tester) async {
        for (final locale in qaLocales) {
          await pumpQa(
            tester,
            _filterApi(),
            const TrustFilterScreen(),
            locale: locale,
          );
          final l = qaL10n(locale);
          expect(tester.takeException(), isNull, reason: '$locale');
          expect(find.text(l.settingsTrustFiltersTitle), findsOneWidget);
          expect(find.text(l.engagementTrustFiltersEnable), findsOneWidget);
          expect(find.text(l.engagementTrustFiltersMinimum(0)), findsOneWidget);
          await qaScrollTo(tester, find.byKey(_save));
          expect(tester.takeException(), isNull, reason: '$locale');
          expect(find.text(l.engagementTrustFiltersSave), findsOneWidget);
          expect(find.text(l.matchesTrustBadgeVerifiedActive), findsOneWidget);
          await qaUnmount(tester);
        }
      },
    );
  });
}
