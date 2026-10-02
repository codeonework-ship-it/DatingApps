import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/rich_text/rich_document.dart';
import 'package:verified_dating_app/core/rich_text/rich_document_view.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/intentional_dating/profile_stories.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

class _Api {
  final saves = <Map<String, dynamic>>[];
  Map<String, dynamic> saved = {
    'stories': <dynamic>[],
    'published': false,
    'version': 0,
    'photos': <dynamic>[],
  };
  Dio get dio => Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          if (r.method == 'PUT') {
            saves.add(Map<String, dynamic>.from(r.data as Map));
            saved = {
              ...saved,
              ...saves.last,
              'version': (saved['version'] as int) + 1,
            };
          }
          h.resolve(
            Response<dynamic>(requestOptions: r, statusCode: 200, data: saved),
          );
        },
      ),
    );
}

Widget host(_Api api, Widget child) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(api.dio),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
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

void main() {
  testWidgets('stories save formatting, style and derived text', (t) async {
    final api = _Api();
    await t.pumpWidget(host(api, const ProfileStoriesScreen()));
    await t.pumpAndSettle();
    await tapVisible(t, find.byKey(const ValueKey('qa.stories.add')));
    final field = find.byType(TextFormField).first;
    await t.enterText(field, 'Soup when you are ill');
    final controller = t
        .widget<TextField>(
          find.descendant(of: field, matching: find.byType(TextField)),
        )
        .controller!;
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 4);
    await t.pump();
    final prefix = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.endsWith('.italic'),
    );
    await tapVisible(t, prefix);
    final poetic = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.endsWith('.style.poetic'),
    );
    await tapVisible(t, poetic);

    await tapVisible(t, find.text('Preview my stories'));
    expect(find.byType(RichDocumentView), findsOneWidget);
    await tapVisible(t, find.byKey(const ValueKey('qa.stories.save')));
    final story = (api.saves.single['stories'] as List).single as Map;
    expect(story['text'], 'Soup when you are ill');
    final doc = RichDocument.tryParse(story['content'])!;
    expect(doc.style, WritingStyle.poetic);
    expect(doc.blocks.single.spans.first.text, 'Soup');
    expect(doc.blocks.single.spans.first.marks, {RichMark.italic});
    expect(doc.plainText, story['text']);
  });

  testWidgets('profile cards render formatted and legacy stories', (t) async {
    final api = _Api();
    await t.pumpWidget(
      host(
        api,
        const Column(
          children: [
            StoryMomentCard(
              story: {
                'prompt_id': 'care',
                'text': '• Soup',
                'content': {
                  'version': 1,
                  'style': 'typewriter',
                  'blocks': [
                    {
                      'type': 'bullet',
                      'spans': [
                        {'text': 'Soup'},
                      ],
                    },
                  ],
                },
              },
            ),
            StoryMomentCard(
              story: {'prompt_id': 'weekend', 'text': 'An older plain story'},
            ),
          ],
        ),
      ),
    );
    expect(find.byType(RichDocumentView), findsOneWidget);
    expect(find.text('•'), findsOneWidget);
    expect(find.text('An older plain story'), findsOneWidget);
  });
}
