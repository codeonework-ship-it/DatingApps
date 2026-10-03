// Control-level tests for Moderation appeals: the three inputs, Submit (and
// its validation and failure), pull to refresh with reviewer updates, and
// Retry after a failed load.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/common/screens/moderation_appeals_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';

final AppLocalizations en = qaL10n(const Locale('en'));

Map<String, dynamic> _appeal(
  String id, {
  String reason = 'My photo was removed by mistake',
  String status = 'submitted',
  String? reviewedBy,
  String? description,
}) => {
  'id': id,
  'user_id': 'me',
  'reason': reason,
  'status': status,
  'sla_deadline_at': '2026-10-04T12:00:00Z',
  'created_at': '2026-10-02T12:00:00Z',
  'description': ?description,
  'reviewed_by': ?reviewedBy,
};

class _AppealServer {
  _AppealServer({List<Map<String, dynamic>>? appeals})
    : appeals = appeals ?? [] {
    api
      ..on('GET /moderation/appeals', (_) => qaOk({'appeals': this.appeals}))
      ..on('POST /moderation/appeals', (call) {
        final appeal = _appeal(
          'apl-${this.appeals.length + 1}',
          reason: call.body['reason'].toString(),
          description: (call.body['description'] as String?)?.isEmpty ?? true
              ? null
              : call.body['description'] as String,
        );
        this.appeals = [appeal, ...this.appeals];
        return qaOk({'appeal': appeal, 'success': true});
      });
  }

  final api = QaApi();
  List<Map<String, dynamic>> appeals;

  List<QaCall> get submits => api.sent('POST', '/moderation/appeals');
}

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _open(
  WidgetTester tester,
  _AppealServer server, {
  Locale? locale,
}) => pumpQa(
  tester,
  server.api,
  const ModerationAppealsScreen(),
  launcher: true,
  locale: locale,
);

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(_key('qa.appeals.submit'));
  await qaSettle(tester);
}

String _text(WidgetTester tester, String key) =>
    tester.widget<TextField>(_key(key)).controller!.text;

