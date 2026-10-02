import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/first_chapter/chapter_studio_screen.dart';
import 'package:verified_dating_app/features/first_chapter/comfort_cards_screen.dart';
import 'package:verified_dating_app/features/first_chapter/chapter_provider.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

const scene = <String, dynamic>{
  'id': 'rain',
  'title': 'A little rain',
  'prompt': 'A rainy afternoon and a small budget.',
  'beginnings': ['Browse a tiny bookshop', 'Find a cosy coffee corner'],
  'surprises': ['Choose a book by its first line', 'Draw a postcard'],
  'venue': 'coffee',
};
Map<String, dynamic> pair({Map<String, dynamic>? chapter}) => {
  'scenes': [scene],
  'chapter': chapter,
  'mine': {'choices': <String>[], 'version': 0},
  'mutual': <String>[],
  'comfort': <dynamic>[],
  'can_give_back': false,
};

class Harness {
  final List<RequestOptions> writes = [];
  Map<String, dynamic> data = pair();
  bool fail = false;
  Future<void> show(
    WidgetTester tester, {
    double width = 390,
    double scale = 1,
    Widget? screen,
    Locale? locale,
  }) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) {
            if (r.method != 'GET') {
              writes.add(r);
              if (fail) {
                h.reject(
                  DioException(
                    requestOptions: r,
                    type: DioExceptionType.connectionError,
                  ),
                );
                return;
              }
            }
            Map<String, dynamic> body = r.path.endsWith('publications')
                ? {'publications': <dynamic>[]}
                : r.path.endsWith('comfort')
                ? {'cards': <dynamic>[], 'shared': false, 'version': 0}
                : data;
            h.resolve(
              Response<dynamic>(requestOptions: r, statusCode: 200, data: body),
            );
          },
        ),
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(dio)],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home:
              screen ??
              const ChapterStudioScreen(matchId: 'match', partnerName: 'Alex'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final finder = find.text(label);
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('the studio follows the app language', (tester) async {
    final h = Harness();
    await h.show(tester, locale: const Locale('de'));
    expect(find.text('First-Chapter-Studio'), findsOneWidget);
    expect(find.text('01 / Wähle deine Szene'), findsOneWidget);
    expect(
      find.textContaining('Du und Alex. Ein Anfang, eine unerwartete Wendung'),
      findsOneWidget,
    );
    // Scene text comes from the server and is not translated.
    expect(find.text('A little rain'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'scene start retains the same command ID after an uncertain save',
    (tester) async {
      final h = Harness()..fail = true;
      await h.show(tester);
      await h.tap(tester, 'A little rain');
      await h.tap(tester, 'Browse a tiny bookshop');
      await h.tap(tester, 'Start our chapter');
      await h.tap(tester, 'Start our chapter');
      expect(h.writes.length, 2);
      expect(h.writes[0].data['id'], h.writes[1].data['id']);
      expect(h.writes[0].data['action'], 'start');
      expect(h.writes[0].data['choice'], 'Browse a tiny bookshop');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('only the invited author sees surprise actions', (tester) async {
    final h = Harness()
      ..data = pair(
        chapter: {
          'id': 'chapter',
          'scene': 'rain',
          'beginning': 'Browse a tiny bookshop',
          'surprise': '',
          'version': 1,
          'my_turn': true,
        },
      );
    await h.show(tester);
    await h.tap(tester, 'Draw a postcard');
    expect(h.writes.single.data, {
      'action': 'surprise',
      'id': 'chapter',
      'version': 1,
      'choice': 'Draw a postcard',
    });
    expect(tester.takeException(), isNull);
  });
  testWidgets('a share needs the explicit public preview approval', (
    tester,
  ) async {
    final h = Harness();
    await h.show(tester);
    await h.tap(tester, 'A little rain');
    await h.tap(tester, 'Browse a tiny bookshop');
    await h.tap(tester, 'Pass the Chapter');
    expect(find.text('Preview your public chapter'), findsOneWidget);
    expect(h.writes, isEmpty);
    await h.tap(tester, 'Keep private');
    expect(h.writes, isEmpty);
    await h.tap(tester, 'Pass the Chapter');
    await h.tap(tester, 'Create share link');
    expect(
      h.writes.single.data.keys,
      unorderedEquals(['action', 'id', 'scene', 'beginning']),
    );
    expect(h.writes.single.data['beginning'], 'Browse a tiny bookshop');
  });
  testWidgets('green light selections stay local until saved privately', (
    tester,
  ) async {
    final h = Harness();
    await h.show(tester);
    await h.tap(tester, 'Try a call');
    expect(h.writes, isEmpty);
    await h.tap(tester, 'Save privately');
    expect(h.writes.single.method, 'PUT');
    expect(h.writes.single.data, {
      'choices': ['call'],
      'version': 0,
    });
    expect(find.text('Any shared next step will appear here.'), findsOneWidget);
  });
  testWidgets('comfort cards preserve original and label member translation', (
    tester,
  ) async {
    final h = Harness();
    await h.show(tester, screen: const ComfortCardsScreen());
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Arabic');
    await tester.enterText(fields.at(1), 'أفضل التحدث ببطء');
    await tester.enterText(fields.at(2), 'I prefer a slower pace');
    await tester.enterText(fields.at(3), 'English');
    await h.tap(tester, 'Add / replace this card in draft');
    expect(find.text('Member-provided translation · English'), findsOneWidget);
    await h.tap(tester, 'Save my choices');
    expect(h.writes.single.data['shared'], false);
    expect(h.writes.single.data['cards'][0]['original'], 'أفضل التحدث ببطء');
    expect(
      h.writes.single.data['cards'][0]['translation'],
      'I prefer a slower pace',
    );
  });
  for (final width in [320.0, 800.0]) {
    testWidgets('studio fits $width at large text', (tester) async {
      final h = Harness();
      await h.show(tester, width: width, scale: 1.6);
      await h.tap(tester, 'A little rain');
      expect(tester.takeException(), isNull);
    });
  }
  test('share links contain only an opaque publication identifier', () {
    final url = Uri.parse(chapterShareUrl('anonymous-card'));
    expect(url.path, '/chapter.html');
    expect(url.queryParameters, {'share': 'anonymous-card'});
  });
}
