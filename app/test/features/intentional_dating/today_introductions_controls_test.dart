// Control tests for the Today screen's introductions
// (lib/features/intentional_dating/today_introductions.dart), with the real
// providers behind the recording fake BFF: activity filters, both refresh
// paths, the paused / failed notices, the rhythm entry and l10n.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/intentional_dating/dating_rhythm.dart';
import 'package:verified_dating_app/features/intentional_dating/today_introductions.dart';

import '../../support/qa_api.dart';
import '../swipe/discover_qa_fixtures.dart';
import 'intentional_dating_qa_support.dart';

const _today = '/discovery/me/today';

Map<String, dynamic> _pick(String id, String name, String activity) => {
  ...qaCandidate(id, name, reasons: ['A similar communication pace']),
  'shared_activities': [activity],
};

/// The fake BFF behind Today; [picks] is what the next read of today's set
/// returns.
class _TodayWorld {
  _TodayWorld({List<Map<String, dynamic>>? picks, this.paused = false})
    : picks =
          picks ??
          [_pick('u-maya', 'Maya', 'coffee'), _pick('u-sam', 'Sam', 'walk')] {
    heal();
  }

  final api = QaApi();
  List<Map<String, dynamic>> picks;
  bool paused;

  void heal() {
    api
      ..on(
        'GET $_today',
        (_) => qaOk({'candidates': picks, 'set_date': '2026-10-03'}),
      )
      ..json('GET /account/me/dating-preferences', {
        'preferences': {'version': 1},
      })
      ..on('GET /account/me/discovery/pause', (_) => qaOk({'paused': paused}))
      ..json('GET /walls/today', {'day': '2026-10-03', 'items': <dynamic>[]})
      ..json('GET /themes/cover', {'cover': null})
      ..json('GET /profile/me/stories', {
        'version': 1,
        'stories': <dynamic>[],
        'photos': <dynamic>[],
      });
  }

  int reads(String path) => api.sent('GET', path).length;
}

Future<void> _pump(
  WidgetTester t,
  _TodayWorld w, {
  Locale? locale,
  Size size = const Size(430, 5200),
}) => pumpQa(
  t,
  w.api,
  TodayIntroductions(onOpenProfile: (_) {}, onBrowse: () {}),
  locale: locale,
  size: size,
);

final _en = qaL10n(const Locale('en'));
Finder _card(String id) => find.byKey(ValueKey('qa.today.profile.$id'));

Future<void> _tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
  await qaSettle(t);
}

bool _chipSelected(WidgetTester t, Finder chip) =>
    t.widget<ChoiceChip>(chip).selected;

/// Every read a Today refresh makes, counted.
Map<String, int> _refreshReads(_TodayWorld w) => {
  for (final p in [
    _today,
    '/account/me/dating-preferences',
    '/account/me/discovery/pause',
    '/walls/today',
    '/themes/cover',
    '/profile/me/stories',
  ])
    p: w.reads(p),
};

void _expectRefreshed(_TodayWorld w, Map<String, int> before) {
  for (final e in before.entries) {
    expect(w.reads(e.key), greaterThan(e.value), reason: e.key);
  }
}

