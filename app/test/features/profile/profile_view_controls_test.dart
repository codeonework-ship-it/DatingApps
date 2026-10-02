// Test names carry literal catalog case ids, which can be long.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:verified_dating_app/features/intentional_dating/profile_stories.dart';
import 'package:verified_dating_app/features/profile/screens/edit_profile_screen.dart';
import 'package:verified_dating_app/features/profile/screens/profile_view_screen.dart';
import 'package:verified_dating_app/features/profile/screens/profile_viewers_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_photos_screen.dart';
import 'package:verified_dating_app/features/profile/widgets/cinematic_profile.dart';
import 'package:verified_dating_app/features/swipe/screens/liked_me_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/liked_profiles_screen.dart';

import '../../support/qa_api.dart';
import 'support/profile_bff.dart';

// Control-level tests for the member's own profile (ProfileViewScreen) and
// "Who viewed my profile" (ProfileViewersScreen): the account summary comes
// from GET /profile/{id}/summary, the preview from GET /profile/{id}, and
// every tool, tile and bar button is driven by tap with its outcome asserted.

final _en = qaL10n(const Locale('en'));

const _heroPhoto = ValueKey('qa.profile.hero_photo');
const _retry = ValueKey('qa.profile.retry');
const _barViewers = ValueKey('qa.profile.bar.viewers');
const _barRefresh = ValueKey('qa.profile.bar.refresh');
const _whoViewed = ValueKey('qa.profile.who_viewed');
const _whoLikedMe = ValueKey('qa.profile.who_liked_me');

Map<String, dynamic> _summary({String name = 'Maya'}) => {
  'user': {
    'id': 'me',
    'name': name,
    'date_of_birth': '1996-05-22',
    'gender': 'F',
    'bio': 'Architect by day, amateur baker by night.',
    'profession': 'Architect',
    'height_cm': 167,
    'profile_completion': 80,
    'is_verified': true,
  },
  'preferences': {
    'seeking_genders': ['M'],
    'min_age_years': 26,
    'max_age_years': 38,
    'max_distance_km': 25,
  },
  'stats': {'likes_count': 18, 'matches_count': 4, 'messages_count': 37},
};

const _photos = [
  'https://example.com/a.jpg',
  'https://example.com/b.jpg',
  'https://example.com/c.jpg',
];

/// The fake BFF for My Profile (plus the draft API the tools open).
QaApi _api({String name = 'Maya'}) {
  final api = QaApi();
  ProfileBff(api);
  api
    ..json('GET /profile/me/summary', _summary(name: name))
    ..json('GET /profile/me', {
      'profile': {'id': 'me', 'name': name, 'photo_urls': _photos},
    })
    ..json('GET /profile/me/viewers', {
      'viewers': [
        {
          'user_id': 'rhea',
          'name': 'Rhea',
          'photo_url': '',
          'viewed_at': '2026-09-30T18:45:00Z',
        },
      ],
    });
  return api;
}

Future<List<Object?>> _open(WidgetTester tester, QaApi api, {Locale? locale}) =>
    pumpQa(
      tester,
      api,
      const ProfileViewScreen(),
      locale: locale,
      extra: qaMasterDataOverrides(),
    );

/// Scrolls the profile until [finder] is built and sits mid-screen, clear
/// of the floating top bar.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await qaSettle(tester, frames: 2);
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await qaSettle(tester, frames: 2);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.tap(finder);
  await qaSettle(tester);
}

int _summaries(QaApi api) => api.sent('GET', '/profile/me/summary').length;

Future<void> _back(WidgetTester tester) async {
  await tester.pageBack();
  await qaSettle(tester);
}

