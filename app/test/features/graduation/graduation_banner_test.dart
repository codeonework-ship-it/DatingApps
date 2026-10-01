import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/graduation/models/graduation.dart';
import 'package:verified_dating_app/features/graduation/screens/graduation_celebration_screen.dart';
import 'package:verified_dating_app/features/graduation/screens/propose_graduation_sheet.dart';
import 'package:verified_dating_app/features/graduation/widgets/graduation_banner.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(isAuthenticated: true, userId: 'partner-1');
}

/// In-memory BFF for a single match: answers the graduation snapshot and
/// records every command it receives.
class _FakeGraduationApi {
  _FakeGraduationApi({required this.snapshot});

  Map<String, dynamic> snapshot;
  final List<({String path, Map<String, dynamic> body})> commands = [];

  Dio build() {
    final dio = Dio(BaseOptions(baseUrl: 'http://bff.test/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.method == 'GET' && options.path.endsWith('/graduation')) {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: snapshot,
              ),
            );
            return;
          }
          if (options.method == 'POST') {
            final body = (options.data as Map).cast<String, dynamic>();
            commands.add((path: options.path, body: body));
            Map<String, dynamic> graduation;
            if (options.path.endsWith('/graduation')) {
              graduation = _graduation(
                status: 'proposed',
                viewerRole: 'proposer',
                nextAction: 'await_decision',
                note: body['note']?.toString() ?? '',
                shareWithFriends: body['share_with_friends'] as bool? ?? false,
              );
            } else {
              graduation = Map<String, dynamic>.from(
                snapshot['graduation'] as Map<String, dynamic>,
              );
              if (options.path.endsWith('/decision')) {
                final confirm = body['decision'] == 'confirm';
                graduation['status'] = confirm ? 'confirmed' : 'declined';
                graduation['next_action'] = confirm ? 'celebrate' : 'propose';
                graduation['share_with_friends'] = body['share_with_friends'];
                graduation['friend_recipients'] = confirm ? 2 : 0;
              } else if (options.path.endsWith('/withdraw')) {
                graduation['status'] = 'withdrawn';
                graduation['next_action'] = 'propose';
              }
            }
            snapshot = {
              ...snapshot,
              'graduation': graduation,
              'can_propose': false,
              'graduated': graduation['status'] == 'confirmed',
            };
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: options.path.endsWith('/graduation') ? 201 : 200,
                data: {'graduation': graduation},
              ),
            );
            return;
          }
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: 404,
                data: {'error': 'unexpected ${options.method} ${options.path}'},
              ),
            ),
          );
        },
      ),
    );
    return dio;
  }
}

Map<String, dynamic> _graduation({
  String status = 'proposed',
  String viewerRole = 'partner',
  String nextAction = 'decide',
  String note = 'I think we found each other.',
  bool shareWithFriends = false,
}) => {
  'id': 'graduation-1',
  'match_id': 'match-1',
  'proposer_user_id': 'proposer-1',
  'partner_user_id': 'partner-1',
  'status': status,
  'note': note,
  'proposer_share_with_friends': true,
  'partner_share_with_friends': false,
  'created_at': '2026-09-27T10:00:00Z',
  'updated_at': '2026-09-27T10:00:00Z',
  'lock_version': 0,
  'viewer_role': viewerRole,
  'other_user_id': 'proposer-1',
  'other_name': 'Arjun',
  'share_with_friends': shareWithFriends,
  'next_action': nextAction,
  'rewards': <Map<String, dynamic>>[],
};

Map<String, dynamic> _snapshot({Map<String, dynamic>? graduation}) => {
  'match_id': 'match-1',
  'graduation': graduation,
  'history': <dynamic>[],
  'graduated': graduation?['status'] == 'confirmed',
  'can_propose': graduation == null,
  'unlock_state': 'conversation_unlocked',
  'discovery_paused': false,
};

Widget _host(_FakeGraduationApi api, {Widget? body}) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(api.build()),
  ],
  child: MaterialApp(
    home: Scaffold(
      body:
          body ??
          const GraduationBanner(matchId: 'match-1', partnerName: 'Arjun'),
    ),
  ),
);

