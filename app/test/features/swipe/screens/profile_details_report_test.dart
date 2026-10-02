import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/safety_actions_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/friends/models/friend_social.dart';
import 'package:verified_dating_app/features/friends/providers/friend_social_provider.dart';
import 'package:verified_dating_app/features/intentional_dating/profile_stories.dart';
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
        safetyActionsProvider.overrideWith(_Safety.new),
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

// AND-12: closing the report sheet without sending anything still showed
// "Report submitted." (with an Appeal action) on the profile.

final _sent = <String>[];

class _Safety extends SafetyActions {
  _Safety(super.ref);
  @override
  Future<String?> reportUser({
    required String reportedUserId,
    required String reason,
    String? description,
    String? messageId,
  }) async {
    _sent.add(reportedUserId);
    // The API may answer without an id; a sent report is still a report.
    return null;
  }
}

void main() {
  setUp(_sent.clear);

  testWidgets('dismissing the report sheet does not claim a report was sent', (
    tester,
  ) async {
    // Test fonts are wider than the device's; give the sheet room. No photo
    // URLs, so no network image loads in the test.
    await _pump(
      tester,
      size: const Size(700, 1000),
      details: _details(photos: const []),
    );
    await tester.tap(
      find.byKey(const ValueKey('qa.profile_detail.report_button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Submit report'), findsOneWidget);

    // Back out of the sheet.
    await tester.tapAt(const Offset(350, 20));
    await tester.pumpAndSettle();
    expect(find.text('Submit report'), findsNothing);
    expect(_sent, isEmpty);
    expect(find.text('Report submitted.'), findsNothing);
  });

  testWidgets('a sent report is confirmed even without a report id', (
    tester,
  ) async {
    // Test fonts are wider than the device's; give the sheet room. No photo
    // URLs, so no network image loads in the test.
    await _pump(
      tester,
      size: const Size(700, 1000),
      details: _details(photos: const []),
    );
    await tester.tap(
      find.byKey(const ValueKey('qa.profile_detail.report_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    expect(_sent, ['anya']);
    expect(find.text('Report submitted.'), findsOneWidget);
    expect(find.text('Appeal'), findsOneWidget);
  });
}
