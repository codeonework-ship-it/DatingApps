// Test names carry literal catalog case ids, which can be long.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/blog/blog_screen.dart';
import 'package:verified_dating_app/features/photo_themes/photo_theme_widgets.dart';
import 'package:verified_dating_app/features/profile/widgets/cinematic_profile.dart';
import 'package:verified_dating_app/features/profile/widgets/profile_scenes.dart';
import 'package:verified_dating_app/features/profile/widgets/profile_showcase.dart';
import 'package:verified_dating_app/features/swipe/providers/profile_details_provider.dart';

import '../../support/qa_api.dart';

// Control-level tests for the profile widgets: the full-screen gallery and
// the photo reel that opens it (cinematic_profile.dart), the bio's "Read
// more" (profile_scenes.dart) and "Writing & moments" with its consent
// switch (profile_showcase.dart).

final _en = qaL10n(const Locale('en'));

const _photos = [
  'https://example.com/a.jpg',
  'https://example.com/b.jpg',
  'https://example.com/c.jpg',
];

/// Five photos: the reel shows photos 2-5, enough for its pages to move.
const _reelPhotos = [
  ..._photos,
  'https://example.com/d.jpg',
  'https://example.com/e.jpg',
];

const _close = ValueKey('qa.profile.gallery.close');
const _galleryPages = ValueKey('qa.profile.gallery');

/// Opens the gallery like a profile does and records what it hands back.
class _GalleryOpener extends StatelessWidget {
  const _GalleryOpener(this.results, {this.initialIndex = 0});
  final List<int?> results;
  final int initialIndex;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        key: const ValueKey('qa.test.open_gallery'),
        onPressed: () async => results.add(
          await openProfileGallery(
            context,
            userId: 'maya',
            name: 'Maya',
            photos: _photos,
            initialIndex: initialIndex,
          ),
        ),
        child: const Text('photos'),
      ),
    ),
  );
}

Future<List<int?>> _openGallery(
  WidgetTester tester, {
  int initialIndex = 0,
  Locale? locale,
}) async {
  final results = <int?>[];
  await pumpQa(
    tester,
    QaApi(),
    _GalleryOpener(results, initialIndex: initialIndex),
    locale: locale,
  );
  await tester.tap(find.byKey(const ValueKey('qa.test.open_gallery')));
  await qaSettle(tester);
  return results;
}

/// The reel as profiles use it: the gallery opens from a frame.
class _Reel extends StatelessWidget {
  const _Reel();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListView(
      children: [
        ProfilePhotoReel(
          userId: 'maya',
          name: 'Maya',
          photos: _reelPhotos,
          onOpen: (index) => openProfileGallery(
            context,
            userId: 'maya',
            name: 'Maya',
            photos: _reelPhotos,
            initialIndex: index,
          ),
        ),
      ],
    ),
  );
}

ProfileDetails _details({String bio = 'Architect by day.'}) => ProfileDetails(
  userId: 'maya',
  name: 'Maya',
  dateOfBirth: null,
  publicAge: 29,
  gender: 'F',
  bio: bio,
  additionalInfo: null,
  heightCm: 167,
  education: null,
  profession: 'Architect',
  drinking: 'Socially',
  smoking: null,
  religion: null,
  motherTongue: null,
  relationshipStatus: null,
  personalityType: null,
  partyLover: false,
  country: null,
  regionState: null,
  city: null,
  instagramHandle: null,
  hobbies: const ['Pottery'],
  favoriteBooks: const [],
  favoriteNovels: const [],
  favoriteSongs: const [],
  extraCurriculars: const [],
  intentTags: const [],
  languageTags: const [],
  isVerified: true,
  photoUrls: const [],
);

const _chapter = {
  'id': 'c1',
  'title': 'Slow Sundays',
  'excerpt': 'Coffee, a long walk and a market.',
  'published_at': '2026-09-30T10:00:00Z',
  'like_count': 4,
  'comment_count': 1,
};

const _wallPhoto = {
  'id': 'w1',
  'theme_id': 't1',
  'author_id': 'them',
  'author_name': 'Rhea',
  'caption': 'Golden hour on the pier',
  'alt_text': 'A pier at sunset',
  'mine': false,
};

/// Showcase API: [enabled] is the consent; PUT changes it.
QaApi _showcaseApi({
  required bool enabled,
  List<Map<String, Object?>> chapters = const [_chapter],
  List<Map<String, Object?>> photos = const [],
}) {
  var visible = enabled;
  return QaApi()
    ..on(
      'GET /profile/*/showcase',
      (_) => qaOk({'enabled': visible, 'chapters': chapters, 'photos': photos}),
    )
    ..on('GET /profile/*/showcase/consent', (_) => qaOk({'visible': visible}))
    ..on('PUT /profile/*/showcase/consent', (c) {
      visible = c.body['visible'] == true;
      return qaOk({'visible': visible});
    })
    ..json('POST /walls/views', {'recorded': true});
}

