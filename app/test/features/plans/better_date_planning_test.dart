import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/intentional_dating/connection_card.dart';
import 'package:verified_dating_app/features/plans/models/date_plan.dart';
import 'package:verified_dating_app/features/plans/screens/propose_date_plan_sheet.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

class _Api {
  final saves = <Map<String, dynamic>>[];
  bool reject = false;
  Map<String, dynamic>? current;
  Dio get dio => Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          if (r.method == 'POST') {
            saves.add(Map<String, dynamic>.from(r.data as Map));
            if (reject) {
              h.reject(
                DioException(
                  requestOptions: r,
                  response: Response<dynamic>(
                    requestOptions: r,
                    statusCode: 409,
                    data: {
                      'error':
                          'Shared availability has changed. Refresh the time suggestions.',
                    },
                  ),
                ),
              );
              return;
            }
            current = {...planJson, ...saves.last};
            h.resolve(
              Response<dynamic>(
                requestOptions: r,
                statusCode: 201,
                data: {'plan': current},
              ),
            );
            return;
          }
          h.resolve(
            Response<dynamic>(
              requestOptions: r,
              statusCode: 200,
              data: {
                'plan': current,
                'history': <dynamic>[],
                'share_groups': <dynamic>[],
                'can_propose': true,
              },
            ),
          );
        },
      ),
    );
}

final start = DateTime.now().toUtc().add(const Duration(days: 2));
final exactStart = DateTime.utc(start.year, start.month, start.day, 8, 15);
final exactEnd = exactStart.add(const Duration(minutes: 90));
final planJson = <String, dynamic>{
  'id': 'p',
  'match_id': 'm',
  'proposer_user_id': 'them',
  'invitee_user_id': 'me',
  'status': 'proposed',
  'window_start': exactStart.toIso8601String(),
  'window_end': exactEnd.toIso8601String(),
  'venue_category': 'coffee',
  'budget_preference': 'modest',
  'atmosphere_preferences': ['quiet'],
  'accessibility_preferences': ['step_free'],
  'checkin_due_at': exactEnd.add(const Duration(hours: 1)).toIso8601String(),
  'viewer_role': 'invitee',
  'partner_user_id': 'them',
  'partner_name': 'Maya',
  'next_action': 'decide',
  'lock_version': 7,
};
Map<String, dynamic> get overlap => {
  'overlap': [
    {'start': exactStart.toIso8601String(), 'end': exactEnd.toIso8601String()},
  ],
};
Widget host(
  _Api api, {
  DatePlan? counter,
  Map<String, dynamic>? connection,
  double scale = 1,
  bool acceptance = false,
  String? chapterNote,
  String? chapterVenue,
}) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(api.dio),
    datingConnectionProvider(
      'm',
    ).overrideWith((_) => Stream.value(connection ?? overlap)),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (c, w) => MediaQuery(
      data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
      child: w!,
    ),
    home: Builder(
      builder: (c) => Scaffold(
        body: TextButton(
          onPressed: () => acceptance
              ? showAcceptDatePlanSheet(
                  context: c,
                  plan: DatePlan.fromJson(planJson),
                  groups: [],
                )
              : showProposeDatePlanSheet(
                  context: c,
                  matchId: 'm',
                  partnerName: 'Maya',
                  counterTo: counter,
                  initialNote: chapterNote,
                  initialVenueCategory: chapterVenue,
                ),
          child: const Text('Open plan'),
        ),
      ),
    ),
  ),
);
Future<void> reveal(WidgetTester t, Finder finder) async {
  await t.ensureVisible(finder);
  await t.pumpAndSettle();
}

Future<void> tap(WidgetTester t, String key) async {
  final finder = find.byKey(ValueKey(key));
  await reveal(t, finder);
  await t.tap(finder);
  await t.pumpAndSettle();
}

