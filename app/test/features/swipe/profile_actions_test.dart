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
import 'package:verified_dating_app/features/matching/providers/match_provider.dart';
import 'package:verified_dating_app/features/messaging/screens/chat_screen.dart';
import 'package:verified_dating_app/features/swipe/models/discovery_profile.dart';
import 'package:verified_dating_app/features/swipe/providers/profile_details_provider.dart';
import 'package:verified_dating_app/features/swipe/screens/profile_details_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/spotlight_profiles_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

// P0 regression (2026-10-02): Message and Love on another member's profile
// did nothing when the profile was opened from Spotlight, Today or the
// liked/passed lists — the screen popped an enum the opener ignored, and the
// like itself acted on the deck's top card. The full Spotlight screen's
// buttons never called the API at all. These tests assert real outcomes:
// the request that reaches the server, and what the member sees.

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

class _Matches extends MatchNotifier {
  _Matches(this.initial);
  final List<Match> initial;
  @override
  MatchState build() => MatchState(matches: initial);
  @override
  Future<void> refresh() async {}
}

/// Records every request; `/swipe` answers with [swipeBody] or [swipeStatus].
class _Server {
  _Server({this.swipeBody = const {}, this.swipeStatus = 200});
  final Map<String, dynamic> swipeBody;
  final int swipeStatus;
  final requests = <RequestOptions>[];

  List<Map<String, dynamic>> get swipes => requests
      .where((r) => r.method == 'POST' && r.path == '/swipe')
      .map((r) => (r.data as Map).cast<String, dynamic>())
      .toList();

  Dio get dio => Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          requests.add(o);
          if (o.path == '/swipe' && swipeStatus != 200) {
            h.reject(
              DioException(
                requestOptions: o,
                response: Response(
                  requestOptions: o,
                  statusCode: swipeStatus,
                  data: {
                    'error_code': 'DAILY_LIKE_LIMIT_REACHED',
                    'kind': 'like',
                    'limit': 10,
                    'plan_name': 'Free',
                    'resets_at': '2026-10-03T00:00:00Z',
                  },
                ),
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }
          h.resolve(
            Response<dynamic>(
              requestOptions: o,
              statusCode: 200,
              data: o.path == '/swipe' ? swipeBody : <String, dynamic>{},
            ),
          );
        },
      ),
    );
}

DiscoveryProfile _anya() => const DiscoveryProfile(
  id: 'anya',
  name: 'Anya',
  dateOfBirth: null,
  publicAge: 29,
  bio: 'Sketches strangers on trains.',
  additionalInfo: null,
  profession: 'Designer',
  education: null,
  instagramHandle: null,
  hobbies: [],
  favoriteSongs: [],
  extraCurriculars: [],
  intentTags: [],
  languageTags: [],
  isVerified: true,
  photoUrls: [],
);

ProfileDetails _details() => ProfileDetails(
  userId: 'anya',
  name: 'Anya',
  dateOfBirth: null,
  publicAge: 29,
  gender: 'F',
  bio: 'Sketches strangers on trains.',
  additionalInfo: null,
  heightCm: null,
  education: null,
  profession: 'Designer',
  drinking: null,
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
  hobbies: const [],
  favoriteBooks: const [],
  favoriteNovels: const [],
  favoriteSongs: const [],
  extraCurriculars: const [],
  intentTags: const [],
  languageTags: const [],
  isVerified: true,
  photoUrls: const [],
);

Match _matchWithAnya() => Match(
  id: 'match-1',
  userId: 'anya',
  userName: 'Anya',
  userPhoto: '',
  lastMessage: 'Hi',
  lastMessageTime: DateTime(2026, 10, 2),
  unreadCount: 0,
  isOnline: false,
);

