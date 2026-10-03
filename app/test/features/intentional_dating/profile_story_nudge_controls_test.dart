// Control tests for Today's "Your story" card
// (lib/features/intentional_dating/profile_story_nudge.dart).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/intentional_dating/profile_stories.dart';
import 'package:verified_dating_app/features/intentional_dating/profile_story_nudge.dart';

import '../../support/qa_api.dart';
import 'intentional_dating_qa_support.dart';

const _stories = '/profile/me/stories';

Map<String, dynamic> _story(String prompt) => {
  'prompt_id': prompt,
  'text': 'A story about $prompt',
};

QaApi _api(List<Map<String, dynamic>> Function() stories) => QaApi()
  ..on(
    'GET $_stories',
    (_) => qaOk({
      'version': 1,
      'published': false,
      'stories': stories(),
      'photos': <dynamic>[],
    }),
  );

Future<void> _pump(WidgetTester t, QaApi api, {Locale? locale}) => pumpQa(
  t,
  api,
  const Scaffold(
    body: SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: ProfileStoryNudge(),
    ),
  ),
  locale: locale,
  size: const Size(430, 2400),
);

final _en = qaL10n(const Locale('en'));

void main() {
  testWidgets(
    'the stories button opens the stories editor, and coming back '
    'shows the new count '
    '[case:intentional_dating.profile_story_nudge.today_stories_open.action]',
    (t) async {
      var stories = <Map<String, dynamic>>[];
      final api = _api(() => stories)
        ..on('PUT $_stories', (call) {
          stories = [
            for (final s in call.body['stories'] as List)
              (s as Map).cast<String, dynamic>(),
          ];
          return qaOk({'version': 2, 'stories': stories, 'published': false});
        });
      await _pump(t, api);
      expect(find.text(_en.storiesNudgeActionFirst), findsOneWidget);
      expect(find.byType(ProfileStoriesScreen), findsNothing);

      await t.tap(find.byKey(const ValueKey('qa.today.stories')));
      await qaSettle(t);
      expect(find.byType(ProfileStoriesScreen), findsOneWidget);

      // Write one story in the editor, then go back to Today.
      await t.tap(find.byKey(const ValueKey('qa.stories.add')));
      await qaSettle(t, frames: 3);
      await t.enterText(
        find.byKey(const ValueKey('qa.stories.text.0')),
        'Market coffee every Saturday',
      );
      await t.ensureVisible(find.byKey(const ValueKey('qa.stories.save')));
      await t.tap(find.byKey(const ValueKey('qa.stories.save')));
      await qaSettle(t);
      expect(api.sent('PUT', _stories), hasLength(1));
      final reads = api.sent('GET', _stories).length;
      await t.pageBack();
      await qaSettle(t);

      expect(find.byType(ProfileStoriesScreen), findsNothing);
      // The card re-reads the stories when the editor closes.
      expect(api.sent('GET', _stories).length, greaterThan(reads));
      expect(find.text(_en.storiesNudgeSharedTitle(1, 3)), findsOneWidget);
      expect(find.text(_en.storiesNudgeActionAdd), findsOneWidget);
      await idTeardown(t);
    },
  );

  testWidgets(
    'a prompt idea chip opens the stories editor too '
    '[case:intentional_dating.profile_story_nudge.today_stories_open.action]',
    (t) async {
      final api = _api(() => []);
      await _pump(t, api);
      await t.tap(find.widgetWithText(ActionChip, _en.storiesPromptWeekend));
      await qaSettle(t);
      expect(find.byType(ProfileStoriesScreen), findsOneWidget);
      await idTeardown(t);
    },
  );

  testWidgets('the story card renders translated in every locale '
      '[case:intentional_dating.profile_story_nudge.l10n]', (t) async {
    // No stories yet: title, body, ideas and the first-story button.
    await idSweepLocales(
      t,
      pump: (locale) => _pump(t, _api(() => []), locale: locale),
      labels: (l10n) => [
        l10n.storiesNudgeTitle,
        l10n.storiesNudgeBodyEmpty,
        l10n.storiesNudgeIdeas,
        l10n.storiesPromptLittleJoy,
        l10n.storiesNudgeActionFirst,
      ],
    );
    // Some stories: progress and the latest prompt.
    await idSweepLocales(
      t,
      pump: (locale) => _pump(
        t,
        _api(() => [_story('little_joy'), _story('weekend')]),
        locale: locale,
      ),
      labels: (l10n) => [
        l10n.storiesNudgeSharedTitle(2, maxProfileStories),
        l10n.storiesNudgeBodyLatest(l10n.storiesPromptWeekend),
        l10n.storiesNudgeActionAdd,
      ],
    );
    // Complete.
    await idSweepLocales(
      t,
      pump: (locale) => _pump(
        t,
        _api(() => [_story('little_joy'), _story('weekend'), _story('care')]),
        locale: locale,
      ),
      labels: (l10n) => [
        l10n.storiesNudgeCompleteTitle,
        l10n.storiesNudgeCompleteBody,
        l10n.storiesNudgeActionEdit,
      ],
    );
    // Unknown (the read failed).
    await idSweepLocales(
      t,
      pump: (locale) =>
          _pump(t, QaApi()..fail('GET $_stories'), locale: locale),
      labels: (l10n) => [
        l10n.storiesNudgeTitle,
        l10n.storiesNudgeBodyUnknown,
        l10n.storiesNudgeActionOpen,
      ],
    );
  });
}