void main() {
  testWidgets('the banner stays hidden while nothing is proposed', (
    tester,
  ) async {
    final api = _FakeGraduationApi(snapshot: _snapshot());
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();
    expect(find.textContaining('leave Connect'), findsNothing);
    expect(find.byKey(const ValueKey('qa.graduation.confirm')), findsNothing);
  });

  testWidgets('a member proposes from the sheet with a note and share', (
    tester,
  ) async {
    final api = _FakeGraduationApi(snapshot: _snapshot());
    await tester.pumpWidget(
      _host(
        api,
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              key: const ValueKey('open'),
              onPressed: () => showProposeGraduationSheet(
                context: context,
                matchId: 'match-1',
                partnerName: 'Arjun',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();

    expect(find.text('Leave Connect with Arjun?'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('qa.graduation.note')),
      'Ready when you are',
    );
    await tester.tap(find.byKey(const ValueKey('qa.graduation.share_switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('qa.graduation.submit')));
    await tester.pumpAndSettle();

    expect(api.commands, hasLength(1));
    expect(api.commands.single.path, endsWith('/matches/match-1/graduation'));
    expect(api.commands.single.body['note'], 'Ready when you are');
    expect(api.commands.single.body['share_with_friends'], isTrue);
    // The sheet closed on success.
    expect(find.text('Leave Connect with Arjun?'), findsNothing);
  });

  testWidgets('the partner confirms through the celebration screen', (
    tester,
  ) async {
    final api = _FakeGraduationApi(
      snapshot: _snapshot(graduation: _graduation()),
    );
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();

    expect(find.text('Arjun wants to leave Connect together'), findsOneWidget);
    expect(find.textContaining('I think we found each other'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('qa.graduation.confirm')));
    await tester.pumpAndSettle();

    // The celebration screen completes the confirmation.
    expect(find.byType(GraduationCelebrationScreen), findsOneWidget);
    expect(find.text('You found each other'), findsOneWidget);
    expect(api.commands, isEmpty);
    await tester.tap(
      find.byKey(const ValueKey('qa.graduation.celebration.share')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('qa.graduation.celebration.done')),
    );
    await tester.pumpAndSettle();

    expect(api.commands, hasLength(1));
    expect(
      api.commands.single.path,
      endsWith('/graduation/graduation-1/decision'),
    );
    expect(api.commands.single.body['decision'], 'confirm');
    expect(api.commands.single.body['share_with_friends'], isTrue);
    // Back on the chat, the banner celebrates and re-opens the screen.
    expect(find.byType(GraduationCelebrationScreen), findsNothing);
    expect(find.text('You found each other'), findsOneWidget);
    expect(find.byKey(const ValueKey('qa.graduation.celebrate')), findsOne);
    await tester.tap(find.byKey(const ValueKey('qa.graduation.celebrate')));
    await tester.pumpAndSettle();
    expect(find.byType(GraduationCelebrationScreen), findsOneWidget);
    expect(find.text('Your friends have been told.'), findsOneWidget);
    expect(find.text('Back to Connect'), findsOneWidget);
  });

  testWidgets('the partner can decline from the banner', (tester) async {
    final api = _FakeGraduationApi(
      snapshot: _snapshot(graduation: _graduation()),
    );
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('qa.graduation.decline')));
    await tester.pumpAndSettle();

    expect(api.commands.single.body['decision'], 'decline');
    expect(find.byKey(const ValueKey('qa.graduation.confirm')), findsNothing);
  });

  testWidgets('the proposer waits and can withdraw', (tester) async {
    final api = _FakeGraduationApi(
      snapshot: _snapshot(
        graduation: _graduation(
          viewerRole: 'proposer',
          nextAction: 'await_decision',
          shareWithFriends: true,
        ),
      ),
    );
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();

    expect(find.text('Waiting for Arjun'), findsOneWidget);
    expect(find.text('Your friends are told once they confirm.'), findsOne);
    await tester.tap(find.byKey(const ValueKey('qa.graduation.withdraw')));
    await tester.pumpAndSettle();

    expect(api.commands.single.path, endsWith('/graduation-1/withdraw'));
    expect(find.text('Waiting for Arjun'), findsNothing);
  });

  test('models parse the BFF payloads', () {
    final graduation = Graduation.fromJson(_graduation());
    expect(graduation.isOpen, isTrue);
    expect(graduation.viewerIsPartner, isTrue);
    expect(graduation.viewerDecides, isTrue);
    expect(graduation.otherName, 'Arjun');

    final snapshot = MatchGraduationSnapshot.fromJson(
      _snapshot(graduation: _graduation(status: 'confirmed')),
    );
    expect(snapshot.graduated, isTrue);
    expect(snapshot.canPropose, isFalse);

    final pause = DiscoveryPause.fromJson(const <String, dynamic>{
      'reason': 'graduated',
      'paused_at': '2026-09-27T10:00:00Z',
    });
    expect(pause.isActive, isTrue);
    expect(pause.isGraduation, isTrue);
  });
}
