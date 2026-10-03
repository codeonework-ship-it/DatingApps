// Control tests for "Your dating rhythm"
// (lib/features/intentional_dating/dating_rhythm.dart): every chip, switch
// and button, the save and pause requests, failures and the l10n render.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/intentional_dating/dating_rhythm.dart';

import '../../support/qa_api.dart';
import 'intentional_dating_qa_support.dart';

const _prefs = '/account/me/dating-preferences';

/// A stateful fake: saved preferences come back on the next read, and the
/// pause endpoints flip the paused flag.
class _RhythmWorld {
  _RhythmWorld({Map<String, dynamic>? saved})
    : saved =
          saved ??
          {
            'version': 1,
            'intent': '',
            'pace': '',
            'pace_status': '',
            'share_pace': false,
            'activities': <String>[],
            'availability': <dynamic>[],
            'share_availability': false,
            'allow_friend_intros': false,
          } {
    heal();
  }

  final api = QaApi();
  Map<String, dynamic> saved;
  bool paused = false;

  void heal() {
    api
      ..on('GET $_prefs', (_) => qaOk({'preferences': saved}))
      ..on('PUT $_prefs', (call) {
        saved = {...call.body, 'version': (saved['version'] as int) + 1};
        return qaOk({'preferences': saved});
      })
      ..on('GET /account/me/discovery/pause', (_) => qaOk({'paused': paused}))
      ..on('POST /account/me/discovery/pause', (_) {
        paused = true;
        return qaOk({
          'paused': true,
          'pause': {'reason': 'manual', 'paused_at': '2026-10-03T09:00:00Z'},
        });
      })
      ..on('POST /account/me/discovery/resume', (_) {
        paused = false;
        return qaOk({'paused': false});
      });
  }

  Map<String, dynamic> get lastSave => api.sent('PUT', _prefs).last.body;
}

Future<void> _pump(WidgetTester t, _RhythmWorld w, {Locale? locale}) => pumpQa(
  t,
  w.api,
  const DatingRhythmScreen(),
  locale: locale,
  size: const Size(430, 4200),
);

final _en = qaL10n(const Locale('en'));

Finder _chip<T extends Widget>(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(T));

bool _selected(WidgetTester t, Finder chip) {
  final w = t.widget(chip);
  return w is ChoiceChip ? w.selected : (w as FilterChip).selected;
}

Finder _switch(String title) => find.ancestor(
  of: find.text(title),
  matching: find.byWidgetPredicate((w) => w is SwitchListTile),
);

bool _on(WidgetTester t, String title) =>
    t.widget<SwitchListTile>(_switch(title)).value;

Future<void> _tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
  await qaSettle(t, frames: 4);
}

Future<void> _save(WidgetTester t) =>
    _tap(t, find.byKey(const ValueKey('qa.rhythm.save')));

