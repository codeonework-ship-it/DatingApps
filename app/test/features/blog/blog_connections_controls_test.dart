// Control-level tests for Chapter connections (blog_connections.dart): the
// private response / appeal / contribution composer, the connections hub
// (responses, shared links, review notices) and the private exchange with
// its safety controls. Each test performs the real gesture and asserts the
// request the fake BFF received, the navigation, and what the member sees.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/blog/blog_connections.dart';
import 'package:verified_dating_app/features/blog/blog_data.dart';
import 'package:verified_dating_app/features/blog/blog_sharing.dart';
import 'package:verified_dating_app/features/first_chapter/chapter_studio_screen.dart';
import 'package:verified_dating_app/features/intentional_dating/connection_card.dart';

import '../../support/qa_api.dart';

final en = qaL10n(const Locale('en'));
final uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

Finder key(String k) => find.byKey(ValueKey(k));
const field = ValueKey('qa.blog.text_command.field');
const submit = ValueKey('qa.blog.text_command.submit');

BlogPost post() => BlogPost.fromJson({
  'id': 'post1',
  'author_id': 'author',
  'author_name': 'Priya',
  'title': 'A little Sunday',
  'body': 'Coffee and a bookshop.',
  'audience': 'community',
  'invitation': 'your_version',
  'version': 1,
  'photos': <dynamic>[],
});

/// One row of `GET /blog/responses`.
Map<String, dynamic> responseRow({
  String id = 'ex1',
  String partner = 'Alex',
  String text = 'A private hello',
  String status = 'pending',
  bool incoming = true,
}) => {
  'id': id,
  'partner_name': partner,
  'text': text,
  'status': status,
  'incoming': incoming,
  'revealed': false,
};

/// `GET /blog/responses/{id}`'s `response`.
Map<String, dynamic> exchange({
  String status = 'pending',
  bool incoming = true,
  String myStory = '',
  String partnerStory = '',
  bool revealed = false,
  bool canPlan = false,
  bool canJointShare = false,
  String matchId = '',
}) => {
  'id': 'ex1',
  'post_id': 'post1',
  'partner_name': 'Alex',
  'partner_id': 'alex',
  'text': 'A private hello',
  'status': status,
  'incoming': incoming,
  'my_story': myStory,
  'partner_story': partnerStory,
  'revealed': revealed,
  'version': 3,
  'can_plan': canPlan,
  'can_joint_share': canJointShare,
  'match_id': matchId,
};

Map<String, dynamic> publication({
  String id = 'pub1',
  String excerpt = 'Coffee and a bookshop.',
  bool published = true,
  bool joint = false,
  bool myApproval = true,
}) => {
  'id': id,
  'title': 'A little Sunday',
  'excerpt': excerpt,
  'published': published,
  'joint': joint,
  'my_approval': myApproval,
  'moderation_state': 'active',
  'version': 4,
};

/// Ends a test that left the exchange screen (25 s refresh timer) mounted.
Future<void> done(WidgetTester t) => t.pumpWidget(const SizedBox());

/// Scrolls [finder] into view on the current screen and taps it.
Future<void> tapIn(WidgetTester t, Finder finder) async {
  await t.scrollUntilVisible(
    finder,
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await t.ensureVisible(finder);
  await t.pump();
  await t.tap(finder);
  await qaSettle(t);
}

/// Taps the confirm (or [cancel]) button of the open confirmation dialog.
Future<void> answerDialog(
  WidgetTester t,
  String action, {
  bool cancel = false,
}) async {
  await t.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text(cancel ? en.blogCancel : action),
    ),
  );
  await qaSettle(t);
}

/// Records what the app writes to the clipboard. [failWrites] makes the next
/// writes fail the way a denied clipboard does.
class FakeClipboard {
  String? text;
  int failWrites = 0;

  void install(WidgetTester t) {
    final messenger = t.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          if (failWrites > 0) {
            failWrites--;
            throw PlatformException(code: 'denied');
          }
          text = (call.arguments as Map)['text'] as String?;
          return null;
        case 'Clipboard.getData':
          return text == null ? null : {'text': text};
        case 'Clipboard.hasStrings':
          return {'value': text != null};
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
  }
}

/// Selects all of a SelectableText with the real long-press toolbar and
/// copies it.
Future<void> copyAllOf(WidgetTester t, Finder selectable) async {
  await t.ensureVisible(selectable);
  await t.pump();
  await t.longPress(selectable);
  await qaSettle(t, frames: 5);
  final selectAll = find.text('Select all');
  if (selectAll.evaluate().isNotEmpty) {
    await t.tap(selectAll);
    await qaSettle(t, frames: 5);
  }
  await t.tap(find.text('Copy'));
  await qaSettle(t, frames: 5);
}

/// The private-response composer as a chapter page opens it.
Widget respondLauncher() => Builder(
  builder: (context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => respondToChapter(context, post()),
        child: const Text('Respond privately'),
      ),
    ),
  ),
);

const composer = BlogTextCommandScreen(
  title: 'A private response',
  help: 'Only the author receives this response.',
  label: 'Send private response',
  path: '/blog/responses',
  payload: {'post_id': 'post1'},
  maxLength: 600,
);