void main() {
  group('photos', () {
    testWidgets('tapping the starring photo opens the gallery on photo 1 '
        '[case:profile.profile_view.starring_onopenphoto.action]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api);
      await tester.tap(find.byKey(_heroPhoto));
      await qaSettle(tester);
      final gallery = tester.widget<ProfileGalleryScreen>(
        find.byType(ProfileGalleryScreen),
      );
      expect(gallery.initialIndex, 0);
      expect(gallery.photos, _photos);
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('tapping a frame in the photo reel opens that photo '
        '[case:profile.profile_view.name_photo_index_of_count_onopen.action]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api);
      await _tap(tester, find.text('02'));
      expect(find.byType(ProfileGalleryScreen), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget);
    });
  });

  group('load, retry and refresh', () {
    testWidgets('a failed load shows the server reason; Retry loads it '
        '[case:profile.profile_view.retry.action]', (tester) async {
      final api = _api()
        ..fail('GET /profile/me/summary', message: 'Profile service is down');
      await _open(tester, api);
      await _reveal(tester, find.byKey(_retry));
      expect(find.text('Profile service is down'), findsOneWidget);

      api.json('GET /profile/me/summary', _summary());
      await _tap(tester, find.byKey(_retry));
      expect(_summaries(api), 2);
      expect(find.text('Profile service is down'), findsNothing);
      expect(find.byKey(_retry), findsNothing);
      expect(find.text('Maya'), findsWidgets);
    });

    testWidgets('Retry while still offline explains again and stays usable '
        '[case:profile.profile_view.retry.api_failure]', (tester) async {
      final api = _api()..offline('GET /profile/me/summary');
      await _open(tester, api);
      await _reveal(tester, find.byKey(_retry));
      expect(find.text(_en.memberProfileLoadFailed), findsOneWidget);
      await _tap(tester, find.byKey(_retry));
      expect(_summaries(api), 2, reason: 'one request per tap');
      expect(find.text(_en.memberProfileLoadFailed), findsOneWidget);
      expect(find.byKey(_retry), findsOneWidget);
    });

    testWidgets('Refresh reloads the summary and the published preview '
        '[case:profile.profile_view.refresh_profile.action]', (tester) async {
      final api = _api();
      await _open(tester, api);
      expect(_summaries(api), 1);
      api.json('GET /profile/me/summary', _summary(name: 'Maya R'));
      await tester.tap(find.byKey(_barRefresh));
      await qaSettle(tester);
      expect(_summaries(api), 2);
      expect(api.sent('GET', '/profile/me'), hasLength(2));
      expect(find.text('Maya R'), findsWidgets);
    });

    // Regression (2026-10-02): with a profile on screen, a failed refresh
    // said nothing at all.
    testWidgets('a failed refresh keeps the profile and says why '
        '[case:profile.profile_view.refresh_profile.api_failure]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api);
      api.fail('GET /profile/me/summary', message: 'Profile service is down');
      await tester.tap(find.byKey(_barRefresh));
      await qaSettle(tester);
      expect(qaSnackText(tester), 'Profile service is down');
      expect(find.text('Maya'), findsWidgets);
      expect(_summaries(api), 2);
      final refresh = tester.widget<IconButton>(find.byKey(_barRefresh));
      expect(refresh.onPressed, isNotNull);
    });

    testWidgets('an offline refresh says the profile could not load '
        '[case:profile.profile_view.refresh_profile.api_failure]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api);
      api.offline('GET /profile/me/summary');
      await tester.tap(find.byKey(_barRefresh));
      await qaSettle(tester);
      expect(qaSnackText(tester), _en.memberProfileLoadFailed);
    });
  });

  group('who viewed my profile', () {
    testWidgets('the tile opens the viewers list; coming back refreshes '
        '[case:profile.profile_view.who_viewed_my_profile.action]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api);
      await _tap(tester, find.byKey(_whoViewed));
      expect(find.byType(ProfileViewersScreen), findsOneWidget);
      final viewers = api.sent('GET', '/profile/me/viewers').single;
      expect(viewers.query, {'limit': 100});
      expect(find.text('Rhea'), findsOneWidget);
      expect(find.textContaining('2026'), findsOneWidget);

      await _back(tester);
      expect(find.byType(ProfileViewersScreen), findsNothing);
      expect(_summaries(api), 2, reason: 'the profile reloads on return');
    });

    testWidgets('a viewers list that fails explains; Retry loads it '
        '[case:profile.profile_view.who_viewed_my_profile.api_failure] '
        '[case:profile.profile_viewers.retry.action]', (tester) async {
      final api = _api();
      final ok = {
        'viewers': [
          {'user_id': 'rhea', 'name': 'Rhea', 'photo_url': '', 'viewed_at': ''},
        ],
      };
      api.fail('GET /profile/me/viewers');
      await _open(tester, api);
      await _tap(tester, find.byKey(_whoViewed));
      expect(find.text(_en.profileViewersLoadFailed), findsOneWidget);
      expect(find.text('Rhea'), findsNothing);

      // Still failing: one request per tap, the error stays.
      await tester.tap(find.text(_en.commonRetry));
      await qaSettle(tester);
      expect(api.sent('GET', '/profile/me/viewers'), hasLength(2));
      expect(find.text(_en.profileViewersLoadFailed), findsOneWidget);

      api.json('GET /profile/me/viewers', ok);
      await tester.tap(find.text(_en.commonRetry));
      await qaSettle(tester);
      expect(api.sent('GET', '/profile/me/viewers'), hasLength(3));
      expect(find.text('Rhea'), findsOneWidget);
      expect(find.text(_en.profileViewersViewedRecently), findsOneWidget);
    });

    testWidgets('the eye button in the top bar opens the viewers list '
        '[case:profile.profile_view.who_viewed_my_profile_2.action]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api);
      expect(find.byTooltip(_en.memberProfileWhoViewedTooltip), findsOneWidget);
      await tester.tap(find.byKey(_barViewers));
      await qaSettle(tester);
      expect(find.byType(ProfileViewersScreen), findsOneWidget);
      expect(find.text('Rhea'), findsOneWidget);
      await _back(tester);
      expect(_summaries(api), 2);
    });

    testWidgets('the top-bar viewers list explains a failure '
        '[case:profile.profile_view.who_viewed_my_profile_2.api_failure]', (
      tester,
    ) async {
      final api = _api()..offline('GET /profile/me/viewers');
      await _open(tester, api);
      await tester.tap(find.byKey(_barViewers));
      await qaSettle(tester);
      expect(find.text(_en.profileViewersLoadFailed), findsOneWidget);
      expect(find.text(_en.commonRetry), findsOneWidget);
      expect(api.sent('GET', '/profile/me/viewers'), hasLength(1));
    });

    testWidgets('no viewers yet says so '
        '[case:profile.profile_viewers.retry.action]', (tester) async {
      final api = _api()
        ..json('GET /profile/me/viewers', {'viewers': <Object>[]});
      await pumpQa(tester, api, const ProfileViewersScreen());
      expect(find.text(_en.profileViewersEmpty), findsOneWidget);
    });
  });

  group('behind the scenes', () {
    testWidgets('You liked opens the profiles I liked '
        '[case:profile.profile_view.you_liked.action]', (tester) async {
      final api = _api();
      await _open(tester, api);
      await _reveal(
        tester,
        find.byKey(const ValueKey('qa.profile.stat.liked')),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('qa.profile.stat.liked')),
          matching: find.text('18'),
        ),
        findsOneWidget,
      );
      await _tap(tester, find.byKey(const ValueKey('qa.profile.stat.liked')));
      expect(find.byType(LikedProfilesScreen), findsOneWidget);
    });

    testWidgets('Who liked me opens the members who liked me '
        '[case:profile.profile_view.profile_who_liked_me.action]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api);
      await _tap(tester, find.byKey(_whoLikedMe));
      expect(find.byType(LikedMeScreen), findsOneWidget);
    });
  });

  group('owner tools', () {
    testWidgets(
      'Edit profile opens Edit Profile; the preview reloads on return '
      '[case:profile.profile_view.outlinedbutton_icon_onpressed.action] '
      '[case:profile.profile_view.tool_edit.action]',
      (tester) async {
        final api = _api();
        await _open(tester, api);
        await _tap(tester, find.byKey(const ValueKey('qa.profile.tool.edit')));
        expect(find.byType(EditProfileScreen), findsOneWidget);
        expect(api.sent('GET', '/profile/me/draft'), isNotEmpty);
        await _back(tester);
        expect(_summaries(api), 2);
        expect(api.sent('GET', '/profile/me'), hasLength(2));
      },
    );

    testWidgets('Photos opens the photo editor '
        '[case:profile.profile_view.outlinedbutton_icon_onpressed.action] '
        '[case:profile.profile_view.tool_photos.action]', (tester) async {
      final api = _api();
      await _open(tester, api);
      await _tap(tester, find.byKey(const ValueKey('qa.profile.tool.photos')));
      expect(find.byType(SetupPhotosScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('qa.setup.photos.delete_p1')),
        findsOneWidget,
      );
      await _back(tester);
      expect(_summaries(api), 2);
    });

    testWidgets('Stories opens my profile stories '
        '[case:profile.profile_view.outlinedbutton_icon_onpressed.action] '
        '[case:profile.profile_view.tool_stories.action]', (tester) async {
      final api = _api();
      await _open(tester, api);
      await _tap(tester, find.byKey(const ValueKey('qa.profile.tool.stories')));
      expect(find.byType(ProfileStoriesScreen), findsOneWidget);
    });

    testWidgets('Viewers opens who viewed my profile '
        '[case:profile.profile_view.outlinedbutton_icon_onpressed.action] '
        '[case:profile.profile_view.tool_viewers.action]', (tester) async {
      final api = _api();
      await _open(tester, api);
      await _tap(tester, find.byKey(const ValueKey('qa.profile.tool.viewers')));
      expect(find.byType(ProfileViewersScreen), findsOneWidget);
      expect(find.text('Rhea'), findsOneWidget);
    });
  });

  testWidgets('My Profile renders translated in every locale '
      '[case:profile.profile_view.l10n]', (tester) async {
    for (final locale in qaLocales) {
      await tester.pumpWidget(const SizedBox());
      final api = _api();
      await _open(tester, api, locale: locale);
      final l10n = qaL10n(locale);
      expect(find.byTooltip(l10n.memberProfileRefreshTooltip), findsOneWidget);
      expect(
        find.byTooltip(l10n.memberProfileWhoViewedTooltip),
        findsOneWidget,
      );
      await _reveal(
        tester,
        find.byKey(const ValueKey('qa.profile.owner_console')),
      );
      expect(find.text(l10n.memberProfileToolEdit), findsOneWidget);
      expect(find.text(l10n.memberProfileToolPhotos), findsOneWidget);
      expect(find.text(l10n.memberProfileCompleteness(80)), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });

  testWidgets('Who viewed my profile renders translated in every locale '
      '[case:profile.profile_viewers.l10n]', (tester) async {
    for (final locale in qaLocales) {
      await tester.pumpWidget(const SizedBox());
      final api = _api();
      await pumpQa(tester, api, const ProfileViewersScreen(), locale: locale);
      final l10n = qaL10n(locale);
      expect(find.text(l10n.profileViewersTitle), findsOneWidget);
      expect(find.text('Rhea'), findsOneWidget);
      final at = DateFormat.yMMMd(
        locale.toString(),
      ).add_jm().format(DateTime.parse('2026-09-30T18:45:00Z').toLocal());
      expect(find.text(l10n.profileViewersViewedAt(at)), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });
}
