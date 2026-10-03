import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/common/screens/account_data_screen.dart';

import '../../support/qa_api.dart';

// Account & Data: hide/unhide, export (shown and copied to the clipboard)
// and deletion (always confirmed, with "hide instead" offered), plus the
// countdown's "Keep my account". Every action sends the request the server
// expects and shows the account's real state afterwards; failures explain
// and leave the controls usable.

const _retry = ValueKey('qa.account.retry');
const _cancelDeletion = ValueKey('qa.account.cancel_deletion_button');
const _pause = ValueKey('qa.account.pause_toggle_button');
const _export = ValueKey('qa.account.export_button');
const _exportText = ValueKey('qa.account.export_text');
const _copy = ValueKey('qa.account.export_copy');
const _close = ValueKey('qa.account.export_close');
const _delete = ValueKey('qa.account.delete_button');
const _keep = ValueKey('qa.account.delete_keep');
const _hideInstead = ValueKey('qa.account.delete_hide_instead');
const _confirmDelete = ValueKey('qa.account.delete_confirm_button');

/// What a member's export looks like, with text in several scripts.
const _exportPayload = <String, dynamic>{
  'profile': {'name': 'Zoë Łucja', 'bio': 'Café ☕ · 東京 · «привет» 🌸'},
  'messages_sent': [
    {'text': 'See you at 7? 😊'},
  ],
};

class _Account {
  _Account({bool deactivated = false, bool deletionScheduled = false}) {
    lifecycle['deactivated'] = deactivated || deletionScheduled;
    if (deletionScheduled) {
      _schedule();
    }
    api
      ..on('GET /account/me/lifecycle', (_) => qaOk(_state()))
      ..on('POST /account/me/deactivate', (_) {
        lifecycle['deactivated'] = true;
        return qaOk(_state());
      })
      ..on('POST /account/me/reactivate', (_) {
        lifecycle['deactivated'] = false;
        return qaOk(_state());
      })
      ..on('POST /account/me/deletion', (_) {
        lifecycle['deactivated'] = true;
        _schedule();
        return qaOk(_state());
      })
      ..on('DELETE /account/me/deletion', (_) {
        lifecycle
          ..remove('deletion_requested_at')
          ..remove('deletion_effective_at')
          ..['deletion_cancellable'] = false
          ..['deactivated'] = false;
        return qaOk(_state());
      })
      ..json('POST /account/me/export', {'export': _exportPayload});
  }

  final api = QaApi();
  final lifecycle = <String, dynamic>{'is_active': true};

  void _schedule() {
    final now = DateTime.now().toUtc();
    lifecycle
      ..['deletion_requested_at'] = now.toIso8601String()
      ..['deletion_effective_at'] = now
          .add(const Duration(days: 14, hours: 1))
          .toIso8601String()
      ..['deletion_cancellable'] = true;
  }

  Map<String, dynamic> _state() => {
    'lifecycle': {...lifecycle},
  };

  List<String> get writes => api.writeLines;
  int get lifecycleReads => api.sent('GET', '/account/me/lifecycle').length;
}

Future<void> _open(WidgetTester tester, _Account account, {Locale? locale}) =>
    pumpQa(tester, account.api, const AccountDataScreen(), locale: locale);

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pump();
  await tester.tap(find.byKey(key));
  await qaSettle(tester, frames: 5);
}

ButtonStyleButton _button(WidgetTester tester, Key key) =>
    tester.widget<ButtonStyleButton>(find.byKey(key));

/// Records what the app puts on the clipboard.
List<String> _recordClipboard(WidgetTester tester) {
  final copied = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return copied;
}

