// Control-level tests for the chapter editor (BlogEditor): write, preview,
// publish, save as Only me, failed saves and the saved-version sheet,
// photos (picker answered through its platform channel) and the rich-text
// toolbar as the blog uses it. Every test asserts the request the app sent
// and what the member sees.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/rich_text/rich_document.dart';
import 'package:verified_dating_app/features/blog/blog_data.dart';
import 'package:verified_dating_app/features/blog/blog_editor.dart';
import 'package:verified_dating_app/features/engagement/screens/level_progression_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';

final AppLocalizations _en = qaL10n(const Locale('en'));

const _title = ValueKey('qa.blog.editor.title');
const _save = ValueKey('blog.save');
const _savePrivate = ValueKey('qa.blog.editor.save_private');
const _checkSaved = ValueKey('qa.blog.editor.check_saved');
const _addPhoto = ValueKey('qa.blog.editor.add_photo');
const _photoAlt = ValueKey('qa.blog.editor.photo_alt');
const _photoAdd = ValueKey('qa.blog.editor.photo_add');
const _photoCancel = ValueKey('qa.blog.editor.photo_cancel');

/// A 1x1 transparent PNG.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Map<String, dynamic> _chapter({
  String id = 'p1',
  String title = 'My title',
  String body = 'My words.',
  String audience = 'private',
  String invitation = '',
  String topic = '',
  int version = 1,
  List<Map<String, dynamic>> photos = const [],
}) => {
  'id': id,
  'author_id': 'me',
  'author_name': 'Me',
  'title': title,
  'body': body,
  'audience': audience,
  'invitation': invitation,
  'topic': topic,
  'version': version,
  'photos': photos,
};

/// The post the server stores for a `PUT /blog/posts/{id}` call.
Map<String, dynamic> _stored(
  QaCall call, {
  List<Map<String, dynamic>> photos = const [],
}) => {
  ..._chapter(
    id: call.path.split('/').last,
    title: call.body['title'] as String,
    body: call.body['body'] as String,
    audience: call.body['audience'] as String,
    invitation: call.body['invitation'] as String,
    topic: call.body['topic'] as String,
    version: (call.body['expected_version'] as int) + 1,
    photos: photos,
  ),
  'content': call.body['content'],
  'allow_featuring': call.body['allow_featuring'],
};

/// A server that stores every save, lists two topics and serves photos.
QaApi _api() {
  final api = QaApi()
    ..json('GET /blog/topics', {
      'topics': [
        {'slug': 'feelings', 'title': 'Feelings & healing', 'post_count': 4},
        {'slug': 'love', 'title': 'Love & relationships', 'post_count': 2},
      ],
    })
    ..json('GET /blog/featured', {'posts': <dynamic>[]})
    ..json('GET /blog/posts', {'posts': <dynamic>[], 'next_cursor': ''})
    ..on('PUT /blog/posts/*', (call) => qaOk({'post': _stored(call)}))
    ..json('GET /blog/posts/*/photos/*', _png);
  return api;
}

List<QaCall> _saves(QaApi api) => api.sent('PUT', '/blog/posts/*');

Finder get _story => find.widgetWithText(TextField, _en.blogStoryLabel);

String _fieldText(WidgetTester tester, Finder field) => tester
    .widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    )
    .controller
    .text;

Future<void> _write(
  WidgetTester tester, {
  String title = 'The smallest adventure',
  String story = 'A quiet coffee and a book.',
}) async {
  await tester.enterText(find.byKey(_title), title);
  await tester.enterText(_story, story);
  await tester.pump();
}

/// Scrolls [finder] into view in the top route's list, then taps it.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await _scrollToTop(tester);
  }
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await qaSettle(tester);
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await _scrollToTop(tester);
  }
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pump();
}

Future<void> _scrollToTop(WidgetTester tester) async {
  // A lazily built list corrects its offset after a long jump; jump until
  // the start really is at the top.
  for (var i = 0; i < 5; i++) {
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    if (position.pixels == 0) {
      break;
    }
    position.jumpTo(0);
    await tester.pump();
  }
}

/// The save button's label, scrolled into view.
Future<String?> _saveLabel(WidgetTester tester) async {
  await _scrollTo(tester, find.byKey(_save));
  return tester
      .widget<Text>(
        find.descendant(of: find.byKey(_save), matching: find.byType(Text)),
      )
      .data;
}

/// Taps Publish and confirms the dialog.
Future<void> _publish(WidgetTester tester) async {
  await _tap(tester, find.byKey(_save));
  expect(find.byType(AlertDialog), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('qa.blog.confirm.ok')));
  await qaSettle(tester);
}

const _pickerChannel = MethodChannel('plugins.flutter.io/image_picker');

/// Answers the gallery picker with [path] (null: the member cancelled).
List<MethodCall> _mockPicker(WidgetTester tester, String? path) {
  final calls = <MethodCall>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    _pickerChannel,
    (call) async {
      calls.add(call);
      return path;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _pickerChannel,
      null,
    ),
  );
  return calls;
}

/// Lets the picked file be read from disk, then settles. Reading takes
/// several real I/O round trips, each continued by a fake-async frame.
Future<void> _settleIo(WidgetTester tester) async {
  await qaSettle(tester);
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await qaSettle(tester);
}

late String _photoPath;

