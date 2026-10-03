// Control tests for the profile stories editor and the public stories
// section (lib/features/intentional_dating/profile_stories.dart), against
// the recording fake BFF.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/intentional_dating/profile_stories.dart';

import '../../support/qa_api.dart';
import 'intentional_dating_qa_support.dart';

const _stories = '/profile/me/stories';
const _photoA = '0b6c3c3e-8a43-4d3f-9a39-1f1a3c7e5a01';
const _photoB = '0b6c3c3e-8a43-4d3f-9a39-1f1a3c7e5a02';

/// A stateful fake: a save bumps the version and is what the next read
/// returns.
class _StoriesWorld {
  _StoriesWorld({List<Map<String, dynamic>>? stories})
    : stories = stories ?? [] {
    heal();
  }

  final api = QaApi();
  List<Map<String, dynamic>> stories;
  bool published = false;
  int version = 3;

  Map<String, dynamic> read() => {
    'version': version,
    'published': published,
    'stories': stories,
    'photos': [
      {'id': _photoA, 'url': 'https://photos.test/a.jpg'},
      {'id': _photoB, 'url': 'https://photos.test/b.jpg'},
    ],
  };

  void heal() {
    api
      ..on('GET $_stories', (_) => qaOk(read()))
      ..on('PUT $_stories', (call) {
        version++;
        published = call.body['published'] == true;
        stories = [
          for (final s in call.body['stories'] as List)
            (s as Map).cast<String, dynamic>(),
        ];
        return qaOk(read());
      });
  }

  List<QaCall> get saves => api.sent('PUT', _stories);
  Map<String, dynamic> get lastSave => saves.last.body;
  List<Map<String, dynamic>> get savedStories => [
    for (final s in lastSave['stories'] as List)
      (s as Map).cast<String, dynamic>(),
  ];
}

Map<String, dynamic> _story(String prompt, String text, {String? photo}) => {
  'prompt_id': prompt,
  'text': text,
  'photo_id': ?photo,
  if (photo != null) 'photo_url': 'https://photos.test/a.jpg',
  if (photo != null) 'photo_description': 'A novel on a picnic blanket',
};

final _en = qaL10n(const Locale('en'));

Future<void> _pump(WidgetTester t, _StoriesWorld w, {Locale? locale}) => pumpQa(
  t,
  w.api,
  const ProfileStoriesScreen(),
  locale: locale,
  size: const Size(430, 3200),
);

Future<void> _tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
  await qaSettle(t, frames: 4);
}

Finder _text(int key) => find.byKey(ValueKey('qa.stories.text.$key'));
Finder get _save => find.byKey(const ValueKey('qa.stories.save'));
Finder get _description =>
    find.widgetWithText(TextFormField, _en.storiesPhotoDescriptionLabel);

String _descriptionText(WidgetTester t) => t
    .widget<EditableText>(
      find.descendant(of: _description, matching: find.byType(EditableText)),
    )
    .controller
    .text;

/// Picks [option] from the [index]th dropdown labelled [label].
Future<void> _choose(
  WidgetTester t,
  String label,
  String option, {
  int index = 0,
}) async {
  await _tap(
    t,
    find
        .ancestor(
          of: find.text(label),
          matching: find.byType(DropdownButtonFormField<String>),
        )
        .at(index),
  );
  await t.tap(find.text(option).last);
  await qaSettle(t, frames: 4);
}

