// Case ids stay whole in test names (the QA Lab reads them literally).
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/common/widgets/report_user_sheet.dart';

import '../../support/qa_api.dart';

// The shared report sheet: a reason (four choices, "Inappropriate content"
// by default) and an optional note, handed to the caller's submit callback
// exactly as entered; the sheet closes with the report id on success.

const _open = ValueKey('host.open_report');

final _en = qaL10n(const Locale('en'));

/// What the sheet handed to the caller's submit callback.
typedef _Submitted = ({String reason, String? description});

class _Recorder {
  final submitted = <_Submitted>[];
  final results = <String?>[];
}

Widget _host(_Recorder recorder) => Builder(
  builder: (context) => Scaffold(
    body: Center(
      child: TextButton(
        key: _open,
        onPressed: () async {
          recorder.results.add(
            await showReportUserSheet(
              context: context,
              onSubmit: ({required reason, description}) async {
                recorder.submitted.add((
                  reason: reason,
                  description: description,
                ));
                return 'report-${recorder.submitted.length}';
              },
            ),
          );
        },
        child: const Text('open'),
      ),
    ),
  ),
);

Future<_Recorder> _openSheet(WidgetTester tester, {Locale? locale}) async {
  final recorder = _Recorder();
  await pumpQa(tester, QaApi(), _host(recorder), locale: locale);
  await tester.tap(find.byKey(_open));
  await tester.pumpAndSettle();
  return recorder;
}

Finder get _description => find.byType(TextField);

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, _en.reportSubmit));
  await tester.pumpAndSettle();
}

String? _dropdownValue(WidgetTester tester) => tester
    .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
    .value;

void main() {
  testWidgets('opening a report presents the sheet with the reason, the '
      'optional note and Submit; dismissing it reports nothing '
      '[case:common.report_user_sheet.showmodalbottomsheet_open.action]', (
    tester,
  ) async {
    final recorder = await _openSheet(tester);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text(_en.reportSheetTitle), findsOneWidget);
    expect(find.text(_en.reportReasonLabel), findsOneWidget);
    expect(find.text(_en.reportReasonInappropriate), findsOneWidget);
    expect(_dropdownValue(tester), 'inappropriate');
    expect(find.text(_en.reportDescriptionLabel), findsOneWidget);
    expect(find.widgetWithText(FilledButton, _en.reportSubmit), findsOneWidget);

    // Swiping the sheet away (or tapping outside) cancels.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(recorder.submitted, isEmpty);
    expect(recorder.results, [null]);
  });

  group('Reason', () {
    for (final (label, value) in [
      (_en.reportReasonHarassment, 'harassment'),
      (_en.reportReasonFraud, 'fraud'),
      (_en.reportReasonFake, 'fake'),
    ]) {
      testWidgets('choosing "$label" submits reason "$value" '
          '[case:common.report_user_sheet.reason.action]', (tester) async {
        final recorder = await _openSheet(tester);

        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
        expect(_dropdownValue(tester), value);
        expect(find.text(label), findsOneWidget);

        await _submit(tester);

        expect(recorder.submitted.single.reason, value);
        expect(recorder.results, ['report-1']);
        expect(find.byType(BottomSheet), findsNothing);
      });
    }

    testWidgets('left alone, the reason is "inappropriate" '
        '[case:common.report_user_sheet.reason.action]', (tester) async {
      final recorder = await _openSheet(tester);
      await _submit(tester);
      expect(recorder.submitted.single.reason, 'inappropriate');
    });
  });

  group('Description (optional)', () {
    testWidgets('typing a note focuses the field and the note is submitted '
        'as typed; without one an empty note is sent '
        '[case:common.report_user_sheet.description_optional_input.action]', (
      tester,
    ) async {
      final recorder = await _openSheet(tester);
      expect(
        find.descendant(
          of: _description,
          matching: find.text(_en.reportDescriptionLabel),
        ),
        findsOneWidget,
      );

      await tester.tap(_description);
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      await tester.enterText(_description, 'Asked me for money\non day one');
      await tester.pump();
      expect(find.text('Asked me for money\non day one'), findsOneWidget);
      await _submit(tester);

      expect(recorder.submitted.single, (
        reason: 'inappropriate',
        description: 'Asked me for money\non day one',
      ));

      // Again without a note.
      await tester.tap(find.byKey(_open));
      await tester.pumpAndSettle();
      await _submit(tester);
      expect(recorder.submitted.last.description, '');
      expect(recorder.results, ['report-1', 'report-2']);
    });

    testWidgets(
      'unicode and emoji reach the caller unchanged; a note longer '
      'than the server accepts (1,000 characters) is stopped while typing '
      '[case:common.report_user_sheet.description_optional_input.validation]',
      (tester) async {
        final recorder = await _openSheet(tester);
        const unicode = 'Ünïcødé 😀👍🏽 日本語 مرحبا — “quoted”';
        await tester.enterText(_description, unicode);
        await tester.pump();
        expect(find.text(unicode), findsOneWidget);
        await _submit(tester);
        expect(recorder.submitted.single.description, unicode);

        await tester.tap(find.byKey(_open));
        await tester.pumpAndSettle();
        final tooLong = 'a' * (reportDescriptionMaxLength + 200);
        await tester.enterText(_description, tooLong);
        await tester.pump();
        final typed = tester.widget<TextField>(_description).controller!.text;
        expect(typed.length, reportDescriptionMaxLength);
        // The counter tells the member where the limit is.
        expect(
          find.text('$reportDescriptionMaxLength/$reportDescriptionMaxLength'),
          findsOneWidget,
        );
        await _submit(tester);
        expect(
          recorder.submitted.last.description!.length,
          reportDescriptionMaxLength,
        );

        // Whitespace only is allowed (the note is optional); it is passed on
        // for the server to trim.
        await tester.tap(find.byKey(_open));
        await tester.pumpAndSettle();
        await tester.enterText(_description, '   ');
        await _submit(tester);
        expect(recorder.submitted.last.description, '   ');
        expect(recorder.results, ['report-1', 'report-2', 'report-3']);
      },
    );
  });

  testWidgets('the sheet renders translated in every shipped language without '
      'overflowing (regression: a long reason overflowed the field), with no '
      'English left [case:common.report_user_sheet.l10n]', (tester) async {
    for (final locale in qaLocales) {
      final l10n = qaL10n(locale);
      await tester.pumpWidget(const SizedBox());
      await _openSheet(tester, locale: locale);

      for (final text in [
        l10n.reportSheetTitle,
        l10n.reportReasonLabel,
        l10n.reportReasonInappropriate,
        l10n.reportDescriptionLabel,
        l10n.reportSubmit,
      ]) {
        expect(find.text(text), findsOneWidget, reason: '$locale: $text');
      }
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      for (final text in [
        l10n.reportReasonHarassment,
        l10n.reportReasonFraud,
        l10n.reportReasonFake,
      ]) {
        expect(find.text(text), findsWidgets, reason: '$locale: $text');
      }
      if (const ['de', 'it'].contains(locale.languageCode)) {
        for (final english in [
          _en.reportSheetTitle,
          _en.reportReasonLabel,
          _en.reportReasonInappropriate,
          _en.reportReasonHarassment,
          _en.reportReasonFraud,
          _en.reportReasonFake,
          _en.reportDescriptionLabel,
          _en.reportSubmit,
        ]) {
          expect(find.text(english), findsNothing, reason: '$locale: $english');
        }
      }
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });
}
