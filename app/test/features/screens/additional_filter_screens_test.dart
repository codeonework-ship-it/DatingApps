import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/engagement/screens/trust_filter_screen.dart';
import 'package:verified_dating_app/features/swipe/models/discovery_profile.dart';
import 'package:verified_dating_app/features/swipe/screens/spotlight_profiles_screen.dart';
import 'package:verified_dating_app/features/swipe/widgets/swipe_card.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(isAuthenticated: true, userId: 'qa-user');
}

DiscoveryProfile profile(String name, int age, bool verified) =>
    DiscoveryProfile(
      id: name,
      name: name,
      dateOfBirth: DateTime(DateTime.now().year - age, 1, 1),
      bio: 'QA profile',
      additionalInfo: null,
      profession: null,
      education: null,
      instagramHandle: null,
      hobbies: [],
      favoriteSongs: [],
      extraCurriculars: [],
      intentTags: [],
      languageTags: [],
      isVerified: verified,
      photoUrls: [],
    );
void main() {
  late List<RequestOptions> requests;
  late bool reject;
  Future<void> mount(WidgetTester tester, Widget screen) async {
    requests = [];
    reject = false;
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          requests.add(o);
          if (reject) {
            h.reject(
              DioException(
                requestOptions: o,
                response: Response<dynamic>(
                  requestOptions: o,
                  statusCode: 503,
                  data: {'error': 'QA save failed'},
                ),
              ),
            );
            return;
          }
          final body = o.data as Map? ?? {};
          h.resolve(
            Response<dynamic>(
              requestOptions: o,
              statusCode: 200,
              data: {
                'rooms': <Object>[],
                'trust_filter': o.method == 'PATCH'
                    ? body
                    : {
                        'enabled': false,
                        'minimum_active_badges': 0,
                        'required_badge_codes': <String>[],
                      },
                'available_badges': [
                  {
                    'badge_code': 'prompt_completer',
                    'badge_label': 'Prompt Completer',
                  },
                  {
                    'badge_code': 'respectful_communicator',
                    'badge_label': 'Respectful Communicator',
                  },
                  {
                    'badge_code': 'consistent_profile',
                    'badge_label': 'Consistent Profile',
                  },
                  {
                    'badge_code': 'verified_active',
                    'badge_label': 'Verified & Active',
                  },
                ],
              },
            ),
          );
        },
      ),
    );
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(dio),
          authNotifierProvider.overrideWith(_Auth.new),
        ],
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Conversation Rooms moved to live chat rooms; see
  // test/features/engagement/conversation_rooms_screen_test.dart.
  testWidgets('standalone trust controls persist complete payload', (
    tester,
  ) async {
    await mount(tester, const TrustFilterScreen());
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    tester.widget<Slider>(find.byType(Slider)).onChanged!(4);
    await tester.pumpAndSettle();
    for (final label in [
      'Prompt Completer',
      'Respectful Communicator',
      'Consistent Profile',
      'Verified & Active',
    ]) {
      await tester.tap(find.widgetWithText(CheckboxListTile, label));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Save Trust Filters'));
    await tester.pumpAndSettle();
    final body = requests.last.data as Map;
    expect(body['enabled'], true);
    expect(body['minimum_active_badges'], 4);
    expect(
      body['required_badge_codes'],
      unorderedEquals([
        'prompt_completer',
        'respectful_communicator',
        'consistent_profile',
        'verified_active',
      ]),
    );
    expect(find.text('Trust filters saved.'), findsOneWidget);
  });
  testWidgets('standalone trust save failure never claims success', (
    tester,
  ) async {
    await mount(tester, const TrustFilterScreen());
    reject = true;
    await tester.tap(find.text('Save Trust Filters'));
    await tester.pumpAndSettle();
    expect(find.text('QA save failed'), findsWidgets);
    expect(find.text('Trust filters saved.'), findsNothing);
  });
  testWidgets(
    'spotlight age and verification exclude profiles; reset restores deck',
    (tester) async {
      await mount(
        tester,
        SpotlightProfilesScreen(
          profiles: [
            profile('Unverified', 25, false),
            profile('Verified', 30, true),
            profile('Older', 55, true),
          ],
        ),
      );
      expect(
        tester
            .widgetList<SwipeCard>(find.byType(SwipeCard))
            .map((c) => c.profile.name),
        contains('Unverified'),
      );
      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      tester.widget<RangeSlider>(find.byType(RangeSlider)).onChanged!(
        const RangeValues(28, 35),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<SwipeCard>(find.byType(SwipeCard))
            .map((c) => c.profile.name),
        everyElement('Verified'),
      );
      expect(find.byType(SwipeCard), findsWidgets);
      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<SwipeCard>(find.byType(SwipeCard))
            .map((c) => c.profile.name),
        contains('Unverified'),
      );
    },
  );
}