/// Opens [screen] from a launcher, like every real entry point does (the
/// deck is empty: nothing may depend on it). Returns the pop results.
Future<List<Object?>> _open(
  WidgetTester tester,
  _Server server,
  Widget Function() screen, {
  List<Match> matches = const [],
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final results = <Object?>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_Auth.new),
        apiClientProvider.overrideWithValue(server.dio),
        matchNotifierProvider.overrideWith(() => _Matches(matches)),
        runtimeFeatureFlagsProvider.overrideWith(
          (ref) => Stream.value(RuntimeFeatureFlags.defaults),
        ),
        profileDetailsProvider.overrideWith((ref, id) async => _details()),
        publicVouchesProvider.overrideWith(
          (ref, id) async => const <PublicVouch>[],
        ),
        profileStoriesProvider.overrideWith(
          (ref, id) async => {'published': false, 'stories': <dynamic>[]},
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => results.add(
                await Navigator.of(
                  context,
                ).push<Object?>(MaterialPageRoute(builder: (_) => screen())),
              ),
              child: const Text('open'),
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

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _love = ValueKey('qa.profile_detail.love_button');
const _message = ValueKey('qa.profile_detail.message_button');

void main() {
  group('profile page (any entry point, empty deck)', () {
    testWidgets(
      'Love saves one like for this member and closes '
      '[case:swipe.profile_details.profile_detail_love_button_love.action] '
      '[case:swipe.profile_details.profile_detail_love_button_love.api_contract]',
      (tester) async {
        final server = _Server();
        final results = await _open(
          tester,
          server,
          () => ProfileDetailsScreen(profile: _anya()),
        );
        await tester.tap(find.byKey(_love));
        await tester.tap(find.byKey(_love), warnIfMissed: false); // double tap
        await _settle(tester);

        expect(server.swipes, [
          {'user_id': 'me', 'target_user_id': 'anya', 'is_like': true},
        ]);
        expect(results, [ProfileDetailsAction.love]);
        expect(find.byType(ProfileDetailsScreen), findsNothing);
        expect(find.text('Super like sent to Anya'), findsOneWidget);
      },
    );

    testWidgets('Love that makes a match shows the match screen '
        '[case:swipe.profile_details.openers_handle_result]', (tester) async {
      final server = _Server(swipeBody: {'match_id': 'match-9'});
      await _open(tester, server, () => ProfileDetailsScreen(profile: _anya()));
      await tester.tap(find.byKey(_love));
      await _settle(tester);
      // Network photos cannot load in widget tests.
      tester.takeException();
      expect(server.swipes, hasLength(1));
      expect(find.byType(ProfileDetailsScreen), findsNothing);
      expect(find.text('open'), findsNothing, reason: 'match screen on top');
    });

    testWidgets(
      'Message with an existing match opens the chat, no like '
      '[case:swipe.profile_details.profile_detail_message_button_message.action]',
      (tester) async {
        final server = _Server();
        await _open(
          tester,
          server,
          () => ProfileDetailsScreen(profile: _anya()),
          matches: [_matchWithAnya()],
        );
        await tester.tap(find.byKey(_message));
        await _settle(tester);
        expect(find.byType(ChatScreen), findsOneWidget);
        expect(server.swipes, isEmpty);
      },
    );

    testWidgets(
      'Message without a match sends a like, explains, stays '
      '[case:swipe.profile_details.profile_detail_message_button_message.api_contract]',
      (tester) async {
        final server = _Server();
        final results = await _open(
          tester,
          server,
          () => ProfileDetailsScreen(profile: _anya()),
        );
        await tester.tap(find.byKey(_message));
        await _settle(tester);
        expect(server.swipes, [
          {'user_id': 'me', 'target_user_id': 'anya', 'is_like': true},
        ]);
        expect(
          find.text(
            'Love sent to Anya. You can chat as soon as they like you back.',
          ),
          findsOneWidget,
        );
        expect(find.byType(ProfileDetailsScreen), findsOneWidget);
        expect(results, isEmpty, reason: 'it must not fall back to the list');
      },
    );

    testWidgets('Message whose like makes the match opens the chat', (
      tester,
    ) async {
      final server = _Server(swipeBody: {'match_id': 'match-9'});
      await _open(tester, server, () => ProfileDetailsScreen(profile: _anya()));
      await tester.tap(find.byKey(_message));
      await _settle(tester);
      expect(find.byType(ChatScreen), findsOneWidget);
    });

    testWidgets(
      'the daily like limit is explained and the profile stays '
      '[case:swipe.profile_details.profile_detail_love_button_love.api_failure]',
      (tester) async {
        final server = _Server(swipeStatus: 429);
        final results = await _open(
          tester,
          server,
          () => ProfileDetailsScreen(profile: _anya()),
        );
        await tester.tap(find.byKey(_love));
        await _settle(tester);
        expect(find.byType(ProfileDetailsScreen), findsOneWidget);
        expect(results, isEmpty);
        expect(find.text('See plans'), findsOneWidget);
      },
    );

    testWidgets('a screen with its own rule (Liked you) is used instead '
        '[case:discover.profile_entry_points.liked_you.own_rule]', (
      tester,
    ) async {
      final server = _Server();
      var answered = 0;
      final results = await _open(
        tester,
        server,
        () => ProfileDetailsScreen(
          profile: _anya(),
          onLove: (_) async {
            answered++;
            return true;
          },
        ),
      );
      await tester.tap(find.byKey(_love));
      await _settle(tester);
      expect(answered, 1);
      expect(server.swipes, isEmpty);
      expect(results, [ProfileDetailsAction.love]);
    });
  });

  group('Spotlight screen buttons reach the server', () {
    for (final (key, like) in [
      ('qa.spotlight.like_button', true),
      ('qa.spotlight.superlike_button', true),
      ('qa.spotlight.pass_button', false),
    ]) {
      testWidgets(
        '$key saves is_like=$like for that member '
        '[case:discover.profile_entry_points.spotlight_screen.buttons_reach_server]',
        (tester) async {
          final server = _Server();
          await _open(
            tester,
            server,
            () => SpotlightProfilesScreen(profiles: [_anya()]),
          );
          await tester.tap(find.byKey(ValueKey(key)).first);
          await _settle(tester);
          expect(server.swipes, [
            {'user_id': 'me', 'target_user_id': 'anya', 'is_like': like},
          ]);
        },
      );
    }
  });
}