void main() {
  testWidgets(
    'Submit sends reason, report id and context, lists the appeal and clears '
    'the form [case:common.moderation_appeals.appeals_submit.action] '
    '[case:common.moderation_appeals.appeals_reason_input.action] '
    '[case:common.moderation_appeals.appeals_report_id_input.action] '
    '[case:common.moderation_appeals.appeals_context_input.action]',
    (tester) async {
      final server = _AppealServer();
      await _open(tester, server);
      expect(find.text(en.appealsEmpty), findsOneWidget);

      await tester.enterText(
        _key('qa.appeals.reason'),
        '  My photo was removed by mistake  ',
      );
      await tester.enterText(_key('qa.appeals.report_id'), ' rep-42 ');
      await tester.enterText(
        _key('qa.appeals.context'),
        'It is a picture of my dog at the beach.',
      );
      server.api.calls.clear();
      await _submit(tester);

      expect(server.submits.single.body, {
        'user_id': 'me',
        'report_id': 'rep-42',
        'reason': 'My photo was removed by mistake',
        'description': 'It is a picture of my dog at the beach.',
      });
      // The list is re-read from the server after filing.
      expect(server.api.sent('GET', '/moderation/appeals'), hasLength(1));
      expect(server.api.sent('GET', '/moderation/appeals').single.query, {
        'user_id': 'me',
        'limit': 50,
      });
      expect(qaSnackText(tester), en.appealsSubmitted);
      expect(find.text(en.engagementAppealStatusSubmitted), findsOneWidget);
      expect(find.text(en.appealsIdLine('apl-1')), findsOneWidget);
      expect(
        find.text('It is a picture of my dog at the beach.'),
        findsOneWidget,
      );
      expect(_text(tester, 'qa.appeals.reason'), isEmpty);
      expect(_text(tester, 'qa.appeals.report_id'), isEmpty);
      expect(_text(tester, 'qa.appeals.context'), isEmpty);
    },
  );

  testWidgets(
    'a missing reason is refused before anything is sent; unicode reasons '
    'are kept [case:common.moderation_appeals.appeals_reason_input.validation]',
    (tester) async {
      final server = _AppealServer();
      await _open(tester, server);
      for (final reason in ['', '   \n  ']) {
        await tester.enterText(_key('qa.appeals.reason'), reason);
        await _submit(tester);
        expect(qaSnackText(tester), en.appealsReasonRequired);
        ScaffoldMessenger.of(
          tester.element(find.byType(ModerationAppealsScreen)),
        ).clearSnackBars();
        await qaSettle(tester);
      }
      expect(server.submits, isEmpty);

      const unicode = 'Это ошибка — هذا خطأ 🙏';
      await tester.enterText(_key('qa.appeals.reason'), unicode);
      await _submit(tester);
      expect(server.submits.single.body['reason'], unicode);
      expect(find.text(unicode), findsOneWidget);
    },
  );

  testWidgets(
    'report id and context are optional and trimmed; unicode context is kept '
    '[case:common.moderation_appeals.appeals_report_id_input.validation] '
    '[case:common.moderation_appeals.appeals_context_input.validation]',
    (tester) async {
      final server = _AppealServer();
      await _open(tester, server);
      await tester.enterText(_key('qa.appeals.reason'), 'Wrong ban');
      await tester.enterText(_key('qa.appeals.report_id'), '   ');
      await tester.enterText(_key('qa.appeals.context'), '  ');
      await _submit(tester);
      expect(server.submits.single.body['report_id'], '');
      expect(server.submits.single.body['description'], '');
      expect(qaSnackText(tester), en.appealsSubmitted);

      ScaffoldMessenger.of(
        tester.element(find.byType(ModerationAppealsScreen)),
      ).clearSnackBars();
      await tester.enterText(_key('qa.appeals.reason'), 'Wrong ban again');
      await tester.enterText(
        _key('qa.appeals.context'),
        'Contexte: été 🌞\nLigne 2',
      );
      await _submit(tester);
      expect(
        server.submits.last.body['description'],
        'Contexte: été 🌞\nLigne 2',
      );
    },
  );

  testWidgets(
    'a refused appeal explains, keeps what was typed and re-enables Submit '
    '[case:common.moderation_appeals.appeals_submit.api_failure]',
    (tester) async {
      final server = _AppealServer();
      server.api.fail(
        'POST /moderation/appeals',
        status: 400,
        message: 'report not found',
      );
      await _open(tester, server);
      await tester.enterText(_key('qa.appeals.reason'), 'Please review');
      await tester.enterText(_key('qa.appeals.report_id'), 'rep-x');
      await _submit(tester);

      expect(qaSnackText(tester), en.appealsSubmitFailed);
      expect(_text(tester, 'qa.appeals.reason'), 'Please review');
      expect(_text(tester, 'qa.appeals.report_id'), 'rep-x');
      expect(
        tester.widget<FilledButton>(_key('qa.appeals.submit')).onPressed,
        isNotNull,
      );
      expect(server.submits, hasLength(1));
      expect(find.text(en.appealsEmpty), findsOneWidget);
    },
  );

  testWidgets(
    'a filed appeal is not reported as failed when only the re-read fails '
    '(regression: invited duplicate appeals) '
    '[case:common.moderation_appeals.appeals_submit.reload_failure]',
    (tester) async {
      final server = _AppealServer();
      await _open(tester, server);
      server.api.fail('GET /moderation/appeals', status: 503);
      await tester.enterText(_key('qa.appeals.reason'), 'Please review');
      await _submit(tester);

      expect(server.submits, hasLength(1));
      expect(qaSnackText(tester), en.appealsSubmitted);
      expect(find.text(en.appealsIdLine('apl-1')), findsOneWidget);
      expect(_text(tester, 'qa.appeals.reason'), isEmpty);
    },
  );

  testWidgets(
    'pull to refresh shows the reviewer\'s decision '
    '[case:common.moderation_appeals.reviewed_by_reviewer_onrefresh.action]',
    (tester) async {
      final server = _AppealServer(appeals: [_appeal('apl-7')]);
      await _open(tester, server);
      expect(find.text(en.engagementAppealStatusSubmitted), findsOneWidget);

      server.appeals = [
        _appeal(
          'apl-7',
          status: 'resolved_reversed',
          reviewedBy: 'Safety team',
        ),
      ];
      server.api.calls.clear();
      await tester.fling(
        find.text(en.appealsIdLine('apl-7')),
        const Offset(0, 500),
        1000,
      );
      await qaSettle(tester, frames: 30);

      expect(server.api.sent('GET', '/moderation/appeals'), hasLength(1));
      expect(
        find.text(en.engagementAppealStatusResolvedReversed),
        findsOneWidget,
      );
      expect(find.text(en.appealsReviewedBy('Safety team')), findsOneWidget);
    },
  );

  testWidgets(
    'a failed refresh keeps the list and says so (regression: it failed '
    'silently) [case:common.moderation_appeals.reviewed_by_reviewer_onrefresh.api_failure]',
    (tester) async {
      final server = _AppealServer(appeals: [_appeal('apl-7')]);
      await _open(tester, server);
      server.api.offline('GET /moderation/appeals');
      await tester.fling(
        find.text(en.appealsIdLine('apl-7')),
        const Offset(0, 500),
        1000,
      );
      await qaSettle(tester, frames: 30);

      expect(qaSnackText(tester), en.commonSomethingWentWrongTryAgain);
      expect(find.text(en.appealsIdLine('apl-7')), findsOneWidget);
    },
  );

  testWidgets(
    'a failed load is not shown as "no appeals"; Retry reloads (regression) '
    '[case:common.moderation_appeals.appeals_retry.action]',
    (tester) async {
      final server = _AppealServer(appeals: [_appeal('apl-7')]);
      server.api.fail('GET /moderation/appeals', status: 500);
      await _open(tester, server);
      expect(find.text(en.appealsEmpty), findsNothing);
      expect(find.text(en.commonSomethingWentWrongTryAgain), findsOneWidget);
      // The form stays usable while the list is unavailable.
      expect(
        tester.widget<FilledButton>(_key('qa.appeals.submit')).onPressed,
        isNotNull,
      );

      server.api.on(
        'GET /moderation/appeals',
        (_) => qaOk({'appeals': server.appeals}),
      );
      await tester.tap(_key('qa.appeals.retry'));
      await qaSettle(tester);
      expect(server.api.sent('GET', '/moderation/appeals'), hasLength(2));
      expect(find.text(en.appealsIdLine('apl-7')), findsOneWidget);
    },
  );

  testWidgets('Moderation appeals renders translated in all 10 languages '
      '[case:common.moderation_appeals.l10n]', (tester) async {
    for (final locale in qaLocales) {
      await tester.pumpWidget(const SizedBox());
      final l10n = qaL10n(locale);
      await _open(
        tester,
        _AppealServer(appeals: [_appeal('apl-7')]),
        locale: locale,
      );
      expect(find.text(l10n.privacyModerationAppeals), findsOneWidget);
      expect(find.text(l10n.appealsSubmit), findsOneWidget);
      expect(find.text(l10n.appealsReasonLabel), findsOneWidget);
      expect(find.text(l10n.engagementAppealStatusSubmitted), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });
}