void main() {
  setUpAll(() {
    final dir = Directory.systemTemp.createTempSync('blog_editor_photo');
    _photoPath = '${dir.path}/terrace.png';
    File(_photoPath).writeAsBytesSync(_png);
  });

  group('writing and saving', () {
    testWidgets(
      'Save only for me saves the trimmed title and story as a private draft '
      '[case:blog.blog_editor.blog_save.action] '
      '[case:blog.blog_editor.chapter_title_input.action]',
      (tester) async {
        final api = _api();
        await pumpQa(tester, api, const BlogEditor());
        await _write(
          tester,
          title: '  The smallest adventure  ',
          story: 'A quiet coffee and a book.',
        );
        await _scrollTo(tester, find.byKey(_save));
        expect(
          find.descendant(
            of: find.byKey(_save),
            matching: find.text(_en.blogSaveOnlyForMe),
          ),
          findsOneWidget,
        );
        await _tap(tester, find.byKey(_save));

        expect(find.byType(AlertDialog), findsNothing, reason: 'no confirm');
        final call = _saves(api).single;
        final body = {...call.body}..remove('content');
        expect(body, {
          'title': 'The smallest adventure',
          'body': 'A quiet coffee and a book.',
          'audience': 'private',
          'invitation': '',
          'expected_version': 0,
          'allow_featuring': false,
          'topic': '',
        });
        expect(
          RichDocument.tryParse(call.body['content'])!.plainText,
          'A quiet coffee and a book.',
        );
        await _scrollToTop(tester);
        expect(find.text(_en.blogSavedOnlyMe), findsOneWidget);
        expect(find.text(_en.blogSavedFor('private')), findsOneWidget);
        expect(qaSnackText(tester), isNull, reason: 'no XP for a draft');

        // The next save updates the same chapter at its new version.
        await tester.enterText(find.byKey(_title), 'A smaller adventure');
        await _tap(tester, find.byKey(_save));
        expect(_saves(api), hasLength(2));
        expect(_saves(api).last.path, call.path);
        expect(_saves(api).last.body['expected_version'], 1);
        expect(_saves(api).last.body['title'], 'A smaller adventure');
      },
    );

    testWidgets(
      'publishing asks first, publishes, explains XP and can then be left '
      '[case:blog.blog_editor.blog_save.action]',
      (tester) async {
        final api = _api();
        final popped = await pumpQa(
          tester,
          api,
          const BlogEditor(),
          launcher: true,
        );
        await _write(tester);
        await _tap(
          tester,
          find.byKey(const ValueKey('qa.blog.editor.audience.community')),
        );
        expect(await _saveLabel(tester), _en.blogPublishTo('community'));
        await _tap(tester, find.byKey(_save));
        expect(
          find.text(_en.blogPublishConfirmTitle('community')),
          findsOneWidget,
        );
        expect(find.text(_en.blogPublishCommunityBody), findsOneWidget);
        expect(_saves(api), isEmpty, reason: 'nothing before confirming');
        await tester.tap(find.byKey(const ValueKey('qa.blog.confirm.ok')));
        await qaSettle(tester);

        expect(_saves(api).single.body['audience'], 'community');
        expect(qaSnackText(tester), contains(_en.blogSharedSnack));
        await _scrollToTop(tester);
        expect(find.text(_en.blogPublishedTo('community')), findsOneWidget);

        // Nothing unsaved: back leaves without asking.
        await tester.tap(find.byType(BackButton));
        await qaSettle(tester);
        expect(find.byType(BlogEditor), findsNothing);
        expect(popped, [null]);
      },
    );

    testWidgets(
      'See my level regression: the shared snack bar opens the level screen, '
      'also after leaving the editor '
      '[case:blog.blog_editor.see_my_level.action]',
      (tester) async {
        Future<void> publishAndOpenLevel({required bool leaveFirst}) async {
          final api = _api();
          await pumpQa(tester, api, const BlogEditor(), launcher: true);
          await _write(tester);
          await _tap(
            tester,
            find.byKey(const ValueKey('qa.blog.editor.audience.friends')),
          );
          await _publish(tester);
          expect(qaSnackText(tester), contains(_en.blogSharedSnack));
          if (leaveFirst) {
            await tester.tap(find.byType(BackButton));
            await qaSettle(tester);
            expect(find.byType(BlogEditor), findsNothing);
          }
          await tester.tap(
            find.widgetWithText(SnackBarAction, _en.blogSeeMyLevel),
          );
          await qaSettle(tester);
          expect(tester.takeException(), isNull);
          expect(find.byType(LevelProgressionScreen), findsOneWidget);
          expect(api.sent('GET', '/progression/me'), isNotEmpty);
          await tester.pumpWidget(const SizedBox());
        }

        await publishAndOpenLevel(leaveFirst: false);
        await publishAndOpenLevel(leaveFirst: true);
      },
    );

    testWidgets(
      'a failed save keeps every word, explains and retries the same version '
      '[case:blog.blog_editor.blog_save.api_failure]',
      (tester) async {
        var attempts = 0;
        final api = _api()
          ..on('PUT /blog/posts/*', (call) {
            attempts++;
            return switch (attempts) {
              1 => qaOffline,
              2 => qaError(409, message: 'This chapter changed elsewhere.'),
              _ => qaOk({'post': _stored(call)}),
            };
          });
        await pumpQa(tester, api, const BlogEditor());
        await _write(tester);
        await _tap(tester, find.byKey(_save));

        await _scrollToTop(tester);
        expect(
          find.text(_en.blogEditsStillHere(_en.networkOfflineTryAgain)),
          findsOneWidget,
        );
        expect(
          _fieldText(tester, find.byKey(_title)),
          'The smallest adventure',
        );
        expect(_fieldText(tester, _story), 'A quiet coffee and a book.');
        expect(find.byKey(_checkSaved), findsOneWidget);
        await _scrollTo(tester, find.byKey(_save));
        expect(
          tester.widget<ButtonStyleButton>(find.byKey(_save)).onPressed,
          isNotNull,
        );
        expect(_saves(api), hasLength(1));

        await _tap(tester, find.byKey(_save));
        await _scrollToTop(tester);
        expect(
          find.text(_en.blogEditsStillHere('This chapter changed elsewhere.')),
          findsOneWidget,
        );

        await _tap(tester, find.byKey(_save));
        expect(_saves(api), hasLength(3));
        expect({for (final c in _saves(api)) c.path}, hasLength(1));
        expect({for (final c in _saves(api)) c.body['expected_version']}, {0});
        await _scrollToTop(tester);
        expect(find.text(_en.blogSavedOnlyMe), findsOneWidget);
        expect(find.byKey(_checkSaved), findsNothing);
      },
    );

    testWidgets(
      'Save as Only me keeps a chosen audience private without asking '
      '[case:blog.blog_editor.save_as_only_me.action]',
      (tester) async {
        final api = _api();
        await pumpQa(tester, api, const BlogEditor());
        await _write(tester);
        await _tap(
          tester,
          find.byKey(const ValueKey('qa.blog.editor.audience.friends')),
        );
        await _tap(tester, find.byKey(_savePrivate));

        expect(find.byType(AlertDialog), findsNothing);
        expect(_saves(api).single.body['audience'], 'private');
        expect(_saves(api).single.body['allow_featuring'], false);
        // The editor now reflects what was saved.
        expect(find.byKey(_savePrivate), findsNothing);
        expect(await _saveLabel(tester), _en.blogSaveOnlyForMe);
        await _scrollToTop(tester);
        expect(find.text(_en.blogSavedOnlyMe), findsOneWidget);
      },
    );

    testWidgets(
      'a failed Save as Only me keeps the words and the chosen audience '
      '[case:blog.blog_editor.save_as_only_me.api_failure]',
      (tester) async {
        var attempts = 0;
        final api = _api()
          ..on('PUT /blog/posts/*', (call) {
            attempts++;
            return attempts == 1
                ? qaError(500, message: 'Saving is paused for a moment.')
                : qaOk({'post': _stored(call)});
          });
        await pumpQa(tester, api, const BlogEditor());
        await _write(tester);
        await _tap(
          tester,
          find.byKey(const ValueKey('qa.blog.editor.audience.friends')),
        );
        await _tap(tester, find.byKey(_savePrivate));

        expect(_saves(api), hasLength(1));
        expect(
          tester
              .widget<ChoiceChip>(
                find.byKey(const ValueKey('qa.blog.editor.audience.friends')),
              )
              .selected,
          isTrue,
        );
        expect(
          tester.widget<ButtonStyleButton>(find.byKey(_savePrivate)).onPressed,
          isNotNull,
        );
        await _scrollToTop(tester);
        expect(
          find.text(_en.blogEditsStillHere('Saving is paused for a moment.')),
          findsOneWidget,
        );
        expect(_fieldText(tester, _story), 'A quiet coffee and a book.');

        await _tap(tester, find.byKey(_savePrivate));
        expect(_saves(api), hasLength(2));
        expect(_saves(api).last.body['audience'], 'private');
        await _scrollToTop(tester);
        expect(find.text(_en.blogSavedOnlyMe), findsOneWidget);
      },
    );

    testWidgets(
      'audience chips change the help, the button and what is published '
      '[case:blog.blog_editor.choicechip_onselected.action]',
      (tester) async {
        final api = _api();
        await pumpQa(tester, api, const BlogEditor());
        await _write(tester);
        const friends = ValueKey('qa.blog.editor.audience.friends');
        const community = ValueKey('qa.blog.editor.audience.community');
        const private = ValueKey('qa.blog.editor.audience.private');
        await _scrollTo(tester, find.byKey(private));
        expect(tester.widget<ChoiceChip>(find.byKey(private)).selected, isTrue);

        await _tap(tester, find.byKey(community));
        expect(find.text(_en.blogAudienceCommunityHelp), findsOneWidget);
        expect(
          find.byKey(const ValueKey('blog.allow_featuring')),
          findsOneWidget,
        );
        expect(await _saveLabel(tester), _en.blogPublishTo('community'));

        await _tap(tester, find.byKey(friends));
        expect(tester.widget<ChoiceChip>(find.byKey(friends)).selected, isTrue);
        expect(find.text(_en.blogAudienceFriendsHelp), findsOneWidget);
        expect(
          find.byKey(const ValueKey('blog.allow_featuring')),
          findsNothing,
        );
        expect(await _saveLabel(tester), _en.blogPublishTo('friends'));
        expect(find.byKey(_savePrivate), findsOneWidget);

        await _tap(tester, find.byKey(_save));
        expect(find.text(_en.blogPublishFriendsBody), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('qa.blog.confirm.ok')));
        await qaSettle(tester);
        expect(_saves(api).single.body['audience'], 'friends');

        await _tap(tester, find.byKey(private));
        expect(find.text(_en.blogAudiencePrivateHelp), findsOneWidget);
        expect(find.byKey(_savePrivate), findsNothing);
        expect(await _saveLabel(tester), _en.blogSaveOnlyForMe);
      },
    );

    testWidgets(
      'Allow featuring is offered for the community only and sent only there '
      '[case:blog.blog_editor.blog_allow_featuring.action]',
      (tester) async {
        final api = _api();
        await pumpQa(tester, api, const BlogEditor());
        await _write(tester);
        const featuring = ValueKey('blog.allow_featuring');
        expect(find.byKey(featuring), findsNothing);
        await _tap(
          tester,
          find.byKey(const ValueKey('qa.blog.editor.audience.community')),
        );
        expect(
          tester.widget<SwitchListTile>(find.byKey(featuring)).value,
          isFalse,
        );
        await _tap(tester, find.byKey(featuring));
        expect(
          tester.widget<SwitchListTile>(find.byKey(featuring)).value,
          isTrue,
        );
        await _publish(tester);
        expect(_saves(api).last.body['allow_featuring'], true);
        expect(_saves(api).last.body['audience'], 'community');

        // Switched off again, it is sent as false.
        await _tap(tester, find.byKey(featuring));
        await _publish(tester);
        expect(_saves(api).last.body['allow_featuring'], false);

        // Never sent as true for another audience, even if it was on.
        await _tap(tester, find.byKey(featuring));
        await _tap(
          tester,
          find.byKey(const ValueKey('qa.blog.editor.audience.friends')),
        );
        await _publish(tester);
        expect(_saves(api).last.body['audience'], 'friends');
        expect(_saves(api).last.body['allow_featuring'], false);
      },
    );

    testWidgets(
      'title validation: blank titles cannot be published, 100 characters max, '
      'unicode kept exactly '
      '[case:blog.blog_editor.chapter_title_input.validation]',
      (tester) async {
        final api = _api();
        await pumpQa(tester, api, const BlogEditor());
        await _write(tester, title: '   ');
        await _tap(
          tester,
          find.byKey(const ValueKey('qa.blog.editor.audience.community')),
        );
        await _tap(tester, find.byKey(_save));
        expect(find.byType(AlertDialog), findsNothing);
        expect(_saves(api), isEmpty);
        await _scrollToTop(tester);
        expect(find.text(_en.blogEditorMissingFields), findsOneWidget);

        await tester.enterText(find.byKey(_title), 'x' * 101);
        await tester.pump();
        expect(_fieldText(tester, find.byKey(_title)), 'x' * 100);

        const unicode = 'شاي على السطح 🌧️ — Ünïcødé ✍🏽';
        const story = 'Ромашка, 雨, and a quiet ☕ — עברית too.';
        await _write(tester, title: unicode, story: story);
        await _publish(tester);
        expect(_saves(api).single.body['title'], unicode);
        expect(_saves(api).single.body['body'], story);
        expect(
          RichDocument.tryParse(_saves(api).single.body['content'])!.plainText,
          story,
        );
      },
    );

    testWidgets('End with an invitation is previewed and saved '
        '[case:blog.blog_editor.end_with_an_invitation_optional.action]', (
      tester,
    ) async {
      final api = _api();
      await pumpQa(tester, api, const BlogEditor());
      await _write(tester);
      final dropdown = find.byType(DropdownButtonFormField<String>);
      await _tap(tester, dropdown);
      await tester.tap(find.text(_en.blogInvitationTeachMe).last);
      await qaSettle(tester);
      expect(
        find.descendant(
          of: dropdown,
          matching: find.text(_en.blogInvitationTeachMe),
        ),
        findsOneWidget,
      );

      await _scrollToTop(tester);
      await tester.tap(find.byKey(const ValueKey('qa.blog.editor.preview')));
      await qaSettle(tester);
      expect(find.text(_en.blogInvitationTeachMe), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('qa.blog.editor.preview')));
      await qaSettle(tester);

      await _tap(tester, find.byKey(_save));
      expect(_saves(api).single.body['invitation'], 'teach_me');
    });

    testWidgets('a topic chip files the chapter; tapping it again clears it '
        '[case:blog.blog_editor.blog_editor_topic_x.action]', (tester) async {
      final api = _api();
      await pumpQa(tester, api, const BlogEditor());
      await _write(tester);
      const feelings = ValueKey('blog.editor.topic.feelings');
      await _tap(tester, find.byKey(feelings));
      expect(tester.widget<ChoiceChip>(find.byKey(feelings)).selected, isTrue);
      await _tap(tester, find.byKey(_save));
      expect(_saves(api).last.body['topic'], 'feelings');

      await _tap(tester, find.byKey(feelings));
      expect(tester.widget<ChoiceChip>(find.byKey(feelings)).selected, isFalse);
      await _tap(tester, find.byKey(_save));
      expect(_saves(api).last.body['topic'], '');
    });

    testWidgets(
      'Preview shows the chapter as readers will, writes nothing, Keep writing '
      'returns [case:blog.blog_editor.preview.action]',
      (tester) async {
        final api = _api();
        await pumpQa(tester, api, const BlogEditor());
        const preview = ValueKey('qa.blog.editor.preview');

        // An empty chapter previews as untitled with a placeholder.
        await tester.tap(find.byKey(preview));
        await qaSettle(tester);
        expect(find.text(_en.blogUntitled), findsOneWidget);
        expect(find.text(_en.blogStoryPlaceholder), findsOneWidget);
        await tester.tap(find.byKey(preview));
        await qaSettle(tester);

        await _write(tester);
        await tester.tap(find.byKey(preview));
        await qaSettle(tester);
        expect(find.text(_en.blogEditorPreviewTitle), findsOneWidget);
        expect(
          find.text(_en.blogPreviewNotSaved(_en.blogAudiencePrivate)),
          findsOneWidget,
        );
        expect(find.text('The smallest adventure'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('blog.editor.preview')),
          findsOneWidget,
        );
        expect(find.byKey(_title), findsNothing);
        expect(find.text(_en.blogKeepWriting), findsOneWidget);
        expect(api.writes, isEmpty);

        await tester.tap(find.byKey(preview));
        await qaSettle(tester);
        expect(find.text(_en.blogEditorTitle), findsOneWidget);
        expect(
          _fieldText(tester, find.byKey(_title)),
          'The smallest adventure',
        );
        expect(_fieldText(tester, _story), 'A quiet coffee and a book.');
        expect(api.writes, isEmpty);
      },
    );

    testWidgets(
      'unsaved words ask before leaving; Leave discards, Cancel stays '
      '[case:blog.blog_editor.leave_editor.action]',
      (tester) async {
        final api = _api();
        final popped = await pumpQa(
          tester,
          api,
          const BlogEditor(),
          launcher: true,
        );
        await _write(tester);
        await tester.tap(find.byType(BackButton));
        await qaSettle(tester);
        expect(find.text(_en.blogLeaveEditorTitle), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('qa.blog.confirm.cancel')));
        await qaSettle(tester);
        expect(find.byType(BlogEditor), findsOneWidget);
        expect(_fieldText(tester, _story), 'A quiet coffee and a book.');

        await tester.tap(find.byType(BackButton));
        await qaSettle(tester);
        await tester.tap(find.byKey(const ValueKey('qa.blog.confirm.ok')));
        await qaSettle(tester);
        expect(find.byType(BlogEditor), findsNothing);
        expect(popped, [null]);
        expect(api.writes, isEmpty);
      },
    );
  });

  group('saved version', () {
    final remote = _chapter(
      title: 'Their newer title',
      body: 'Newer words.',
      audience: 'friends',
      invitation: 'what_next',
      topic: 'love',
      version: 5,
    );

    /// An editor on chapter p1 (v1) whose first save conflicts.
    Future<QaApi> conflicted(
      WidgetTester tester, {
      Map<String, dynamic>? saved,
    }) async {
      var attempts = 0;
      final api = _api()
        ..on('PUT /blog/posts/*', (call) {
          attempts++;
          return attempts == 1
              ? qaError(409, message: 'This chapter changed on another device.')
              : qaOk({'post': _stored(call)});
        })
        ..json('GET /blog/posts/*', {'post': saved ?? remote});
      await pumpQa(
        tester,
        api,
        BlogEditor(initial: BlogPost.fromJson(_chapter())),
      );
      await tester.enterText(find.byKey(_title), 'My edited title');
      await _tap(tester, find.byKey(_save));
      await _scrollToTop(tester);
      expect(
        find.text(
          _en.blogEditsStillHere('This chapter changed on another device.'),
        ),
        findsOneWidget,
      );
      return api;
    }

    testWidgets('Check saved version shows the server copy next to my edits '
        '[case:blog.blog_editor.check_saved_version.action] '
        '[case:blog.blog_editor.saved_version_audience.action] '
        '[case:blog.blog_editor.selectabletext_input_input.action]', (
      tester,
    ) async {
      final api = await conflicted(tester);
      await tester.tap(find.byKey(_checkSaved));
      await qaSettle(tester);

      expect(api.sent('GET', '/blog/posts/p1'), hasLength(1));
      final sheet = find.byKey(
        const ValueKey('qa.blog.editor.saved_version_sheet'),
      );
      expect(sheet, findsOneWidget);
      expect(
        find.text(_en.blogSavedVersionTitle(_en.blogAudienceFriends)),
        findsOneWidget,
      );
      final selectable = find.descendant(
        of: sheet,
        matching: find.byType(SelectableText),
      );
      expect(
        tester.widget<SelectableText>(selectable.first).data,
        'Their newer title',
      );
      expect(
        find.descendant(of: sheet, matching: find.text('Newer words.')),
        findsOneWidget,
      );
      expect(find.text(_en.blogSavedVersionNote), findsOneWidget);
      // My edits are untouched underneath.
      expect(_fieldText(tester, find.byKey(_title)), 'My edited title');
    });

    testWidgets(
      'Keep my edits closes the sheet and saves my words over the newer '
      'version [case:blog.blog_editor.keep_my_edits_for_the_next_save.action]',
      (tester) async {
        final api = await conflicted(tester);
        await tester.tap(find.byKey(_checkSaved));
        await qaSettle(tester);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('qa.blog.editor.keep_edits')),
          200,
          scrollable: find
              .descendant(
                of: find.byKey(
                  const ValueKey('qa.blog.editor.saved_version_sheet'),
                ),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(
          find.byKey(const ValueKey('qa.blog.editor.keep_edits')),
        );
        await qaSettle(tester);

        expect(
          find.byKey(const ValueKey('qa.blog.editor.saved_version_sheet')),
          findsNothing,
        );
        expect(_fieldText(tester, find.byKey(_title)), 'My edited title');
        expect(find.byKey(_checkSaved), findsNothing);
        expect(find.text(_en.blogSavedFor('friends')), findsOneWidget);

        await _tap(tester, find.byKey(_save));
        final retry = _saves(api).last;
        expect(_saves(api), hasLength(2));
        expect(retry.body['expected_version'], 5);
        expect(retry.body['title'], 'My edited title');
        expect(retry.body['audience'], 'private');
      },
    );

    testWidgets('Use saved version replaces my edits with the server copy '
        '[case:blog.blog_editor.use_saved_version.action]', (tester) async {
      final api = await conflicted(tester);
      await tester.tap(find.byKey(_checkSaved));
      await qaSettle(tester);
      final use = find.byKey(const ValueKey('qa.blog.editor.use_saved'));
      await tester.scrollUntilVisible(
        use,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(
                const ValueKey('qa.blog.editor.saved_version_sheet'),
              ),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(use);
      await qaSettle(tester);

      expect(use, findsNothing);
      expect(_fieldText(tester, find.byKey(_title)), 'Their newer title');
      expect(_fieldText(tester, _story), 'Newer words.');
      await _scrollTo(
        tester,
        find.byKey(const ValueKey('qa.blog.editor.audience.friends')),
      );
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const ValueKey('qa.blog.editor.audience.friends')),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const ValueKey('blog.editor.topic.love')),
            )
            .selected,
        isTrue,
      );

      await _publish(tester);
      final put = _saves(api).last.body;
      expect(put['expected_version'], 5);
      expect(put['title'], 'Their newer title');
      expect(put['body'], 'Newer words.');
      expect(put['audience'], 'friends');
      expect(put['invitation'], 'what_next');
      expect(put['topic'], 'love');
    });

    testWidgets(
      'the saved title is shown and reused byte for byte, RTL and emoji '
      'included [case:blog.blog_editor.selectabletext_input_input.validation]',
      (tester) async {
        const title = 'مطر على الشرفة 🌧️ — Ünïcødé ✍🏽';
        final api = await conflicted(
          tester,
          saved: _chapter(title: title, body: 'Слова 雨 ☕', version: 7),
        );
        await tester.tap(find.byKey(_checkSaved));
        await qaSettle(tester);
        final sheet = find.byKey(
          const ValueKey('qa.blog.editor.saved_version_sheet'),
        );
        expect(
          tester
              .widget<SelectableText>(
                find
                    .descendant(
                      of: sheet,
                      matching: find.byType(SelectableText),
                    )
                    .first,
              )
              .data,
          title,
        );
        final use = find.byKey(const ValueKey('qa.blog.editor.use_saved'));
        await tester.scrollUntilVisible(
          use,
          200,
          scrollable: find
              .descendant(of: sheet, matching: find.byType(Scrollable))
              .first,
        );
        await tester.tap(use);
        await qaSettle(tester);
        expect(_fieldText(tester, find.byKey(_title)), title);

        await _tap(tester, find.byKey(_save));
        expect(_saves(api).last.body['title'], title);
        expect(_saves(api).last.body['body'], 'Слова 雨 ☕');
        expect(_saves(api).last.body['expected_version'], 7);
      },
    );

    testWidgets('a failed check explains, keeps my words and can be retried '
        '[case:blog.blog_editor.check_saved_version.api_failure]', (
      tester,
    ) async {
      final api = await conflicted(tester);
      var reads = 0;
      api.on('GET /blog/posts/*', (call) {
        reads++;
        return switch (reads) {
          1 => qaError(500, message: 'Saved copy unavailable right now.'),
          2 => const QaReply(500, <String, dynamic>{}),
          _ => qaOk({'post': remote}),
        };
      });
      await tester.tap(find.byKey(_checkSaved));
      await qaSettle(tester);
      expect(find.text('Saved copy unavailable right now.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('qa.blog.editor.saved_version_sheet')),
        findsNothing,
      );
      expect(_fieldText(tester, find.byKey(_title)), 'My edited title');
      expect(
        tester.widget<ButtonStyleButton>(find.byKey(_checkSaved)).onPressed,
        isNotNull,
      );
      expect(api.sent('GET', '/blog/posts/p1'), hasLength(1));

      await tester.tap(find.byKey(_checkSaved));
      await qaSettle(tester);
      expect(find.text(_en.blogSavedVersionLoadFailed), findsOneWidget);

      await tester.tap(find.byKey(_checkSaved));
      await qaSettle(tester);
      expect(api.sent('GET', '/blog/posts/p1'), hasLength(3));
      expect(
        find.byKey(const ValueKey('qa.blog.editor.saved_version_sheet')),
        findsOneWidget,
      );
    });
  });

  group('photos', () {
    /// Serves the photo upload: the stored post gains the photo.
    void serveUpload(QaApi api, {QaReply? Function(QaCall)? fail}) {
      api.on('PUT /blog/posts/*/photos/*', (call) {
        final failed = fail?.call(call);
        if (failed != null) {
          return failed;
        }
        final fields = Map.fromEntries((call.data! as FormData).fields);
        final stored = _saves(api).last;
        return qaOk({
          'post': _stored(
            stored,
            photos: [
              {'id': call.path.split('/').last, 'alt_text': fields['alt_text']},
            ],
          )..['version'] = int.parse(fields['expected_version']!) + 1,
        });
      });
    }

    testWidgets(
      'Add a photo: describe it, then it is saved with the private draft '
      '[case:blog.blog_editor.add_a_photo.action] '
      '[case:blog.blog_editor.describe_your_photo.action] '
      '[case:blog.blog_editor.what_is_in_this_photo.action] '
      '[case:blog.blog_editor.add_to_private_draft.action]',
      (tester) async {
        final picker = _mockPicker(tester, _photoPath);
        final api = _api();
        serveUpload(api);
        await pumpQa(tester, api, const BlogEditor());
        await _write(tester);
        await _tap(tester, find.byKey(_addPhoto));

        expect(picker.single.method, 'pickImage');
        expect(picker.single.arguments, containsPair('source', 1));
        expect(picker.single.arguments, containsPair('maxWidth', 2048.0));
        expect(find.text(_en.blogDescribePhotoTitle), findsOneWidget);
        expect(find.text(_en.blogDescribePhotoBody), findsOneWidget);
        expect(find.text(_en.blogDescribePhotoLabel), findsOneWidget);
        expect(
          tester.widget<FilledButton>(find.byKey(_photoAdd)).onPressed,
          isNull,
        );

        await tester.enterText(find.byKey(_photoAlt), '  A wet terrace  ');
        await tester.pump();
        await tester.tap(find.byKey(_photoAdd));
        await _settleIo(tester);

        expect(find.text(_en.blogDescribePhotoTitle), findsNothing);
        final draft = _saves(api).single;
        expect(draft.body['audience'], 'private');
        expect(draft.body['title'], 'The smallest adventure');
        final upload = api.sent('PUT', '/blog/posts/*/photos/*').single;
        expect(upload.path, startsWith('${draft.path}/photos/'));
        final form = upload.data! as FormData;
        expect(Map.fromEntries(form.fields), {
          'expected_version': '1',
          'alt_text': 'A wet terrace',
        });
        expect(form.files.single.key, 'image');
        expect(form.files.single.value.filename, 'terrace.png');
        expect(form.files.single.value.length, _png.length);

        await _scrollToTop(tester);
        expect(find.text(_en.blogPhotoAdded), findsOneWidget);
        await _scrollTo(tester, find.text('A wet terrace'));
        expect(
          find.byWidgetPredicate(
            (w) => w is Image && w.semanticLabel == 'A wet terrace',
          ),
          findsOneWidget,
        );
        final photoId = upload.path.split('/').last;
        expect(api.sent('GET', '${draft.path}/photos/$photoId'), isNotEmpty);
        await _scrollTo(
          tester,
          find.byKey(ValueKey('qa.blog.editor.remove_photo.$photoId')),
        );
        expect(
          find.byKey(ValueKey('qa.blog.editor.remove_photo.$photoId')),
          findsOneWidget,
        );
        await qaSettle(tester);
      },
    );

    testWidgets('Cancel closes the photo description and sends nothing '
        '[case:blog.blog_editor.cancel.action]', (tester) async {
      _mockPicker(tester, _photoPath);
      final api = _api();
      serveUpload(api);
      await pumpQa(tester, api, const BlogEditor());
      await _write(tester);
      await _tap(tester, find.byKey(_addPhoto));
      await tester.enterText(find.byKey(_photoAlt), 'A wet terrace');
      await tester.tap(find.byKey(_photoCancel));
      await _settleIo(tester);

      expect(find.text(_en.blogDescribePhotoTitle), findsNothing);
      expect(api.writes, isEmpty);
      expect(_fieldText(tester, _story), 'A quiet coffee and a book.');

      // A picker closed without a photo opens nothing and sends nothing.
      _mockPicker(tester, null);
      await _tap(tester, find.byKey(_addPhoto));
      expect(find.text(_en.blogDescribePhotoTitle), findsNothing);
      expect(api.writes, isEmpty);
    });

    testWidgets(
      'photo description regression: Add stays disabled until described; 160 '
      'max; unicode kept '
      '[case:blog.blog_editor.what_is_in_this_photo.validation]',
      (tester) async {
        _mockPicker(tester, _photoPath);
        final api = _api();
        serveUpload(api);
        await pumpQa(tester, api, const BlogEditor());
        await _write(tester);
        await _tap(tester, find.byKey(_addPhoto));
        FilledButton add() =>
            tester.widget<FilledButton>(find.byKey(_photoAdd));

        expect(add().onPressed, isNull, reason: 'empty');
        await tester.enterText(find.byKey(_photoAlt), '    ');
        await tester.pump();
        expect(add().onPressed, isNull, reason: 'whitespace only');
        await tester.tap(find.byKey(_photoAdd), warnIfMissed: false);
        await qaSettle(tester);
        expect(find.text(_en.blogDescribePhotoTitle), findsOneWidget);
        expect(api.writes, isEmpty);

        await tester.enterText(find.byKey(_photoAlt), 'a' * 161);
        await tester.pump();
        expect(_fieldText(tester, find.byKey(_photoAlt)), 'a' * 160);

        const alt = 'مطر على الشرفة 🌧️ — на террасе ✍🏽';
        await tester.enterText(find.byKey(_photoAlt), alt);
        await tester.pump();
        expect(add().onPressed, isNotNull);
        await tester.tap(find.byKey(_photoAdd));
        await _settleIo(tester);
        final form =
            api.sent('PUT', '/blog/posts/*/photos/*').single.data! as FormData;
        expect(Map.fromEntries(form.fields)['alt_text'], alt);
      },
    );

    testWidgets(
      'a failed upload explains, blocks blind retries until the saved version '
      'is checked [case:blog.blog_editor.add_a_photo.api_failure]',
      (tester) async {
        _mockPicker(tester, _photoPath);
        var uploads = 0;
        final api = _api();
        serveUpload(
          api,
          fail: (call) => ++uploads == 1
              ? qaError(500, message: 'Photo storage is busy.')
              : null,
        );
        await pumpQa(tester, api, const BlogEditor());
        await _write(tester);
        await _tap(tester, find.byKey(_addPhoto));
        await tester.enterText(find.byKey(_photoAlt), 'A wet terrace');
        await tester.pump();
        await tester.tap(find.byKey(_photoAdd));
        await _settleIo(tester);

        expect(api.sent('PUT', '/blog/posts/*/photos/*'), hasLength(1));
        await _scrollToTop(tester);
        expect(
          find.text(_en.blogCheckSavedBeforeRetrying('Photo storage is busy.')),
          findsOneWidget,
        );
        expect(_fieldText(tester, _story), 'A quiet coffee and a book.');
        await _scrollTo(tester, find.byKey(_addPhoto));
        expect(
          tester.widget<ButtonStyleButton>(find.byKey(_addPhoto)).onPressed,
          isNull,
          reason: 'the outcome is unknown until the saved version is checked',
        );

        // Checking the saved version (no photo there) re-enables it.
        final draftId = _saves(api).single.path.split('/').last;
        api.json('GET /blog/posts/*', {'post': _stored(_saves(api).single)});
        await _scrollToTop(tester);
        await tester.tap(find.byKey(_checkSaved));
        await qaSettle(tester);
        expect(api.sent('GET', '/blog/posts/$draftId'), hasLength(1));
        final keep = find.byKey(const ValueKey('qa.blog.editor.keep_edits'));
        await tester.scrollUntilVisible(
          keep,
          200,
          scrollable: find
              .descendant(
                of: find.byKey(
                  const ValueKey('qa.blog.editor.saved_version_sheet'),
                ),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(keep);
        await qaSettle(tester);
        await _scrollTo(tester, find.byKey(_addPhoto));
        expect(
          tester.widget<ButtonStyleButton>(find.byKey(_addPhoto)).onPressed,
          isNotNull,
        );
      },
    );

    testWidgets('Add a photo is not offered for a published chapter '
        '[case:blog.blog_editor.add_a_photo.action]', (tester) async {
      final picker = _mockPicker(tester, _photoPath);
      final api = _api();
      await pumpQa(
        tester,
        api,
        BlogEditor(initial: BlogPost.fromJson(_chapter(audience: 'friends'))),
      );
      await _scrollTo(tester, find.byKey(_addPhoto));
      expect(
        tester.widget<ButtonStyleButton>(find.byKey(_addPhoto)).onPressed,
        isNull,
      );
      await tester.tap(find.byKey(_addPhoto), warnIfMissed: false);
      await qaSettle(tester);
      expect(picker, isEmpty);
    });

    testWidgets('Remove photo deletes it from this version of the draft '
        '[case:blog.blog_editor.remove_photo.action]', (tester) async {
      final api = _api();
      final withPhoto = _chapter(
        version: 2,
        photos: [
          {'id': 'ph1', 'alt_text': 'A wet terrace'},
        ],
      );
      api.json('DELETE /blog/posts/*/photos/*', {'post': _chapter(version: 3)});
      await pumpQa(
        tester,
        api,
        BlogEditor(initial: BlogPost.fromJson(withPhoto)),
      );
      const remove = ValueKey('qa.blog.editor.remove_photo.ph1');
      await _tap(tester, find.byKey(remove));

      expect(api.sent('DELETE', '/blog/posts/p1/photos/ph1').single.body, {
        'expected_version': 2,
      });
      expect(find.byKey(remove), findsNothing);
      expect(find.text('A wet terrace'), findsNothing);

      // The next save is against the version the removal produced.
      await _tap(tester, find.byKey(_save));
      expect(_saves(api).single.body['expected_version'], 3);
    });

    testWidgets(
      'a failed removal keeps the photo and explains; it can be retried after '
      'checking [case:blog.blog_editor.remove_photo.api_failure]',
      (tester) async {
        var attempts = 0;
        final withPhoto = _chapter(
          version: 2,
          photos: [
            {'id': 'ph1', 'alt_text': 'A wet terrace'},
          ],
        );
        final api = _api()
          ..on('DELETE /blog/posts/*/photos/*', (call) {
            attempts++;
            return attempts == 1
                ? qaError(500, message: 'Removal did not go through.')
                : qaOk({'post': _chapter(version: 3)});
          })
          ..json('GET /blog/posts/*', {'post': withPhoto});
        await pumpQa(
          tester,
          api,
          BlogEditor(initial: BlogPost.fromJson(withPhoto)),
        );
        const remove = ValueKey('qa.blog.editor.remove_photo.ph1');
        await _tap(tester, find.byKey(remove));

        expect(api.sent('DELETE', '/blog/posts/p1/photos/ph1'), hasLength(1));
        expect(find.byKey(remove), findsOneWidget);
        expect(
          tester.widget<ButtonStyleButton>(find.byKey(remove)).onPressed,
          isNull,
        );
        await _scrollToTop(tester);
        expect(find.text('Removal did not go through.'), findsOneWidget);

        await tester.tap(find.byKey(_checkSaved));
        await qaSettle(tester);
        final keep = find.byKey(const ValueKey('qa.blog.editor.keep_edits'));
        await tester.scrollUntilVisible(
          keep,
          200,
          scrollable: find
              .descendant(
                of: find.byKey(
                  const ValueKey('qa.blog.editor.saved_version_sheet'),
                ),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.tap(keep);
        await qaSettle(tester);
        await _tap(tester, find.byKey(remove));
        expect(api.sent('DELETE', '/blog/posts/p1/photos/ph1'), hasLength(2));
        expect(find.byKey(remove), findsNothing);
      },
    );
  });

  testWidgets('the formatting toolbar shapes what the chapter saves '
      '[case:blog.blog_editor.rich_toolbar.action]', (tester) async {
    final api = _api();
    await pumpQa(tester, api, const BlogEditor());
    await _write(tester, story: 'Sunday\nslowly we walked');
    // Line one becomes a heading (block menu).
    final controller = tester.widget<TextField>(_story).controller!
      ..selection = const TextSelection.collapsed(offset: 2);
    await tester.pump();
    await _tap(tester, find.byKey(const ValueKey('blog.editor.block_menu')));
    await tester.tap(find.byKey(const ValueKey('blog.editor.block.heading')));
    await qaSettle(tester);

    // "slowly" is italic and underlined.
    controller.selection = const TextSelection(baseOffset: 7, extentOffset: 13);
    await tester.pump();
    await _tap(tester, find.byKey(const ValueKey('blog.editor.italic')));
    controller.selection = const TextSelection(baseOffset: 7, extentOffset: 13);
    await tester.pump();
    await _tap(tester, find.byKey(const ValueKey('blog.editor.underline')));

    // "walked" links out.
    controller.selection = const TextSelection(
      baseOffset: 17,
      extentOffset: 23,
    );
    await tester.pump();
    await _tap(tester, find.byKey(const ValueKey('blog.editor.link')));
    await tester.enterText(
      find.byKey(const ValueKey('rich.link.field')),
      'https://example.com/walk',
    );
    await tester.tap(find.byKey(const ValueKey('rich.link.apply')));
    await qaSettle(tester);

    await _tap(tester, find.byKey(_save));
    final put = _saves(api).single.body;
    expect(put['body'], 'Sunday\nslowly we walked');
    final doc = RichDocument.tryParse(put['content'])!;
    expect(doc.plainText, put['body']);
    expect(doc.blocks.first.type, RichBlockType.heading);
    expect(doc.blocks.first.text, 'Sunday');
    final spans = doc.blocks[1].spans;
    final slowly = spans.firstWhere((s) => s.text == 'slowly');
    expect(slowly.marks, {RichMark.italic, RichMark.underline});
    final walked = spans.firstWhere((s) => s.text == 'walked');
    expect(walked.marks, contains(RichMark.link));
    expect(walked.href, 'https://example.com/walk');
  });

  testWidgets('the editor renders translated in every locale '
      '[case:blog.blog_editor.l10n]', (tester) async {
    for (final locale in qaLocales) {
      final l10n = qaL10n(locale);
      await tester.pumpWidget(const SizedBox());
      await pumpQa(tester, _api(), const BlogEditor(), locale: locale);
      expect(tester.takeException(), isNull, reason: '$locale');
      expect(find.text(l10n.blogEditorTitle), findsOneWidget);
      expect(find.text(l10n.blogEditorHeadline), findsOneWidget);
      expect(find.text(l10n.blogChapterTitleLabel), findsOneWidget);
      await _scrollTo(tester, find.text(l10n.blogSaveOnlyForMe));
      expect(tester.takeException(), isNull, reason: '$locale bottom');
      expect(find.text(l10n.blogWhoFor), findsOneWidget);
    }
  });
}
