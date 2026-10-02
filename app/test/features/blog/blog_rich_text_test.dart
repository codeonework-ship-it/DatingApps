import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/rich_text/rich_document.dart';
import 'package:verified_dating_app/core/rich_text/rich_document_view.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/blog/blog_data.dart';
import 'package:verified_dating_app/features/blog/blog_editor.dart';
import 'package:verified_dating_app/features/blog/blog_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

class _Api {
  _Api(this.saved);
  final writes = <RequestOptions>[];
  Map<String, dynamic> saved;
  Dio get dio => Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          if (r.method == 'PUT') {
            writes.add(r);
            final data = Map<String, dynamic>.from(r.data as Map);
            saved = {
              ...saved,
              ...data,
              'version': (data['expected_version'] as int) + 1,
            };
          }
          h.resolve(
            Response<dynamic>(
              requestOptions: r,
              statusCode: 200,
              data: r.path.startsWith('/blog/posts/')
                  ? {'post': saved}
                  : <String, dynamic>{
                      'posts': <dynamic>[],
                      'comments': <dynamic>[],
                      'topics': <dynamic>[],
                    },
            ),
          );
        },
      ),
    );
}

Map<String, dynamic> post({Object? content, String body = 'Plain words'}) => {
  'id': 'chapter',
  'author_id': 'me',
  'author_name': 'Alex',
  'title': 'A title',
  'body': body,
  'content': content,
  'audience': 'private',
  'invitation': '',
  'version': 1,
  'photos': <dynamic>[],
};

Widget host(_Api api, Widget child) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(api.dio),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

Future<void> tapVisible(WidgetTester t, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    t.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await t.ensureVisible(finder);
  await t.pumpAndSettle();
  await t.tap(finder);
  await t.pumpAndSettle();
}

final formatted = {
  'version': 1,
  'style': 'journal',
  'blocks': [
    {
      'type': 'heading',
      'spans': [
        {'text': 'Sunday'},
      ],
    },
    {
      'type': 'paragraph',
      'spans': [
        {
          'text': 'slowly',
          'marks': ['italic'],
        },
      ],
    },
  ],
};

void main() {
  testWidgets('formatting and writing style are saved with a plain body', (
    t,
  ) async {
    final api = _Api(post());
    await t.pumpWidget(host(api, const BlogEditor()));
    await t.pumpAndSettle();
    await t.enterText(
      find.widgetWithText(TextField, 'Chapter title'),
      'Bold move',
    );
    final story = find.widgetWithText(TextField, 'Your story');
    await t.enterText(story, 'A quiet coffee');
    final controller = t.widget<TextField>(story).controller!;
    controller.selection = const TextSelection(baseOffset: 2, extentOffset: 7);
    await t.pump();
    await tapVisible(t, find.byKey(const ValueKey('blog.editor.bold')));
    await tapVisible(t, find.byKey(const ValueKey('blog.editor.style.poetic')));

    // Preview shows the formatted, styled chapter and writes nothing.
    await tapVisible(t, find.text('Preview'));
    expect(find.byKey(const ValueKey('blog.editor.preview')), findsOneWidget);
    expect(api.writes, isEmpty);
    await tapVisible(t, find.text('Keep writing'));

    await tapVisible(t, find.byKey(const ValueKey('blog.save')));
    final data = api.writes.single.data as Map;
    expect(data['body'], 'A quiet coffee');
    final content = data['content'] as Map<String, dynamic>;
    expect(content['version'], 1);
    expect(content['style'], 'poetic');
    final spans = (content['blocks'] as List).single['spans'] as List;
    expect(spans[1], {
      'text': 'quiet',
      'marks': ['bold'],
    });
    expect(RichDocument.tryParse(content)!.plainText, data['body']);
  });

  testWidgets(
    'a legacy chapter opens as plain paragraphs and saves unchanged',
    (t) async {
      const legacy = 'Line one\n\n• typed bullet\n1. typed number';
      final api = _Api(post(body: legacy));
      await t.pumpWidget(
        host(api, BlogEditor(initial: BlogPost.fromJson(post(body: legacy)))),
      );
      await t.pumpAndSettle();
      expect(find.text(legacy), findsOneWidget);
      await tapVisible(t, find.byKey(const ValueKey('blog.save')));
      final data = api.writes.single.data as Map;
      expect(data['body'], legacy);
      final doc = RichDocument.tryParse(data['content'])!;
      expect(doc.isFormatted, isFalse);
      expect(doc.plainText, legacy);
    },
  );

  testWidgets('unsaved formatting still asks before leaving', (t) async {
    final api = _Api(post());
    await t.pumpWidget(
      host(
        api,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const BlogEditor()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    // Only a writing-style change: still an unsaved edit.
    await tapVisible(
      t,
      find.byKey(const ValueKey('blog.editor.style.journal')),
    );
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.text('Leave without saving?'), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(find.byType(BlogEditor), findsOneWidget);
  });

  testWidgets('detail renders formatting; legacy chapters render as before', (
    t,
  ) async {
    final api = _Api(post(content: formatted, body: 'Sunday\nslowly'));
    await t.pumpWidget(host(api, const BlogDetailScreen(id: 'chapter')));
    await t.pumpAndSettle();
    expect(find.byType(RichDocumentView), findsOneWidget);
    expect(find.text('Sunday'), findsOneWidget);

    final legacy = _Api(post(body: 'Just words\non two lines'));
    await t.pumpWidget(host(legacy, const BlogDetailScreen(id: 'chapter')));
    await t.pumpAndSettle();
    expect(find.byType(RichDocumentView), findsNothing);
    final text = t.widget<SelectableText>(
      find.descendant(
        of: find.byKey(const ValueKey('blog.detail.body')),
        matching: find.byType(SelectableText),
      ),
    );
    expect(text.data, 'Just words\non two lines');
  });
}
