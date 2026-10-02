// Control-level tests for the public copy of a chapter (blog_sharing.dart):
// consent, the excerpt and photos that go public, the request that creates
// the link, copying it, and managing links afterwards.
//
// There is no OS share sheet in this flow: the link is copied to the
// clipboard (or shown in a dialog when the clipboard refuses).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/blog/blog_connections.dart';
import 'package:verified_dating_app/features/blog/blog_data.dart';
import 'package:verified_dating_app/features/blog/blog_sharing.dart';

import '../../support/qa_api.dart';

final en = qaL10n(const Locale('en'));
final uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

const body = 'Coffee and a bookshop. The owner knew every first line.';

BlogPost post({List<Map<String, dynamic>> photos = const []}) =>
    BlogPost.fromJson({
      'id': 'post1',
      'author_id': 'me',
      'author_name': 'Me',
      'title': 'A little Sunday',
      'body': body,
      'audience': 'community',
      'invitation': 'your_version',
      'version': 4,
      'photos': photos,
    });

/// A recording BFF that accepts publications and lists them afterwards.
QaApi shareApi() => QaApi()
  ..on(
    'POST /blog/publications',
    (c) => qaOk({
      'publication': {'id': c.body['id']},
    }),
  )
  ..on('GET /blog/posts/post1/photos/*', (_) => qaError(404))
  ..json('GET /blog/publications', {
    'publications': [
      {
        'id': 'pub1',
        'title': 'A little Sunday',
        'excerpt': body,
        'published': true,
        'joint': false,
        'moderation_state': 'active',
        'version': 1,
      },
    ],
    'next_cursor': '',
  });

Finder key(String k) => find.byKey(ValueKey(k));

/// Scrolls [k] into view in the share screen and taps it.
Future<void> tapKey(WidgetTester t, String k) async {
  await t.scrollUntilVisible(
    key(k),
    150,
    scrollable: find.byType(Scrollable).first,
  );
  await t.ensureVisible(key(k));
  await t.pump();
  await t.tap(key(k));
  await qaSettle(t);
}

bool createEnabled(WidgetTester t) =>
    t.widget<FilledButton>(key('qa.blog.share.create')).onPressed != null;

bool approvedBox(WidgetTester t) =>
    t.widget<CheckboxListTile>(key('qa.blog.share.approve')).value!;

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

/// Approves and creates the public link; returns the publication id sent.
Future<String> create(WidgetTester t, QaApi api) async {
  await tapKey(t, 'qa.blog.share.approve');
  await tapKey(t, 'qa.blog.share.create');
  return api.sent('POST', '/blog/publications').last.body['id'] as String;
}

