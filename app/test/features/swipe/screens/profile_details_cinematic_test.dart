import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/core/theme/cinematic_effects.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/friends/models/friend_social.dart';
import 'package:verified_dating_app/features/friends/providers/friend_social_provider.dart';
import 'package:verified_dating_app/features/intentional_dating/profile_stories.dart';
import 'package:verified_dating_app/features/profile/widgets/cinematic_profile.dart';
import 'package:verified_dating_app/features/swipe/models/discovery_profile.dart';
import 'package:verified_dating_app/features/swipe/providers/profile_details_provider.dart';
import 'package:verified_dating_app/features/swipe/screens/profile_details_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

Dio _api() => Dio()
  ..interceptors.add(
    InterceptorsWrapper(
      onRequest: (o, h) => h.resolve(
        Response<dynamic>(
          requestOptions: o,
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      ),
    ),
  );

const _longBio =
    'Product designer who sketches strangers on trains, hikes before sunrise '
    'and believes the best conversations happen over filter coffee that has '
    'gone slightly cold. Looking for someone curious, kind and a little bit '
    'silly, who likes long walks and longer talks.';

ProfileDetails _details({
  String bio = _longBio,
  List<String> hobbies = const ['Hiking', 'Sketching'],
  List<String> photos = const [
    'https://photos.test/0.jpg',
    'https://photos.test/1.jpg',
    'https://photos.test/2.jpg',
  ],
  int? heightCm = 165,
  String? profession = 'Product Designer',
  bool verified = true,
}) => ProfileDetails(
  userId: 'anya',
  name: 'Anya',
  dateOfBirth: null,
  publicAge: 29,
  gender: 'F',
  bio: bio,
  additionalInfo: null,
  heightCm: heightCm,
  education: null,
  profession: profession,
  drinking: null,
  smoking: null,
  religion: null,
  motherTongue: null,
  relationshipStatus: null,
  personalityType: null,
  partyLover: false,
  country: null,
  regionState: null,
  city: 'Bengaluru',
  instagramHandle: null,
  hobbies: hobbies,
  favoriteBooks: const [],
  favoriteNovels: const [],
  favoriteSongs: const [],
  extraCurriculars: const [],
  intentTags: const [],
  languageTags: const [],
  isVerified: verified,
  photoUrls: photos,
);

DiscoveryProfile _card({List<String> photos = const []}) => DiscoveryProfile(
  id: 'anya',
  name: 'Anya',
  dateOfBirth: null,
  publicAge: 29,
  bio: null,
  additionalInfo: null,
  profession: 'Product Designer',
  education: null,
  instagramHandle: null,
  hobbies: const [],
  favoriteSongs: const [],
  extraCurriculars: const [],
  intentTags: const [],
  languageTags: const [],
  isVerified: true,
  photoUrls: photos,
);

/// Pumps a launcher that opens the profile, so the pop result can be read.
Future<List<ProfileDetailsAction?>> _pump(
  WidgetTester tester, {
  ProfileDetails? details,
  ThemeData? theme,
  Size size = const Size(390, 844),
  double textScale = 1,
  bool reduceMotion = false,
  bool storiesOn = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final results = <ProfileDetailsAction?>[];
  final d = details ?? _details();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_Auth.new),
        apiClientProvider.overrideWithValue(_api()),
        runtimeFeatureFlagsProvider.overrideWith(
          (ref) => Stream.value(
            RuntimeFeatureFlags({'intentional_dating_enabled': storiesOn}),
          ),
        ),
        profileDetailsProvider.overrideWith((ref, id) async => d),
        publicVouchesProvider.overrideWith(
          (ref, id) async => const <PublicVouch>[],
        ),
        profileStoriesProvider.overrideWith(
          (ref, id) async => {'published': true, 'stories': <dynamic>[]},
        ),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  results.add(
                    await Navigator.of(context).push<ProfileDetailsAction>(
                      MaterialPageRoute(
                        builder: (_) => ProfileDetailsScreen(
                          profile: _card(photos: d.photoUrls),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  testWidgets('hero introduces the member by name and age', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    expect(find.byType(CinematicProfileHero), findsOneWidget);
    expect(find.text('INTRODUCING'), findsOneWidget);
    // Name and age are read as one label.
    expect(find.bySemanticsLabel('Anya, 29, Verified'), findsOneWidget);
    expect(find.text('Product Designer'), findsWidgets);
    expect(find.text('Bengaluru'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('keeps every automation handle the QA suites rely on', (
    tester,
  ) async {
    await _pump(tester);
    for (final key in [
      'qa.profile_detail.back_button',
      'qa.profile_detail.report_button',
      'qa.profile_detail.carousel',
      'qa.profile_detail.thumbnail_0',
      'qa.profile_detail.thumbnail_1',
      'qa.profile_detail.message_button',
      'qa.profile_detail.love_button',
    ]) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }
    // A long bio folds behind "Read more".
    final readMore = find.byKey(
      const ValueKey('qa.profile_detail.read_more_button'),
    );
    await tester.scrollUntilVisible(
      readMore,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Centre it, clear of the floating dock and the top bar.
    await Scrollable.ensureVisible(tester.element(readMore), alignment: 0.5);
    await tester.pumpAndSettle();
    expect(find.text('Read more'), findsOneWidget);
    await tester.tap(readMore);
    await tester.pumpAndSettle();
    expect(find.text('Read less'), findsOneWidget);
  });

  testWidgets('screen readers never hear a qa id; the hero photo keeps it as '
      'an identifier', (tester) async {
    // Regression (2026-10-03): the hero photo was announced as
    // "qa.profile_detail.thumbnail_0 Anya…, photo 1 of 3".
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    final labels = <String>[];
    final identifiers = <String>[];
    void walk(SemanticsNode node) {
      final data = node.getSemanticsData();
      labels.add(data.label);
      identifiers.add(data.identifier);
      node.visitChildren((child) {
        walk(child);
        return true;
      });
    }

    walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
    expect(labels.where((l) => l.contains('qa.')), isEmpty);
    expect(identifiers, contains('qa.profile_detail.thumbnail_0'));
    final hero = tester.getSemantics(
      find.byKey(const ValueKey('qa.profile_detail.thumbnail_0')),
    );
    expect(hero.label, startsWith('Anya'));
    semantics.dispose();
  });

  testWidgets('empty sections are hidden and no raw nulls are shown', (
    tester,
  ) async {
    await _pump(
      tester,
      details: _details(
        bio: '  ',
        hobbies: const [],
        heightCm: null,
        profession: null,
        verified: false,
        photos: const [],
      ),
    );
    expect(find.text('ABOUT'), findsNothing);
    expect(find.text('INTERESTS'), findsNothing);
    expect(find.text('LIFESTYLE'), findsNothing);
    expect(find.text('TRUST'), findsNothing);
    expect(find.text('PHOTOS'), findsNothing);
    // City is the only basic fact left.
    expect(find.text('THE BASICS'), findsOneWidget);
    expect(find.textContaining('null'), findsNothing);
    // No photo: the initials poster stands in, and the carousel handle
    // moves to it.
    expect(find.byType(ProfilePhotoFallback), findsOneWidget);
    expect(
      find.byKey(const ValueKey('qa.profile_detail.carousel')),
      findsOneWidget,
    );
  });

  testWidgets('tapping a photo opens the full-screen gallery', (tester) async {
    await _pump(tester);
    await tester.tap(
      find.byKey(const ValueKey('qa.profile_detail.thumbnail_0')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProfileGalleryScreen), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.fling(
      find.byKey(const ValueKey('qa.profile.gallery')),
      const Offset(-400, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('qa.profile.gallery.close')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileGalleryScreen), findsNothing);
    expect(find.byType(ProfileDetailsScreen), findsOneWidget);
  });

  testWidgets('the Ken Burns drift runs, and stops under reduced motion', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      tester
          .state<CinematicKenBurnsState>(find.byType(CinematicKenBurns))
          .isDrifting,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, reduceMotion: true);
    expect(
      tester
          .state<CinematicKenBurnsState>(find.byType(CinematicKenBurns))
          .isDrifting,
      isFalse,
    );
  });

  // The dock's real behaviour (Love saves a like for this member and
  // closes; Message opens the chat or explains) is covered end to end in
  // profile_actions_test.dart. It used to only pop an enum that several
  // openers ignored, so this file no longer asserts the pop alone.

  testWidgets('back returns none', (tester) async {
    final results = await _pump(tester);
    await tester.tap(
      find.byKey(const ValueKey('qa.profile_detail.back_button')),
    );
    await tester.pumpAndSettle();
    expect(results, [ProfileDetailsAction.none]);
  });

  testWidgets('report stays one tap away in the top bar', (tester) async {
    // Wide enough for the report sheet's own reason menu in the test font.
    await _pump(tester, size: const Size(800, 900));
    await tester.tap(
      find.byKey(const ValueKey('qa.profile_detail.report_button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Submit report'), findsWidgets);
  });

  for (final entry in {
    'light': AppTheme.lightTheme,
    'dark': AppTheme.darkTheme,
  }.entries) {
    testWidgets('no overflow at 320x568 with text at 2.0 (${entry.key})', (
      tester,
    ) async {
      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      try {
        await _pump(
          tester,
          theme: entry.value,
          size: const Size(320, 568),
          textScale: 2,
          storiesOn: true,
        );
        // Scroll the whole page through the viewport.
        for (var i = 0; i < 12; i++) {
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -400),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();
      } finally {
        FlutterError.onError = previous;
      }
      expect(
        errors
            .map((e) => '${e.exceptionAsString()} ${e.context}')
            .where((e) => e.contains('overflowed') || e.contains('RenderFlex')),
        isEmpty,
      );
    });
  }
}
