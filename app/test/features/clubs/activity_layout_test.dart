import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/clubs/club_detail_screen.dart';
import 'package:verified_dating_app/features/clubs/clubs_data.dart';
import 'package:verified_dating_app/features/clubs/clubs_screen.dart';
import 'package:verified_dating_app/features/clubs/my_lists_screen.dart';
import 'package:verified_dating_app/features/clubs/title_detail_screen.dart';
import 'package:verified_dating_app/features/photo_themes/photo_theme_gallery_screen.dart';
import 'package:verified_dating_app/features/photo_themes/photo_themes_screen.dart';

import '../responsive/screen_matrix_harness.dart';

/// The screen matrix pumps these screens without data. This walks the same
/// device sizes with full, long-worded data so cards, pills and discussion
/// posts are checked for overflow where they actually appear.
class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

const _longName = 'The Extraordinarily Long Sunday Afternoon Reading Society';

final _title = {
  'id': 'title-1',
  'kind': 'film',
  'title': 'Portrait of a Lady on Fire and Other Very Long Titles',
  'creator': 'Céline Sciamma',
  'release_year': 2019,
  'average_rating': 4.25,
  'review_count': 17,
};

final _selection = {
  'id': 'sel-1',
  'week_start': mondayOf(DateTime.now()),
  'note': 'Watch it twice if you can; the second time is different.',
  'title': _title,
  'post_count': 23,
};

final _club = {
  'id': 'club-1',
  'kind': 'film',
  'name': _longName,
  'description': 'Slow films, warm tea and honest opinions. ' * 4,
  'owner_id': 'me',
  'member_count': 128,
  'my_role': 'owner',
  'version': 3,
  'moderation_state': 'active',
  'current_selection': _selection,
};

Map<String, dynamic> _post(int i, {bool spoiler = false}) => {
  'id': 'p-$i',
  'club_id': 'club-1',
  'selection_id': 'sel-1',
  'author_id': i.isEven ? 'me' : 'u-$i',
  'author_name': 'Alexandria Montgomery-Whitfield',
  'body': 'That final scene stayed with me all week. ' * 3,
  'has_spoilers': spoiler,
  'created_at': '2026-09-29T09:0$i:00Z',
  'mine': i.isEven,
  'hidden': i == 3,
};

final _review = {
  'id': 'r-1',
  'title_id': 'title-1',
  'author_id': 'u-2',
  'author_name': 'Alexandria Montgomery-Whitfield',
  'rating': 4,
  'body': 'Beautifully paced, and the ending earns every minute. ' * 3,
  'has_spoilers': true,
  'audience': 'community',
  'version': 1,
  'created_at': '2026-09-20T09:00:00Z',
  'updated_at': '2026-09-20T09:00:00Z',
  'mine': false,
};

final _theme = {
  'id': 'theme-1',
  'slug': 'where-i-feel-like-me',
  'title': 'Where I feel most like myself, wherever that is',
  'prompt': 'The place you go when you need to come back to yourself.',
  'entry_count': 1240,
  'my_entry_id': 'entry-1',
};

Map<String, dynamic> _entry(int i) => {
  'id': 'entry-$i',
  'theme_id': 'theme-1',
  'author_id': i == 1 ? 'me' : 'u-$i',
  'author_name': 'Alexandria Montgomery-Whitfield',
  'caption': 'The bench by the lake where the ducks know my name. ' * 2,
  'alt_text': 'A wooden bench beside a lake at dusk',
  'created_at': '2026-09-28T10:15:00Z',
  'mine': i == 1,
};

final _routes = <String, Object>{
  '/clubs': {
    'clubs': [
      _club,
      {..._club, 'id': 'club-2', 'kind': 'book', 'current_selection': null},
    ],
    'eligible': false,
  },
  '/clubs/club-1': {
    'club': _club,
    'selections': [
      _selection,
      {..._selection, 'id': 'sel-0', 'week_start': '2026-09-21'},
    ],
  },
  '/clubs/club-1/posts': {
    'posts': [for (var i = 1; i <= 4; i++) _post(i, spoiler: i == 1)],
    'next_cursor': 'p-4',
  },
  '/clubs/titles/title-1': {
    'title': _title,
    'my_review': {..._review, 'id': 'r-0', 'mine': true, 'author_id': 'me'},
    'reviews': [_review],
  },
  '/clubs/lists': {
    'lists': [
      {
        'id': 'l-1',
        'owner_id': 'me',
        'owner_name': 'Alex',
        'name': 'Films that rearranged my whole personality',
        'kind': 'film',
        'audience': 'friends',
        'version': 1,
        'mine': true,
        'items': [
          {'title': _title, 'note': 'Rewatch every winter.', 'position': 1},
        ],
      },
    ],
  },
  '/themes': {
    'themes': [_theme, _theme],
    'eligible': false,
    'eligibility_message':
        'Complete your profile with two approved photos to share your own.',
  },
  '/themes/theme-1/entries': {
    'theme': _theme,
    'entries': [for (var i = 1; i <= 5; i++) _entry(i)],
    'next_cursor': 'entry-5',
  },
};

