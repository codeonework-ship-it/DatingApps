import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/plans/models/date_plan.dart';
import 'package:verified_dating_app/features/plans/screens/plan_sharing_sheet.dart';

void main() {
  final plan = DatePlan.fromJson({'id': 'p', 'match_id': 'm'});
  testWidgets(
    'Contact sharing is an explicit versioned choice with a preview',
    (tester) async {
      final saves = <Map<String, dynamic>>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (r, h) {
              if (r.method == 'POST')
                saves.add(Map<String, dynamic>.from(r.data as Map));
              h.resolve(
                Response<dynamic>(
                  requestOptions: r,
                  statusCode: 200,
                  data: {
                    'version': 3,
                    'contact_ids': <String>[],
                    'contacts': [
                      {'id': 'trusted', 'name': 'Meera'},
                      {'id': 'unselected', 'name': 'Dev'},
                    ],
                  },
                ),
              );
            },
          ),
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(dio)],
          child: MaterialApp(
            home: Scaffold(body: PlanSharingSheet(plan: plan)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Preview · no contacts selected'), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('qa.plan.contact.trusted')),
            )
            .value,
        isFalse,
      );
      await tester.tap(find.byKey(const ValueKey('qa.plan.contact.trusted')));
      await tester.pumpAndSettle();
      expect(find.text('Preview · 1 selected'), findsOneWidget);
      final save = find.byKey(const ValueKey('qa.plan.sharing.save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(saves.single, {
        'contact_ids': ['trusted'],
        'expected_version': 3,
      });
    },
  );
  testWidgets('Failed save preserves choices and never announces success', (
    tester,
  ) async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) {
            if (r.method == 'POST') {
              h.reject(
                DioException(
                  requestOptions: r,
                  response: Response<dynamic>(
                    requestOptions: r,
                    statusCode: 409,
                    data: {'error': 'Sharing changed. Reload your choices.'},
                  ),
                ),
              );
              return;
            }
            h.resolve(
              Response<dynamic>(
                requestOptions: r,
                statusCode: 200,
                data: {
                  'version': 2,
                  'contact_ids': ['trusted'],
                  'contacts': [
                    {'id': 'trusted', 'name': 'Meera'},
                  ],
                },
              ),
            );
          },
        ),
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(dio)],
        child: MaterialApp(
          home: Scaffold(body: PlanSharingSheet(plan: plan)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('qa.plan.sharing.save'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Reload sharing choices'), findsOneWidget);
    expect(find.text('Preview · 1 selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
