import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/friends/models/friend_social.dart';
import 'package:verified_dating_app/features/friends/providers/friend_social_provider.dart';
import 'package:verified_dating_app/features/intentional_dating/profile_stories.dart';
import 'package:verified_dating_app/features/profile/models/profile_models.dart';
import 'package:verified_dating_app/features/profile/providers/profile_provider.dart';
import 'package:verified_dating_app/features/profile/screens/profile_view_screen.dart';
import 'package:verified_dating_app/features/profile/widgets/cinematic_profile.dart';
import 'package:verified_dating_app/features/swipe/models/discovery_profile.dart';
import 'package:verified_dating_app/features/swipe/providers/profile_details_provider.dart';
import 'package:verified_dating_app/features/swipe/screens/profile_details_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

class _Profile extends ProfileNotifier {
  @override
  ProfileState build() {
    final now = DateTime(2026, 10, 1);
    return ProfileState(
      user: User(
        id: 'me',
        phoneNumber: '+10000000000',
        name: 'Maya',
        dateOfBirth: DateTime(1996, 5, 22),
        gender: 'F',
        bio: 'Architect by day, amateur baker by night.',
        heightCm: 167,
        profession: 'Architect',
        createdAt: now,
        profileCompletion: 80,
        isVerified: true,
      ),
      likesCount: 18,
      matchesCount: 4,
      messagesCount: 37,
    );
  }
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

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  ThemeData? theme,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_Auth.new),
        apiClientProvider.overrideWithValue(_api()),
        profileNotifierProvider.overrideWith(_Profile.new),
        runtimeFeatureFlagsProvider.overrideWith(
          (ref) => Stream.value(
            const RuntimeFeatureFlags({'intentional_dating_enabled': true}),
          ),
        ),
        // The published profile is not available yet: the preview falls
        // back to the account summary.
        profileDetailsProvider.overrideWith(
          (ref, id) async => throw StateError('unpublished'),
        ),
        publicVouchesProvider.overrideWith(
          (ref, id) async => const <PublicVouch>[],
        ),
        profileStoriesProvider.overrideWith(
          (ref, id) async => {'published': false, 'stories': <dynamic>[]},
        ),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _tools = [
  'qa.profile.tool.edit',
  'qa.profile.tool.photos',
  'qa.profile.tool.stories',
  'qa.profile.tool.viewers',
];

void main() {
  testWidgets('my profile shows how I appear, with owner tools', (
    tester,
  ) async {
    await _pump(tester, const ProfileViewScreen());
    expect(find.byType(CinematicProfileHero), findsOneWidget);
    expect(find.text('STARRING'), findsOneWidget);
    expect(find.text('Maya'), findsWidgets);
    expect(find.text('THIS IS HOW YOU APPEAR'), findsOneWidget);
    expect(find.text('Profile 80% complete'), findsOneWidget);
    for (final key in _tools) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }
    // The account summary fills the preview until the profile publishes.
    await tester.scrollUntilVisible(
      find.text('THE BASICS'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Architect'), findsWidgets);
    expect(find.text('167 cm'), findsOneWidget);
    // Behind the scenes keeps the private numbers and tiles.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('qa.profile.who_liked_me')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Behind the scenes'), findsOneWidget);
  });

  testWidgets('owner tools never appear on someone else\'s profile', (
    tester,
  ) async {
    await _pump(
      tester,
      const ProfileDetailsScreen(
        profile: DiscoveryProfile(
          id: 'anya',
          name: 'Anya',
          dateOfBirth: null,
          bio: null,
          additionalInfo: null,
          profession: null,
          education: null,
          instagramHandle: null,
          hobbies: [],
          favoriteSongs: [],
          extraCurriculars: [],
          intentTags: [],
          languageTags: [],
          isVerified: false,
          photoUrls: [],
        ),
      ),
    );
    for (final key in _tools) {
      expect(find.byKey(ValueKey(key)), findsNothing, reason: key);
    }
    expect(find.text('THIS IS HOW YOU APPEAR'), findsNothing);
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
          const ProfileViewScreen(),
          theme: entry.value,
          size: const Size(320, 568),
          textScale: 2,
        );
        for (var i = 0; i < 16; i++) {
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