void main() {
  testWidgets(
    'Consent starts unchecked; ticking it enables Create, unticking disables '
    'it again, and nothing is sent [case:blog.blog_sharing.i_approve_this_exact_public_copy.action]',
    (t) async {
      final api = shareApi();
      await pumpQa(t, api, BlogShareScreen(post: post()));
      expect(approvedBox(t), isFalse);
      expect(createEnabled(t), isFalse);
      expect(find.text(en.blogApproveCopyNote), findsOneWidget);
      await tapKey(t, 'qa.blog.share.approve');
      expect(approvedBox(t), isTrue);
      expect(createEnabled(t), isTrue);
      await tapKey(t, 'qa.blog.share.approve');
      expect(approvedBox(t), isFalse);
      expect(createEnabled(t), isFalse);
      expect(api.writes, isEmpty);
    },
  );

  testWidgets(
    'Create public link sends exactly the approved copy once, then shows it '
    'read-only with Copy and Manage [case:blog.blog_sharing.create_public_link.action]',
    (t) async {
      final api = shareApi()
        ..on(
          'POST /blog/publications',
          (c) => QaReply(200, {
            'publication': {'id': c.body['id']},
          }, delay: const Duration(milliseconds: 300)),
        );
      await pumpQa(t, api, BlogShareScreen(post: post()));
      await tapKey(t, 'qa.blog.share.approve');
      await t.ensureVisible(key('qa.blog.share.create'));
      await t.pump();
      await t.tap(key('qa.blog.share.create'));
      await t.pump();
      expect(find.text(en.blogSaving), findsOneWidget);
      expect(createEnabled(t), isFalse);
      await t.tap(key('qa.blog.share.create'), warnIfMissed: false);
      await qaSettle(t);

      final sent = api.sent('POST', '/blog/publications');
      expect(sent, hasLength(1));
      final id = sent.single.body['id'] as String;
      expect(id, matches(uuid));
      expect(sent.single.body, {
        'id': id,
        'post_id': 'post1',
        'expected_version': 4,
        'approved': true,
        'excerpt': body,
        'photo_ids': <String>[],
      });
      expect(find.text(en.blogPublicCopyReady), findsOneWidget);
      expect(key('qa.blog.share.create'), findsNothing);
      expect(key('qa.blog.share.excerpt'), findsNothing);
      expect(t.widget<SelectableText>(key('qa.blog.share.preview')).data, body);
      expect(key('qa.blog.share.copy_link'), findsOneWidget);
      expect(key('qa.blog.share.manage_links'), findsOneWidget);
    },
  );

  testWidgets(
    'A failed create keeps the exact preview and consent, says what happened, '
    're-enables Create, and the retry reuses the same id '
    '[case:blog.blog_sharing.create_public_link.api_failure]',
    (t) async {
      final api = shareApi()
        ..fail(
          'POST /blog/publications',
          status: 409,
          message: 'The source changed. Your words are still here.',
        );
      await pumpQa(t, api, BlogShareScreen(post: post()));
      await create(t, api);
      expect(
        find.text('The source changed. Your words are still here.'),
        findsOneWidget,
      );
      expect(find.text(en.blogPublicCopyReady), findsNothing);
      expect(find.text(en.blogCreatePublicLink), findsOneWidget);
      expect(createEnabled(t), isTrue);
      expect(approvedBox(t), isTrue);
      expect(
        t.widget<TextField>(key('qa.blog.share.excerpt')).controller!.text,
        body,
      );

      api.on('POST /blog/publications', (_) => const QaReply(500, null));
      await tapKey(t, 'qa.blog.share.create');
      expect(find.text(en.blogShareUnconfirmed), findsOneWidget);

      api.on(
        'POST /blog/publications',
        (c) => qaOk({
          'publication': {'id': c.body['id']},
        }),
      );
      await tapKey(t, 'qa.blog.share.create');
      final sent = api.sent('POST', '/blog/publications');
      expect(sent, hasLength(3));
      expect(sent.map((c) => c.body['id']).toSet(), hasLength(1));
      expect(find.text(en.blogPublicCopyReady), findsOneWidget);
    },
  );

  testWidgets(
    'Editing the excerpt withdraws consent; the edited words are what goes '
    'public [case:blog.blog_sharing.exact_excerpt_from_your_chapter.action]',
    (t) async {
      final api = shareApi();
      await pumpQa(t, api, BlogShareScreen(post: post()));
      expect(find.text(en.blogExcerptLabel), findsOneWidget);
      await tapKey(t, 'qa.blog.share.approve');
      await t.enterText(key('qa.blog.share.excerpt'), 'Coffee and a bookshop.');
      await t.pump();
      expect(approvedBox(t), isFalse);
      expect(createEnabled(t), isFalse);
      expect(api.writes, isEmpty);
      await create(t, api);
      expect(api.writes.single.body['excerpt'], 'Coffee and a bookshop.');
    },
  );

  testWidgets(
    'regression: an empty or blank excerpt cannot be published even with '
    'consent; the 1,500 limit holds and unicode is sent byte-for-byte '
    '[case:blog.blog_sharing.exact_excerpt_from_your_chapter.validation]',
    (t) async {
      final api = shareApi();
      await pumpQa(t, api, BlogShareScreen(post: post()));
      for (final blank in ['', '   \n  ']) {
        await t.enterText(key('qa.blog.share.excerpt'), blank);
        await t.pump();
        await tapKey(t, 'qa.blog.share.approve');
        expect(approvedBox(t), isTrue);
        expect(createEnabled(t), isFalse, reason: 'blank: "$blank"');
        await t.tap(key('qa.blog.share.create'), warnIfMissed: false);
        await qaSettle(t);
        expect(api.writes, isEmpty);
      }

      await t.enterText(key('qa.blog.share.excerpt'), 'x' * 1501);
      await t.pump();
      expect(
        t.widget<TextField>(key('qa.blog.share.excerpt')).controller!.text,
        'x' * 1500,
      );

      const unicode = 'Café ☕️ — שלום, مرحبا 👩🏽‍🍳';
      await t.enterText(key('qa.blog.share.excerpt'), '  $unicode \n');
      await t.pump();
      await create(t, api);
      expect(api.writes.single.body['excerpt'], unicode);
    },
  );

  testWidgets(
    'Ticking a photo withdraws consent and adds exactly that photo; '
    'unticking removes it [case:blog.blog_sharing.include_description.action]',
    (t) async {
      final api = shareApi();
      await pumpQa(
        t,
        api,
        BlogShareScreen(
          post: post(
            photos: [
              {'id': 'ph1', 'alt_text': 'Window seat at dawn'},
              {'id': 'ph2', 'alt_text': 'The shop cat'},
            ],
          ),
        ),
      );
      expect(find.text('Include: Window seat at dawn'), findsOneWidget);
      await tapKey(t, 'qa.blog.share.approve');
      await tapKey(t, 'qa.blog.share.photo.ph1');
      expect(
        t.widget<CheckboxListTile>(key('qa.blog.share.photo.ph1')).value,
        isTrue,
      );
      expect(approvedBox(t), isFalse, reason: 'consent covers the exact copy');
      await tapKey(t, 'qa.blog.share.photo.ph2');
      await tapKey(t, 'qa.blog.share.photo.ph2');
      await create(t, api);
      expect(api.writes.single.body['photo_ids'], ['ph1']);
    },
  );

  testWidgets(
    'Copy public link copies the link of exactly the publication just created '
    '[case:blog.blog_sharing.copy_public_link.action]',
    (t) async {
      final clipboard = FakeClipboard()..install(t);
      final api = shareApi();
      await pumpQa(t, api, BlogShareScreen(post: post()));
      final id = await create(t, api);
      await tapKey(t, 'qa.blog.share.copy_link');
      expect(clipboard.text, blogShareUrl(id));
      final url = Uri.parse(clipboard.text!);
      expect(url.path, '/story.html');
      expect(url.queryParameters, {'id': id});
      expect(qaSnackText(t), en.blogLinkCopied);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'When the clipboard refuses, the link is shown in a "Your public link" '
    'dialog instead of failing silently [case:blog.blog_sharing.your_public_link.action]',
    (t) async {
      final clipboard = FakeClipboard()..install(t);
      final api = shareApi();
      await pumpQa(t, api, BlogShareScreen(post: post()));
      final id = await create(t, api);
      clipboard.failWrites = 1;
      await tapKey(t, 'qa.blog.share.copy_link');
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(en.blogYourPublicLink), findsOneWidget);
      expect(
        t.widget<SelectableText>(key('qa.blog.public_link.text')).data,
        blogShareUrl(id),
      );
      expect(qaSnackText(t), isNull, reason: 'no false "copied"');
      expect(clipboard.text, isNull);
    },
  );

  testWidgets('The link in the dialog can be selected and copied by hand '
      '[case:blog.blog_sharing.selectabletext_input_input.action]', (t) async {
    final clipboard = FakeClipboard()..install(t);
    final api = shareApi();
    await pumpQa(t, api, BlogShareScreen(post: post()));
    final id = await create(t, api);
    clipboard.failWrites = 1;
    await tapKey(t, 'qa.blog.share.copy_link');
    await copyAllOf(t, key('qa.blog.public_link.text'));
    expect(clipboard.text, blogShareUrl(id));
  });

  testWidgets('The dialog link is byte-for-byte the public page contract: '
      '/story.html?id=<the new publication id> '
      '[case:blog.blog_sharing.selectabletext_input_input.validation]', (
    t,
  ) async {
    final clipboard = FakeClipboard()..install(t);
    final api = shareApi();
    await pumpQa(t, api, BlogShareScreen(post: post()));
    final id = await create(t, api);
    clipboard.failWrites = 1;
    await tapKey(t, 'qa.blog.share.copy_link');
    final shown = t
        .widget<SelectableText>(key('qa.blog.public_link.text'))
        .data!;
    expect(shown, 'http://127.0.0.1:4190/story.html?id=$id');
    expect(shown.trim(), shown);
  });

  group('shared journal page (joint)', () {
    Map<String, dynamic> exchange({
      bool incoming = true,
      String mine = 'One voice',
      String theirs = 'Another voice',
    }) => {
      'id': 'ex1',
      'incoming': incoming,
      'my_story': mine,
      'partner_story': theirs,
    };

    testWidgets(
      'Both contributions show read-only, author first, and can be copied '
      '[case:blog.blog_sharing.selectabletext_input_input_2.action]',
      (t) async {
        final clipboard = FakeClipboard()..install(t);
        final api = shareApi();
        await pumpQa(
          t,
          api,
          BlogShareScreen(post: post(), exchange: exchange(incoming: false)),
        );
        expect(find.text(en.blogSharedJournalPage), findsOneWidget);
        expect(key('qa.blog.share.excerpt'), findsNothing);
        final preview = key('qa.blog.share.preview');
        expect(
          t.widget<SelectableText>(preview).data,
          'Another voice\n\nOne voice',
        );
        await copyAllOf(t, preview);
        expect(clipboard.text, 'Another voice\n\nOne voice');
        expect(api.writes, isEmpty);
      },
    );

    testWidgets(
      'Emoji and RTL contributions are shown and sent byte-for-byte with the '
      'exchange id [case:blog.blog_sharing.selectabletext_input_input_2.validation]',
      (t) async {
        const mine = 'שלום 🌿 first light';
        const theirs = 'مرحبا — café 👩🏽‍🍳';
        final api = shareApi();
        await pumpQa(
          t,
          api,
          BlogShareScreen(
            post: post(),
            exchange: exchange(mine: mine, theirs: theirs),
          ),
        );
        expect(
          t.widget<SelectableText>(key('qa.blog.share.preview')).data,
          '$mine\n\n$theirs',
        );
        await tapKey(t, 'qa.blog.share.approve');
        expect(find.text(en.blogRequestOtherApproval), findsOneWidget);
        await tapKey(t, 'qa.blog.share.create');
        final sent = api.writes.single.body;
        expect(sent['response_id'], 'ex1');
        expect(sent['excerpt'], '$mine\n\n$theirs');
        expect(find.text(en.blogJointApprovalRecorded), findsOneWidget);
        expect(key('qa.blog.share.copy_link'), findsNothing);
      },
    );
  });

  testWidgets('Manage shared links opens Shared links with the new copy listed '
      '[case:blog.blog_sharing.manage_shared_links.action]', (t) async {
    final api = shareApi();
    await pumpQa(t, api, BlogShareScreen(post: post()));
    await create(t, api);
    await tapKey(t, 'qa.blog.share.manage_links');
    expect(find.byType(BlogConnectionsScreen), findsOneWidget);
    expect(api.sent('GET', '/blog/publications'), hasLength(1));
    expect(
      t
          .widget<ChoiceChip>(key('qa.blog.connections.section.publications'))
          .selected,
      isTrue,
    );
    expect(find.text(en.blogPublicationLive), findsOneWidget);
    expect(key('qa.blog.connections.copy_link.pub1'), findsOneWidget);
  });

  testWidgets('The sharing screen renders translated in every language without '
      'overflow, before and after creating [case:blog.blog_sharing.l10n]', (
    t,
  ) async {
    for (final locale in qaLocales) {
      final l10n = qaL10n(locale);
      final api = shareApi();
      await pumpQa(
        t,
        api,
        BlogShareScreen(
          post: post(
            photos: [
              {'id': 'ph1', 'alt_text': 'Window seat at dawn'},
            ],
          ),
        ),
        locale: locale,
        size: const Size(360, 800),
      );
      expect(t.takeException(), isNull, reason: '$locale');
      expect(find.text(l10n.blogYourPublicPreview), findsOneWidget);
      expect(find.text(l10n.blogShareSoloHeadline), findsOneWidget);
      await t.scrollUntilVisible(
        key('qa.blog.share.create'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(l10n.blogApproveCopy), findsOneWidget);
      expect(find.text(l10n.blogCreatePublicLink), findsOneWidget);
      await create(t, api);
      expect(find.text(l10n.blogPublicCopyReady), findsOneWidget);
      expect(find.text(l10n.blogCopyPublicLink), findsOneWidget);
      expect(t.takeException(), isNull, reason: '$locale after create');
      await t.pumpWidget(const SizedBox());
    }
  });
}