void main() {
  final en = qaL10n(const Locale('en'));
  final pretty = const JsonEncoder.withIndent('  ').convert(_exportPayload);

  group('load', () {
    testWidgets('Retry reloads the account after a failed load '
        '[case:common.account_data.account_retry_retry.action]', (tester) async {
      final account = _Account();
      account.api.fail('GET /account/me/lifecycle', status: 503);
      await _open(tester, account);
      expect(find.text(en.accountLoadFailed), findsOneWidget);
      expect(find.byKey(_pause), findsNothing);

      account.api.on(
        'GET /account/me/lifecycle',
        (_) => qaOk({'lifecycle': account.lifecycle}),
      );
      await _tap(tester, _retry);

      expect(account.lifecycleReads, 2);
      expect(find.text(en.accountLoadFailed), findsNothing);
      expect(find.text(en.accountTakeBreakTitle), findsOneWidget);
      expect(find.text(en.accountDownloadTitle), findsOneWidget);
    });

    testWidgets(
      'Retry while still offline keeps the message and the Retry button '
      '[case:common.account_data.account_retry_retry.api_failure]',
      (tester) async {
        final account = _Account();
        account.api.offline('GET /account/me/lifecycle');
        await _open(tester, account);

        await _tap(tester, _retry);

        expect(account.lifecycleReads, 2);
        expect(find.text(en.accountLoadFailed), findsOneWidget);
        expect(find.byKey(_retry), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('take a break', () {
    testWidgets('Hide my profile hides it; Unhide brings it back '
        '[case:common.account_data.account_pause_toggle_button.action]', (
      tester,
    ) async {
      final account = _Account();
      await _open(tester, account);
      expect(find.text(en.accountHideProfile), findsOneWidget);

      await _tap(tester, _pause);
      expect(
        account.api.sent('POST', '/account/me/deactivate').single.body,
        <String, dynamic>{},
      );
      expect(qaSnackText(tester), en.accountNowHiddenSnack);
      expect(find.text(en.accountHiddenTitle), findsOneWidget);
      expect(find.text(en.accountUnhideProfile), findsOneWidget);
      // Let the first message time out.
      await tester.pump(const Duration(seconds: 5));
      await qaSettle(tester);

      await _tap(tester, _pause);
      expect(account.writes, [
        'POST /account/me/deactivate',
        'POST /account/me/reactivate',
      ]);
      expect(qaSnackText(tester), en.accountVisibleAgainSnack);
      expect(find.text(en.accountTakeBreakTitle), findsOneWidget);
      expect(find.text(en.accountHideProfile), findsOneWidget);
    });

    testWidgets('a refused hide explains and shows the account as it really is '
        '[case:common.account_data.account_pause_toggle_button.api_failure]', (
      tester,
    ) async {
      final account = _Account();
      account.api.fail('POST /account/me/deactivate', status: 500);
      await _open(tester, account);

      await _tap(tester, _pause);

      expect(account.writes, ['POST /account/me/deactivate']);
      expect(qaSnackText(tester), en.accountUpdateFailed);
      // Re-read from the server: still visible, and the button still works.
      expect(account.lifecycleReads, 2);
      expect(find.text(en.accountTakeBreakTitle), findsOneWidget);
      expect(_button(tester, _pause).onPressed, isNotNull);
    });
  });

  group('export', () {
    testWidgets('Prepare my data shows the export in a dialog '
        '[case:common.account_data.account_export_button.action] '
        '[case:common.account_data.showdialog_open.action] '
        '[case:common.account_data.account_export_text_input.action]', (
      tester,
    ) async {
      final account = _Account();
      await _open(tester, account);

      await _tap(tester, _export);

      expect(account.writes, ['POST /account/me/export']);
      expect(account.lifecycleReads, 2);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(en.accountYourData), findsOneWidget);
      expect(
        tester.widget<SelectableText>(find.byKey(_exportText)).data,
        pretty,
      );
      expect(qaSnackText(tester), isNull);
    });

    testWidgets(
      'Copy puts the whole export on the clipboard, unicode intact, and closes '
      '[case:common.account_data.account_export_copy.action] '
      '[case:common.account_data.account_export_text_input.validation]',
      (tester) async {
        final copied = _recordClipboard(tester);
        final account = _Account();
        await _open(tester, account);
        await _tap(tester, _export);

        await _tap(tester, _copy);

        expect(copied, [pretty]);
        expect(copied.single, contains('Zoë Łucja'));
        expect(copied.single, contains('Café ☕ · 東京 · «привет» 🌸'));
        expect(jsonDecode(copied.single), _exportPayload);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text(en.accountPrepareData), findsOneWidget);
        expect(_button(tester, _export).onPressed, isNotNull);
      },
    );

    testWidgets('Close dismisses the export without copying '
        '[case:common.account_data.account_export_close.action]', (tester) async {
      final copied = _recordClipboard(tester);
      final account = _Account();
      await _open(tester, account);
      await _tap(tester, _export);

      await _tap(tester, _close);

      expect(find.byType(AlertDialog), findsNothing);
      expect(copied, isEmpty);
      expect(account.writes, ['POST /account/me/export']);
      expect(_button(tester, _export).onPressed, isNotNull);
    });

    testWidgets(
      'while preparing, the button is busy and a second tap sends nothing '
      '[case:common.account_data.account_export_button.action]',
      (tester) async {
        final account = _Account();
        account.api.on(
          'POST /account/me/export',
          (_) => const QaReply(200, {
            'export': _exportPayload,
          }, delay: Duration(milliseconds: 400)),
        );
        await _open(tester, account);
        await tester.ensureVisible(find.byKey(_export));
        await tester.pump();

        await tester.tap(find.byKey(_export));
        await tester.pump();
        expect(find.text(en.accountPreparing), findsOneWidget);
        expect(_button(tester, _export).onPressed, isNull);
        await tester.tap(find.byKey(_export), warnIfMissed: false);
        await qaSettle(tester, frames: 8);

        expect(account.writes, ['POST /account/me/export']);
        expect(find.byType(AlertDialog), findsOneWidget);
      },
    );

    testWidgets('a failed export explains and the button works again '
        '[case:common.account_data.account_export_button.api_failure]', (
      tester,
    ) async {
      final account = _Account();
      account.api.fail('POST /account/me/export', status: 500);
      await _open(tester, account);

      await _tap(tester, _export);

      expect(account.writes, ['POST /account/me/export']);
      expect(find.byType(AlertDialog), findsNothing);
      expect(qaSnackText(tester), en.accountPrepareFailed);
      expect(find.text(en.accountPrepareData), findsOneWidget);
      expect(_button(tester, _export).onPressed, isNotNull);

      // Once the server is back, the same button produces the export.
      account.api.json('POST /account/me/export', {'export': _exportPayload});
      await _tap(tester, _export);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('export offline explains and the button works again '
        '[case:common.account_data.account_export_button.api_failure]', (
      tester,
    ) async {
      final account = _Account();
      account.api.offline('POST /account/me/export');
      await _open(tester, account);

      await _tap(tester, _export);

      expect(qaSnackText(tester), en.accountPrepareFailed);
      expect(_button(tester, _export).onPressed, isNotNull);
    });
  });

  group('delete', () {
    testWidgets('Delete my account asks first and offers hiding instead '
        '[case:common.account_data.delete_your_account.action]', (
      tester,
    ) async {
      final account = _Account();
      await _open(tester, account);

      await _tap(tester, _delete);

      expect(find.text(en.accountDeleteConfirmTitle), findsOneWidget);
      expect(find.text(en.accountDeleteConfirmBody), findsOneWidget);
      expect(find.byKey(_keep), findsOneWidget);
      expect(find.byKey(_hideInstead), findsOneWidget);
      expect(find.byKey(_confirmDelete), findsOneWidget);
      // Asking is not deleting.
      expect(account.writes, isEmpty);
    });

    testWidgets('Keep my account closes the question and changes nothing '
        '[case:common.account_data.account_delete_keep.action]', (tester) async {
      final account = _Account();
      await _open(tester, account);
      await _tap(tester, _delete);

      await _tap(tester, _keep);

      expect(find.byType(AlertDialog), findsNothing);
      expect(account.writes, isEmpty);
      expect(qaSnackText(tester), isNull);
      expect(find.text(en.accountTakeBreakTitle), findsOneWidget);
      expect(_button(tester, _delete).onPressed, isNotNull);
    });

    testWidgets('Hide instead hides the profile and deletes nothing '
        '[case:common.account_data.account_delete_hide_instead.action]', (tester) async {
      final account = _Account();
      await _open(tester, account);
      await _tap(tester, _delete);

      await _tap(tester, _hideInstead);

      expect(account.writes, ['POST /account/me/deactivate']);
      expect(qaSnackText(tester), en.accountNowHiddenSnack);
      expect(find.text(en.accountHiddenTitle), findsOneWidget);
      expect(find.text(en.accountDeletionAlreadyScheduled), findsNothing);
    });

    testWidgets(
      'Hide instead refused explains and leaves the account as it was '
      '[case:common.account_data.account_delete_hide_instead.api_failure]',
      (tester) async {
        final account = _Account();
        account.api.offline('POST /account/me/deactivate');
        await _open(tester, account);
        await _tap(tester, _delete);

        await _tap(tester, _hideInstead);

        expect(account.writes, ['POST /account/me/deactivate']);
        expect(qaSnackText(tester), en.commonSomethingWentWrongTryAgain);
        expect(find.text(en.accountTakeBreakTitle), findsOneWidget);
      },
    );

    testWidgets(
      'confirming Delete schedules the deletion and shows the countdown '
      '[case:common.account_data.account_delete_button.action] '
      '[case:common.account_data.account_delete_confirm_button.action]',
      (tester) async {
        final account = _Account();
        await _open(tester, account);
        await _tap(tester, _delete);

        await _tap(tester, _confirmDelete);

        expect(
          account.api.sent('POST', '/account/me/deletion').single.body,
          <String, dynamic>{},
        );
        expect(account.writes, ['POST /account/me/deletion']);
        expect(find.byType(AlertDialog), findsNothing);
        expect(qaSnackText(tester), en.accountDeletionScheduledSnack);
        expect(find.text(en.accountDeletionIn(14)), findsOneWidget);
        expect(find.text(en.accountDeletionAlreadyScheduled), findsOneWidget);
        // Nothing else can be toggled while a deletion is pending.
        expect(_button(tester, _delete).onPressed, isNull);
        expect(_button(tester, _pause).onPressed, isNull);
        expect(_button(tester, _cancelDeletion).onPressed, isNotNull);
      },
    );

    testWidgets('a refused deletion explains and leaves the account untouched '
        '[case:common.account_data.account_delete_button.api_failure]', (
      tester,
    ) async {
      final account = _Account();
      account.api.fail('POST /account/me/deletion', status: 500);
      await _open(tester, account);
      await _tap(tester, _delete);

      await _tap(tester, _confirmDelete);

      expect(account.writes, ['POST /account/me/deletion']);
      expect(qaSnackText(tester), en.commonSomethingWentWrongTryAgain);
      expect(find.byKey(_cancelDeletion), findsNothing);
      expect(_button(tester, _delete).onPressed, isNotNull);
    });

    testWidgets('Keep my account on the countdown cancels the deletion '
        '[case:common.account_data.account_cancel_deletion_button.action]', (
      tester,
    ) async {
      final account = _Account(deletionScheduled: true);
      await _open(tester, account);
      expect(find.text(en.accountDeletionIn(14)), findsOneWidget);

      await _tap(tester, _cancelDeletion);

      expect(account.writes, ['DELETE /account/me/deletion']);
      expect(qaSnackText(tester), en.accountNotDeletedSnack);
      expect(find.byKey(_cancelDeletion), findsNothing);
      expect(find.text(en.accountTakeBreakTitle), findsOneWidget);
      expect(_button(tester, _delete).onPressed, isNotNull);
    });

    testWidgets(
      'a refused cancel explains and keeps the countdown actionable '
      '[case:common.account_data.account_cancel_deletion_button.api_failure]',
      (tester) async {
        final account = _Account(deletionScheduled: true);
        account.api.fail('DELETE /account/me/deletion', status: 500);
        await _open(tester, account);

        await _tap(tester, _cancelDeletion);

        expect(account.writes, ['DELETE /account/me/deletion']);
        expect(qaSnackText(tester), en.accountCancelFailed);
        expect(find.text(en.accountDeletionIn(14)), findsOneWidget);
        expect(_button(tester, _cancelDeletion).onPressed, isNotNull);
      },
    );
  });

  testWidgets('Account & Data renders in every shipped language '
      '[case:common.account_data.l10n]', (tester) async {
    for (final locale in qaLocales) {
      final l10n = qaL10n(locale);
      await tester.pumpWidget(const SizedBox());
      await _open(tester, _Account(), locale: locale);
      expect(tester.takeException(), isNull, reason: '$locale');
      expect(find.text(l10n.accountTitle), findsOneWidget, reason: '$locale');
      expect(
        find.text(l10n.accountTakeBreakTitle),
        findsOneWidget,
        reason: '$locale',
      );
      expect(
        find.text(l10n.accountPrepareData),
        findsOneWidget,
        reason: '$locale',
      );
    }
  });
}