Future<void> open(WidgetTester t, Widget widget) async {
  await t.pumpWidget(widget);
  await t.tap(find.text('Open plan'));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('chapter idea prefills an editable proposal without sending it', (
    t,
  ) async {
    final api = _Api();
    const note =
        'Browse a tiny bookshop. Then choose a book by its first line.';
    await open(t, host(api, chapterNote: note, chapterVenue: 'meal'));
    expect(api.saves, isEmpty);
    expect(
      t
          .widget<TextField>(find.byKey(const ValueKey('qa.plan.note')))
          .controller!
          .text,
      note,
    );
    await tap(t, 'qa.plan.submit');
    expect(api.saves.single['note'], note);
    expect(api.saves.single['venue_category'], 'meal');
  });
  testWidgets(
    'shared 90-minute window, budget and comfort choices survive sending',
    (t) async {
      final api = _Api();
      await open(t, host(api));
      for (final key in [
        'step_free',
        'accessible_toilet',
        'seating',
        'low_noise',
        'nearby_transit',
        'captions',
      ])
        expect(
          t
              .widget<CheckboxListTile>(
                find.byKey(ValueKey('qa.plan.accessibility.$key')),
              )
              .value,
          false,
        );
      await tap(t, 'qa.plan.overlap.0');
      await tap(t, 'qa.plan.budget.modest');
      await tap(t, 'qa.plan.atmosphere.quiet');
      await tap(t, 'qa.plan.accessibility.step_free');
      await tap(t, 'qa.plan.submit');
      final saved = api.saves.single;
      expect(saved['window_start'], exactStart.toIso8601String());
      expect(saved['window_end'], exactEnd.toIso8601String());
      expect(saved['budget_preference'], 'modest');
      expect(saved['atmosphere_preferences'], ['quiet']);
      expect(saved['accessibility_preferences'], ['step_free']);
      expect(saved['shared_window'], overlap['overlap'][0]);
    },
  );
  testWidgets(
    'counterproposal preserves exact duration and existing requests',
    (t) async {
      final api = _Api();
      await open(t, host(api, counter: DatePlan.fromJson(planJson)));
      expect(find.textContaining('Duration: 90 minutes'), findsOneWidget);
      expect(
        t
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('qa.plan.accessibility.step_free')),
            )
            .value,
        true,
      );
      await tap(t, 'qa.plan.submit');
      final saved = api.saves.single;
      expect(saved['expected_version'], 7);
      expect(saved['window_end'], exactEnd.toIso8601String());
      expect(saved['atmosphere_preferences'], ['quiet']);
      expect(saved['accessibility_preferences'], ['step_free']);
      expect(saved.containsKey('shared_window'), false);
    },
  );
  testWidgets(
    'expanding beyond overlap becomes an explicitly manual proposal',
    (t) async {
      final api = _Api();
      await open(t, host(api));
      await tap(t, 'qa.plan.overlap.0');
      await tap(t, 'qa.plan.duration.180');
      expect(find.text('A time you’re suggesting'), findsOneWidget);
      await tap(t, 'qa.plan.submit');
      expect(api.saves.single.containsKey('shared_window'), false);
      expect(
        DateTime.parse(
          api.saves.single['window_end'] as String,
        ).difference(exactStart),
        const Duration(hours: 3),
      );
    },
  );
  testWidgets(
    'availability conflict preserves the draft and checked preferences',
    (t) async {
      final api = _Api()..reject = true;
      await open(t, host(api));
      await tap(t, 'qa.plan.overlap.0');
      await tap(t, 'qa.plan.atmosphere.relaxed');
      await tap(t, 'qa.plan.accessibility.low_noise');
      await tap(t, 'qa.plan.submit');
      expect(
        find.text(
          'Shared availability has changed. Refresh the time suggestions.',
        ),
        findsOneWidget,
      );
      expect(
        t
            .widget<FilterChip>(
              find.byKey(const ValueKey('qa.plan.atmosphere.relaxed')),
            )
            .selected,
        true,
      );
      expect(
        t
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('qa.plan.accessibility.low_noise')),
            )
            .value,
        true,
      );
      expect(
        find.textContaining('Selected from shared availability'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'manual plan works without availability and preferences stay optional',
    (t) async {
      final api = _Api();
      await open(t, host(api, connection: {'overlap': <dynamic>[]}));
      expect(find.textContaining('does not mean either'), findsOneWidget);
      await tap(t, 'qa.plan.submit');
      expect(api.saves.single['accessibility_preferences'], isEmpty);
      expect(api.saves.single['atmosphere_preferences'], isEmpty);
      expect(api.saves.single.containsKey('shared_window'), false);
    },
  );
  testWidgets(
    'three atmosphere choices cap selection without losing earlier choices',
    (t) async {
      final api = _Api();
      await open(t, host(api));
      for (final key in ['quiet', 'relaxed', 'indoors']) {
        await tap(t, 'qa.plan.atmosphere.$key');
      }
      expect(
        t
            .widget<FilterChip>(
              find.byKey(const ValueKey('qa.plan.atmosphere.outdoors')),
            )
            .onSelected,
        isNull,
      );
      await tap(t, 'qa.plan.atmosphere.quiet');
      expect(
        t
            .widget<FilterChip>(
              find.byKey(const ValueKey('qa.plan.atmosphere.outdoors')),
            )
            .onSelected,
        isNotNull,
      );
    },
  );
  for (final width in [390.0, 768.0, 1440.0]) {
    testWidgets('plan choices and acceptance fit $width at twice text size', (
      t,
    ) async {
      t.view.physicalSize = Size(width, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await open(t, host(_Api(), scale: 2));
      await reveal(t, find.byKey(const ValueKey('qa.plan.submit')));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      await open(t, host(_Api(), scale: 2, acceptance: true));
      await reveal(t, find.byKey(const ValueKey('qa.plan.accept_confirm')));
      expect(find.text('• Step-free access'), findsOneWidget);
      expect(find.textContaining('Quiet conversation'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
}
