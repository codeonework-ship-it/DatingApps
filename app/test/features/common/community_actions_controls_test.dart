// Case ids stay whole in test names (the QA Lab reads them literally).
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/common/widgets/community_actions.dart';

import '../../support/qa_api.dart';

// Shared community actions used by Photo Themes, Clubs, Reviews and Lists:
// the "cannot be undone" confirmation (Cancel resolves false, the action
// resolves true), blocking a member after confirming (POST /safety/block),
// and reporting an item through the Open Chapters queue
// (POST /blog/reports/{kind}/{id}) with a thank-you on success and a
// readable failure that keeps the sheet open for a retry.

const _report = ValueKey('host.report');
const _block = ValueKey('host.block');

final _en = qaL10n(const Locale('en'));

/// A screen with a Report and a Block button, the way member activities
/// wire them; [blocks] collects what [blockCommunityMember] resolved to.
class _Host extends ConsumerWidget {
  const _Host(this.blocks);
  final List<bool> blocks;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            key: _report,
            onPressed: () => reportCommunityItem(
              context,
              ref,
              kind: 'club_post',
              id: 'post-7',
            ),
            child: const Text('report'),
          ),
          TextButton(
            key: _block,
            onPressed: () async => blocks.add(
              await blockCommunityMember(
                context,
                ref,
                userId: 'asha',
                name: 'Asha',
              ),
            ),
            child: const Text('block'),
          ),
        ],
      ),
    ),
  );
}

QaApi _server() => QaApi()
  ..json('POST /blog/reports/*/*', {
    'accepted': true,
    'report': {'id': 'case-1'},
  })
  ..json('POST /safety/block', {'success': true});

Future<List<bool>> _pump(
  WidgetTester tester,
  QaApi api, {
  Locale? locale,
}) async {
  final blocks = <bool>[];
  await pumpQa(tester, api, _Host(blocks), locale: locale);
  return blocks;
}

Finder _submit() => find.widgetWithText(FilledButton, _en.reportSubmit);