void main() {
  testWidgets('an activity chip shows only the introductions that share it, '
      'and tapping it again clears the filter '
      '[case:intentional_dating.today_introductions.today_activity_x.action]', (
    t,
  ) async {
    final w = _TodayWorld();
    await _pump(t, w);
    expect(_card('u-maya'), findsOneWidget);
    expect(_card('u-sam'), findsOneWidget);
    final coffee = find.byKey(const ValueKey('qa.today.activity.coffee'));

    await _tap(t, coffee);
    expect(_chipSelected(t, coffee), isTrue);
    expect(_card('u-maya'), findsOneWidget);
    expect(_card('u-sam'), findsNothing);

    await _tap(t, find.byKey(const ValueKey('qa.today.activity.walk')));
    expect(_card('u-maya'), findsNothing);
    expect(_card('u-sam'), findsOneWidget);

    await _tap(t, find.byKey(const ValueKey('qa.today.activity.walk')));
    expect(_card('u-maya'), findsOneWidget);
    expect(_card('u-sam'), findsOneWidget);
    // Filtering is local: no extra read of today's set.
    expect(w.reads(_today), 1);
  });

  testWidgets(
    '"All introductions" clears an activity filter and shows every '
    'pick again '
    '[case:intentional_dating.today_introductions.all_introductions.action]',
    (t) async {
      final w = _TodayWorld();
      await _pump(t, w);
      final all = find.widgetWithText(ChoiceChip, _en.todayAllIntroductions);
      expect(_chipSelected(t, all), isTrue);
      await _tap(t, find.byKey(const ValueKey('qa.today.activity.coffee')));
      expect(_chipSelected(t, all), isFalse);
      expect(_card('u-sam'), findsNothing);

      await _tap(t, all);
      expect(_chipSelected(t, all), isTrue);
      expect(
        _chipSelected(
          t,
          find.byKey(const ValueKey('qa.today.activity.coffee')),
        ),
        isFalse,
      );
      expect(_card('u-maya'), findsOneWidget);
      expect(_card('u-sam'), findsOneWidget);
    },
  );

  testWidgets(
    'the "Refresh Today" button reloads the introductions and every '
    'Today section '
    // ignore: lines_longer_than_80_chars
    '[case:intentional_dating.today_introductions.refresh_today_onrefresh.action]',
    (t) async {
      final w = _TodayWorld();
      await _pump(t, w);
      expect(_card('u-lee'), findsNothing);
      final before = _refreshReads(w);

      w.picks = [...w.picks, _pick('u-lee', 'Lee', 'meal')];
      await _tap(t, find.byTooltip(_en.todayRefreshTooltip));

      _expectRefreshed(w, before);
      expect(_card('u-lee'), findsOneWidget);
      expect(find.byKey(const ValueKey('qa.today.activity.meal')), findsOne);
    },
  );

  testWidgets(
    'pulling Today down refreshes the introductions and every Today '
    'section '
    '[case:intentional_dating.today_introductions.today_screen_refresh.action]',
    (t) async {
      final w = _TodayWorld();
      // A phone-height view: the pull distance scales with the viewport.
      await _pump(t, w, size: const Size(430, 932));
      final before = _refreshReads(w);
      w.picks = [_pick('u-lee', 'Lee', 'meal')];

      await t.fling(
        find.byKey(const ValueKey('qa.today.date')),
        const Offset(0, 500),
        1500,
      );
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await qaSettle(t);

      _expectRefreshed(w, before);
      expect(find.byKey(const ValueKey('qa.today.activity.meal')), findsOne);
      expect(
        find.byKey(const ValueKey('qa.today.activity.coffee')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'while paused, "Take the time you need." hides the picks and '
    'its button opens the rhythm screen '
    // ignore: lines_longer_than_80_chars
    '[case:intentional_dating.today_introductions.take_the_time_you_need.action]',
    (t) async {
      final w = _TodayWorld(paused: true);
      await _pump(t, w);
      expect(find.text(_en.todayPausedTitle), findsOneWidget);
      expect(find.text(_en.todayPausedBody), findsOneWidget);
      expect(_card('u-maya'), findsNothing);

      await _tap(t, find.widgetWithText(OutlinedButton, _en.todayManageRhythm));
      expect(find.byType(DatingRhythmScreen), findsOneWidget);
      expect(find.text(_en.todayRhythmResume), findsOneWidget);
      await idTeardown(t);
    },
  );

  testWidgets(
    'when introductions fail to load, the notice\'s "Try again" '
    'retries and shows them '
    // ignore: lines_longer_than_80_chars
    '[case:intentional_dating.today_introductions.your_introductions_are_taking_a.action]',
    (t) async {
      final w = _TodayWorld();
      w.api.fail('GET $_today');
      await _pump(t, w);
      expect(find.text(_en.todayFailedTitle), findsOneWidget);
      expect(_card('u-maya'), findsNothing);
      final reads = w.reads(_today);

      w.heal();
      await _tap(t, find.widgetWithText(OutlinedButton, _en.todayTryAgain));
      expect(w.reads(_today), greaterThan(reads));
      expect(find.text(_en.todayFailedTitle), findsNothing);
      expect(_card('u-maya'), findsOneWidget);
      expect(_card('u-sam'), findsOneWidget);
    },
  );

  testWidgets('"Set your rhythm" opens the dating rhythm screen '
      '[case:intentional_dating.today_introductions.today_rhythm.action]', (
    t,
  ) async {
    final w = _TodayWorld();
    await _pump(t, w);
    final reads = w.reads('/account/me/dating-preferences');
    await _tap(t, find.byKey(const ValueKey('qa.today.rhythm')));
    expect(find.byType(DatingRhythmScreen), findsOneWidget);
    expect(find.text(_en.todayRhythmTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('qa.rhythm.save')), findsOneWidget);
    expect(
      w.reads('/account/me/dating-preferences'),
      greaterThanOrEqualTo(reads),
    );
    await idTeardown(t);
  });

  testWidgets('Today renders translated in every locale '
      '[case:intentional_dating.today_introductions.l10n]', (t) async {
    const fixture = {
      'Maya',
      'Sam',
      'Maya sketches strangers on trains.',
      'Sam sketches strangers on trains.',
      'A similar communication pace',
      'Designer',
    };
    await idSweepLocales(
      t,
      pump: (locale) => _pump(t, _TodayWorld(), locale: locale),
      labels: (l10n) => [
        l10n.todayLabel,
        l10n.todayHeroSubtitle,
        l10n.todaySectionPace,
        l10n.todayPaceTitle,
        l10n.todaySetRhythm,
        l10n.todaySectionStory,
        l10n.todaySectionIntroductions,
        l10n.todayIntroductionsTitle,
        l10n.todayAllIntroductions,
        l10n.todayActivityCoffee,
        l10n.todayCommonGround,
        l10n.todayFirstHelloCoffee,
        l10n.todayMeetName('Maya'),
        l10n.todayBreatheTitle,
        l10n.todayExploreMore,
      ],
      fixture: fixture,
    );
    // The paused and the failed notices.
    await idSweepLocales(
      t,
      pump: (locale) {
        final w = _TodayWorld(paused: true);
        return _pump(t, w, locale: locale);
      },
      labels: (l10n) => [
        l10n.todayPausedTitle,
        l10n.todayPausedBody,
        l10n.todayManageRhythm,
      ],
    );
    await idSweepLocales(
      t,
      pump: (locale) {
        final w = _TodayWorld()..api.fail('GET $_today');
        return _pump(t, w, locale: locale);
      },
      labels: (l10n) => [
        l10n.todayFailedTitle,
        l10n.todayFailedBody,
        l10n.todayTryAgain,
      ],
    );
  });
}
