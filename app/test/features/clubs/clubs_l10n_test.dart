import 'package:dio/dio.dart';
import 'package:flutter/material.dart' hide Title;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/clubs/club_detail_screen.dart';
import 'package:verified_dating_app/features/clubs/club_widgets.dart';
import 'package:verified_dating_app/features/clubs/clubs_data.dart';
import 'package:verified_dating_app/features/clubs/clubs_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

/// The clubs screens read every label from [AppLocalizations]: in German the
/// chrome, counts and ratings are German while club and title names stay as
/// their members wrote them.
class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

const _title = {
  'id': 'title-1',
  'kind': 'book',
  'title': 'Piranesi',
  'creator': 'Susanna Clarke',
  'release_year': 2020,
  'average_rating': 4.5,
  'review_count': 2,
};

final _selection = {
  'id': 'sel-1',
  'week_start': mondayOf(DateTime.now()),
  'note': 'Start with the first notebook.',
  'title': _title,
  'post_count': 3,
};

final _club = {
  'id': 'club-1',
  'kind': 'book',
  'name': 'Sunday Slow Reads',
  'description': 'One chapter at a time.',
  'owner_id': 'me',
  'member_count': 8,
  'my_role': 'owner',
  'version': 2,
  'moderation_state': 'active',
  'current_selection': _selection,
};

final _routes = <String, Object>{
  '/clubs': {
    'clubs': [_club],
    'eligible': true,
  },
  '/clubs/club-1': {
    'club': _club,
    'selections': [_selection],
  },
  '/clubs/club-1/posts': {'posts': const <Object>[], 'next_cursor': ''},
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

Widget _host(Locale locale, Widget child) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(_api()),
  ],
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

void main() {
  testWidgets('ClubsScreen speaks German', (t) async {
    await t.pumpWidget(_host(const Locale('de'), const ClubsScreen()));
    await t.pumpAndSettle();

    expect(find.text('Buch- & Filmclubs'), findsOneWidget);
    expect(find.text('Meine Clubs'), findsOneWidget);
    expect(find.text('Club gründen'), findsOneWidget);
    expect(find.text('Book & Film Clubs'), findsNothing);
    await t.scrollUntilVisible(find.text('Sunday Slow Reads'), 200);
    expect(find.text('8 Mitglieder'), findsOneWidget);
    expect(find.text('Buchclub'), findsOneWidget);
    expect(find.text('Diese Woche'), findsOneWidget);
    expect(find.text('Du leitest ihn'), findsOneWidget);
  });

  testWidgets('ClubDetailScreen formats ratings and plurals per locale', (
    t,
  ) async {
    await t.pumpWidget(
      _host(const Locale('de'), const ClubDetailScreen(clubId: 'club-1')),
    );
    await t.pumpAndSettle();

    expect(find.text('Club verlassen'), findsOneWidget);
    expect(find.text('4,5 · 2 Rezensionen'), findsOneWidget);
    expect(find.text('3 Beiträge in der Diskussion'), findsOneWidget);
    expect(find.text('„Start with the first notebook.“'), findsOneWidget);
    expect(find.text('Du: Leitung'), findsOneWidget);
  });

  testWidgets('Russian uses its few/many plural forms', (t) async {
    await t.pumpWidget(_host(const Locale('ru'), const ClubsScreen()));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Sunday Slow Reads'), 200);
    expect(find.text('8 участников'), findsOneWidget);
  });

  test('English ratings keep one decimal, rounding half up', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(formatClubRating(en, 4.25), 4.25.toStringAsFixed(1));
    expect(formatClubRating(en, 4), '4.0');
    expect(
      en.clubsRatingSummary(formatClubRating(en, 4.25), 17),
      '4.3 · 17 reviews',
    );
    expect(en.clubsRatingSummary('5.0', 1), '5.0 · 1 review');
    expect(weekLabel(en, '2026-01-05'), 'Week of 2026-01-05');
  });
}