void main() {
  testWidgets('choosing what you are open to and your pace selects one chip '
      'each and saves them '
      '[case:intentional_dating.dating_rhythm.choicechip_onselected.action]', (
    t,
  ) async {
    final w = _RhythmWorld();
    await _pump(t, w);
    final none = _chip<ChoiceChip>(_en.todayRhythmIntentNone);
    final relationship = _chip<ChoiceChip>(_en.todayRhythmIntentRelationship);
    expect(_selected(t, none), isTrue);

    await _tap(t, relationship);
    expect(_selected(t, relationship), isTrue);
    expect(_selected(t, none), isFalse);
    await _tap(t, _chip<ChoiceChip>(_en.todayRhythmPaceSteady));
    expect(_selected(t, _chip<ChoiceChip>(_en.todayRhythmPaceSteady)), isTrue);

    await _save(t);
    expect(w.lastSave['intent'], 'relationship');
    expect(w.lastSave['pace'], 'steady');
    expect(w.lastSave['version'], 1);
  });

  testWidgets('first-date chips toggle, stop at five and save the chosen ids '
      '[case:intentional_dating.dating_rhythm.filterchip_onselected.action]', (
    t,
  ) async {
    final w = _RhythmWorld();
    await _pump(t, w);
    final labels = [
      _en.todayActivityCoffee,
      _en.todayActivityWalk,
      _en.todayActivityMeal,
      _en.todayActivityPlayful,
      _en.todayActivityEvent,
      _en.todayActivityVideoCall,
    ];
    for (final label in labels) {
      await _tap(t, _chip<FilterChip>(label));
    }
    // The sixth pick is refused.
    expect(_selected(t, _chip<FilterChip>(_en.todayActivityVideoCall)), false);
    // Unselecting one frees a slot.
    await _tap(t, _chip<FilterChip>(_en.todayActivityMeal));
    expect(_selected(t, _chip<FilterChip>(_en.todayActivityMeal)), isFalse);

    await _save(t);
    expect((w.lastSave['activities'] as List).toSet(), {
      'coffee',
      'walk',
      'activity',
      'event',
    });
  });

  testWidgets(
    'availability windows toggle on and off and save start and end '
    'three hours apart '
    '[case:intentional_dating.dating_rhythm.filterchip_onselected_2.action]',
    (t) async {
      final w = _RhythmWorld();
      await _pump(t, w);
      expect(find.text(_en.todayRhythmEvening), findsNothing);
      await _tap(t, _switch(_en.todayRhythmShareAvailability));
      expect(find.text(_en.todayRhythmEvening), findsWidgets);

      // Tomorrow's morning window always exists (today's may have passed).
      final mornings = find.ancestor(
        of: find.text(_en.todayRhythmMorning),
        matching: find.byType(FilterChip),
      );
      final tomorrow = mornings.at(mornings.evaluate().length - 6);
      await _tap(t, tomorrow);
      expect(_selected(t, tomorrow), isTrue);
      final evening = find
          .ancestor(
            of: find.text(_en.todayRhythmEvening),
            matching: find.byType(FilterChip),
          )
          .last;
      await _tap(t, evening);
      await _tap(t, evening);
      expect(_selected(t, evening), isFalse);

      await _save(t);
      expect(w.lastSave['share_availability'], isTrue);
      final windows = w.lastSave['availability'] as List;
      expect(windows, hasLength(1));
      final window = (windows.single as Map).cast<String, dynamic>();
      final start = DateTime.parse(window['start'] as String);
      final end = DateTime.parse(window['end'] as String);
      expect(end.difference(start), const Duration(hours: 3));
      expect(start.toLocal().hour, 9);
      final now = DateTime.now();
      expect(
        DateTime(
          start.toLocal().year,
          start.toLocal().month,
          start.toLocal().day,
        ),
        DateTime(now.year, now.month, now.day + 1),
      );
    },
  );

  testWidgets('"Slow replies this week" turns the temporary status on and '
      'off in what is saved '
      '[case:intentional_dating.dating_rhythm.slow_replies_this_week.action]', (
    t,
  ) async {
    final w = _RhythmWorld();
    await _pump(t, w);
    expect(_on(t, _en.todayRhythmSlowWeek), isFalse);
    await _tap(t, _switch(_en.todayRhythmSlowWeek));
    expect(_on(t, _en.todayRhythmSlowWeek), isTrue);
    await _save(t);
    expect(w.lastSave['pace_status'], 'slow_week');

    await _tap(t, _switch(_en.todayRhythmSlowWeek));
    await _save(t);
    expect(w.lastSave['pace_status'], '');
  });

  testWidgets(
    'the privacy switches flip their flag, friend intros reveal '
    'their own options, and all are saved '
    // ignore: lines_longer_than_80_chars
    '[case:intentional_dating.dating_rhythm.switchlisttile_adaptive_onchange.action]',
    (t) async {
      final w = _RhythmWorld();
      await _pump(t, w);
      expect(find.text(_en.todayRhythmIntroPhoto), findsNothing);
      await _tap(t, _switch(_en.todayRhythmSharePace));
      await _tap(t, _switch(_en.todayRhythmFriendIntros));
      expect(_on(t, _en.todayRhythmFriendIntros), isTrue);
      expect(find.text(_en.todayRhythmIntroPhoto), findsOneWidget);
      await _tap(t, _switch(_en.todayRhythmIntroCity));
      expect(_on(t, _en.todayRhythmIntroCity), isTrue);

      await _save(t);
      expect(w.lastSave['share_pace'], isTrue);
      expect(w.lastSave['allow_friend_intros'], isTrue);
      expect(w.lastSave['intro_share_city'], isTrue);
      expect(w.lastSave.containsKey('intro_share_photo'), isFalse);
    },
  );

  testWidgets('"Save my rhythm" sends the choices with the version and '
      'confirms '
      '[case:intentional_dating.dating_rhythm.rhythm_save.action]', (t) async {
    final w = _RhythmWorld();
    await _pump(t, w);
    await _tap(t, _chip<ChoiceChip>(_en.todayRhythmIntentExploring));
    await _save(t);

    final save = w.api.sent('PUT', _prefs).single.body;
    expect(save['intent'], 'exploring');
    expect(save['version'], 1);
    expect(save['availability'], isEmpty);
    expect(qaSnackText(t), _en.todayRhythmSaved);
    expect(w.saved['intent'], 'exploring');
    // A second save carries the version the server returned.
    await _save(t);
    expect(w.lastSave['version'], 2);
  });

  testWidgets('a failed save shows the error, keeps the choices and a retry '
      'succeeds '
      '[case:intentional_dating.dating_rhythm.rhythm_save.api_failure]', (
    t,
  ) async {
    final w = _RhythmWorld();
    w.api.fail('PUT $_prefs', message: 'Saving is resting for a moment.');
    await _pump(t, w);
    await _tap(t, _chip<ChoiceChip>(_en.todayRhythmIntentCasual));
    await _tap(t, _switch(_en.todayRhythmSlowWeek));
    await _save(t);

    expect(find.text('Saving is resting for a moment.'), findsOneWidget);
    expect(find.text(_en.todayRhythmReload), findsOneWidget);
    expect(_selected(t, _chip<ChoiceChip>(_en.todayRhythmIntentCasual)), true);
    expect(_on(t, _en.todayRhythmSlowWeek), isTrue);
    expect(qaSnackText(t), isNull);

    w.heal();
    await _save(t);
    expect(w.api.sent('PUT', _prefs), hasLength(2));
    expect(w.lastSave['intent'], 'casual');
    expect(w.lastSave['pace_status'], 'slow_week');
    expect(find.text('Saving is resting for a moment.'), findsNothing);
    expect(qaSnackText(t), _en.todayRhythmSaved);
  });

  testWidgets('"Reload saved choices" after a failed save discards the edits '
      'and shows what the server has '
      '[case:intentional_dating.dating_rhythm.reload_saved_choices.action]', (
    t,
  ) async {
    final w = _RhythmWorld(
      saved: {
        'version': 4,
        'intent': 'relationship',
        'activities': ['coffee'],
      },
    );
    w.api.fail('PUT $_prefs', status: 409, message: 'Your rhythm changed.');
    await _pump(t, w);
    await _tap(t, _chip<ChoiceChip>(_en.todayRhythmIntentCasual));
    await _save(t);
    expect(find.text('Your rhythm changed.'), findsOneWidget);
    final reads = w.api.sent('GET', _prefs).length;

    w.saved = {...w.saved, 'version': 5, 'intent': 'exploring'};
    await _tap(t, find.text(_en.todayRhythmReload));

    expect(w.api.sent('GET', _prefs).length, reads + 1);
    expect(find.text('Your rhythm changed.'), findsNothing);
    expect(
      _selected(t, _chip<ChoiceChip>(_en.todayRhythmIntentExploring)),
      isTrue,
    );
    expect(_selected(t, _chip<ChoiceChip>(_en.todayRhythmIntentCasual)), false);
    expect(_selected(t, _chip<FilterChip>(_en.todayActivityCoffee)), isTrue);
  });

  testWidgets('"Pause introductions" pauses discovery, then resumes it '
      '[case:intentional_dating.dating_rhythm.pause_introductions.action]', (
    t,
  ) async {
    final w = _RhythmWorld();
    await _pump(t, w);
    await _tap(t, find.text(_en.todayRhythmPause));

    final pause = w.api.sent('POST', '/account/me/discovery/pause');
    expect(pause.single.body, {'reason': 'manual'});
    expect(w.paused, isTrue);
    expect(find.text(_en.todayRhythmResume), findsOneWidget);
    expect(find.text(_en.todayRhythmPause), findsNothing);

    await _tap(t, find.text(_en.todayRhythmResume));
    expect(w.api.sent('POST', '/account/me/discovery/resume'), hasLength(1));
    expect(w.paused, isFalse);
    expect(find.text(_en.todayRhythmPause), findsOneWidget);
  });

  testWidgets(
    'a failed pause shows the error, stays unpaused, keeps the '
    'draft and a retry pauses '
    '[case:intentional_dating.dating_rhythm.pause_introductions.api_failure]',
    (t) async {
      final w = _RhythmWorld();
      w.api.fail('POST /account/me/discovery/pause', message: 'Pause failed.');
      await _pump(t, w);
      await _tap(t, _chip<ChoiceChip>(_en.todayRhythmIntentRelationship));
      await _tap(t, find.text(_en.todayRhythmPause));

      expect(qaSnackText(t), 'Pause failed.');
      expect(find.text(_en.todayRhythmPause), findsOneWidget);
      expect(find.text(_en.todayRhythmResume), findsNothing);
      expect(
        _selected(t, _chip<ChoiceChip>(_en.todayRhythmIntentRelationship)),
        isTrue,
      );
      ScaffoldMessenger.of(t.element(find.byType(ListView))).clearSnackBars();
      await qaSettle(t, frames: 3);

      w.heal();
      await _tap(t, find.text(_en.todayRhythmPause));
      expect(w.api.sent('POST', '/account/me/discovery/pause'), hasLength(2));
      expect(find.text(_en.todayRhythmResume), findsOneWidget);
    },
  );

  testWidgets('"Try again" after a failed load reads the preferences again '
      'and opens the editor '
      '[case:intentional_dating.dating_rhythm.try_again.action]', (t) async {
    final w = _RhythmWorld(saved: {'version': 2, 'intent': 'casual'});
    w.api.fail('GET $_prefs');
    await _pump(t, w);
    expect(find.text(_en.todayRhythmLoadFailed), findsOneWidget);
    expect(find.byKey(const ValueKey('qa.rhythm.save')), findsNothing);

    w.heal();
    await _tap(t, find.text(_en.todayTryAgain));
    expect(w.api.sent('GET', _prefs), hasLength(2));
    expect(find.text(_en.todayRhythmLoadFailed), findsNothing);
    expect(find.byKey(const ValueKey('qa.rhythm.save')), findsOneWidget);
    expect(_selected(t, _chip<ChoiceChip>(_en.todayRhythmIntentCasual)), true);
  });

  testWidgets('the rhythm screen renders translated in every locale '
      '[case:intentional_dating.dating_rhythm.l10n]', (t) async {
    await idSweepLocales(
      t,
      pump: (locale) => _pump(
        t,
        _RhythmWorld(
          saved: {
            'version': 1,
            'share_availability': true,
            'allow_friend_intros': true,
          },
        ),
        locale: locale,
      ),
      labels: (l10n) => [
        l10n.todayRhythmTitle,
        l10n.todayRhythmHeadline,
        l10n.todayRhythmOpenTo,
        l10n.todayRhythmIntentRelationship,
        l10n.todayRhythmPaceSection,
        l10n.todayRhythmSlowWeek,
        l10n.todayRhythmSharePace,
        l10n.todayRhythmFirstDate,
        l10n.todayActivityCoffee,
        l10n.todayRhythmChooseFive,
        l10n.todayRhythmShareAvailability,
        l10n.todayRhythmEvening,
        l10n.todayRhythmFriendIntros,
        l10n.todayRhythmIntroPhoto,
        l10n.todayRhythmIntroCity,
        l10n.todayRhythmSave,
        l10n.todayRhythmBreakTitle,
        l10n.todayRhythmPause,
      ],
      // German uses the loanword: todayActivityDrinks is "Drinks" in de.
      sameInGerman: {'Drinks'},
    );
    // The failed-load state.
    await idSweepLocales(
      t,
      pump: (locale) {
        final w = _RhythmWorld()..api.fail('GET $_prefs');
        return _pump(t, w, locale: locale);
      },
      labels: (l10n) => [
        l10n.todayRhythmTitle,
        l10n.todayRhythmLoadFailed,
        l10n.todayTryAgain,
      ],
    );
  });
}