Dio _api() => Dio()
  ..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final body = _routes[options.path];
        if (body == null) {
          handler.reject(DioException(requestOptions: options));
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

/// Scrolls the main list to the end so every card is built and laid out,
/// and checks along the way that the screen's data really arrived.
Future<void> _scrollThrough(WidgetTester t, String probe) async {
  var seen = find.textContaining(probe).evaluate().isNotEmpty;
  final list = find.byType(Scrollable);
  for (var i = 0; i < 12 && list.evaluate().isNotEmpty; i++) {
    expect(find.textContaining('could not load'), findsNothing);
    await t.drag(list.first, const Offset(0, -400), warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 50));
    seen = seen || find.textContaining(probe).evaluate().isNotEmpty;
  }
  expect(seen, isTrue, reason: '"$probe" never appeared');
}

void main() {
  // Each screen with a piece of text that only appears once its data loads.
  final screens = <String, (Widget Function(), String)>{
    'PhotoThemesScreen': (PhotoThemesScreen.new, '1240 shared'),
    'PhotoThemeGalleryScreen': (
      () => const PhotoThemeGalleryScreen(themeId: 'theme-1'),
      'The place you go',
    ),
    'ClubsScreen': (ClubsScreen.new, 'You can look around'),
    'ClubDetailScreen': (
      () => const ClubDetailScreen(clubId: 'club-1'),
      '128 members',
    ),
    'TitleDetailScreen': (
      () => const TitleDetailScreen(titleId: 'title-1'),
      '4.3 · 17 reviews',
    ),
    'MyListsScreen': (MyListsScreen.new, 'Films that rearranged'),
  };
  final overrides = [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(_api()),
  ];
  final themes = {'light': AppTheme.lightTheme, 'dark': AppTheme.darkTheme};

  for (final MapEntry(key: name, value: (build, probe)) in screens.entries) {
    for (final MapEntry(key: device, value: size)
        in screenMatrixDevices.entries) {
      testWidgets('$name with data lays out on $device', (t) async {
        final errors = await pumpAndCollectLayoutErrors(
          t,
          build(),
          size,
          AppTheme.lightTheme,
          overrides: overrides,
          whileMounted: () => _scrollThrough(t, probe),
        );
        expect(errors, isEmpty, reason: errors.join('\n'));
      });
    }
    for (final MapEntry(key: label, value: theme) in themes.entries) {
      testWidgets('$name with data supports large text [$label]', (t) async {
        final errors = await pumpAndCollectLayoutErrors(
          t,
          build(),
          screenMatrixDevices['small phone 320x568']!,
          theme,
          textScaler: const TextScaler.linear(1.3),
          overrides: overrides,
          whileMounted: () => _scrollThrough(t, probe),
        );
        expect(errors, isEmpty, reason: errors.join('\n'));
      });
      testWidgets('$name with data meets accessibility guidelines [$label]', (
        t,
      ) async {
        final failing = <String>[];
        await pumpAndCollectLayoutErrors(
          t,
          build(),
          screenMatrixDevices[screenMatrixReferencePhone]!,
          theme,
          overrides: overrides,
          whileMounted: () async {
            for (final guideline in [
              labeledTapTargetGuideline,
              androidTapTargetGuideline,
              textContrastGuideline,
            ]) {
              final result = await guideline.evaluate(t);
              if (!result.passed) {
                failing.add('${guideline.description}\n${result.reason}');
              }
            }
            // Let timers started while the frame rendered for real finish.
            await t.pump(const Duration(seconds: 2));
          },
        );
        expect(failing, isEmpty, reason: failing.join('\n\n'));
      });
    }
  }
}
