import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/engagement/providers/daily_prompt_provider.dart';
import 'package:verified_dating_app/features/matching/providers/match_provider.dart';
import 'package:verified_dating_app/features/matching/screens/matches_list_screen.dart';
import 'package:verified_dating_app/features/payment/providers/entitlements_provider.dart';
import 'package:verified_dating_app/features/swipe/models/discovery_profile.dart';
import 'package:verified_dating_app/features/swipe/providers/swipe_provider.dart';
import 'package:verified_dating_app/features/swipe/screens/home_discovery_screen.dart';
import 'package:verified_dating_app/features/swipe/widgets/swipe_card.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  _Auth(this.plan);
  final String plan;
  @override
  AuthState build() => AuthState(isAuthenticated: true, userId: '$plan-member');
}

class _Prompt extends DailyPromptNotifier {
  _Prompt(super.ref);
  @override
  Future<void> load() async {
    state = const DailyPromptState();
  }
}

class _Matches extends MatchNotifier {
  @override
  MatchState build() => const MatchState();
}

class _Deck extends SwipeNotifier {
  @override
  SwipeState build() => SwipeState(
    profiles: [
      DiscoveryProfile(
        id: 'candidate',
        name: 'Alex',
        dateOfBirth: DateTime(1995, 4, 2),
        bio: 'A reader who enjoys weekend walks.',
        additionalInfo: null,
        instagramHandle: null,
        profession: 'Designer',
        education: 'Graduate',
        hobbies: const ['Reading'],
        favoriteSongs: const [],
        extraCurriculars: const [],
        intentTags: const ['serious'],
        languageTags: const ['English'],
        isVerified: true,
        photoUrls: const [],
      ),
    ],
  );
  @override
  Future<String?> likeProfile() async {
    state = state.copyWith(likeCount: state.likeCount + 1);
    return null;
  }

  void refuse() {
    state = state.copyWith(
      dailyLimit: {
        'error_code': 'DAILY_LIKE_LIMIT_REACHED',
        'plan_name': 'Free',
        'limit': 10,
        'used': 10,
        'resets_at': '2027-01-01T00:00:00Z',
        'error': 'Daily limit reached',
      },
    );
  }
}

Future<ProviderContainer> _show(
  WidgetTester tester,
  String plan, {
  double width = 390,
  double scale = 1,
  Widget? home,
  VoidCallback? filters,
}) async {
  tester.view.physicalSize = Size(width, 920);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (o, h) => h.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: o,
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      ),
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(() => _Auth(plan)),
        apiClientProvider.overrideWithValue(dio),
        swipeNotifierProvider.overrideWith(_Deck.new),
        dailyPromptProvider.overrideWith(_Prompt.new),
        matchNotifierProvider.overrideWith(_Matches.new),
        runtimeFeatureFlagsProvider.overrideWith(
          (ref) => Stream.value(
            const RuntimeFeatureFlags({
              'curated_daily_set_enabled': true,
              'intentional_dating_enabled': true,
              'billing_enabled': true,
              'calls_enabled': false,
            }),
          ),
        ),
        entitlementsProvider.overrideWith(
          (ref) async => Entitlements.fromJson({
            'plan_id': plan,
            'plan_name': plan,
            'enforced': true,
            'likes': {
              'limit': plan == 'free' ? 10 : 100,
              'used': 0,
              'remaining': plan == 'free' ? 10 : 100,
            },
            'messages': {'limit': 10, 'used': 0, 'remaining': 10},
          }),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (_, child) => MediaQuery(
          data: MediaQueryData(
            size: Size(width, 920),
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home:
            home ??
            IndexedStack(
              index: 1,
              children: [
                const HomeDiscoveryScreen(isActive: false),
                MatchesListScreen(
                  onOpenFilters: filters,
                  activeFilterChips: const ['Age 25–35'],
                ),
              ],
            ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

void main() {
  for (final plan in ['free', 'premium']) {
    testWidgets('$plan opens Discover Matches with a real deck and filters', (
      tester,
    ) async {
      var filters = 0;
      final container = await _show(tester, plan, filters: () => filters++);
      expect((await container.read(entitlementsProvider.future))!.planId, plan);
      expect(container.read(matchesViewProvider), MatchesView.discover);
      expect(find.text('Discover Matches'), findsOneWidget);
      expect(find.byType(SwipeCard), findsOneWidget);
      expect(find.text('Age 25–35'), findsOneWidget);
      expect(find.text('Back to Today'), findsNothing);
      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      expect(filters, 1);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      '$plan can use likes and reach conversations then return to discovery',
      (tester) async {
        final container = await _show(tester, plan);
        final like = find.byKey(const ValueKey('qa.discovery.like_button'));
        await tester.ensureVisible(like);
        await tester.tap(like);
        await tester.pumpAndSettle();
        expect(container.read(swipeNotifierProvider).likeCount, 1);
        await tester.ensureVisible(find.text('Messages'));
        await tester.tap(find.text('Messages'));
        await tester.pumpAndSettle();
        expect(container.read(matchesViewProvider), MatchesView.conversations);
        await tester.tap(find.byKey(const ValueKey('qa.matches.people_tab')));
        await tester.pumpAndSettle();
        expect(find.text('Search your matches'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('qa.matches.discover_tab')));
        await tester.pumpAndSettle();
        expect(find.byType(SwipeCard), findsOneWidget);
        expect(container.read(swipeNotifierProvider).likeCount, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('restored section fits compact and large text', (tester) async {
    await _show(tester, 'free', width: 320, scale: 1.6);
    expect(
      find.byKey(const ValueKey('qa.matches.discover_tab')),
      findsOneWidget,
    );
    expect(find.text('Discover Matches'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('offstage discovery does not duplicate quota dialogs', (
    tester,
  ) async {
    final container = await _show(
      tester,
      'free',
      home: const IndexedStack(
        index: 1,
        children: [
          HomeDiscoveryScreen(browseOnly: true, isActive: false),
          HomeDiscoveryScreen(browseOnly: true),
        ],
      ),
    );
    (container.read(swipeNotifierProvider.notifier) as _Deck).refuse();
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet, skipOffstage: false), findsOneWidget);
    expect(find.text("You've used today's 10 likes on Free"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
