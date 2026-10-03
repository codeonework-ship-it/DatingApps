// Control-level tests for comfort cards (comfort_cards_screen.dart): the
// member's own words about pace, dates, languages and family, an optional
// member-provided translation, sharing with matches, and the reload, remove
// and save controls. Every test performs the real gesture against the
// recording fake BFF and asserts the request sent or what the member sees.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/first_chapter/comfort_cards_screen.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';

final en = qaL10n(const Locale('en'));

Finder key(String k) => find.byKey(ValueKey(k));
final language = key('qa.comfort.language');
final original = key('qa.comfort.original');
final translation = key('qa.comfort.translation');
final translationLanguage = key('qa.comfort.translation_language');
final error = key('qa.comfort.error');

Map<String, dynamic> card(
  String topic,
  String text, {
  String language = 'English',
  String translation = '',
  String translationLanguage = '',
}) => {
  'topic': topic,
  'original': text,
  'language': language,
  'translation': translation,
  'translation_language': translationLanguage,
};

/// `/chapters/comfort` on the fake server; a PUT replaces the saved cards.
class ComfortWorld {
  ComfortWorld({List<Map<String, dynamic>>? cards, this.shared = false})
    : cards = cards ?? [] {
    api
      ..on(
        'GET /chapters/comfort',
        (_) => qaOk({'cards': this.cards, 'shared': shared, 'version': 4}),
      )
      ..on('PUT /chapters/comfort', (c) {
        this.cards = (c.body['cards'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        shared = c.body['shared'] as bool;
        return qaOk({'version': 5});
      });
  }

  final api = QaApi();
  List<Map<String, dynamic>> cards;
  bool shared;

  Map<String, dynamic> get saved =>
      api.sent('PUT', '/chapters/comfort').single.body;
}

Future<List<Object?>> pumpComfort(WidgetTester t, ComfortWorld w) => pumpQa(
  t,
  w.api,
  const ComfortCardsScreen(),
  size: const Size(430, 2400),
  launcher: true,
);

Future<void> tapIn(WidgetTester t, Finder finder) async {
  await t.ensureVisible(finder);
  await t.pump();
  await t.tap(finder);
  await qaSettle(t);
}

Future<void> addCard(WidgetTester t) => tapIn(t, key('qa.comfort.add'));
Future<void> save(WidgetTester t) => tapIn(t, key('qa.comfort.save'));

String fieldText(WidgetTester t, Finder f) =>
    t.widget<TextField>(f).controller!.text;

/// The Text that shows [text], to check its direction.
Text textOf(WidgetTester t, String text) => t.widget<Text>(find.text(text));

void main() {
  group('writing a card', () {
    testWidgets(
      'A little context about picks the card topic, which titles the card '
      'and is saved with it '
      '[case:first_chapter.comfort_cards.comfort_topic.action]',
      (t) async {
        final w = ComfortWorld();
        await pumpComfort(t, w);
        await tapIn(t, key('qa.comfort.topic'));
        await t.tap(find.text(en.firstChapterTopicFamily).last);
        await qaSettle(t);
        await t.enterText(original, 'My parents meet people later.');
        await addCard(t);

        expect(find.text(en.firstChapterTopicFamily), findsWidgets);
        expect(find.text('My parents meet people later.'), findsOneWidget);
        await save(t);
        expect((w.saved['cards'] as List).single['topic'], 'family');
      },
    );

    testWidgets(
      'In your own words is added to the draft as written, then the field '
      'clears for the next card '
      '[case:first_chapter.comfort_cards.comfort_original_input.action] '
      '[case:first_chapter.comfort_cards.comfort_add.action]',
      (t) async {
        final w = ComfortWorld();
        await pumpComfort(t, w);
        await t.enterText(original, 'I enjoy daytime dates.');
        await addCard(t);

        expect(find.text(en.firstChapterTopicPace), findsWidgets);
        expect(
          find.text(en.firstChapterComfortOriginal('English')),
          findsOneWidget,
        );
        expect(find.text('I enjoy daytime dates.'), findsOneWidget);
        expect(fieldText(t, original), isEmpty);
        expect(key('qa.comfort.remove.pace'), findsOneWidget);
        expect(w.api.writes, isEmpty, reason: 'only saved on Save');

        // Adding the same topic again replaces that card.
        await t.enterText(original, 'A slower pace, please.');
        await addCard(t);
        expect(find.text('I enjoy daytime dates.'), findsNothing);
        expect(find.text('A slower pace, please.'), findsOneWidget);
        expect(key('qa.comfort.remove.pace'), findsOneWidget);
        await save(t);
        expect(w.saved['cards'], [card('pace', 'A slower pace, please.')]);
      },
    );

    testWidgets(
      'In your own words: empty or spaces only is refused, the text is '
      'trimmed, emoji and right-to-left text are kept, 280 characters is the '
      'limit, and an unadded card blocks saving '
      '[case:first_chapter.comfort_cards.comfort_original_input.validation]',
      (t) async {
        final w = ComfortWorld();
        await pumpComfort(t, w);
        await addCard(t);
        expect(find.text(en.firstChapterComfortMissingFields), findsOneWidget);
        await t.enterText(original, '    ');
        await addCard(t);
        expect(find.text(en.firstChapterComfortMissingFields), findsOneWidget);
        expect(key('qa.comfort.remove.pace'), findsNothing);

        await t.enterText(original, 'x' * 300);
        expect(fieldText(t, original), hasLength(280));

        await t.enterText(original, '  أفضل التحدث ببطء 🌿  ');
        await t.enterText(language, 'العربية');
        await addCard(t);
        expect(error, findsNothing);
        expect(
          textOf(t, 'أفضل التحدث ببطء 🌿').textDirection,
          TextDirection.rtl,
        );

        await t.enterText(original, 'Not added yet');
        await save(t);
        expect(find.text(en.firstChapterComfortUnaddedCard), findsOneWidget);
        expect(w.api.writes, isEmpty);
      },
    );

    testWidgets(
      'Original language labels the card, sets its reading direction and is '
      'saved with it '
      '[case:first_chapter.comfort_cards.comfort_language_input.action]',
      (t) async {
        final w = ComfortWorld();
        await pumpComfort(t, w);
        expect(fieldText(t, language), en.firstChapterComfortDefaultLanguage);
        await t.enterText(language, 'Arabic');
        await t.enterText(original, 'أفضل التحدث ببطء');
        await addCard(t);

        expect(
          find.text(en.firstChapterComfortOriginal('Arabic')),
          findsOneWidget,
        );
        expect(textOf(t, 'أفضل التحدث ببطء').textDirection, TextDirection.rtl);
        await save(t);
        expect((w.saved['cards'] as List).single['language'], 'Arabic');
      },
    );

    testWidgets(
      'Original language: empty, one letter or spaces is refused, 35 '
      'characters is the limit, and a name in its own script is accepted '
      '[case:first_chapter.comfort_cards.comfort_language_input.validation]',
      (t) async {
        final w = ComfortWorld();
        await pumpComfort(t, w);
        await t.enterText(original, 'Slow mornings.');
        for (final bad in ['', 'a', '   ']) {
          await t.enterText(language, bad);
          await addCard(t);
          expect(
            find.text(en.firstChapterComfortMissingFields),
            findsOneWidget,
            reason: '"$bad"',
          );
          expect(key('qa.comfort.remove.pace'), findsNothing);
        }
        await t.enterText(language, 'L' * 40);
        expect(fieldText(t, language), hasLength(35));

        await t.enterText(language, ' 日本語 ');
        await addCard(t);
        expect(error, findsNothing);
        expect(
          find.text(en.firstChapterComfortOriginal('日本語')),
          findsOneWidget,
        );
      },
    );
  });

  group('member translation', () {
    testWidgets(
      'Your translation is labelled as member-provided under the original '
      'and saved with its language '
      '[case:first_chapter.comfort_cards.comfort_translation_input.action] '
      '[case:first_chapter.comfort_cards.comfort_translation_language_input.action]',
      (t) async {
        final w = ComfortWorld();
        await pumpComfort(t, w);
        await t.enterText(language, 'Arabic');
        await t.enterText(original, 'أفضل التحدث ببطء');
        await t.enterText(translation, 'I prefer a slower pace');
        await t.enterText(translationLanguage, 'English');
        await addCard(t);

        expect(
          find.text(en.firstChapterComfortMemberTranslation('English')),
          findsOneWidget,
        );
        expect(find.text('I prefer a slower pace'), findsOneWidget);
        expect(textOf(t, 'I prefer a slower pace').textDirection, isNull);
        expect(fieldText(t, translation), isEmpty);
        expect(fieldText(t, translationLanguage), isEmpty);
        await save(t);
        expect(
          (w.saved['cards'] as List).single,
          card(
            'pace',
            'أفضل التحدث ببطء',
            language: 'Arabic',
            translation: 'I prefer a slower pace',
            translationLanguage: 'English',
          ),
        );
      },
    );

    testWidgets(
      'Your translation: it needs a language, spaces alone are no '
      'translation, and 280 characters is the limit '
      '[case:first_chapter.comfort_cards.comfort_translation_input.validation]',
      (t) async {
        final w = ComfortWorld();
        await pumpComfort(t, w);
        await t.enterText(original, 'Slow mornings.');
        await t.enterText(translation, 'Mañanas lentas');
        await addCard(t);
        expect(find.text(en.firstChapterComfortMissingFields), findsOneWidget);

        await t.enterText(translation, 'y' * 300);
        expect(fieldText(t, translation), hasLength(280));

        await t.enterText(translation, '   ');
        await addCard(t);
        expect(error, findsNothing, reason: 'spaces are not a translation');
        expect(
          find.textContaining('Member-provided translation'),
          findsNothing,
        );
        await save(t);
        final saved = (w.saved['cards'] as List).single as Map;
        expect(saved['translation'], '');
        expect(saved['translation_language'], '');
      },
    );

    testWidgets(
      'Translation language: one letter is refused, 35 characters is the '
      'limit, and without a translation it is not saved '
      '[case:first_chapter.comfort_cards.comfort_translation_language_input.validation]',
      (t) async {
        final w = ComfortWorld();
        await pumpComfort(t, w);
        await t.enterText(original, 'Slow mornings.');
        await t.enterText(translation, 'Mañanas lentas');
        await t.enterText(translationLanguage, 'E');
        await addCard(t);
        expect(find.text(en.firstChapterComfortMissingFields), findsOneWidget);

        await t.enterText(translationLanguage, 'S' * 40);
        expect(fieldText(t, translationLanguage), hasLength(35));

        await t.enterText(translation, '');
        await t.enterText(translationLanguage, 'Español');
        await addCard(t);
        expect(error, findsNothing);
        await save(t);
        expect(
          ((w.saved['cards'] as List).single as Map)['translation_language'],
          '',
        );
      },
    );
  });

  group('the draft', () {
    testWidgets(
      'Remove from draft takes the card out, and Save sends only the rest '
      '[case:first_chapter.comfort_cards.comfort_remove_card.action]',
      (t) async {
        final w = ComfortWorld(
          cards: [card('pace', 'Slow mornings.'), card('family', 'Later.')],
        );
        await pumpComfort(t, w);
        await tapIn(t, key('qa.comfort.remove.family'));
        expect(find.text('Later.'), findsNothing);
        expect(find.text('Slow mornings.'), findsOneWidget);
        expect(w.api.writes, isEmpty);
        await save(t);
        expect(w.saved['cards'], [card('pace', 'Slow mornings.')]);
      },
    );

    testWidgets(
      'Share these cards with my matches is off until switched on, and Save '
      'sends the choice '
      '[case:first_chapter.comfort_cards.comfort_shared.action]',
      (t) async {
        final w = ComfortWorld(cards: [card('pace', 'Slow mornings.')]);
        await pumpComfort(t, w);
        final share = key('qa.comfort.shared');
        expect(t.widget<SwitchListTile>(share).value, isFalse);
        await tapIn(t, share);
        expect(t.widget<SwitchListTile>(share).value, isTrue);
        expect(w.api.writes, isEmpty);
        await save(t);
        expect(w.saved['shared'], isTrue);
      },
    );

    testWidgets(
      'Save my choices sends the cards, the sharing choice and the version, '
      'then closes the screen '
      '[case:first_chapter.comfort_cards.comfort_save.action]',
      (t) async {
        final w = ComfortWorld(cards: [card('pace', 'Slow mornings.')]);
        final popped = await pumpComfort(t, w);
        await t.enterText(original, 'Daytime first.');
        await tapIn(t, key('qa.comfort.topic'));
        await t.tap(find.text(en.firstChapterTopicDates).last);
        await qaSettle(t);
        await addCard(t);
        await save(t);

        expect(w.api.writeLines, ['PUT /chapters/comfort']);
        expect(w.saved, {
          'cards': [
            card('pace', 'Slow mornings.'),
            card('dates', 'Daytime first.'),
          ],
          'shared': false,
          'version': 4,
        });
        expect(find.byType(ComfortCardsScreen), findsNothing);
        expect(popped, hasLength(1));
      },
    );

    testWidgets('A failed save keeps the draft and the screen, and says so', (
      t,
    ) async {
      final w = ComfortWorld();
      w.api.on('PUT /chapters/comfort', (_) => const QaReply(500, null));
      await pumpComfort(t, w);
      await t.enterText(original, 'Daytime first.');
      await addCard(t);
      await save(t);
      expect(find.text(en.firstChapterComfortSaveFailed), findsOneWidget);
      expect(find.byType(ComfortCardsScreen), findsOneWidget);
      expect(find.text('Daytime first.'), findsOneWidget);
      expect(
        t.widget<ButtonStyleButton>(key('qa.comfort.save')).onPressed,
        isNotNull,
      );
    });

    testWidgets(
      'Reload saved version drops the unsaved draft and shows what the '
      'server holds now '
      '[case:first_chapter.comfort_cards.comfort_reload.action]',
      (t) async {
        final w = ComfortWorld(cards: [card('pace', 'Slow mornings.')]);
        await pumpComfort(t, w);
        await tapIn(t, key('qa.comfort.remove.pace'));
        await tapIn(t, key('qa.comfort.shared'));
        expect(find.text('Slow mornings.'), findsNothing);

        // Saved from another device meanwhile.
        w.cards = [card('pace', 'Slow mornings.'), card('family', 'Later.')];
        await t.tap(key('qa.comfort.reload'));
        await qaSettle(t);

        expect(w.api.sent('GET', '/chapters/comfort'), hasLength(2));
        expect(find.text('Slow mornings.'), findsOneWidget);
        expect(find.text('Later.'), findsOneWidget);
        expect(
          t.widget<SwitchListTile>(key('qa.comfort.shared')).value,
          isFalse,
        );
        expect(w.api.writes, isEmpty);
      },
    );

    testWidgets(
      'Cards that cannot load offer Reload comfort cards, which loads them '
      '[case:first_chapter.comfort_cards.comfort_retry.action]',
      (t) async {
        final w = ComfortWorld(cards: [card('pace', 'Slow mornings.')]);
        w.api.fail('GET /chapters/comfort');
        await pumpComfort(t, w);
        expect(find.text(en.firstChapterComfortReloadCards), findsOneWidget);
        expect(original, findsNothing);

        w.api.on(
          'GET /chapters/comfort',
          (_) => qaOk({'cards': w.cards, 'shared': false, 'version': 4}),
        );
        await t.tap(key('qa.comfort.retry'));
        await qaSettle(t);
        expect(w.api.sent('GET', '/chapters/comfort'), hasLength(2));
        expect(find.text('Slow mornings.'), findsOneWidget);
        expect(original, findsOneWidget);
      },
    );
  });

  group('screen quality', () {
    ComfortWorld world() => ComfortWorld(
      cards: [
        card(
          'language',
          'أفضل التحدث ببطء',
          language: 'Arabic',
          translation: 'I prefer a slower pace',
          translationLanguage: 'English',
        ),
        card('family', 'My parents meet people later.'),
      ],
    );

    testWidgets('lays out with cards on phone and tablet, both themes '
        '[case:first_chapter.comfort_cards.layout_matrix]', (t) async {
      await qaExpectLaysOutEverywhere(
        t,
        world().api,
        ComfortCardsScreen.new,
        loaded: key('qa.comfort.save'),
      );
    });

    testWidgets('meets tap-target, label and contrast guidelines '
        '[case:first_chapter.comfort_cards.a11y_guidelines]', (t) async {
      await qaExpectMeetsA11yGuidelines(
        t,
        world().api,
        ComfortCardsScreen.new,
        size: const Size(430, 2400),
        loaded: find.text(en.firstChapterComfortHeadline),
      );
    });

    testWidgets('pushed, Back returns to the studio '
        '[case:first_chapter.comfort_cards.back_affordance]', (t) async {
      await qaExpectBackReturns(
        t,
        world().api,
        ComfortCardsScreen.new,
        screen: ComfortCardsScreen,
      );
    });

    testWidgets('renders in every shipped locale with nothing left in English '
        '[case:first_chapter.comfort_cards.l10n]', (t) async {
      await qaExpectRendersInAllLocales(
        t,
        world().api,
        ComfortCardsScreen.new,
        size: const Size(430, 2400),
        expected: [
          (l) => l.firstChapterInMyWords,
          (l) => l.firstChapterComfortHeadline,
          (l) => l.firstChapterComfortShareTitle,
          (l) => l.firstChapterTopicLanguage,
          (l) => l.firstChapterTopicFamily,
          (l) => l.firstChapterComfortOriginal('Arabic'),
          (l) => l.firstChapterComfortMemberTranslation('English'),
          (l) => l.firstChapterComfortRemoveFromDraft,
          (l) => l.firstChapterComfortTopicLabel,
          (l) => l.firstChapterComfortOriginalLanguage,
          (l) => l.firstChapterComfortOwnWords,
          (l) => l.firstChapterComfortTranslation,
          (l) => l.firstChapterComfortTranslationLanguage,
          (l) => l.firstChapterComfortAddCard,
          (l) => l.firstChapterComfortSave,
        ],
        // The member's own words and language names, as typed.
        allow: {
          'أفضل التحدث ببطء',
          'I prefer a slower pace',
          'My parents meet people later.',
          'Original · Arabic',
          'Original · English',
        },
      );
    });
  });
}
