// Control-level tests for the First Chapter Studio (chapter_studio_screen.dart):
// choosing a scene and a beginning, starting a chapter with a match, adding a
// surprise, closing it, the private green light, passing a solo scene or an
// anonymous joint story through the public preview, approving, copying and
// revoking shared links, and the reload controls. Every test performs the
// real gesture against the recording fake BFF and asserts the request sent,
// the navigation, or what the member sees afterwards.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/first_chapter/chapter_provider.dart';
import 'package:verified_dating_app/features/first_chapter/chapter_studio_screen.dart';
import 'package:verified_dating_app/features/first_chapter/comfort_cards_screen.dart';
import 'package:verified_dating_app/features/intentional_dating/connection_card.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';

final en = qaL10n(const Locale('en'));
final uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

Finder key(String k) => find.byKey(ValueKey(k));

const rain = <String, dynamic>{
  'id': 'rain',
  'title': 'A little rain',
  'prompt': 'A rainy afternoon and a small budget.',
  'beginnings': ['Browse a tiny bookshop', 'Find a cosy coffee corner'],
  'surprises': ['Choose a book by its first line', 'Draw a postcard'],
  'venue': 'coffee',
};

Map<String, dynamic> chapterJson({
  String surprise = '',
  bool myTurn = false,
  int version = 2,
}) => {
  'id': 'ch1',
  'scene': 'rain',
  'beginning': 'Browse a tiny bookshop',
  'surprise': surprise,
  'version': version,
  'my_turn': myTurn,
};

Map<String, dynamic> publicationJson({
  String id = 'pub1',
  bool published = true,
  bool myApproval = true,
  bool revoked = false,
  String surprise = '',
}) => {
  'id': id,
  'beginning': 'Browse a tiny bookshop',
  'surprise': surprise,
  'published': published,
  'my_approval': myApproval,
  'revoked': revoked,
  'version': 5,
};

/// The studio's server: the pair resource, the solo catalogue, the member's
/// publications and the comfort cards, with every write applied to state so
/// the reload after a command shows what the server now holds.
class StudioWorld {
  StudioWorld({
    this.chapter,
    List<Map<String, dynamic>>? publications,
    this.canGiveBack = false,
    this.mutual = const [],
    this.mine = const [],
  }) : publications = publications ?? [] {
    api
      ..on('GET /matches/m1/chapter', (_) => qaOk(pair()))
      ..on(
        'GET /chapters/catalogue',
        (_) => qaOk({
          'scenes': [rain],
        }),
      )
      ..on(
        'GET /chapters/publications',
        (_) => qaOk({'publications': this.publications}),
      )
      ..on(
        'GET /chapters/comfort',
        (_) => qaOk({'cards': <dynamic>[], 'shared': false, 'version': 0}),
      )
      ..on('GET /matches/me', (_) => qaOk({'matches': matches}))
      ..on('POST /matches/m1/chapter', (c) {
        switch (c.body['action']) {
          case 'start':
            chapter = chapterJson();
          case 'surprise':
            chapter = chapterJson(surprise: c.body['choice'] as String);
          case 'close':
            chapter = null;
        }
        return qaOk({'chapter': chapter});
      })
      ..on('PUT /matches/m1/chapter/green-light', (c) {
        mine = (c.body['choices'] as List).cast<String>();
        return qaOk({'version': 1});
      })
      ..on('POST /chapters/publications', (c) {
        if (c.body['action'] == 'create') {
          this.publications.add(
            publicationJson(id: 'new', published: c.body['chapter_id'] == null),
          );
        } else {
          final i = this.publications.indexWhere(
            (p) => p['id'] == c.body['id'],
          );
          this.publications[i] = {
            ...this.publications[i],
            'my_approval': true,
            'published': true,
          };
        }
        return qaOk({'ok': true});
      })
      ..on('DELETE /chapters/publications/*', (c) {
        final id = c.path.split('/').last;
        final i = this.publications.indexWhere((p) => p['id'] == id);
        this.publications[i] = {...this.publications[i], 'revoked': true};
        return qaOk({'ok': true});
      });
  }

  final api = QaApi();
  Map<String, dynamic>? chapter;
  final List<Map<String, dynamic>> publications;
  bool canGiveBack;
  List<String> mutual;
  List<String> mine;
  List<Map<String, dynamic>> matches = [];

