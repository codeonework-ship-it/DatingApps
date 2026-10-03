import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/blog/blog_screen.dart';
import 'package:verified_dating_app/features/celebrations/celebrations_data.dart';
import 'package:verified_dating_app/features/celebrations/rose_rain.dart';
import 'package:verified_dating_app/features/photo_themes/photo_theme_gallery_screen.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';

// The wall-tier celebration (rose rain): the host asks the server for new
// celebrations, opens the dialog for each, marks it seen, and "See chapter"
// / "See photo" opens the work that reached the walls.

final _en = qaL10n(const Locale('en'));

Map<String, dynamic> _chapter() => {
  'id': 'c-1',
  'kind': 'chapter',
  'content_id': 'post-1',
  'tier': 1,
  'reach': 50,
  'title': 'A story',
};

Map<String, dynamic> _photo() => {
  'id': 'c-2',
  'kind': 'photo',
  'content_id': 'entry-1',
  'theme_id': 'theme-1',
  'tier': 2,
  'reach': 100,
  'title': 'Golden hour',
};

QaApi _api(List<Map<String, dynamic>> celebrations) {
  var listed = 0;
  return QaApi()
    ..on(
      'GET /walls/celebrations',
      (_) => qaOk({
        'celebrations': listed++ == 0 ? celebrations : const <Object>[],
      }),
    )
    ..on('POST /walls/celebrations/*/seen', (_) => qaOk({'seen': true}));
}

const _host = Scaffold(body: Stack(children: [RoseRainHost()]));

void main() {
  testWidgets('a new wall tier opens the celebration dialog over the app '
      '[case:celebrations.rose_rain.showgeneraldialog_open.action]', (
    tester,
  ) async {
    final api = _api([_chapter()]);
    await pumpQa(tester, api, _host);
    expect(api.sent('GET', '/walls/celebrations'), hasLength(1));
    expect(find.byType(RoseRainOverlay), findsOneWidget);
    expect(find.text('Your chapter reached 50 walls'), findsOneWidget);
    // A dismissible modal barrier, announced by its label.
    final barrier = tester
        .widgetList<ModalBarrier>(find.byType(ModalBarrier))
        .last;
    expect(barrier.dismissible, isTrue);
    expect(barrier.semanticsLabel, _en.celebrationBarrier);
    // Nothing is marked seen until the member closes it.
    expect(api.sent('POST', '/walls/celebrations/*/seen'), isEmpty);

    // Tapping outside closes it and marks it seen.
    await tester.tapAt(const Offset(8, 8));
    await qaSettle(tester);
    expect(find.byType(RoseRainOverlay), findsNothing);
    expect(api.sent('POST', '/walls/celebrations/c-1/seen'), hasLength(1));
    await qaUnmountScreen(tester);
  });

  testWidgets('no new tier, no dialog; returning to the app checks again '
      '[case:celebrations.rose_rain.showgeneraldialog_open.action]', (
    tester,
  ) async {
    final api = QaApi()
      ..json('GET /walls/celebrations', {'celebrations': const <Object>[]});
    await pumpQa(tester, api, _host);
    expect(find.byType(RoseRainOverlay), findsNothing);
    expect(api.sent('GET', '/walls/celebrations'), hasLength(1));

    api.json('GET /walls/celebrations', {
      'celebrations': [_photo()],
    });
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await qaSettle(tester);
    expect(api.sent('GET', '/walls/celebrations'), hasLength(2));
    expect(find.text('Your photo reached 100 walls'), findsOneWidget);
    await qaUnmountScreen(tester);
  });

  testWidgets('See chapter marks the celebration seen and opens the chapter '
      '[case:celebrations.rose_rain.rose_rain_open.action]', (tester) async {
    final api = _api([_chapter()]);
    await pumpQa(tester, api, _host);
    expect(find.text(_en.celebrationSeeChapter), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('qa.rose_rain.open')));
    await qaSettle(tester);
    expect(find.byType(RoseRainOverlay), findsNothing);
    expect(api.sent('POST', '/walls/celebrations/c-1/seen'), hasLength(1));
    final detail = tester.widget<BlogDetailScreen>(
      find.byType(BlogDetailScreen),
    );
    expect(detail.id, 'post-1');
    await qaUnmountScreen(tester);
  });

  testWidgets('See photo opens the photo theme the photo was shared to '
      '[case:celebrations.rose_rain.rose_rain_open.action]', (tester) async {
    final api = _api([_photo()]);
    await pumpQa(tester, api, _host);
    expect(find.text(_en.celebrationSeePhoto), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('qa.rose_rain.open')));
    await qaSettle(tester);
    expect(api.sent('POST', '/walls/celebrations/c-2/seen'), hasLength(1));
    final gallery = tester.widget<PhotoThemeGalleryScreen>(
      find.byType(PhotoThemeGalleryScreen),
    );
    expect(gallery.themeId, 'theme-1');
    await qaUnmountScreen(tester);
  });

  testWidgets('Lovely closes the card, marks it seen and opens nothing; the '
      'next celebration follows '
      '[case:celebrations.rose_rain.rose_rain_close.action]', (tester) async {
    final api = _api([_chapter(), _photo()]);
    await pumpQa(tester, api, _host);
    expect(find.text('Your chapter reached 50 walls'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('qa.rose_rain.close')));
    await qaSettle(tester);
    expect(api.sent('POST', '/walls/celebrations/c-1/seen'), hasLength(1));
    expect(find.byType(BlogDetailScreen), findsNothing);
    expect(find.text('Your chapter reached 50 walls'), findsNothing);
    expect(find.text('Your photo reached 100 walls'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('qa.rose_rain.close')));
    await qaSettle(tester);
    expect(api.sent('POST', '/walls/celebrations/c-2/seen'), hasLength(1));
    expect(find.byType(RoseRainOverlay), findsNothing);
    expect(find.byType(PhotoThemeGalleryScreen), findsNothing);
    await qaUnmountScreen(tester);
  });

  testWidgets('the celebration card renders in every locale with no English '
      'left [case:celebrations.rose_rain.l10n]', (tester) async {
    for (final json in [_chapter(), _photo()]) {
      final celebration = WallCelebration.fromJson(json);
      await qaExpectRendersInAllLocales(
        tester,
        QaApi(),
        () => RoseRainOverlay(celebration: celebration),
        expected: [
          celebration.headlineIn,
          celebration.messageIn,
          (l) => l.celebrationQuotedTitle(celebration.title),
          (l) => l.celebrationLovely,
          (l) => celebration.isPhoto
              ? l.celebrationSeePhoto
              : l.celebrationSeeChapter,
        ],
        // Some languages quote titles exactly as English does.
        allow: {_en.celebrationQuotedTitle(celebration.title)},
      );
    }
  });
}
