import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/intentional_dating/dating_rhythm.dart';
import 'package:verified_dating_app/features/intentional_dating/connection_card.dart';
import 'package:verified_dating_app/features/plans/models/date_plan.dart';
import 'package:verified_dating_app/features/plans/screens/propose_date_plan_sheet.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

class _Api {
  final List<Map<String, dynamic>> saves = [];
  final List<String> paths = [];
  bool refuse = false;
  Dio get dio {
    final client = Dio();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          var body = <String, dynamic>{};
          if (request.path.endsWith('dating-preferences')) {
            if (request.method == 'PUT') {
              saves.add(Map<String, dynamic>.from(request.data as Map));
              if (refuse) {
                handler.reject(
                  DioException(
                    requestOptions: request,
                    response: Response<dynamic>(
                      requestOptions: request,
                      statusCode: 409,
                      data: {'error': 'Refresh before trying again.'},
                    ),
                  ),
                );
                return;
              }
              body = {
                'preferences': {...saves.last, 'version': 2},
              };
            } else {
              body = {
                'preferences': {
                  'version': 1,
                  'intent': '',
                  'pace': '',
                  'activities': <String>[],
                  'availability': <dynamic>[],
                  'share_availability': false,
                  'allow_friend_intros': false,
                },
              };
            }
          } else if (request.path.endsWith('/discovery/pause')) {
            body = {'paused': false};
          } else if (request.path.endsWith('/connection')) {
            body = {'overlap': <dynamic>[], 'reasons': <String>[]};
          } else if (request.method == 'POST') {
            paths.add(request.path);
            saves.add(Map<String, dynamic>.from(request.data as Map));
            body = {'plan': _plan};
          }
          handler.resolve(
            Response<dynamic>(
              requestOptions: request,
              statusCode: 200,
              data: body,
            ),
          );
        },
      ),
    );
    return client;
  }
}

final _plan = <String, dynamic>{
  'id': 'p',
  'match_id': 'm',
  'proposer_user_id': 'them',
  'invitee_user_id': 'me',
  'status': 'proposed',
  'window_start': DateTime.now()
      .add(const Duration(days: 1))
      .toUtc()
      .toIso8601String(),
  'window_end': DateTime.now()
      .add(const Duration(days: 1, hours: 2))
      .toUtc()
      .toIso8601String(),
  'venue_category': 'coffee',
  'checkin_due_at': DateTime.now()
      .add(const Duration(days: 1, hours: 3))
      .toUtc()
      .toIso8601String(),
  'viewer_role': 'invitee',
  'partner_user_id': 'them',
  'partner_name': 'Maya',
  'next_action': 'decide',
  'lock_version': 7,
};
Widget host(
  Widget child,
  _Api api, {
  double scale = 1,
  Stream<Map<String, dynamic>>? connection,
}) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(api.dio),
    if (connection != null)
      datingConnectionProvider('m').overrideWith((_) => connection),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: child,
  ),
);

Future<void> reveal(
  WidgetTester tester,
  Finder target, {
  double delta = 300,
}) async {
  await tester.scrollUntilVisible(
    target,
    delta,
    scrollable: find.byType(Scrollable).first,
  );
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets(
      'rhythm layout at $width handles large text and saves private defaults',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = _Api();
        await tester.pumpWidget(
          host(const DatingRhythmScreen(), api, scale: 1.5),
        );
        await tester.pumpAndSettle();
        await reveal(tester, find.text('A relationship'));
        await tester.tap(find.text('A relationship'));
        await tester.pump();
        await reveal(tester, find.byKey(const ValueKey('qa.rhythm.save')));
        await tester.tap(find.byKey(const ValueKey('qa.rhythm.save')));
        await tester.pumpAndSettle();
        expect(api.saves.single['intent'], 'relationship');
        expect(api.saves.single['share_availability'], false);
        expect(api.saves.single['allow_friend_intros'], false);
        expect(api.saves.single['availability'], isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('turning availability off removes selected windows from save', (
    tester,
  ) async {
    final api = _Api();
    await tester.pumpWidget(host(const DatingRhythmScreen(), api));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Use my broad availability'));
    await tester.tap(find.text('Use my broad availability'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Afternoon').first, delta: 180);
    await tester.tap(find.text('Afternoon').first);
    await tester.pump();
    await reveal(tester, find.text('Use my broad availability'), delta: -150);
    await tester.tap(find.text('Use my broad availability'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('qa.rhythm.save')));
    await tester.tap(find.byKey(const ValueKey('qa.rhythm.save')));
    await tester.pumpAndSettle();
    expect(api.saves.single['availability'], isEmpty);
  });
  testWidgets('a failed rhythm save keeps the member choices', (tester) async {
    final api = _Api()..refuse = true;
    await tester.pumpWidget(host(const DatingRhythmScreen(), api));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('A relationship'));
    await tester.tap(find.text('A relationship'));
    await tester.pump();
    await reveal(tester, find.byKey(const ValueKey('qa.rhythm.save')));
    await tester.tap(find.byKey(const ValueKey('qa.rhythm.save')));
    await tester.pumpAndSettle();
    expect(find.text('Refresh before trying again.'), findsOneWidget);
    api.refuse = false;
    await tester.tap(find.byKey(const ValueKey('qa.rhythm.save')));
    await tester.pumpAndSettle();
    expect(api.saves.last['intent'], 'relationship');
  });
  testWidgets('chemistry reveals answers together without gating chat', (
    tester,
  ) async {
    final updates = StreamController<Map<String, dynamic>>();
    addTearDown(updates.close);
    await tester.pumpWidget(
      host(
        const Scaffold(body: ChemistrySheet(matchId: 'm')),
        _Api(),
        connection: updates.stream,
      ),
    );
    updates.add({
      'moment': {
        'id': 'one',
        'prompt': 'sunday',
        'status': 'waiting',
        'my_answer': 'food',
        'options': {'food': 'Brunch', 'bookstore': 'Bookstore'},
      },
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('saved privately'), findsOneWidget);
    expect(find.text('Bookstore'), findsNothing);
    expect(find.textContaining('never controls access'), findsOneWidget);
    updates.add({
      'moment': {
        'id': 'one',
        'prompt': 'sunday',
        'status': 'revealed',
        'my_answer': 'food',
        'partner_answer': 'bookstore',
        'options': {'food': 'Brunch', 'bookstore': 'Bookstore'},
      },
    });
    await tester.pumpAndSettle();
    expect(find.text('Both answers, together'), findsOneWidget);
    expect(find.text('Bookstore'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('counterproposal submits the version that was shown', (
    tester,
  ) async {
    final api = _Api();
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showProposeDatePlanSheet(
                context: context,
                matchId: 'm',
                partnerName: 'Maya',
                counterTo: DatePlan.fromJson(_plan),
              ),
              child: const Text('Change plan'),
            ),
          ),
        ),
        api,
      ),
    );
    await tester.tap(find.text('Change plan'));
    await tester.pumpAndSettle();
    expect(find.text('Shape this plan together'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Keep it free'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Keep it free'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('qa.plan.submit')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('qa.plan.submit')));
    await tester.pumpAndSettle();
    expect(api.paths.single, '/matches/m/plans/p/counter');
    expect(api.saves.single['expected_version'], 7);
    expect(api.saves.single['budget_preference'], 'free');
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