  Map<String, dynamic> pair() => {
    'scenes': [rain],
    'chapter': chapter,
    'mine': {'choices': mine, 'version': 0},
    'mutual': mutual,
    'comfort': [
      {
        'topic': 'pace',
        'original': 'I like slow mornings.',
        'language': 'English',
        'translation': '',
        'translation_language': '',
      },
    ],
    'can_give_back': canGiveBack,
  };
}

Widget pairStudio() =>
    const ChapterStudioScreen(matchId: 'm1', partnerName: 'Alex');

/// Pumps the studio on a tall phone view, so the whole page (down to the
/// shared chapters) is built.
Future<void> pumpStudio(
  WidgetTester t,
  StudioWorld w, {
  Widget? screen,
  List<Override> extra = const [],
}) => pumpQa(
  t,
  w.api,
  screen ?? pairStudio(),
  size: const Size(430, 2600),
  extra: extra,
);

/// Ends a test that left the studio (20 s refresh timer) mounted.
Future<void> done(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 1));
}

Future<void> tapIn(WidgetTester t, Finder finder) async {
  if (finder.hitTestable().evaluate().isEmpty) {
    await t.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await t.ensureVisible(finder);
  await t.pump();
  await t.tap(finder);
  await qaSettle(t);
}

/// Chooses the rain scene and its first beginning.
Future<void> chooseBeginning(WidgetTester t) async {
  await tapIn(t, key('qa.chapter.scene.rain'));
  await tapIn(t, find.widgetWithText(ChoiceChip, 'Browse a tiny bookshop'));
}

/// Records what the app writes to the clipboard.
List<String> mockClipboard(WidgetTester t) {
  final copied = <String>[];
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return copied;
}

void main() {
  group('choosing and starting a chapter', () {
    testWidgets('Choosing a scene marks it and offers its beginnings '
        '[case:first_chapter.chapter_studio.chapter_scene_scene.action]', (
      t,
    ) async {
      final w = StudioWorld();
      await pumpStudio(t, w);
      expect(find.text(en.firstChapterStepWriteBeginning), findsNothing);
      final icon = find.descendant(
        of: key('qa.chapter.scene.rain'),
        matching: find.byType(Icon),
      );
      expect(t.widget<Icon>(icon).icon, Icons.auto_stories_outlined);

      await tapIn(t, key('qa.chapter.scene.rain'));
      expect(t.widget<Icon>(icon).icon, Icons.check_circle);
      expect(find.text(en.firstChapterStepWriteBeginning), findsOneWidget);
      expect(
        find.widgetWithText(ChoiceChip, 'Browse a tiny bookshop'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ChoiceChip, 'Find a cosy coffee corner'),
        findsOneWidget,
      );
      // Nothing can be started until a beginning is chosen.
      expect(
        t.widget<ButtonStyleButton>(key('qa.chapter.start')).onPressed,
        isNull,
      );
      expect(w.api.writes, isEmpty);
      await done(t);
    });

    testWidgets('Start our chapter sends one start command with the scene and '
        'beginning, then shows the saved chapter '
        '[case:first_chapter.chapter_studio.chapter_start.action]', (t) async {
      final w = StudioWorld();
      await pumpStudio(t, w);
      await chooseBeginning(t);
      await tapIn(t, key('qa.chapter.start'));

      final start = w.api.sent('POST', '/matches/m1/chapter').single.body;
      expect(start['action'], 'start');
      expect(start['scene'], 'rain');
      expect(start['choice'], 'Browse a tiny bookshop');
      expect(start['id'], matches(uuid));
      expect(find.text(en.firstChapterYourFirstChapter), findsOneWidget);
      expect(find.text(en.firstChapterBeginningSaved), findsOneWidget);
      expect(key('qa.chapter.scene.rain'), findsNothing);
      await done(t);
    });

    testWidgets(
      'With their turn, a surprise is sent as one versioned command and '
      'the chapter shows it '
      '[case:first_chapter.chapter_studio.chapter_surprise_x.action]',
      (t) async {
        final w = StudioWorld(chapter: chapterJson(myTurn: true));
        await pumpStudio(t, w);
        expect(find.text(en.firstChapterYourTurn), findsOneWidget);
        await tapIn(t, key('qa.chapter.surprise.Draw a postcard'));

        expect(w.api.sent('POST', '/matches/m1/chapter').single.body, {
          'action': 'surprise',
          'id': 'ch1',
          'version': 2,
          'choice': 'Draw a postcard',
        });
        expect(find.text(en.firstChapterAndThen), findsOneWidget);
        expect(find.text('Draw a postcard'), findsOneWidget);
        expect(key('qa.chapter.surprise.Draw a postcard'), findsNothing);
        await done(t);
      },
    );

    testWidgets(
      'Close this chapter sends a versioned close and the scenes come back '
      '[case:first_chapter.chapter_studio.chapter_close.action]',
      (t) async {
        final w = StudioWorld(chapter: chapterJson());
        await pumpStudio(t, w);
        await tapIn(t, key('qa.chapter.close'));

        expect(w.api.sent('POST', '/matches/m1/chapter').single.body, {
          'action': 'close',
          'id': 'ch1',
          'version': 2,
        });
        expect(find.text(en.firstChapterYourFirstChapter), findsNothing);
        expect(find.text(en.firstChapterStepChooseScene), findsOneWidget);
        expect(key('qa.chapter.scene.rain'), findsOneWidget);
        await done(t);
      },
    );

    testWidgets(
      'Make this a date idea opens the date plan sheet for this match, '
      'prefilled with the chapter, and sends nothing on its own '
      '[case:first_chapter.chapter_studio.chapter_date_idea.action]',
      (t) async {
        final w = StudioWorld(
          chapter: chapterJson(surprise: 'Draw a postcard'),
        );
        w.api.json('GET /matches/m1/plans', {
          'plan': null,
          'history': <dynamic>[],
          'share_groups': <dynamic>[],
          'can_propose': true,
        });
        await pumpStudio(
          t,
          w,
          extra: [
            datingConnectionProvider(
              'm1',
            ).overrideWith((_) => Stream.value({'overlap': <dynamic>[]})),
          ],
        );
        await tapIn(t, key('qa.chapter.date_idea'));

        expect(find.text(en.planProposeHeadline), findsOneWidget);
        expect(find.text(en.planProposeLead('Alex')), findsOneWidget);
        expect(
          t.widget<TextField>(key('qa.plan.note')).controller!.text,
          en.firstChapterDateIdeaNote(
            'Browse a tiny bookshop',
            'Draw a postcard',
          ),
        );
        expect(w.api.writes, isEmpty, reason: 'nothing is booked');
        await done(t);
      },
    );
  });

  group('passing a chapter on', () {
    testWidgets(
      'Pass the Chapter opens the public preview first and Keep private '
      'closes it without sending anything '
      '[case:first_chapter.chapter_studio.chapter_pass.action] '
      '[case:first_chapter.chapter_studio.chapter_preview_keep_private.action]',
      (t) async {
        final w = StudioWorld();
        await pumpStudio(t, w);
        await chooseBeginning(t);
        await tapIn(t, key('qa.chapter.pass'));

        final dialog = find.byType(AlertDialog);
        expect(dialog, findsOneWidget);
        expect(
          find.descendant(
            of: dialog,
            matching: find.text(en.firstChapterSoloPreviewTitle),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: dialog, matching: find.text('A little rain')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: dialog,
            matching: find.text('Browse a tiny bookshop'),
          ),
          findsOneWidget,
        );
        expect(w.api.writes, isEmpty);

        await t.tap(key('qa.chapter.preview_keep_private'));
        await qaSettle(t);
        expect(find.byType(AlertDialog), findsNothing);
        expect(w.api.writes, isEmpty);
        expect(find.text(en.firstChapterNothingPublic), findsOneWidget);
        await done(t);
      },
    );

    testWidgets(
      'Create share link publishes only the scene and the beginning, and the '
      'new link is listed with Copy and Revoke '
      '[case:first_chapter.chapter_studio.chapter_preview_share.action] '
      '[case:first_chapter.chapter_studio.create_share_link.action]',
      (t) async {
        final w = StudioWorld();
        await pumpStudio(t, w);
        await chooseBeginning(t);
        await tapIn(t, key('qa.chapter.pass'));
        expect(find.text(en.firstChapterCreateShareLink), findsOneWidget);
        await t.tap(key('qa.chapter.preview_share'));
        await qaSettle(t);

        final create = w.api.sent('POST', '/chapters/publications').single.body;
        expect(
          create.keys,
          unorderedEquals(['action', 'id', 'scene', 'beginning']),
        );
        expect(create['action'], 'create');
        expect(create['scene'], 'rain');
        expect(create['beginning'], 'Browse a tiny bookshop');
        expect(create['id'], matches(uuid));
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text(en.firstChapterNothingPublic), findsNothing);
        expect(find.text(en.firstChapterPublicScene), findsOneWidget);
        expect(key('qa.chapter.copy.new'), findsOneWidget);
        expect(key('qa.chapter.revoke.new'), findsOneWidget);
        await done(t);
      },
    );

    testWidgets(
      'Preview our anonymous story asks for this member’s half of a joint '
      'approval and sends the chapter with the match '
      '[case:first_chapter.chapter_studio.chapter_give_back.action]',
      (t) async {
        final w = StudioWorld(
          chapter: chapterJson(surprise: 'Draw a postcard'),
          canGiveBack: true,
        );
        await pumpStudio(t, w);
        expect(find.text(en.firstChapterGiveBackTitle), findsOneWidget);
        await tapIn(t, key('qa.chapter.give_back'));

        final dialog = find.byType(AlertDialog);
        expect(
          find.descendant(
            of: dialog,
            matching: find.text(en.firstChapterJointPreviewTitle),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: dialog,
            matching: find.text(en.firstChapterThenSurprise('Draw a postcard')),
          ),
          findsOneWidget,
        );
        await t.tap(
          find.descendant(
            of: dialog,
            matching: find.text(en.firstChapterApproveMyHalf),
          ),
        );
        await qaSettle(t);

        final create = w.api.sent('POST', '/chapters/publications').single.body;
        expect(create['action'], 'create');
        expect(create['scene'], 'rain');
        expect(create['beginning'], 'Browse a tiny bookshop');
        expect(create['chapter_id'], 'ch1');
        expect(create['match_id'], 'm1');
        // A joint story stays private until the partner approves too.
        expect(find.text(en.firstChapterPrivateUntilBoth), findsOneWidget);
        await done(t);
      },
    );
  });

  group('shared chapters', () {
    testWidgets(
      'Approve this exact story sends one versioned approval and the story '
      'goes public '
      '[case:first_chapter.chapter_studio.chapter_approve_p.action]',
      (t) async {
        final w = StudioWorld(
          publications: [publicationJson(published: false, myApproval: false)],
        );
        await pumpStudio(t, w);
        expect(find.text(en.firstChapterPrivateUntilBoth), findsOneWidget);
        await tapIn(t, key('qa.chapter.approve.pub1'));

        expect(w.api.sent('POST', '/chapters/publications').single.body, {
          'action': 'approve',
          'id': 'pub1',
          'version': 5,
        });
        expect(find.text(en.firstChapterPublicScene), findsOneWidget);
        expect(key('qa.chapter.approve.pub1'), findsNothing);
        expect(key('qa.chapter.copy.pub1'), findsOneWidget);
        await done(t);
      },
    );

    testWidgets('Copy link copies the opaque share URL and confirms '
        '[case:first_chapter.chapter_studio.chapter_copy_p.action]', (t) async {
      final copied = mockClipboard(t);
      final w = StudioWorld(publications: [publicationJson()]);
      await pumpStudio(t, w);
      await tapIn(t, key('qa.chapter.copy.pub1'));

      expect(copied, [chapterShareUrl('pub1')]);
      expect(Uri.parse(copied.single).queryParameters, {'share': 'pub1'});
      expect(qaSnackText(t), en.firstChapterLinkCopied);
      expect(w.api.writes, isEmpty);
      await done(t);
    });

    testWidgets('Revoke link deletes the publication and shows it revoked '
        '[case:first_chapter.chapter_studio.chapter_revoke_p.action]', (
      t,
    ) async {
      final w = StudioWorld(publications: [publicationJson()]);
      await pumpStudio(t, w);
      await tapIn(t, key('qa.chapter.revoke.pub1'));

      expect(w.api.writeLines, ['DELETE /chapters/publications/pub1']);
      expect(find.text(en.firstChapterLinkRevoked), findsOneWidget);
      expect(key('qa.chapter.copy.pub1'), findsNothing);
      expect(key('qa.chapter.revoke.pub1'), findsNothing);
      await done(t);
    });

    testWidgets(
      'When shared chapters fail to load, Reload shared chapters asks again '
      'and lists them '
      '[case:first_chapter.chapter_studio.chapter_reload_shared.action]',
      (t) async {
        final w = StudioWorld(publications: [publicationJson()]);
        w.api.fail('GET /chapters/publications');
        await pumpStudio(t, w);
        expect(find.text(en.firstChapterReloadShared), findsOneWidget);

        w.api.on(
          'GET /chapters/publications',
          (_) => qaOk({'publications': w.publications}),
        );
        await tapIn(t, key('qa.chapter.reload_shared'));
        expect(w.api.sent('GET', '/chapters/publications'), hasLength(2));
        expect(find.text(en.firstChapterReloadShared), findsNothing);
        expect(key('qa.chapter.copy.pub1'), findsOneWidget);
        await done(t);
      },
    );
  });

  group('green light', () {
    testWidgets(
      'A green light choice stays local until saved; Save privately sends the '
      'choices with the version and the mutual line follows the server '
      '[case:first_chapter.chapter_studio.chapter_green_x.action] '
      '[case:first_chapter.chapter_studio.chapter_save_green.action]',
      (t) async {
        final w = StudioWorld();
        await pumpStudio(t, w);
        final call = key('qa.chapter.green.call');
        await tapIn(t, call);
        expect(t.widget<FilterChip>(call).selected, isTrue);
        expect(w.api.writes, isEmpty, reason: 'only saved on Save privately');
        await tapIn(t, key('qa.chapter.green.date'));
        await tapIn(t, key('qa.chapter.green.date'));
        expect(
          t.widget<FilterChip>(key('qa.chapter.green.date')).selected,
          isFalse,
        );

        w.mutual = ['call'];
        await tapIn(t, key('qa.chapter.save_green'));
        final put = w.api.sent('PUT', '/matches/m1/chapter/green-light');
        expect(put.single.body, {
          'choices': ['call'],
          'version': 0,
        });
        expect(
          find.text(en.firstChapterGreenLightMutual(en.firstChapterGreenCall)),
          findsOneWidget,
        );
        // The saved choice now comes from the server.
        expect(t.widget<FilterChip>(call).selected, isTrue);
        await done(t);
      },
    );

    testWidgets(
      'A save the server does not confirm says so and keeps the choice',
      (t) async {
        final w = StudioWorld();
        // A bare 500: no server message, so the studio's own words show.
        w.api.on(
          'PUT /matches/m1/chapter/green-light',
          (_) => const QaReply(500, null),
        );
        await pumpStudio(t, w);
        await tapIn(t, key('qa.chapter.green.chat'));
        await tapIn(t, key('qa.chapter.save_green'));
        expect(find.text(en.firstChapterSaveUnconfirmed), findsOneWidget);
        expect(
          t.widget<FilterChip>(key('qa.chapter.green.chat')).selected,
          isTrue,
        );
        await done(t);
      },
    );
  });

  group('navigation and reloads', () {
    testWidgets('Make room for what matters to you opens the comfort cards '
        '[case:first_chapter.chapter_studio.chapter_comfort_cards.action]', (
      t,
    ) async {
      final w = StudioWorld();
      await pumpStudio(t, w);
      await tapIn(t, key('qa.chapter.comfort_cards'));
      expect(find.byType(ComfortCardsScreen), findsOneWidget);
      expect(find.text(en.firstChapterComfortHeadline), findsOneWidget);
      expect(w.api.sent('GET', '/chapters/comfort'), hasLength(1));
      await done(t);
    });

    testWidgets(
      'Create a first chapter together opens the studio for that match '
      '[case:first_chapter.chapter_studio.chapter_match_x.action]',
      (t) async {
        final w = StudioWorld()
          ..matches = [
            {'id': 'm1', 'user_id': 'alex', 'user_name': 'Alex'},
          ];
        await pumpStudio(t, w, screen: const ChapterStudioScreen());
        expect(find.text(en.firstChapterHeroSolo), findsOneWidget);
        expect(w.api.sent('GET', '/matches/m1/chapter'), isEmpty);
        await tapIn(t, key('qa.chapter.match.m1'));

        expect(find.text(en.firstChapterHeroPair('Alex')), findsOneWidget);
        expect(w.api.sent('GET', '/matches/m1/chapter'), hasLength(1));
        expect(find.text(en.firstChapterGreenLightTitle), findsOneWidget);
        await done(t);
      },
    );

    testWidgets(
      'Refresh chapter reloads the chapter and the shared links and shows '
      'what changed '
      '[case:first_chapter.chapter_studio.chapter_refresh.action]',
      (t) async {
        final w = StudioWorld();
        await pumpStudio(t, w);
        expect(find.text(en.firstChapterStepChooseScene), findsOneWidget);

        // The match started the chapter meanwhile.
        w.chapter = chapterJson();
        w.publications.add(publicationJson());
        await t.tap(key('qa.chapter.refresh'));
        await qaSettle(t);

        expect(w.api.sent('GET', '/matches/m1/chapter'), hasLength(2));
        expect(w.api.sent('GET', '/chapters/publications'), hasLength(2));
        expect(find.text(en.firstChapterYourFirstChapter), findsOneWidget);
        expect(key('qa.chapter.copy.pub1'), findsOneWidget);
        await done(t);
      },
    );

    testWidgets('A chapter that cannot load says so and Try again loads it '
        '[case:first_chapter.chapter_studio.chapter_retry.action]', (t) async {
      final w = StudioWorld();
      w.api.fail('GET /matches/m1/chapter');
      await pumpStudio(t, w);
      expect(find.text(en.firstChapterLoadFailed), findsOneWidget);

      w.api.on('GET /matches/m1/chapter', (_) => qaOk(w.pair()));
      await tapIn(t, key('qa.chapter.retry'));
      expect(w.api.sent('GET', '/matches/m1/chapter'), hasLength(2));
      expect(find.text(en.firstChapterLoadFailed), findsNothing);
      expect(key('qa.chapter.scene.rain'), findsOneWidget);
      await done(t);
    });
  });

  group('screen quality', () {
    Finder loaded() => find.text(en.firstChapterGreenLightTitle);

    testWidgets('lays out with a chapter on phone and tablet, both themes '
        '[case:first_chapter.chapter_studio.layout_matrix]', (t) async {
      final w = StudioWorld(
        chapter: chapterJson(surprise: 'Draw a postcard'),
        canGiveBack: true,
        publications: [
          publicationJson(),
          publicationJson(id: 'p2', myApproval: false, published: false),
        ],
      );
      await qaExpectLaysOutEverywhere(t, w.api, pairStudio, loaded: loaded());
    });

    testWidgets('meets tap-target, label and contrast guidelines '
        '[case:first_chapter.chapter_studio.a11y_guidelines]', (t) async {
      final w = StudioWorld(
        chapter: chapterJson(surprise: 'Draw a postcard'),
        canGiveBack: true,
        publications: [publicationJson()],
      );
      await qaExpectMeetsA11yGuidelines(
        t,
        w.api,
        pairStudio,
        size: const Size(430, 2600),
        loaded: find.text(en.firstChapterStudioTitle),
      );
    });

    testWidgets('pushed, Back returns to where the member came from '
        '[case:first_chapter.chapter_studio.back_affordance]', (t) async {
      final w = StudioWorld();
      await qaExpectBackReturns(
        t,
        w.api,
        pairStudio,
        screen: ChapterStudioScreen,
      );
    });

    testWidgets('renders in every shipped locale with nothing left in English '
        '[case:first_chapter.chapter_studio.l10n]', (t) async {
      final w = StudioWorld(
        chapter: chapterJson(surprise: 'Draw a postcard'),
        canGiveBack: true,
        publications: [publicationJson()],
      );
      await qaExpectRendersInAllLocales(
        t,
        w.api,
        pairStudio,
        size: const Size(430, 3200),
        expected: [
          (l) => l.firstChapterStudioTitle,
          (l) => l.firstChapterHeroPair('Alex'),
          (l) => l.firstChapterYourFirstChapter,
          (l) => l.firstChapterMakeDateIdea,
          (l) => l.firstChapterClose,
          (l) => l.firstChapterGiveBackTitle,
          (l) => l.firstChapterPreviewAnonymous,
          (l) => l.firstChapterGreenLightTitle,
          (l) => l.firstChapterGreenCall,
          (l) => l.firstChapterSavePrivately,
          (l) => l.firstChapterInTheirWords,
          (l) => l.firstChapterMakeRoomTitle,
          (l) => l.firstChapterSharedChapters,
          (l) => l.firstChapterCopyLink,
          (l) => l.firstChapterRevokeLink,
        ],
        // Scene text and member words come from the server as written.
        allow: {
          'A little rain',
          'Browse a tiny bookshop',
          'Draw a postcard',
          'I like slow mornings.',
          // "Original" is the German, French, Spanish and Portuguese word
          // too; the language name is what the member typed.
          'Original · English',
        },
      );
    });
  });
}