Future<void> _pumpScene(
  WidgetTester tester,
  QaApi api,
  Widget scene, {
  Locale? locale,
}) => pumpQa(
  tester,
  api,
  Scaffold(body: SingleChildScrollView(child: scene)),
  locale: locale,
);

void main() {
  group('ProfileGalleryScreen', () {
    testWidgets('swiping moves through the photos and the counter follows '
        '[case:profile.cinematic_profile.profile_gallery_pagechanged.action]', (
      tester,
    ) async {
      await _openGallery(tester);
      expect(find.text('1 / 3'), findsOneWidget);
      await tester.fling(
        find.byKey(_galleryPages),
        const Offset(-400, 0),
        1500,
      );
      await qaSettle(tester);
      expect(find.text('2 / 3'), findsOneWidget);
      await tester.fling(
        find.byKey(_galleryPages),
        const Offset(-400, 0),
        1500,
      );
      await qaSettle(tester);
      expect(find.text('3 / 3'), findsOneWidget);
      await tester.fling(find.byKey(_galleryPages), const Offset(400, 0), 1500);
      await qaSettle(tester);
      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('Close returns the photo that was showing '
        '[case:profile.cinematic_profile.profile_gallery_close.action]', (
      tester,
    ) async {
      final results = await _openGallery(tester, initialIndex: 1);
      expect(find.text('2 / 3'), findsOneWidget);
      await tester.fling(
        find.byKey(_galleryPages),
        const Offset(-400, 0),
        1500,
      );
      await qaSettle(tester);
      expect(find.byTooltip(_en.memberProfileCloseGallery), findsOneWidget);
      await tester.tap(find.byKey(_close));
      await qaSettle(tester);
      expect(find.byType(ProfileGalleryScreen), findsNothing);
      expect(results, [2]);
    });

    testWidgets('system back also closes with the photo that was showing '
        '[case:profile.cinematic_profile.profile_gallery_close.action]', (
      tester,
    ) async {
      final results = await _openGallery(tester, initialIndex: 2);
      await tester.binding.handlePopRoute();
      await qaSettle(tester);
      expect(find.byType(ProfileGalleryScreen), findsNothing);
      expect(results, [2]);
    });

    testWidgets('the reel jumps to the photo the gallery was closed on '
        '[case:profile.cinematic_profile.openers_handle_result]', (
      tester,
    ) async {
      await pumpQa(tester, QaApi(), const _Reel());
      expect(find.text('02 / 05'), findsOneWidget);
      await tester.tap(find.text('02'));
      await qaSettle(tester);
      expect(find.text('2 / 5'), findsOneWidget);
      for (var i = 0; i < 2; i++) {
        await tester.fling(
          find.byKey(_galleryPages),
          const Offset(-400, 0),
          1500,
        );
        await qaSettle(tester);
      }
      expect(find.text('4 / 5'), findsOneWidget);
      await tester.tap(find.byKey(_close));
      await qaSettle(tester);
      expect(find.byType(ProfileGalleryScreen), findsNothing);
      // The strip now starts at the photo the member was looking at.
      expect(find.text('04 / 05'), findsOneWidget);
    });

    testWidgets(
      'swiping the reel moves its counter '
      '[case:profile.cinematic_profile.view_full_screen_onpagechanged.action]',
      (tester) async {
        await pumpQa(tester, QaApi(), const _Reel());
        expect(find.text('02 / 05'), findsOneWidget);
        await tester.fling(find.byType(PageView), const Offset(-200, 0), 800);
        await qaSettle(tester);
        expect(find.text('03 / 05'), findsOneWidget);
        await tester.fling(find.byType(PageView), const Offset(200, 0), 800);
        await qaSettle(tester);
        expect(find.text('02 / 05'), findsOneWidget);
      },
    );

    testWidgets('renders translated in every locale '
        '[case:profile.cinematic_profile.l10n]', (tester) async {
      for (final locale in qaLocales) {
        await tester.pumpWidget(const SizedBox());
        final l10n = qaL10n(locale);
        await pumpQa(tester, QaApi(), const _Reel(), locale: locale);
        expect(
          find.text(l10n.memberProfilePhotos.toUpperCase()),
          findsOneWidget,
        );
        expect(find.text(l10n.memberProfileMorePhotos(4)), findsOneWidget);
        await tester.tap(find.text('02'));
        await qaSettle(tester);
        expect(find.byTooltip(l10n.memberProfileCloseGallery), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$locale');
      }
    });
  });

  group('ProfileScenes', () {
    testWidgets('Read more unfolds a long bio and Read less folds it '
        '[case:profile.profile_scenes.read_more.action]', (tester) async {
      final bio = List.filled(40, 'I build quiet houses by the sea.').join(' ');
      await pumpQa(
        tester,
        QaApi(),
        Scaffold(
          body: SingleChildScrollView(child: ProfilePullQuote(text: bio)),
        ),
      );
      Text quote() => tester.widget<Text>(find.text(bio));
      expect(quote().maxLines, 5);
      await tester.tap(find.text(_en.memberProfileReadMore));
      await qaSettle(tester);
      expect(quote().maxLines, isNull);
      expect(find.text(_en.memberProfileReadLess), findsOneWidget);
      await tester.ensureVisible(find.text(_en.memberProfileReadLess));
      await qaSettle(tester, frames: 2);
      await tester.tap(find.text(_en.memberProfileReadLess));
      await qaSettle(tester);
      expect(quote().maxLines, 5);
      expect(find.text(_en.memberProfileReadMore), findsOneWidget);
    });

    testWidgets('a short bio has no Read more '
        '[case:profile.profile_scenes.read_more.action]', (tester) async {
      await pumpQa(
        tester,
        QaApi(),
        const Scaffold(body: ProfilePullQuote(text: 'Short and sweet.')),
      );
      expect(find.text(_en.memberProfileReadMore), findsNothing);
    });

    testWidgets('renders translated in every locale '
        '[case:profile.profile_scenes.l10n]', (tester) async {
      for (final locale in qaLocales) {
        await tester.pumpWidget(const SizedBox());
        final l10n = qaL10n(locale);
        await _pumpScene(
          tester,
          QaApi(),
          ProfileScenes(details: _details()),
          locale: locale,
        );
        expect(
          find.text(l10n.memberProfileSceneAbout.toUpperCase()),
          findsOneWidget,
        );
        expect(
          find.text(l10n.memberProfileSceneBasics.toUpperCase()),
          findsOneWidget,
        );
        expect(
          find.text(l10n.memberProfileFactWork.toUpperCase()),
          findsOneWidget,
        );
        expect(find.text(l10n.memberProfileHeightCm(167)), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$locale');
      }
    });
  });

  group('ProfileShowcaseScene', () {
    const consent = ValueKey('qa.profile.showcase.consent');

    testWidgets(
      'the owner turns the showcase on and off; each change is '
      'saved [case:profile.profile_showcase.profile_showcase_consent.action]',
      (tester) async {
        final api = _showcaseApi(enabled: false);
        await _pumpScene(
          tester,
          api,
          const ProfileShowcaseScene(userId: 'me', isOwner: true),
        );
        expect(find.text(_en.profileShowcaseHiddenTitle), findsOneWidget);
        expect(
          tester.widget<SwitchListTile>(find.byKey(consent)).value,
          isFalse,
        );

        await tester.tap(find.byKey(consent));
        await qaSettle(tester);
        expect(api.sent('PUT', '/profile/me/showcase/consent').single.body, {
          'visible': true,
        });
        expect(
          tester.widget<SwitchListTile>(find.byKey(consent)).value,
          isTrue,
        );
        expect(find.text(_en.profileShowcaseSwitch), findsOneWidget);
        expect(
          api.sent('GET', '/profile/me/showcase'),
          hasLength(2),
          reason: 'the preview reloads with the new consent',
        );

        await tester.tap(find.byKey(consent));
        await qaSettle(tester);
        expect(
          api.sent('PUT', '/profile/me/showcase/consent').map((c) => c.body),
          [
            {'visible': true},
            {'visible': false},
          ],
        );
        expect(
          tester.widget<SwitchListTile>(find.byKey(consent)).value,
          isFalse,
        );
      },
    );

    testWidgets(
      'a failed consent save explains and the switch moves back '
      '[case:profile.profile_showcase.profile_showcase_consent.api_failure]',
      (tester) async {
        final api = _showcaseApi(enabled: false)
          ..fail(
            'PUT /profile/*/showcase/consent',
            message: 'Settings are locked',
          );
        await _pumpScene(
          tester,
          api,
          const ProfileShowcaseScene(userId: 'me', isOwner: true),
        );
        await tester.tap(find.byKey(consent));
        await qaSettle(tester);
        expect(qaSnackText(tester), 'Settings are locked');
        expect(api.sent('PUT', '/profile/*/showcase/consent'), hasLength(1));
        final tile = tester.widget<SwitchListTile>(find.byKey(consent));
        expect(tile.value, isFalse);
        expect(tile.onChanged, isNotNull);
        expect(find.text(_en.profileShowcaseHiddenTitle), findsOneWidget);
      },
    );

    testWidgets(
      'offline consent save uses the translated fallback '
      '[case:profile.profile_showcase.profile_showcase_consent.api_failure]',
      (tester) async {
        final api = _showcaseApi(enabled: false)
          ..on(
            'PUT /profile/*/showcase/consent',
            (_) => const QaReply(500, null),
          );
        await _pumpScene(
          tester,
          api,
          const ProfileShowcaseScene(userId: 'me', isOwner: true),
        );
        await tester.tap(find.byKey(consent));
        await qaSettle(tester);
        expect(qaSnackText(tester), _en.profileShowcaseSaveFailed);
      },
    );

    testWidgets('"Read all their chapters" opens that writer\'s chapters '
        '[case:profile.profile_showcase.profile_showcase_read_all.action]', (
      tester,
    ) async {
      final api = _showcaseApi(enabled: true);
      await _pumpScene(tester, api, const ProfileShowcaseScene(userId: 'them'));
      final readAll = find.byKey(
        const ValueKey('qa.profile.showcase.read_all'),
      );
      expect(find.text(_en.profileShowcaseReadAll), findsOneWidget);
      await tester.ensureVisible(readAll);
      await tester.tap(readAll);
      await qaSettle(tester);
      final blog = tester.widget<BlogScreen>(find.byType(BlogScreen));
      expect(blog.authorId, 'them');
    });

    testWidgets(
      'a chapter opens the chapter and counts one view '
      '[case:profile.profile_showcase.favorite_border_rounded_icon_fav.action]',
      (tester) async {
        final api = _showcaseApi(enabled: true);
        await _pumpScene(
          tester,
          api,
          const ProfileShowcaseScene(userId: 'them'),
        );
        await tester.tap(find.text('Slow Sundays'));
        await qaSettle(tester);
        expect(api.sent('POST', '/walls/views').single.body, {
          'kind': 'chapter',
          'id': 'c1',
        });
        expect(
          tester.widget<BlogDetailScreen>(find.byType(BlogDetailScreen)).id,
          'c1',
        );
      },
    );

    testWidgets(
      'the chapter still opens when the view cannot be counted '
      '[case:profile.profile_showcase.favorite_border_rounded_icon_fav.api_failure]',
      (tester) async {
        final api = _showcaseApi(enabled: true)..offline('POST /walls/views');
        await _pumpScene(
          tester,
          api,
          const ProfileShowcaseScene(userId: 'them'),
        );
        await tester.tap(find.text('Slow Sundays'));
        await qaSettle(tester);
        expect(api.sent('POST', '/walls/views'), hasLength(1));
        expect(find.byType(BlogDetailScreen), findsOneWidget);
        expect(qaSnackText(tester), isNull, reason: 'a view count is silent');
      },
    );

    testWidgets('a wall photo opens larger and counts one view '
        '[case:profile.profile_showcase.themeentrytile_ontap.action]', (
      tester,
    ) async {
      final api = _showcaseApi(enabled: true, photos: [_wallPhoto]);
      await _pumpScene(tester, api, const ProfileShowcaseScene(userId: 'them'));
      final tile = find.byType(ThemeEntryTile);
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await qaSettle(tester);
      expect(api.sent('POST', '/walls/views').single.body, {
        'kind': 'photo',
        'id': 'w1',
      });
      expect(find.byType(ThemeEntrySheet), findsOneWidget);
      expect(
        tester.widget<ThemeEntrySheet>(find.byType(ThemeEntrySheet)).entry.id,
        'w1',
      );
    });

    testWidgets('the photo still opens when the view cannot be counted '
        '[case:profile.profile_showcase.themeentrytile_ontap.api_failure]', (
      tester,
    ) async {
      final api = _showcaseApi(enabled: true, photos: [_wallPhoto])
        ..fail('POST /walls/views');
      await _pumpScene(tester, api, const ProfileShowcaseScene(userId: 'them'));
      final tile = find.byType(ThemeEntryTile);
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await qaSettle(tester);
      expect(api.sent('POST', '/walls/views'), hasLength(1));
      expect(find.byType(ThemeEntrySheet), findsOneWidget);
    });

    testWidgets('renders translated in every locale '
        '[case:profile.profile_showcase.l10n]', (tester) async {
      for (final locale in qaLocales) {
        await tester.pumpWidget(const SizedBox());
        final l10n = qaL10n(locale);
        await _pumpScene(
          tester,
          _showcaseApi(enabled: false, photos: [_wallPhoto]),
          const ProfileShowcaseScene(userId: 'me', isOwner: true),
          locale: locale,
        );
        expect(find.text(l10n.profileShowcaseTitleSelf), findsOneWidget);
        expect(find.text(l10n.profileShowcaseHiddenTitle), findsOneWidget);
        expect(find.text(l10n.profileShowcaseChapters), findsOneWidget);
        expect(find.text(l10n.profileShowcasePhotos), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$locale');
      }
    });
  });
}