void main() {
  group('confirmation dialog', () {
    testWidgets('Block asks first: the dialog names the member, explains, '
        'and nothing is sent yet '
        '[case:common.community_actions.cancel.action]', (tester) async {
      final api = _server();
      final blocks = await _pump(tester, api);
      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.byKey(_block));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(_en.communityBlockTitle('Asha')), findsOneWidget);
      expect(find.text(_en.communityBlockBody), findsOneWidget);
      expect(find.widgetWithText(TextButton, _en.commonCancel), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, _en.communityBlockAction),
        findsOneWidget,
      );
      expect(api.calls, isEmpty);
      expect(blocks, isEmpty);
    });

    testWidgets('Cancel closes the dialog, resolves false and blocks nobody '
        '[case:common.community_actions.cancel_2.action]', (tester) async {
      final api = _server();
      final blocks = await _pump(tester, api);
      await tester.tap(find.byKey(_block));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, _en.commonCancel));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(blocks, [false]);
      expect(api.calls, isEmpty);
      expect(qaSnackText(tester), isNull);
      // The screen underneath is still there and usable.
      expect(find.byKey(_block).hitTestable(), findsOneWidget);
    });

    testWidgets('the action button closes the dialog, resolves true and the '
        'block is sent once '
        '[case:common.community_actions.filledbutton_onpressed.action]', (
      tester,
    ) async {
      final api = _server();
      final blocks = await _pump(tester, api);
      await tester.tap(find.byKey(_block));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(FilledButton, _en.communityBlockAction),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      final sent = api.sent('POST', '/safety/block');
      expect(sent, hasLength(1));
      expect(sent.single.body, {'user_id': 'me', 'blocked_user_id': 'asha'});
      expect(blocks, [true]);
    });

    testWidgets('tapping outside the dialog resolves false and sends nothing '
        '[case:common.community_actions.cancel.action]', (tester) async {
      final api = _server();
      final blocks = await _pump(tester, api);
      await tester.tap(find.byKey(_block));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(blocks, [false]);
      expect(api.calls, isEmpty);
    });
  });

  group('report a community item', () {
    testWidgets(
      'submits the reason and note to the report queue, closes the '
      'sheet and thanks the member '
      '[case:common.community_actions.report_could_not_be_submitted_onsubmit.action]',
      (tester) async {
        final api = _server();
        await _pump(tester, api);
        await tester.tap(find.byKey(_report));
        await tester.pumpAndSettle();
        expect(find.text(_en.reportSheetTitle), findsOneWidget);

        await tester.enterText(
          find.byType(TextField),
          'Spam links in every post',
        );
        await tester.tap(_submit());
        await tester.pumpAndSettle();

        final sent = api.sent('POST', '/blog/reports/club_post/post-7');
        expect(sent, hasLength(1));
        expect(sent.single.body, {
          'reason': 'inappropriate',
          'description': 'Spam links in every post',
        });
        expect(find.text(_en.reportSheetTitle), findsNothing);
        expect(qaSnackText(tester), _en.communityReportSubmitted);
      },
    );

    testWidgets(
      'a refused report explains, keeps the sheet and the note, '
      're-enables Submit, and the retry sends one request and succeeds '
      '[case:common.community_actions.report_could_not_be_submitted_onsubmit.api_failure]',
      (tester) async {
        final api = _server()
          ..fail(
            'POST /blog/reports/club_post/post-7',
            status: 400,
            message: 'Choose a report reason and use up to 1,000 characters',
          );
        await _pump(tester, api);
        await tester.tap(find.byKey(_report));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField),
          'Keeps posting spoilers',
        );

        await tester.tap(_submit());
        await tester.pumpAndSettle();

        expect(
          api.sent('POST', '/blog/reports/club_post/post-7'),
          hasLength(1),
        );
        expect(qaSnackText(tester), _en.reportSubmitFailed);
        // Said inside the sheet too: the snack bar sits behind the sheet
        // (regression: the failure was invisible).
        expect(
          find
              .descendant(
                of: find.byKey(const Key('report_sheet_error')),
                matching: find.text(_en.reportSubmitFailed),
              )
              .hitTestable(),
          findsOneWidget,
        );
        // Nothing is lost: the sheet stays open with the note, ready to retry.
        expect(find.text(_en.reportSheetTitle), findsOneWidget);
        expect(find.text('Keeps posting spoilers'), findsOneWidget);
        final submit = tester.widget<FilledButton>(_submit());
        expect(submit.onPressed, isNotNull);
        expect(tester.takeException(), isNull);

        // Offline is explained the same way.
        api.offline('POST /blog/reports/club_post/post-7');
        await tester.tap(_submit());
        await tester.pumpAndSettle();
        expect(
          api.sent('POST', '/blog/reports/club_post/post-7'),
          hasLength(2),
        );
        expect(find.text(_en.reportSheetTitle), findsOneWidget);

        api.json('POST /blog/reports/club_post/post-7', {
          'accepted': true,
          'report': {'id': 'case-2'},
        });
        await tester.tap(_submit());
        await tester.pump();
        // While it sends, Submit is disabled: a second tap cannot send twice.
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        await tester.tap(find.byType(FilledButton), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(
          api.sent('POST', '/blog/reports/club_post/post-7'),
          hasLength(3),
        );
        expect(api.sent('POST', '/blog/reports/club_post/post-7').last.body, {
          'reason': 'inappropriate',
          'description': 'Keeps posting spoilers',
        });
        expect(find.text(_en.reportSheetTitle), findsNothing);
        // The thank-you replaces the earlier failure at once (regression: it
        // queued behind "Failed to submit report").
        expect(qaSnackText(tester), _en.communityReportSubmitted);
      },
    );
  });

  testWidgets('the confirmation, the report sheet and the results render '
      'translated, with no English left '
      '[case:common.community_actions.l10n]', (tester) async {
    for (final locale in const [Locale('de'), Locale('es')]) {
      final l10n = qaL10n(locale);
      await tester.pumpWidget(const SizedBox());
      final api = _server();
      await _pump(tester, api, locale: locale);

      await tester.tap(find.byKey(_block));
      await tester.pumpAndSettle();
      for (final text in [
        l10n.communityBlockTitle('Asha'),
        l10n.communityBlockBody,
        l10n.commonCancel,
        l10n.communityBlockAction,
      ]) {
        expect(find.text(text), findsOneWidget, reason: '$locale: $text');
      }
      for (final english in [
        _en.communityBlockTitle('Asha'),
        _en.communityBlockBody,
        _en.commonCancel,
        _en.communityBlockAction,
      ]) {
        expect(find.text(english), findsNothing, reason: '$locale: $english');
      }
      await tester.tap(find.text(l10n.commonCancel));
      await tester.pumpAndSettle();

      // A failed report, then a successful one.
      api.fail('POST /blog/reports/club_post/post-7');
      await tester.tap(find.byKey(_report));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l10n.reportSubmit));
      await tester.pumpAndSettle();
      expect(qaSnackText(tester), l10n.reportSubmitFailed, reason: '$locale');
      expect(
        find.descendant(
          of: find.byKey(const Key('report_sheet_error')),
          matching: find.text(l10n.reportSubmitFailed),
        ),
        findsOneWidget,
      );
      for (final text in [
        l10n.reportSheetTitle,
        l10n.reportReasonLabel,
        l10n.reportReasonInappropriate,
        l10n.reportDescriptionLabel,
      ]) {
        expect(find.text(text), findsWidgets, reason: '$locale: $text');
      }
      for (final english in [
        _en.reportSubmitFailed,
        _en.reportReasonLabel,
        _en.reportDescriptionLabel,
        _en.reportSubmit,
      ]) {
        expect(find.text(english), findsNothing, reason: '$locale: $english');
      }
      api.json('POST /blog/reports/club_post/post-7', {
        'accepted': true,
        'report': {'id': 'case-3'},
      });
      await tester.tap(find.widgetWithText(FilledButton, l10n.reportSubmit));
      await tester.pumpAndSettle();
      expect(
        qaSnackText(tester),
        l10n.communityReportSubmitted,
        reason: '$locale',
      );
      expect(find.text(_en.communityReportSubmitted), findsNothing);
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });
}