void main() {
  testWidgets('"Add a story" adds an editor with the next unused prompt, up to '
      'three, and the story is saved '
      '[case:intentional_dating.profile_stories.stories_add.action]', (
    t,
  ) async {
    final w = _StoriesWorld(stories: [_story('little_joy', 'Market coffee')]);
    await _pump(t, w);
    expect(find.text(_en.storiesMomentLabel(2)), findsNothing);

    await _tap(t, find.byKey(const ValueKey('qa.stories.add')));
    expect(find.text(_en.storiesMomentLabel(2)), findsOneWidget);
    // The new story starts on the first prompt nobody uses yet.
    expect(find.text(_en.storiesPromptWeekend), findsOneWidget);
    await t.enterText(_text(1), 'A slow Saturday by the river');
    await _tap(t, find.byKey(const ValueKey('qa.stories.add')));
    expect(find.text(_en.storiesMomentLabel(3)), findsOneWidget);
    expect(find.byKey(const ValueKey('qa.stories.add')), findsNothing);
    await t.enterText(_text(2), 'Hello over a crossword');

    await _tap(t, _save);
    expect(w.savedStories.map((s) => s['prompt_id']), [
      'little_joy',
      'weekend',
      'first_hello',
    ]);
    expect(w.savedStories[1]['text'], 'A slow Saturday by the river');
    expect(w.lastSave['expected_version'], 3);
  });

  testWidgets('"Remove story" removes that story and the save no longer '
      'carries it '
      '[case:intentional_dating.profile_stories.remove_story_number.action]', (
    t,
  ) async {
    final w = _StoriesWorld(
      stories: [
        _story('little_joy', 'Market coffee'),
        _story('weekend', 'A slow Saturday'),
      ],
    );
    await _pump(t, w);
    await _tap(t, find.byTooltip(_en.storiesRemoveTooltip(1)));
    expect(find.text('Market coffee'), findsNothing);
    expect(find.text('A slow Saturday'), findsOneWidget);
    expect(find.byTooltip(_en.storiesRemoveTooltip(2)), findsNothing);

    await _tap(t, _save);
    expect(w.savedStories, hasLength(1));
    expect(w.savedStories.single['prompt_id'], 'weekend');
  });

  testWidgets('choosing "A starting point" changes the story prompt that is '
      'saved, without offering prompts already used '
      '[case:intentional_dating.profile_stories.a_starting_point.action]', (
    t,
  ) async {
    final w = _StoriesWorld(
      stories: [
        _story('little_joy', 'Market coffee'),
        _story('weekend', 'A slow Saturday'),
      ],
    );
    await _pump(t, w);
    final first = find
        .ancestor(
          of: find.text(_en.storiesPromptLabel),
          matching: find.byType(DropdownButtonFormField<String>),
        )
        .first;
    final offered = t
        .widget<DropdownButton<String>>(
          find.descendant(
            of: first,
            matching: find.byType(DropdownButton<String>),
          ),
        )
        .items!
        .map((i) => i.value)
        .toList();
    // "weekend" belongs to the second story, so the first cannot take it.
    expect(offered, ['little_joy', 'first_hello', 'learning', 'care']);
    await _tap(t, first);
    await t.tap(find.text(_en.storiesPromptCare).last);
    await qaSettle(t, frames: 4);

    await _tap(t, _save);
    expect(w.savedStories.map((s) => s['prompt_id']), ['care', 'weekend']);
  });

  testWidgets('"A photo, if you like" attaches a profile photo, asks for a '
      'description and "Words only" removes it '
      '[case:intentional_dating.profile_stories.a_photo_if_you_like.action]', (
    t,
  ) async {
    final w = _StoriesWorld(stories: [_story('little_joy', 'Market coffee')]);
    await _pump(t, w);
    expect(_description, findsNothing);

    await _choose(t, _en.storiesPhotoLabel, _en.storiesProfilePhoto(2));
    expect(_description, findsOneWidget);
    await t.enterText(_description, 'Coffee cups on a market stall');
    await _tap(t, _save);
    expect(w.savedStories.single['photo_id'], _photoB);
    expect(
      w.savedStories.single['photo_description'],
      'Coffee cups on a market stall',
    );

    await _choose(t, _en.storiesPhotoLabel, _en.storiesWordsOnly);
    expect(_description, findsNothing);
    await _tap(t, _save);
    expect(w.savedStories.single.containsKey('photo_id'), isFalse);
    expect(w.savedStories.single.containsKey('photo_description'), isFalse);
  });

  testWidgets('typing into "Describe this photo" is what is saved '
      '[case:intentional_dating.profile_stories.describe_this_photo.action]', (
    t,
  ) async {
    final w = _StoriesWorld(
      stories: [_story('little_joy', 'Reading outside', photo: _photoA)],
    );
    await _pump(t, w);
    expect(_descriptionText(t), 'A novel on a picnic blanket');
    await t.enterText(_description, 'A paperback on a striped blanket');
    await _tap(t, _save);
    expect(w.savedStories.single['photo_id'], _photoA);
    expect(
      w.savedStories.single['photo_description'],
      'A paperback on a striped blanket',
    );
  });

  testWidgets(
    '"Describe this photo" blocks empty and blank text, caps the '
    'length the server allows and keeps emoji and RTL text exactly '
    '[case:intentional_dating.profile_stories.describe_this_photo.validation]',
    (t) async {
      final w = _StoriesWorld(
        stories: [_story('little_joy', 'Reading outside', photo: _photoA)],
      );
      await _pump(t, w);

      // Empty: no request, the field says why.
      await t.enterText(_description, '');
      await _tap(t, _save);
      expect(w.saves, isEmpty);
      expect(find.text(_en.storiesPhotoDescriptionRequired), findsOneWidget);
      expect(find.text(_en.storiesIncomplete), findsOneWidget);

      // Whitespace only: blocked the same way.
      await t.enterText(_description, '    ');
      await _tap(t, _save);
      expect(w.saves, isEmpty);

      // Over the limit: cut at 160 characters.
      await t.enterText(_description, 'a' * 175);
      await t.pump();
      expect(_descriptionText(t).length, storyPhotoDescriptionMax);
      // Emoji made of several code points count by code point, as the server
      // counts them: 40 family emoji (5 code points each) would be 200.
      await t.enterText(_description, '👩‍👩‍👧' * 40);
      await t.pump();
      expect(
        _descriptionText(t).runes.length,
        lessThanOrEqualTo(storyPhotoDescriptionMax),
      );
      await _tap(t, _save);
      expect(
        (w.savedStories.single['photo_description'] as String).runes.length,
        lessThanOrEqualTo(storyPhotoDescriptionMax),
      );

      // Emoji, RTL and accents are sent exactly; surrounding spaces are not.
      const mixed = 'مرحبا 🌿 café — שלום';
      await t.enterText(_description, '  $mixed  ');
      await _tap(t, _save);
      expect(w.savedStories.single['photo_description'], mixed);
      expect(w.saves, hasLength(2));
    },
  );

  testWidgets('"Preview my stories" shows the story cards without saving, '
      'and "Back to editing" returns '
      '[case:intentional_dating.profile_stories.preview_my_stories.action]', (
    t,
  ) async {
    final w = _StoriesWorld(stories: [_story('little_joy', 'Market coffee')]);
    await _pump(t, w);
    await t.enterText(_text(0), 'Market coffee and a crossword');
    await _tap(t, find.text(_en.storiesPreview));

    expect(find.text(_en.storiesPreviewBanner), findsOneWidget);
    expect(find.byType(StoryMomentCard), findsOneWidget);
    expect(find.text('Market coffee and a crossword'), findsOneWidget);
    expect(_text(0), findsNothing);
    expect(w.saves, isEmpty);

    await _tap(t, find.text(_en.storiesBackToEditing));
    expect(find.byType(StoryMomentCard), findsNothing);
    expect(_text(0), findsOneWidget);
    expect(find.text('Market coffee and a crossword'), findsOneWidget);
  });

  testWidgets('"Show these stories on my profile" switches the save to '
      'publishing, and back to private '
      '[case:intentional_dating.profile_stories.stories_publish.action]', (
    t,
  ) async {
    final w = _StoriesWorld(stories: [_story('little_joy', 'Market coffee')]);
    await _pump(t, w);
    final publish = find.byKey(const ValueKey('qa.stories.publish'));
    expect(t.widget<SwitchListTile>(publish).value, isFalse);
    expect(find.text(_en.storiesSavePrivatelyButton), findsOneWidget);

    await _tap(t, publish);
    expect(t.widget<SwitchListTile>(publish).value, isTrue);
    expect(find.text(_en.storiesPublishButton), findsOneWidget);
    await _tap(t, _save);
    expect(w.lastSave['published'], isTrue);
    expect(qaSnackText(t), _en.storiesPublished);

    // The editor reloads with the published state.
    await qaSettle(t);
    final again = find.byKey(const ValueKey('qa.stories.publish'));
    expect(t.widget<SwitchListTile>(again).value, isTrue);
    await _tap(t, again);
    await _tap(t, _save);
    expect(w.lastSave['published'], isFalse);
  });

  testWidgets('"Save privately" sends the stories with the version, confirms '
      'and reloads them '
      '[case:intentional_dating.profile_stories.stories_save.action]', (
    t,
  ) async {
    final w = _StoriesWorld(stories: [_story('little_joy', 'Market coffee')]);
    await _pump(t, w);
    await t.enterText(_text(0), 'Market coffee, always');
    await _tap(t, _save);

    final body = w.saves.single.body;
    expect(body['expected_version'], 3);
    expect(body['published'], isFalse);
    final story = (body['stories'] as List).single as Map;
    expect(story['prompt_id'], 'little_joy');
    expect(story['text'], 'Market coffee, always');
    expect(story['content'], isA<Map<dynamic, dynamic>>());
    expect(qaSnackText(t), _en.storiesSavedPrivately);
    expect(w.api.sent('GET', _stories), hasLength(2));
    // The next save carries the new version.
    await qaSettle(t);
    await _tap(t, _save);
    expect(w.lastSave['expected_version'], 4);
  });

  testWidgets('a failed save shows the error, keeps the words and a retry '
      'saves them '
      '[case:intentional_dating.profile_stories.stories_save.api_failure]', (
    t,
  ) async {
    final w = _StoriesWorld(stories: [_story('little_joy', 'Market coffee')]);
    w.api.fail('PUT $_stories', message: 'Stories are resting.');
    await _pump(t, w);
    await t.enterText(_text(0), 'Keep my unsaved words');
    await _tap(t, _save);

    expect(find.text('Stories are resting.'), findsOneWidget);
    expect(find.text('Keep my unsaved words'), findsOneWidget);
    expect(find.text(_en.storiesReloadDiscard), findsOneWidget);
    expect(qaSnackText(t), isNull);

    w.heal();
    await _tap(t, _save);
    expect(w.saves, hasLength(2));
    expect(w.savedStories.single['text'], 'Keep my unsaved words');
    expect(qaSnackText(t), _en.storiesSavedPrivately);
  });

  testWidgets(
    '"Reload saved stories · discard edits" re-reads the stories '
    'and drops the edits '
    // ignore: lines_longer_than_80_chars
    '[case:intentional_dating.profile_stories.reload_saved_stories_discard_edi.action]',
    (t) async {
      final w = _StoriesWorld(stories: [_story('little_joy', 'Market coffee')]);
      w.api.fail('PUT $_stories', status: 409, message: 'Stories changed.');
      await _pump(t, w);
      await t.enterText(_text(0), 'An edit that loses');
      await _tap(t, _save);
      expect(find.text('Stories changed.'), findsOneWidget);
      final reads = w.api.sent('GET', _stories).length;

      // Another device saved meanwhile.
      w
        ..stories = [_story('weekend', 'Saved on the web')]
        ..version = 9;
      await _tap(t, find.text(_en.storiesReloadDiscard));

      expect(w.api.sent('GET', _stories).length, reads + 1);
      expect(find.text('An edit that loses'), findsNothing);
      expect(find.text('Saved on the web'), findsOneWidget);
      expect(find.text('Stories changed.'), findsNothing);
      w.heal();
      await _tap(t, _save);
      expect(w.lastSave['expected_version'], 9);
    },
  );

  testWidgets('"Try again" after a failed load reads the stories again '
      '[case:intentional_dating.profile_stories.try_again.action]', (t) async {
    final w = _StoriesWorld(stories: [_story('little_joy', 'Market coffee')]);
    w.api.fail('GET $_stories');
    await _pump(t, w);
    expect(find.text(_en.storiesLoadFailed), findsOneWidget);
    expect(_save, findsNothing);

    w.heal();
    await _tap(t, find.text(_en.storiesTryAgain));
    expect(w.api.sent('GET', _stories), hasLength(2));
    expect(find.text(_en.storiesLoadFailed), findsNothing);
    expect(find.text('Market coffee'), findsOneWidget);
  });

  testWidgets(
    '"Try loading stories again" on a profile re-reads them and '
    'shows the cards '
    // ignore: lines_longer_than_80_chars
    '[case:intentional_dating.profile_stories.try_loading_stories_again.action]',
    (t) async {
      final api = QaApi()..fail('GET /profile/them/stories');
      await pumpQa(
        t,
        api,
        const Scaffold(
          body: SingleChildScrollView(
            child: ProfileStoriesSection(userId: 'them'),
          ),
        ),
      );
      expect(find.text(_en.storiesRetryLoad), findsOneWidget);
      expect(find.byType(StoryMomentCard), findsNothing);

      api.json('GET /profile/them/stories', {
        'published': true,
        'stories': [_story('care', 'I bring soup when you are ill')],
      });
      await _tap(t, find.text(_en.storiesRetryLoad));
      expect(api.sent('GET', '/profile/them/stories'), hasLength(2));
      expect(find.text(_en.storiesRetryLoad), findsNothing);
      expect(find.byType(StoryMomentCard), findsOneWidget);
      expect(find.text('I bring soup when you are ill'), findsOneWidget);
      expect(find.text(_en.storiesSectionTitle), findsOneWidget);
    },
  );

  testWidgets('the stories editor renders translated in every locale '
      '[case:intentional_dating.profile_stories.l10n]', (t) async {
    const fixture = {'Market coffee', 'Reading outside'};
    await idSweepLocales(
      t,
      pump: (locale) => _pump(
        t,
        _StoriesWorld(
          stories: [
            _story('little_joy', 'Market coffee'),
            {
              ..._story('weekend', 'Reading outside', photo: _photoA),
              'photo_description': '',
            },
          ],
        ),
        locale: locale,
      ),
      labels: (l10n) => [
        l10n.storiesScreenTitle,
        l10n.storiesHeadline,
        l10n.storiesIntro,
        l10n.storiesPublishSwitch,
        l10n.storiesPreview,
        l10n.storiesMomentLabel(1),
        l10n.storiesPromptLabel,
        l10n.storiesPromptLittleJoy,
        l10n.storiesPhotoLabel,
        l10n.storiesProfilePhoto(1),
        l10n.storiesPhotoDescriptionLabel,
        l10n.storiesAdd,
        l10n.storiesSavePrivatelyButton,
        l10n.storiesPolicyNote,
      ],
      fixture: fixture,
      // storiesMomentLabel and richStyleModern are the same words in German.
      sameInGerman: {'MOMENT 1', 'MOMENT 2', 'Modern'},
    );
    // The preview cards and the public section.
    await idSweepLocales(
      t,
      pump: (locale) async {
        await _pump(
          t,
          _StoriesWorld(stories: [_story('little_joy', 'Market coffee')]),
          locale: locale,
        );
        await _tap(t, find.text(qaL10n(locale).storiesPreview));
      },
      labels: (l10n) => [
        l10n.storiesPreviewBanner,
        l10n.storiesBackToEditing,
        l10n.storiesPromptLittleJoy,
      ],
      fixture: fixture,
    );
    await idSweepLocales(
      t,
      pump: (locale) => pumpQa(
        t,
        QaApi()..fail('GET $_stories'),
        const ProfileStoriesScreen(),
        locale: locale,
      ),
      labels: (l10n) => [l10n.storiesLoadFailed, l10n.storiesTryAgain],
    );
  });
}
