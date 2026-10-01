import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/photo_themes/photo_theme_gallery_screen.dart';
import 'package:verified_dating_app/features/photo_themes/photo_themes_data.dart';
import 'package:verified_dating_app/features/photo_themes/photo_themes_screen.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

const _sunday = {
  'id': 'theme-1',
  'slug': 'perfect-sunday',
  'title': 'My perfect Sunday',
  'prompt': 'Show us what an unhurried Sunday looks like for you.',
  'entry_count': 12,
  'my_entry_id': 'entry-1',
};

const _entry = {
  'id': 'entry-1',
  'theme_id': 'theme-1',
  'author_id': 'me',
  'author_name': 'Priya',
  'caption': 'Pancakes, then nowhere to be.',
  'alt_text': 'A stack of pancakes on a balcony table',
  'created_at': '2026-09-28T10:15:00Z',
  'mine': true,
};

/// Answers every GET from [routes] by path and records the requests.
class _FakeApi {
  _FakeApi(this.routes);
  final Map<String, Object> routes;
  final requests = <RequestOptions>[];

  Dio get dio => Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final body = routes[options.path];
          if (body == null) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 404,
                  data: {'error': 'not found'},
                ),
              ),
            );
            return;
          }
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: body,
            ),
          );
        },
      ),
    );
}

Widget _host(_FakeApi api, Widget child) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(api.dio),
  ],
  child: MaterialApp(home: child),
);

void main() {
  group('PhotoTheme.fromJson', () {
    test('parses every contract field', () {
      final theme = PhotoTheme.fromJson(_sunday);
      expect(theme.id, 'theme-1');
      expect(theme.slug, 'perfect-sunday');
      expect(theme.title, 'My perfect Sunday');
      expect(theme.prompt, startsWith('Show us'));
      expect(theme.entryCount, 12);
      expect(theme.myEntryId, 'entry-1');
      expect(theme.shared, isTrue);
    });

    test('an empty my_entry_id means the member has not shared', () {
      final theme = PhotoTheme.fromJson({..._sunday, 'my_entry_id': ''});
      expect(theme.shared, isFalse);
    });
  });

  test('ThemeEntry.fromJson parses the author, text and timestamp', () {
    final entry = ThemeEntry.fromJson(_entry);
    expect(entry.id, 'entry-1');
    expect(entry.themeId, 'theme-1');
    expect(entry.authorId, 'me');
    expect(entry.authorName, 'Priya');
    expect(entry.caption, 'Pancakes, then nowhere to be.');
    expect(entry.altText, 'A stack of pancakes on a balcony table');
    expect(entry.createdAt, DateTime.utc(2026, 9, 28, 10, 15));
    expect(entry.mine, isTrue);
  });

  test('PhotoThemeList.fromJson reads eligibility', () {
    final list = PhotoThemeList.fromJson({
      'themes': [_sunday],
      'eligible': false,
      'eligibility_message': 'Add two approved photos first.',
    });
    expect(list.themes.single.title, 'My perfect Sunday');
    expect(list.eligible, isFalse);
    expect(list.eligibilityMessage, 'Add two approved photos first.');
  });

  test('ThemeEntryPage.fromJson reads the theme, entries and cursor', () {
    final page = ThemeEntryPage.fromJson({
      'theme': _sunday,
      'entries': [_entry],
      'next_cursor': 'entry-0',
    });
    expect(page.theme?.id, 'theme-1');
    expect(page.entries.single.caption, 'Pancakes, then nowhere to be.');
    expect(page.next, 'entry-0');
  });

  testWidgets('PhotoThemesScreen renders themes from the API', (t) async {
    final api = _FakeApi({
      '/themes': {
        'themes': [
          _sunday,
          {
            ..._sunday,
            'id': 'theme-2',
            'slug': 'comfort-food',
            'title': 'Comfort food',
            'prompt': 'What do you cook on a hard day?',
            'entry_count': 0,
            'my_entry_id': '',
          },
        ],
        'eligible': false,
        'eligibility_message': 'Add two approved photos to share.',
      },
    });
    await t.pumpWidget(_host(api, const PhotoThemesScreen()));
    await t.pumpAndSettle();

    expect(api.requests.single.path, '/themes');
    expect(find.text('My perfect Sunday'), findsOneWidget);
    expect(find.text('12 shared'), findsOneWidget);
    expect(find.text('You shared ✓'), findsOneWidget);
    expect(find.text('Add two approved photos to share.'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Comfort food'), 200);
    expect(find.text('Comfort food'), findsOneWidget);
    expect(find.text('0 shared'), findsOneWidget);
    expect(find.text('Be the first to share →'), findsOneWidget);
  });

  testWidgets('gallery disables sharing once the member has shared', (t) async {
    final api = _FakeApi({
      '/themes': {
        'themes': [_sunday],
        'eligible': true,
        'eligibility_message': '',
      },
      '/themes/theme-1/entries': {
        'theme': _sunday,
        'entries': [
          _entry,
          {
            ..._entry,
            'id': 'entry-2',
            'author_id': 'other',
            'author_name': 'Sam',
            'caption': 'Long walk, short coffee.',
            'mine': false,
          },
        ],
        'next_cursor': 'entry-2',
      },
    });
    await t.pumpWidget(
      _host(api, const PhotoThemeGalleryScreen(themeId: 'theme-1')),
    );
    await t.pumpAndSettle();

    expect(find.text('Long walk, short coffee.'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
    expect(
      find.textContaining('You have shared for this theme'),
      findsOneWidget,
    );
    final fab = t.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(fab.onPressed, isNull);

    // Scroll to the very end so the button clears the floating action.
    await t.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await t.pumpAndSettle();
    await t.tap(find.text('Load more'));
    await t.pumpAndSettle();
    final paged = api.requests.where(
      (r) => r.queryParameters['before'] == 'entry-2',
    );
    expect(paged, hasLength(1));
  });
}