void main() {
  group('private response composer', () {
    testWidgets(
      'Responding privately sends the trimmed words with a command id, closes '
      'the composer and opens Chapter connections with the new response '
      '[case:blog.blog_connections.openers_handle_result]',
      (t) async {
        var sent = false;
        final api = QaApi()
          ..on('POST /blog/responses', (c) {
            sent = true;
            return qaOk({'response': responseRow(incoming: false)});
          })
          ..on(
            'GET /blog/responses',
            (_) => qaOk({
              'responses': [
                if (sent)
                  responseRow(text: 'I have a version too.', incoming: false),
              ],
              'next_cursor': '',
            }),
          );
        await pumpQa(t, api, respondLauncher());
        await t.tap(find.text('Respond privately'));
        await qaSettle(t);
        expect(find.byType(BlogTextCommandScreen), findsOneWidget);
        expect(find.text(en.blogPrivateResponseTitle), findsOneWidget);
        expect(
          find.text(en.blogPrivateResponseHelp(en.blogInvitationYourVersion)),
          findsOneWidget,
        );

        await t.enterText(find.byKey(field), '  I have a version too.  ');
        await t.pump();
        await t.tap(find.byKey(submit));
        await qaSettle(t);

        final post = api.sent('POST', '/blog/responses').single;
        expect(post.body['id'], matches(uuid));
        expect(post.body, {
          'post_id': 'post1',
          'text': 'I have a version too.',
          'id': post.body['id'],
        });
        expect(find.byType(BlogTextCommandScreen), findsNothing);
        expect(find.byType(BlogConnectionsScreen), findsOneWidget);
        expect(find.text(en.blogConnectionsTitle), findsOneWidget);
        expect(find.text('I have a version too.'), findsOneWidget);
        expect(find.text(en.blogResponseSent), findsOneWidget);
      },
    );

    testWidgets(
      'While sending, the button says Sending… and ignores taps; on success '
      'the composer pops the saved response to its opener '
      '[case:blog.blog_connections.sending.action]',
      (t) async {
        final api = QaApi()
          ..on(
            'POST /blog/responses',
            (_) => QaReply(200, {
              'response': {'id': 'ex1'},
            }, delay: const Duration(milliseconds: 300)),
          );
        final results = await pumpQa(t, api, composer, launcher: true);
        await t.enterText(find.byKey(field), 'Hello');
        await t.pump();
        await t.tap(find.byKey(submit));
        await t.pump();
        expect(find.text(en.blogSending), findsOneWidget);
        expect(t.widget<FilledButton>(find.byKey(submit)).onPressed, isNull);
        expect(t.widget<TextField>(find.byKey(field)).enabled, isFalse);
        await t.tap(find.byKey(submit), warnIfMissed: false);
        await qaSettle(t);
        expect(api.writes, hasLength(1));
        expect(results, [
          {
            'response': {'id': 'ex1'},
          },
        ]);
        expect(find.byType(BlogTextCommandScreen), findsNothing);
      },
    );

    testWidgets(
      'A failed send keeps the words, explains, re-enables the button and '
      'retries with the same command id; leaving with unsent words asks first '
      '[case:blog.blog_connections.sending.api_failure]',
      (t) async {
        final api = QaApi()
          ..fail(
            'POST /blog/responses',
            status: 429,
            message: 'You can send one response to this author.',
          );
        final results = await pumpQa(t, api, composer, launcher: true);
        await t.enterText(find.byKey(field), 'A thoughtful hello');
        await t.pump();
        await t.tap(find.byKey(submit));
        await qaSettle(t);
        expect(
          find.text('You can send one response to this author.'),
          findsOneWidget,
        );
        expect(
          t.widget<TextField>(find.byKey(field)).controller!.text,
          'A thoughtful hello',
        );
        expect(t.widget<FilledButton>(find.byKey(submit)).onPressed, isNotNull);

        api.on('POST /blog/responses', (_) => const QaReply(500, null));
        await t.tap(find.byKey(submit));
        await qaSettle(t);
        expect(find.text(en.blogTextSaveUnconfirmed), findsOneWidget);
        final posts = api.sent('POST', '/blog/responses');
        expect(posts, hasLength(2));
        expect(posts[0].body['id'], posts[1].body['id']);

        // Back with unsent words: confirm first; Cancel keeps the composer.
        await t.pageBack();
        await qaSettle(t);
        expect(find.text(en.blogLeaveUnsentTitle), findsOneWidget);
        await answerDialog(t, en.blogLeave, cancel: true);
        expect(find.byType(BlogTextCommandScreen), findsOneWidget);
        await t.pageBack();
        await qaSettle(t);
        await answerDialog(t, en.blogLeave);
        expect(find.byType(BlogTextCommandScreen), findsNothing);
        expect(results, [null]);
        expect(api.writes, hasLength(2));
      },
    );

    testWidgets(
      'Typing fills "In your own words", counts characters and enables the '
      'button; clearing disables it again '
      '[case:blog.blog_connections.in_your_own_words.action]',
      (t) async {
        final api = QaApi();
        await pumpQa(t, api, composer);
        expect(find.text(en.blogOwnWordsLabel), findsOneWidget);
        expect(t.widget<FilledButton>(find.byKey(submit)).onPressed, isNull);
        await t.enterText(find.byKey(field), 'My version');
        await t.pump();
        expect(find.text('10/600'), findsOneWidget);
        expect(t.widget<FilledButton>(find.byKey(submit)).onPressed, isNotNull);
        await t.enterText(find.byKey(field), '');
        await t.pump();
        expect(t.widget<FilledButton>(find.byKey(submit)).onPressed, isNull);
        expect(api.writes, isEmpty);
      },
    );

    testWidgets(
      'Blank words cannot be sent, the length limit holds, and unicode is sent '
      'byte-for-byte [case:blog.blog_connections.in_your_own_words.validation]',
      (t) async {
        final api = QaApi()
          ..json('POST /blog/responses', {
            'response': {'id': 'ex1'},
          });
        await pumpQa(t, api, composer, launcher: true);
        await t.enterText(find.byKey(field), '  \n\t ');
        await t.pump();
        expect(t.widget<FilledButton>(find.byKey(submit)).onPressed, isNull);
        await t.tap(find.byKey(submit), warnIfMissed: false);
        await qaSettle(t);
        expect(api.writes, isEmpty);

        await t.enterText(find.byKey(field), 'y' * 601);
        await t.pump();
        expect(
          t.widget<TextField>(find.byKey(field)).controller!.text,
          'y' * 600,
        );

        const unicode = 'Mi versión 🌙 — שלום, مرحبا 👩🏽‍💻\nsecond line';
        await t.enterText(find.byKey(field), '\n $unicode  ');
        await t.pump();
        await t.tap(find.byKey(submit));
        await qaSettle(t);
        expect(api.writes.single.body['text'], unicode);
      },
    );
  });

  group('connections hub', () {
    testWidgets('Refresh reloads the current list from the server '
        '[case:blog.blog_connections.refresh.action]', (t) async {
      var round = 0;
      final api = QaApi()
        ..on('GET /blog/responses', (_) {
          round++;
          return qaOk({
            'responses': [responseRow(partner: round == 1 ? 'Alex' : 'Sam')],
            'next_cursor': '',
          });
        });
      await pumpQa(t, api, const BlogConnectionsScreen());
      expect(find.text('Alex'), findsOneWidget);
      expect(find.text(en.blogResponseIncoming), findsOneWidget);
      await t.tap(key('qa.blog.connections.refresh'));
      await qaSettle(t);
      expect(api.sent('GET', '/blog/responses'), hasLength(2));
      expect(find.text('Sam'), findsOneWidget);
      expect(find.text('Alex'), findsNothing);
    });

    testWidgets(
      'Section chips switch between responses, shared links and review '
      'notices, each loaded from its own endpoint '
      '[case:blog.blog_connections.choicechip_onselected.action]',
      (t) async {
        final api = QaApi()
          ..json('GET /blog/responses', {
            'responses': [responseRow()],
            'next_cursor': '',
          })
          ..json('GET /blog/publications', {
            'publications': [publication()],
            'next_cursor': '',
          })
          ..json('GET /blog/notices', {
            'notices': <dynamic>[],
            'next_cursor': '',
          });
        await pumpQa(t, api, const BlogConnectionsScreen());
        bool selected(String section) => t
            .widget<ChoiceChip>(key('qa.blog.connections.section.$section'))
            .selected;
        expect(selected('responses'), isTrue);

        await t.tap(key('qa.blog.connections.section.publications'));
        await qaSettle(t);
        expect(selected('publications'), isTrue);
        expect(selected('responses'), isFalse);
        expect(api.sent('GET', '/blog/publications'), hasLength(1));
        expect(find.text(en.blogPublicationLive), findsOneWidget);
        expect(find.text('Alex'), findsNothing);

        await t.tap(key('qa.blog.connections.section.notices'));
        await qaSettle(t);
        expect(selected('notices'), isTrue);
        expect(api.sent('GET', '/blog/notices'), hasLength(1));
        expect(find.text(en.blogNoticesEmpty), findsOneWidget);
        expect(api.writes, isEmpty);
      },
    );

    testWidgets(
      'When connections fail to load, Try again loads them '
      '[case:blog.blog_connections.could_not_load_your_connections_retry.action]',
      (t) async {
        var fail = true;
        final api = QaApi()
          ..on(
            'GET /blog/responses',
            (_) => fail
                ? const QaReply(503, null)
                : qaOk({
                    'responses': [responseRow()],
                    'next_cursor': '',
                  }),
          );
        await pumpQa(t, api, const BlogConnectionsScreen());
        expect(find.text(en.blogConnectionsLoadFailed), findsOneWidget);
        fail = false;
        await t.tap(find.text(en.blogTryAgain));
        await qaSettle(t);
        expect(api.sent('GET', '/blog/responses'), hasLength(2));
        expect(find.text(en.blogConnectionsLoadFailed), findsNothing);
        expect(find.text('Alex'), findsOneWidget);
      },
    );

    testWidgets('Open private exchange opens that exchange '
        '[case:blog.blog_connections.open_private_exchange.action]', (t) async {
      final api = QaApi()
        ..json('GET /blog/responses', {
          'responses': [responseRow(), responseRow(id: 'ex2', partner: 'Sam')],
          'next_cursor': '',
        })
        ..json('GET /blog/responses/ex1', {'response': exchange()});
      await pumpQa(t, api, const BlogConnectionsScreen());
      await tapIn(t, key('qa.blog.connections.open_exchange.ex1'));
      expect(find.byType(BlogExchangeScreen), findsOneWidget);
      expect(
        t.widget<BlogExchangeScreen>(find.byType(BlogExchangeScreen)).id,
        'ex1',
      );
      expect(api.sent('GET', '/blog/responses/ex1'), hasLength(1));
      expect(find.text(en.blogExchangeTitle), findsOneWidget);
      expect(find.text(en.blogExchangeWith('Alex')), findsOneWidget);
      expect(find.text('A private hello'), findsOneWidget);
      await done(t);
    });

    testWidgets(
      'More loads the next page with the server cursor; Previous returns '
      '[case:blog.blog_connections.more.action] '
      '[case:blog.blog_connections.previous.action]',
      (t) async {
        final api = QaApi()
          ..json('GET /blog/responses', {
            'responses': [responseRow()],
            'next_cursor': 'c2',
          })
          ..json('GET /blog/responses?before=c2', {
            'responses': [responseRow(id: 'ex2', partner: 'Sam')],
            'next_cursor': '',
          });
        await pumpQa(t, api, const BlogConnectionsScreen());
        expect(key('qa.blog.connections.previous'), findsNothing);
        await tapIn(t, key('qa.blog.connections.more'));
        expect(api.sent('GET', '/blog/responses?before=c2'), hasLength(1));
        expect(find.text('Sam'), findsOneWidget);
        expect(find.text('Alex'), findsNothing);
        expect(key('qa.blog.connections.more'), findsNothing);

        await tapIn(t, key('qa.blog.connections.previous'));
        expect(find.text('Alex'), findsOneWidget);
        expect(find.text('Sam'), findsNothing);
        expect(key('qa.blog.connections.previous'), findsNothing);
        expect(key('qa.blog.connections.more'), findsOneWidget);
        expect(api.unhandled, isEmpty);
      },
    );
  });

  group('shared links', () {
    QaApi linksApi(List<Map<String, dynamic>> Function() items) => QaApi()
      ..on(
        'GET /blog/publications',
        (_) => qaOk({'publications': items(), 'next_cursor': ''}),
      );

    testWidgets('A shared excerpt can be selected and copied exactly '
        '[case:blog.blog_connections.selectabletext_input_input.action]', (
      t,
    ) async {
      final clipboard = FakeClipboard()..install(t);
      final api = linksApi(() => [publication()]);
      await pumpQa(
        t,
        api,
        const BlogConnectionsScreen(section: 'publications'),
      );
      await copyAllOf(t, key('qa.blog.connections.excerpt.pub1'));
      expect(clipboard.text, 'Coffee and a bookshop.');
      expect(api.writes, isEmpty);
    });

    testWidgets(
      'Emoji, RTL and line breaks in a shared excerpt show byte-for-byte '
      '[case:blog.blog_connections.selectabletext_input_input.validation]',
      (t) async {
        const excerpt = 'Dawn ☀️ at the shop\nשלום — مرحبا 👩🏽‍🍳';
        final clipboard = FakeClipboard()..install(t);
        final api = linksApi(() => [publication(excerpt: excerpt)]);
        await pumpQa(
          t,
          api,
          const BlogConnectionsScreen(section: 'publications'),
        );
        expect(
          t
              .widget<SelectableText>(key('qa.blog.connections.excerpt.pub1'))
              .data,
          excerpt,
        );
        await copyAllOf(t, key('qa.blog.connections.excerpt.pub1'));
        expect(clipboard.text, excerpt);
      },
    );

    testWidgets(
      'Approve exact public copy asks first; Cancel sends nothing, Approve '
      'sends the versioned approval and the link goes live '
      '[case:blog.blog_connections.approve_exact_public_copy.action]',
      (t) async {
        var approved = false;
        final api =
            linksApi(
              () => [
                approved
                    ? publication()
                    : publication(
                        published: false,
                        joint: true,
                        myApproval: false,
                      ),
              ],
            )..on('POST /blog/publications/pub1', (_) {
              approved = true;
              return qaOk({'publication': publication()});
            });
        await pumpQa(
          t,
          api,
          const BlogConnectionsScreen(section: 'publications'),
        );
        expect(find.text(en.blogPublicationNeedsBoth), findsOneWidget);
        await tapIn(t, key('qa.blog.connections.approve_copy.pub1'));
        expect(find.text(en.blogApprovePublicCopyTitle), findsOneWidget);
        expect(find.text(en.blogApprovePublicCopyMessage), findsOneWidget);
        await answerDialog(t, en.blogApprovePublicCopyAction, cancel: true);
        expect(api.writes, isEmpty);

        await tapIn(t, key('qa.blog.connections.approve_copy.pub1'));
        await answerDialog(t, en.blogApprovePublicCopyAction);
        expect(api.writeLines, ['POST /blog/publications/pub1']);
        expect(api.writes.single.body, {
          'action': 'approve',
          'approved': true,
          'expected_version': 4,
        });
        expect(api.sent('GET', '/blog/publications'), hasLength(2));
        expect(find.text(en.blogPublicationLive), findsOneWidget);
        expect(key('qa.blog.connections.approve_copy.pub1'), findsNothing);
        expect(key('qa.blog.connections.copy_link.pub1'), findsOneWidget);
      },
    );

    testWidgets(
      'A failed approval shows the server reason, keeps the button and the '
      'retry succeeds [case:blog.blog_connections.approve_exact_public_copy.api_failure]',
      (t) async {
        var approved = false;
        final api =
            linksApi(
              () => [
                approved
                    ? publication()
                    : publication(
                        published: false,
                        joint: true,
                        myApproval: false,
                      ),
              ],
            )..fail(
              'POST /blog/publications/pub1',
              status: 409,
              message: 'The other author changed the page. Refresh first.',
            );
        await pumpQa(
          t,
          api,
          const BlogConnectionsScreen(section: 'publications'),
        );
        await tapIn(t, key('qa.blog.connections.approve_copy.pub1'));
        await answerDialog(t, en.blogApprovePublicCopyAction);
        expect(
          find.text('The other author changed the page. Refresh first.'),
          findsOneWidget,
        );
        final button = key('qa.blog.connections.approve_copy.pub1');
        expect(t.widget<FilledButton>(button).onPressed, isNotNull);

        api.on('POST /blog/publications/pub1', (_) {
          approved = true;
          return qaOk();
        });
        await tapIn(t, button);
        await answerDialog(t, en.blogApprovePublicCopyAction);
        expect(api.writes, hasLength(2));
        expect(find.text(en.blogPublicationLive), findsOneWidget);
        expect(
          find.text('The other author changed the page. Refresh first.'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Copy link copies the public page link and confirms; when the clipboard '
      'refuses, the link is shown in a dialog instead '
      '[case:blog.blog_connections.copy_link.action]',
      (t) async {
        final clipboard = FakeClipboard()..install(t);
        final api = linksApi(() => [publication()]);
        await pumpQa(
          t,
          api,
          const BlogConnectionsScreen(section: 'publications'),
        );
        await tapIn(t, key('qa.blog.connections.copy_link.pub1'));
        expect(clipboard.text, blogShareUrl('pub1'));
        expect(Uri.parse(clipboard.text!).queryParameters, {'id': 'pub1'});
        expect(qaSnackText(t), en.blogLinkCopied);

        clipboard
          ..text = null
          ..failWrites = 1;
        await tapIn(t, key('qa.blog.connections.copy_link.pub1'));
        expect(find.text(en.blogYourPublicLink), findsOneWidget);
        expect(
          t.widget<SelectableText>(key('qa.blog.public_link.text')).data,
          blogShareUrl('pub1'),
        );
        expect(api.writes, isEmpty);
      },
    );

    testWidgets(
      'Withdraw link asks first; Cancel keeps it, Withdraw deletes it and the '
      'list refreshes [case:blog.blog_connections.withdraw_link.action]',
      (t) async {
        var withdrawn = false;
        final api = linksApi(() => [if (!withdrawn) publication()])
          ..on('DELETE /blog/publications/pub1', (_) {
            withdrawn = true;
            return qaOk();
          });
        await pumpQa(
          t,
          api,
          const BlogConnectionsScreen(section: 'publications'),
        );
        await tapIn(t, key('qa.blog.connections.withdraw_link.pub1'));
        expect(find.text(en.blogWithdrawLinkTitle), findsOneWidget);
        expect(find.text(en.blogWithdrawLinkMessage), findsOneWidget);
        await answerDialog(t, en.blogWithdrawLink, cancel: true);
        expect(api.writes, isEmpty);
        expect(find.text(en.blogPublicationLive), findsOneWidget);

        await tapIn(t, key('qa.blog.connections.withdraw_link.pub1'));
        await answerDialog(t, en.blogWithdrawLink);
        expect(api.writeLines, ['DELETE /blog/publications/pub1']);
        expect(find.text(en.blogPublicationLive), findsNothing);
        expect(find.text(en.blogPublicationsEmpty), findsOneWidget);
      },
    );

    testWidgets(
      'A failed withdraw says it could not be confirmed and keeps the link '
      '[case:blog.blog_connections.withdraw_link.api_failure]',
      (t) async {
        final api = linksApi(() => [publication()])
          ..on(
            'DELETE /blog/publications/pub1',
            (_) => const QaReply(500, null),
          );
        await pumpQa(
          t,
          api,
          const BlogConnectionsScreen(section: 'publications'),
        );
        await tapIn(t, key('qa.blog.connections.withdraw_link.pub1'));
        await answerDialog(t, en.blogWithdrawLink);
        expect(api.writes, hasLength(1));
        expect(find.text(en.blogChangeUnconfirmed), findsOneWidget);
        expect(find.text(en.blogPublicationLive), findsOneWidget);
        expect(
          t
              .widget<TextButton>(key('qa.blog.connections.withdraw_link.pub1'))
              .onPressed,
          isNotNull,
        );
      },
    );
  });

  testWidgets(
    'Appeal this decision opens the appeal composer; the appeal is sent with '
    'the notice version and shows on return '
    '[case:blog.blog_connections.appeal_this_decision.action]',
    (t) async {
      var appealed = '';
      final api = QaApi()
        ..on(
          'GET /blog/notices',
          (_) => qaOk({
            'notices': [
              {
                'id': 'n1',
                'content_type': 'chapter',
                'status': 'removed',
                'decision_note': 'It shared a private address.',
                'appeal': appealed,
                'can_appeal': appealed.isEmpty,
                'version': 2,
              },
            ],
            'next_cursor': '',
          }),
        )
        ..on('POST /blog/notices/n1/appeal', (c) {
          appealed = c.body['text'] as String;
          return qaOk({
            'notice': {'id': 'n1'},
          });
        });
      await pumpQa(t, api, const BlogConnectionsScreen(section: 'notices'));
      expect(find.text('It shared a private address.'), findsOneWidget);
      await tapIn(t, key('qa.blog.connections.appeal.n1'));
      expect(find.byType(BlogTextCommandScreen), findsOneWidget);
      expect(find.text(en.blogRequestReview), findsOneWidget);
      expect(find.text(en.blogRequestReviewHelp), findsOneWidget);
      await t.enterText(find.byKey(field), 'It was a public bookshop.');
      await t.pump();
      expect(find.text(en.blogSubmitAppeal), findsOneWidget);
      await t.tap(find.byKey(submit));
      await qaSettle(t);
      expect(api.writeLines, ['POST /blog/notices/n1/appeal']);
      expect(api.writes.single.body, {
        'expected_version': 2,
        'text': 'It was a public bookshop.',
      });
      expect(find.byType(BlogTextCommandScreen), findsNothing);
      expect(find.text(en.blogYourAppeal), findsOneWidget);
      expect(find.text('It was a public bookshop.'), findsOneWidget);
      expect(key('qa.blog.connections.appeal.n1'), findsNothing);
    },
  );

  group('private exchange', () {
    /// The exchange screen opened from the hub, as members reach it.
    Future<void> openExchange(WidgetTester t, QaApi api) async {
      api.on(
        'GET /blog/responses',
        (_) => qaOk({
          'responses': [responseRow()],
          'next_cursor': '',
        }),
      );
      await pumpQa(t, api, const BlogConnectionsScreen());
      await tapIn(t, key('qa.blog.connections.open_exchange.ex1'));
      expect(find.byType(BlogExchangeScreen), findsOneWidget);
    }

    testWidgets('Refresh reloads the exchange and shows the new state '
        '[case:blog.blog_connections.refresh_2.action]', (t) async {
      var status = 'pending';
      final api = QaApi()
        ..on(
          'GET /blog/responses/ex1',
          (_) => qaOk({'response': exchange(status: status)}),
        );
      await pumpQa(t, api, const BlogExchangeScreen(id: 'ex1'));
      expect(key('qa.blog.exchange.accept'), findsOneWidget);
      status = 'accepted';
      await t.tap(key('qa.blog.exchange.refresh'));
      await qaSettle(t);
      expect(api.sent('GET', '/blog/responses/ex1'), hasLength(2));
      expect(find.text(en.blogOneStoryEach), findsOneWidget);
      expect(key('qa.blog.exchange.accept'), findsNothing);
      await done(t);
    });

    testWidgets(
      'An unavailable exchange says so and Try again reloads it '
      '[case:blog.blog_connections.this_exchange_is_no_longer_avail_retry.action]',
      (t) async {
        var fail = true;
        final api = QaApi()
          ..on(
            'GET /blog/responses/ex1',
            (_) => fail
                ? const QaReply(404, null)
                : qaOk({'response': exchange()}),
          );
        await pumpQa(t, api, const BlogExchangeScreen(id: 'ex1'));
        expect(find.text(en.blogExchangeUnavailable), findsOneWidget);
        fail = false;
        await t.tap(find.text(en.blogTryAgain));
        await qaSettle(t);
        expect(api.sent('GET', '/blog/responses/ex1'), hasLength(2));
        expect(find.text(en.blogExchangeWith('Alex')), findsOneWidget);
        await done(t);
      },
    );

    for (final row in [
      (
        'accept',
        'qa.blog.exchange.accept',
        'accepted',
        '[case:blog.blog_connections.accept_an_exchange.action]',
      ),
      (
        'decline',
        'qa.blog.exchange.decline',
        'declined',
        '[case:blog.blog_connections.decline_kindly.action]',
      ),
    ]) {
      testWidgets(
        'The ${row.$1} button sends one versioned command and the exchange '
        'shows its new state ${row.$4}',
        (t) async {
          var status = 'pending';
          final api = QaApi()
            ..on(
              'GET /blog/responses/ex1',
              (_) => qaOk({'response': exchange(status: status)}),
            )
            ..on('POST /blog/responses/ex1', (c) {
              status = row.$3;
              return QaReply(200, {
                'response': exchange(status: row.$3),
              }, delay: const Duration(milliseconds: 200));
            });
          await pumpQa(t, api, const BlogExchangeScreen(id: 'ex1'));
          expect(find.text(en.blogAcceptExchange), findsOneWidget);
          expect(find.text(en.blogDeclineKindly), findsOneWidget);
          await t.tap(key(row.$2));
          await t.pump();
          expect(
            t.widget<ButtonStyleButton>(key(row.$2)).onPressed,
            isNull,
            reason: 'busy',
          );
          await t.tap(key(row.$2), warnIfMissed: false);
          await qaSettle(t);
          expect(api.writeLines, ['POST /blog/responses/ex1']);
          expect(api.writes.single.body, {
            'action': row.$1,
            'expected_version': 3,
          });
          expect(api.sent('GET', '/blog/responses/ex1'), hasLength(2));
          expect(key('qa.blog.exchange.accept'), findsNothing);
          expect(key('qa.blog.exchange.decline'), findsNothing);
          if (row.$1 == 'accept') {
            expect(find.text(en.blogOneStoryEach), findsOneWidget);
            expect(key('qa.blog.exchange.contribute'), findsOneWidget);
          } else {
            expect(find.text(en.blogExchangeClosedNote), findsOneWidget);
          }
          await done(t);
        },
      );
    }

    for (final row in [
      (
        'accept',
        'qa.blog.exchange.accept',
        '[case:blog.blog_connections.accept_an_exchange.api_failure]',
      ),
      (
        'decline',
        'qa.blog.exchange.decline',
        '[case:blog.blog_connections.decline_kindly.api_failure]',
      ),
    ]) {
      testWidgets(
        'A failed ${row.$1} explains, keeps the exchange pending with both '
        'buttons usable, and the retry is a single request ${row.$3}',
        (t) async {
          var status = 'pending';
          final api = QaApi()
            ..on(
              'GET /blog/responses/ex1',
              (_) => qaOk({'response': exchange(status: status)}),
            )
            ..fail(
              'POST /blog/responses/ex1',
              status: 409,
              message: 'This exchange changed. Refresh and try again.',
            );
          await pumpQa(t, api, const BlogExchangeScreen(id: 'ex1'));
          await t.tap(key(row.$2));
          await qaSettle(t);
          expect(
            find.text('This exchange changed. Refresh and try again.'),
            findsOneWidget,
          );
          for (final k in [
            'qa.blog.exchange.accept',
            'qa.blog.exchange.decline',
          ]) {
            expect(t.widget<ButtonStyleButton>(key(k)).onPressed, isNotNull);
          }

          api.on('POST /blog/responses/ex1', (_) => const QaReply(500, null));
          await t.tap(key(row.$2));
          await qaSettle(t);
          expect(find.text(en.blogExchangeChangeFailed), findsOneWidget);

          api.on('POST /blog/responses/ex1', (_) {
            status = row.$1 == 'accept' ? 'accepted' : 'declined';
            return qaOk();
          });
          await t.tap(key(row.$2));
          await qaSettle(t);
          expect(api.writes, hasLength(3));
          expect(api.writes.map((c) => c.body['action']).toSet(), {row.$1});
          expect(find.text(en.blogExchangeChangeFailed), findsNothing);
          expect(key(row.$2), findsNothing);
          await done(t);
        },
      );
    }

    testWidgets(
      'Add my contribution opens the contribution composer; the words are '
      'sent as a versioned command and show as saved on return '
      '[case:blog.blog_connections.add_my_contribution.action]',
      (t) async {
        var mine = '';
        final api = QaApi()
          ..on(
            'GET /blog/responses/ex1',
            (_) =>
                qaOk({'response': exchange(status: 'accepted', myStory: mine)}),
          )
          ..on('POST /blog/responses/ex1', (c) {
            mine = c.body['text'] as String;
            return qaOk({'response': exchange(status: 'accepted')});
          });
        await pumpQa(t, api, const BlogExchangeScreen(id: 'ex1'));
        await tapIn(t, key('qa.blog.exchange.contribute'));
        expect(find.byType(BlogTextCommandScreen), findsOneWidget);
        expect(find.text(en.blogYourSideTitle), findsOneWidget);
        expect(find.text(en.blogYourSideHelp), findsOneWidget);
        expect(find.text(en.blogSubmitContribution), findsOneWidget);
        await t.enterText(find.byKey(field), 'The day the shop cat chose me.');
        await t.pump();
        expect(find.text('30/1000'), findsOneWidget);
        await t.tap(find.byKey(submit));
        await qaSettle(t);
        expect(api.writeLines, ['POST /blog/responses/ex1']);
        expect(api.writes.single.body, {
          'action': 'contribute',
          'expected_version': 3,
          'text': 'The day the shop cat chose me.',
        });
        expect(find.byType(BlogTextCommandScreen), findsNothing);
        expect(find.text(en.blogYourContribution), findsOneWidget);
        expect(find.text('The day the shop cat chose me.'), findsOneWidget);
        expect(find.text(en.blogContributionSaved), findsOneWidget);
        expect(key('qa.blog.exchange.contribute'), findsNothing);
        await done(t);
      },
    );

    for (final row in [
      (
        'qa.blog.exchange.my_story',
        'My words, kept.',
        '[case:blog.blog_connections.selectabletext_input_input_2.action]',
      ),
      (
        'qa.blog.exchange.partner_story',
        'Their words, revealed.',
        '[case:blog.blog_connections.selectabletext_input_input_3.action]',
      ),
    ]) {
      testWidgets(
        'A contribution can be selected and copied exactly ${row.$3}',
        (t) async {
          final clipboard = FakeClipboard()..install(t);
          final api = QaApi()
            ..json('GET /blog/responses/ex1', {
              'response': exchange(
                status: 'accepted',
                myStory: 'My words, kept.',
                partnerStory: 'Their words, revealed.',
                revealed: true,
              ),
            });
          await pumpQa(t, api, const BlogExchangeScreen(id: 'ex1'));
          expect(find.text(en.blogPartnerContribution('Alex')), findsOneWidget);
          await copyAllOf(t, key(row.$1));
          expect(clipboard.text, row.$2);
          expect(api.writes, isEmpty);
          await done(t);
        },
      );
    }

    for (final row in [
      (
        'qa.blog.exchange.my_story',
        'Mine 🌿\nשלום — first light',
        '[case:blog.blog_connections.selectabletext_input_input_2.validation]',
      ),
      (
        'qa.blog.exchange.partner_story',
        'مرحبا — café 👩🏽‍🍳\n  two spaces',
        '[case:blog.blog_connections.selectabletext_input_input_3.validation]',
      ),
    ]) {
      testWidgets('Emoji, RTL and line breaks in a contribution show and copy '
          'byte-for-byte ${row.$3}', (t) async {
        final clipboard = FakeClipboard()..install(t);
        final api = QaApi()
          ..json('GET /blog/responses/ex1', {
            'response': exchange(
              status: 'accepted',
              myStory: row.$1.endsWith('my_story') ? row.$2 : 'x',
              partnerStory: row.$1.endsWith('partner_story') ? row.$2 : 'y',
              revealed: true,
            ),
          });
        await pumpQa(t, api, const BlogExchangeScreen(id: 'ex1'));
        expect(t.widget<SelectableText>(key(row.$1)).data, row.$2);
        await copyAllOf(t, key(row.$1));
        expect(clipboard.text, row.$2);
        await done(t);
      });
    }

    testWidgets(
      'Shape a date together opens the date plan sheet for this match, '
      'prefilled, and the plan is linked to this exchange '
      '[case:blog.blog_connections.shape_a_date_together.action]',
      (t) async {
        final start = DateTime.now().toUtc().add(const Duration(days: 2));
        final api = QaApi()
          ..json('GET /blog/responses/ex1', {
            'response': exchange(
              status: 'accepted',
              myStory: 'Mine',
              partnerStory: 'Theirs',
              revealed: true,
              canPlan: true,
              matchId: 'm1',
            ),
          })
          ..json('GET /matches/m1/plans', {
            'plan': null,
            'history': <dynamic>[],
            'share_groups': <dynamic>[],
            'can_propose': true,
          })
          ..on(
            'POST /matches/m1/plans',
            (c) => qaOk({
              'plan': {
                'id': 'plan1',
                'match_id': 'm1',
                'proposer_user_id': 'me',
                'invitee_user_id': 'alex',
                'status': 'proposed',
                'window_start': start.toIso8601String(),
                'window_end': start
                    .add(const Duration(hours: 2))
                    .toIso8601String(),
                'venue_category': 'coffee',
                'budget_preference': 'flexible',
                'viewer_role': 'proposer',
                'partner_user_id': 'alex',
                'partner_name': 'Alex',
                'next_action': 'wait',
                'lock_version': 1,
              },
            }),
          );
        await pumpQa(
          t,
          api,
          const BlogExchangeScreen(id: 'ex1'),
          extra: [
            datingConnectionProvider(
              'm1',
            ).overrideWith((_) => Stream.value({'overlap': <dynamic>[]})),
          ],
        );
        await tapIn(t, key('qa.blog.exchange.shape_date'));
        expect(find.text(en.planProposeHeadline), findsOneWidget);
        expect(find.text(en.planProposeLead('Alex')), findsOneWidget);
        expect(
          t.widget<TextField>(key('qa.plan.note')).controller!.text,
          en.blogInspiredNote,
        );
        expect(api.writes, isEmpty, reason: 'opening sends nothing');
        await t.ensureVisible(key('qa.plan.submit'));
        await t.pump();
        await t.tap(key('qa.plan.submit'));
        await qaSettle(t);
        final plan = api.sent('POST', '/matches/m1/plans').single.body;
        expect(plan['source_blog_response_id'], 'ex1');
        expect(plan['note'], 'Inspired by our Chapter exchange.');
        expect(find.text(en.planProposeHeadline), findsNothing);
        expect(find.byType(BlogExchangeScreen), findsOneWidget);
        await done(t);
      },
    );

    testWidgets('Try First Chapter Studio opens the studio for this match '
        '[case:blog.blog_connections.try_first_chapter_studio.action]', (
      t,
    ) async {
      final api = QaApi()
        ..json('GET /blog/responses/ex1', {
          'response': exchange(
            status: 'accepted',
            myStory: 'Mine',
            partnerStory: 'Theirs',
            revealed: true,
            matchId: 'm1',
          ),
        });
      await pumpQa(t, api, const BlogExchangeScreen(id: 'ex1'));
      expect(find.text(en.blogDatePlanningUnavailable), findsOneWidget);
      await tapIn(t, key('qa.blog.exchange.studio'));
      final studio = t.widget<ChapterStudioScreen>(
        find.byType(ChapterStudioScreen),
      );
      expect(studio.matchId, 'm1');
      expect(studio.partnerName, 'Alex');
      expect(api.sent('GET', '/matches/m1/chapter'), hasLength(1));
      await done(t);
    });

    testWidgets(
      'Propose a shared journal page loads the chapter and opens the joint '
      'preview with both contributions '
      '[case:blog.blog_connections.propose_a_shared_journal_page.action]',
      (t) async {
        final api = QaApi()
          ..json('GET /blog/responses/ex1', {
            'response': exchange(
              status: 'accepted',
              incoming: true,
              myStory: 'My half',
              partnerStory: 'Their half',
              revealed: true,
              canJointShare: true,
            ),
          })
          ..json('GET /blog/posts/post1', {
            'post': {
              'id': 'post1',
              'author_id': 'me',
              'author_name': 'Me',
              'title': 'A little Sunday',
              'body': 'Coffee.',
              'audience': 'community',
              'invitation': 'your_version',
              'version': 1,
              'photos': <dynamic>[],
            },
          });
        await pumpQa(t, api, const BlogExchangeScreen(id: 'ex1'));
        await tapIn(t, key('qa.blog.exchange.journal_page'));
        expect(api.sent('GET', '/blog/posts/post1'), hasLength(1));
        final share = t.widget<BlogShareScreen>(find.byType(BlogShareScreen));
        expect(share.post.id, 'post1');
        expect(share.exchange?['id'], 'ex1');
        expect(find.text(en.blogSharedJournalPage), findsOneWidget);
        expect(
          t.widget<SelectableText>(key('qa.blog.share.preview')).data,
          'My half\n\nTheir half',
        );
        expect(api.writes, isEmpty);
        await done(t);
      },
    );

    testWidgets(
      'When the source chapter is gone, the journal page explains and stays '
      'on the exchange [case:blog.blog_connections.propose_a_shared_journal_page.api_failure]',
      (t) async {
        final api = QaApi()
          ..json('GET /blog/responses/ex1', {
            'response': exchange(
              status: 'accepted',
              myStory: 'My half',
              partnerStory: 'Their half',
              revealed: true,
              canJointShare: true,
            ),
          })
          ..on('GET /blog/posts/post1', (_) => const QaReply(404, null));
        await pumpQa(t, api, const BlogExchangeScreen(id: 'ex1'));
        await tapIn(t, key('qa.blog.exchange.journal_page'));
        expect(find.byType(BlogShareScreen), findsNothing);
        expect(find.text(en.blogSourceUnavailable), findsOneWidget);
        await done(t);
      },
    );

    testWidgets(
      'Withdraw exchange asks first; Cancel keeps it, Withdraw deletes it, '
      'closes the exchange and the hub no longer lists it '
      '[case:blog.blog_connections.withdraw_exchange.action]',
      (t) async {
        var withdrawn = false;
        final api = QaApi()
          ..json('GET /blog/responses/ex1', {'response': exchange()})
          ..on('DELETE /blog/responses/ex1', (_) {
            withdrawn = true;
            return qaOk();
          });
        await openExchange(t, api);
        api.on(
          'GET /blog/responses',
          (_) => qaOk({
            'responses': [if (!withdrawn) responseRow()],
            'next_cursor': '',
          }),
        );
        await tapIn(t, key('qa.blog.exchange.withdraw'));
        expect(find.text(en.blogWithdrawExchangeTitle), findsOneWidget);
        expect(find.text(en.blogWithdrawExchangeMessage), findsOneWidget);
        await answerDialog(t, en.blogWithdrawExchange, cancel: true);
        expect(api.writes, isEmpty);
        expect(find.byType(BlogExchangeScreen), findsOneWidget);

        await tapIn(t, key('qa.blog.exchange.withdraw'));
        await answerDialog(t, en.blogWithdrawExchange);
        expect(api.writeLines, ['DELETE /blog/responses/ex1']);
        expect(find.byType(BlogExchangeScreen), findsNothing);
        expect(find.byType(BlogConnectionsScreen), findsOneWidget);
        expect(api.sent('GET', '/blog/responses'), hasLength(2));
        expect(find.text(en.blogResponsesEmpty), findsOneWidget);
      },
    );

    testWidgets(
      'A failed withdraw explains, stays on the exchange, and the retry '
      'closes it [case:blog.blog_connections.withdraw_exchange.api_failure]',
      (t) async {
        final api = QaApi()
          ..json('GET /blog/responses/ex1', {'response': exchange()})
          ..fail(
            'DELETE /blog/responses/ex1',
            message: 'Could not withdraw right now.',
          );
        await openExchange(t, api);
        await tapIn(t, key('qa.blog.exchange.withdraw'));
        await answerDialog(t, en.blogWithdrawExchange);
        expect(find.text('Could not withdraw right now.'), findsOneWidget);
        expect(find.byType(BlogExchangeScreen), findsOneWidget);
        expect(
          t.widget<TextButton>(key('qa.blog.exchange.withdraw')).onPressed,
          isNotNull,
        );

        api.json('DELETE /blog/responses/ex1', <String, dynamic>{});
        await tapIn(t, key('qa.blog.exchange.withdraw'));
        await answerDialog(t, en.blogWithdrawExchange);
        expect(api.writes, hasLength(2));
        expect(find.byType(BlogExchangeScreen), findsNothing);
      },
    );

    Future<void> fillReport(WidgetTester t) async {
      await t.tap(find.text(en.reportReasonInappropriate));
      await qaSettle(t);
      await t.tap(find.text(en.reportReasonFraud).last);
      await qaSettle(t);
      await t.enterText(
        find.widgetWithText(TextField, en.reportDescriptionLabel),
        'Asked me for money',
      );
      await t.pump();
    }

    testWidgets(
      'regression: Report exchange opens the report sheet, sends the reason '
      'and details for this exchange, closes and confirms '
      '[case:blog.blog_connections.report_exchange.action] '
      '[case:blog.blog_connections.submit_report_onsubmit.action]',
      (t) async {
        final api = QaApi()
          ..json('GET /blog/responses/ex1', {'response': exchange()})
          ..json('POST /blog/reports/response/ex1', {
            'report': {'id': 'r1'},
          });
        await pumpQa(t, api, const BlogExchangeScreen(id: 'ex1'));
        await tapIn(t, key('qa.blog.exchange.report'));
        expect(find.text(en.reportSheetTitle), findsOneWidget);
        expect(api.writes, isEmpty, reason: 'opening sends nothing');
        await fillReport(t);
        await t.tap(find.text(en.reportSubmit));
        await qaSettle(t);
        expect(api.writeLines, ['POST /blog/reports/response/ex1']);
        expect(api.writes.single.body, {
          'reason': 'fraud',
          'description': 'Asked me for money',
        });
        expect(find.text(en.reportSheetTitle), findsNothing);
        expect(qaSnackText(t), en.communityReportSubmitted);
        expect(find.byType(BlogExchangeScreen), findsOneWidget);
        await done(t);
      },
    );

    testWidgets(
      'A failed report keeps the sheet and the details, explains, and the '
      'retry is the only other request '
      '[case:blog.blog_connections.report_exchange.api_failure] '
      '[case:blog.blog_connections.submit_report_onsubmit.api_failure]',
      (t) async {
        final api = QaApi()
          ..json('GET /blog/responses/ex1', {'response': exchange()})
          ..fail('POST /blog/reports/response/ex1');
        await pumpQa(t, api, const BlogExchangeScreen(id: 'ex1'));
        await tapIn(t, key('qa.blog.exchange.report'));
        await fillReport(t);
        await t.tap(find.text(en.reportSubmit));
        await qaSettle(t);
        expect(api.writes, hasLength(1));
        expect(find.text(en.reportSheetTitle), findsOneWidget);
        expect(qaSnackText(t), en.reportSubmitFailed);
        expect(find.text('Asked me for money'), findsOneWidget);

        api.json('POST /blog/reports/response/ex1', {
          'report': {'id': 'r1'},
        });
        await t.tap(find.text(en.reportSubmit));
        await qaSettle(t);
        expect(api.writes, hasLength(2));
        expect(api.writes.last.body['reason'], 'fraud');
        expect(find.text(en.reportSheetTitle), findsNothing);
        expect(qaSnackText(t), en.communityReportSubmitted);
        await done(t);
      },
    );

    testWidgets(
      'Block member asks first; Cancel sends nothing, Block blocks the partner, '
      'closes the exchange and refreshes the hub '
      '[case:blog.blog_connections.block_member.action]',
      (t) async {
        var blocked = false;
        final api = QaApi()
          ..json('GET /blog/responses/ex1', {'response': exchange()})
          ..on('POST /safety/block', (_) {
            blocked = true;
            return qaOk();
          });
        await openExchange(t, api);
        api.on(
          'GET /blog/responses',
          (_) => qaOk({
            'responses': [if (!blocked) responseRow()],
            'next_cursor': '',
          }),
        );
        await tapIn(t, key('qa.blog.exchange.block'));
        expect(find.text(en.blogBlockTitle), findsOneWidget);
        expect(find.text(en.blogBlockMessageExchange), findsOneWidget);
        await answerDialog(t, en.blogBlockMember, cancel: true);
        expect(api.writes, isEmpty);

        await tapIn(t, key('qa.blog.exchange.block'));
        await answerDialog(t, en.blogBlockMember);
        expect(api.writeLines, ['POST /safety/block']);
        expect(api.writes.single.body, {
          'user_id': 'me',
          'blocked_user_id': 'alex',
        });
        expect(find.byType(BlogExchangeScreen), findsNothing);
        expect(api.sent('GET', '/blog/responses'), hasLength(2));
        expect(find.text('Alex'), findsNothing);
      },
    );

    testWidgets(
      'A failed block explains, stays on the exchange, and the retry works '
      '[case:blog.blog_connections.block_member.api_failure]',
      (t) async {
        final api = QaApi()
          ..json('GET /blog/responses/ex1', {'response': exchange()})
          ..fail('POST /safety/block');
        await openExchange(t, api);
        await tapIn(t, key('qa.blog.exchange.block'));
        await answerDialog(t, en.blogBlockMember);
        expect(find.text(en.blogBlockFailed), findsOneWidget);
        expect(find.byType(BlogExchangeScreen), findsOneWidget);

        api.json('POST /safety/block', <String, dynamic>{});
        await tapIn(t, key('qa.blog.exchange.block'));
        await answerDialog(t, en.blogBlockMember);
        expect(api.sent('POST', '/safety/block'), hasLength(2));
        expect(find.byType(BlogExchangeScreen), findsNothing);
      },
    );
  });

  testWidgets(
    'Connections, the exchange and the composer render translated in every '
    'language without overflow [case:blog.blog_connections.l10n]',
    (t) async {
      for (final locale in qaLocales) {
        final l10n = qaL10n(locale);
        final api = QaApi()
          ..json('GET /blog/responses', {
            'responses': [responseRow()],
            'next_cursor': 'c2',
          })
          ..json('GET /blog/responses/ex1', {
            'response': exchange(
              status: 'accepted',
              myStory: 'Mine',
              partnerStory: 'Theirs',
              revealed: true,
              canPlan: true,
              canJointShare: true,
              matchId: 'm1',
            ),
          });
        await pumpQa(
          t,
          api,
          const BlogConnectionsScreen(),
          locale: locale,
          size: const Size(360, 800),
        );
        expect(t.takeException(), isNull, reason: '$locale hub');
        expect(find.text(l10n.blogConnectionsTitle), findsOneWidget);
        expect(find.text(l10n.blogPrivateResponses), findsOneWidget);
        expect(find.text(l10n.blogOpenExchange), findsOneWidget);
        expect(find.text(l10n.blogMore), findsOneWidget);

        await tapIn(t, key('qa.blog.connections.open_exchange.ex1'));
        expect(t.takeException(), isNull, reason: '$locale exchange');
        expect(find.text(l10n.blogExchangeTitle), findsOneWidget);
        expect(find.text(l10n.blogOneStoryEach), findsOneWidget);
        await t.scrollUntilVisible(
          key('qa.blog.exchange.block'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(l10n.blogBlockMember), findsOneWidget);
        expect(t.takeException(), isNull, reason: '$locale exchange actions');
        await t.pumpWidget(const SizedBox());

        await pumpQa(
          t,
          QaApi(),
          composer,
          locale: locale,
          size: const Size(360, 800),
        );
        expect(t.takeException(), isNull, reason: '$locale composer');
        expect(find.text(l10n.blogOwnWordsLabel), findsOneWidget);
        await t.pumpWidget(const SizedBox());
      }
    },
  );
}
