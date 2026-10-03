// Control tests for the "Leave Connect together?" sheet against the
// recording fake BFF: the real opener (showProposeGraduationSheet), the note
// (what is actually sent for empty, whitespace, over-long and emoji/RTL
// input), the share switch, "Ask them" with its failure and retry, and the
// sheet in all 10 languages.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/graduation/models/graduation.dart';
import 'package:verified_dating_app/features/graduation/screens/propose_graduation_sheet.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_quality.dart';
import 'graduation_qa_server.dart';

final en = lookupAppLocalizations(const Locale('en'));

Finder _key(String key) => find.byKey(ValueKey(key));

/// A page whose only control opens the sheet with the app's own opener and
/// keeps what the sheet resolved to.
class _Opener extends StatelessWidget {
  const _Opener(this.results);
  final List<Graduation?> results;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: IconButton(
        key: const ValueKey('qa.test.open_sheet'),
        icon: const Icon(Icons.favorite_rounded),
        onPressed: () async => results.add(
          await showProposeGraduationSheet(
            context: context,
            matchId: gradMatchId,
            partnerName: gradPartner,
          ),
        ),
      ),
    ),
  );
}

Future<List<Graduation?>> _openSheet(
  WidgetTester tester,
  GradServer server,
) async {
  final results = <Graduation?>[];
  await pumpQa(tester, server.api, _Opener(results));
  await tester.tap(_key('qa.test.open_sheet'));
  await qaSettle(tester);
  return results;
}

Future<void> _submit(WidgetTester tester) async {
  await tester.ensureVisible(_key('qa.graduation.submit'));
  await tester.tap(_key('qa.graduation.submit'));
  await qaSettle(tester);
}

String _fieldText(WidgetTester tester) =>
    tester.widget<TextField>(_key('qa.graduation.note')).controller!.text;

bool _submitEnabled(WidgetTester tester) =>
    tester.widget<ButtonStyleButton>(_key('qa.graduation.submit')).onPressed !=
    null;

SwitchListTile _share(WidgetTester tester) =>
    tester.widget<SwitchListTile>(_key('qa.graduation.share_switch'));

void main() {
  group('opening', () {
    testWidgets(
      'showProposeGraduationSheet presents the sheet for the match; '
      'backing out resolves to nothing and sends nothing '
      '[case:graduation.propose_graduation_sheet.showmodalbottomsheet_open.action]',
      (tester) async {
        final server = GradServer();
        final results = await _openSheet(tester, server);

        expect(find.byType(BottomSheet), findsOneWidget);
        expect(
          find.text(en.graduationProposeTitle(gradPartner)),
          findsOneWidget,
        );
        expect(
          find.text(en.graduationProposeBody(gradPartner)),
          findsOneWidget,
        );
        expect(_key('qa.graduation.note'), findsOneWidget);
        expect(_key('qa.graduation.share_switch'), findsOneWidget);
        expect(find.text(en.graduationAskThem), findsOneWidget);

        // Tap the scrim above the sheet.
        await tester.tapAt(const Offset(20, 20));
        await qaSettle(tester);
        expect(find.byType(BottomSheet), findsNothing);
        expect(results, [null]);
        expect(server.api.writes, isEmpty);
      },
    );
  });

  group('note', () {
    testWidgets(
      'typing a note shows it with a counter and Ask them sends it '
      '[case:graduation.propose_graduation_sheet.graduation_note_input.action]',
      (tester) async {
        final server = GradServer();
        await _openSheet(tester, server);

        await tester.enterText(
          _key('qa.graduation.note'),
          'Ready when you are',
        );
        await tester.pump();
        expect(_fieldText(tester), 'Ready when you are');
        expect(find.text('18/200'), findsOneWidget);
        await _submit(tester);

        expect(server.api.writes.single.body['note'], 'Ready when you are');
      },
    );

    testWidgets(
      'an empty note is optional: Ask them sends no note field '
      '[case:graduation.propose_graduation_sheet.graduation_note_input.validation]',
      (tester) async {
        final server = GradServer();
        final results = await _openSheet(tester, server);
        await _submit(tester);

        expect(server.api.writeLines, ['POST $gradProposePath']);
        expect(server.api.writes.single.body, {'share_with_friends': false});
        expect(results.single?.isOpen, isTrue);
      },
    );

    testWidgets(
      'a whitespace-only note is sent as no note, and surrounding '
      'spaces are trimmed '
      '[case:graduation.propose_graduation_sheet.graduation_note_input.validation]',
      (tester) async {
        final server = GradServer();
        await _openSheet(tester, server);
        await tester.enterText(_key('qa.graduation.note'), '   \n  ');
        await _submit(tester);
        expect(server.api.writes.single.body.containsKey('note'), isFalse);

        await _openSheet(tester, server);
        await tester.enterText(_key('qa.graduation.note'), '  see you soon  ');
        await _submit(tester);
        expect(server.api.writes.last.body['note'], 'see you soon');
      },
    );

    testWidgets(
      'a note longer than 200 characters is cut at 200 in the field '
      'and only 200 are sent '
      '[case:graduation.propose_graduation_sheet.graduation_note_input.validation]',
      (tester) async {
        final server = GradServer();
        await _openSheet(tester, server);
        await tester.enterText(_key('qa.graduation.note'), 'a' * 250);
        await tester.pump();

        expect(_fieldText(tester), 'a' * 200);
        expect(find.text('200/200'), findsOneWidget);
        await _submit(tester);
        expect(server.api.writes.single.body['note'], 'a' * 200);
      },
    );

    testWidgets(
      'emoji and right-to-left text are sent unchanged '
      '[case:graduation.propose_graduation_sheet.graduation_note_input.validation]',
      (tester) async {
        final server = GradServer();
        await _openSheet(tester, server);
        const note = 'مرحبا 👋🏽 שלום 👨‍👩‍👧 ok';
        await tester.enterText(_key('qa.graduation.note'), note);
        await _submit(tester);

        expect(server.api.writes.single.body['note'], note);
        expect(server.current?['note'], note);
      },
    );

    testWidgets(
      'an emoji-heavy note never exceeds the 200 characters the '
      'server counts (code points), and is cut on a whole emoji '
      '[case:graduation.propose_graduation_sheet.graduation_note_input.validation]',
      (tester) async {
        final server = GradServer();
        await _openSheet(tester, server);
        // 150 thumbs-up with a skin tone: 150 visible emoji, 300 code points.
        const emoji = '👍🏽';
        await tester.enterText(_key('qa.graduation.note'), emoji * 150);
        await tester.pump();

        final kept = _fieldText(tester);
        expect(kept.runes.length, lessThanOrEqualTo(200));
        expect(kept, emoji * 100, reason: 'cut on a whole emoji');
        expect(find.text('200/200'), findsOneWidget);
        await _submit(tester);

        final sent = server.api.writes.single.body['note']! as String;
        expect(sent.runes.length, lessThanOrEqualTo(200));
        expect(sent, emoji * 100);
      },
    );
  });

  group('Tell my friends', () {
    testWidgets(
      'Tell my friends toggles the choice Ask them sends '
      '[case:graduation.propose_graduation_sheet.graduation_share_switch.action]',
      (tester) async {
        final server = GradServer();
        await _openSheet(tester, server);

        expect(_share(tester).value, isFalse);
        await tester.tap(_key('qa.graduation.share_switch'));
        await qaSettle(tester);
        expect(_share(tester).value, isTrue);
        await tester.tap(_key('qa.graduation.share_switch'));
        await qaSettle(tester);
        expect(_share(tester).value, isFalse);
        await tester.tap(_key('qa.graduation.share_switch'));
        await qaSettle(tester);
        expect(server.api.writes, isEmpty, reason: 'toggling is local');

        await _submit(tester);
        expect(server.api.writes.single.body['share_with_friends'], isTrue);
      },
    );
  });

  group('Ask them', () {
    testWidgets('Ask them sends the proposal, reloads, closes the sheet and '
        'hands the proposal to the opener '
        '[case:graduation.propose_graduation_sheet.graduation_submit.action]', (
      tester,
    ) async {
      final server = GradServer();
      final results = await _openSheet(tester, server);

      await tester.enterText(_key('qa.graduation.note'), 'Ready when you are');
      await tester.tap(_key('qa.graduation.share_switch'));
      await qaSettle(tester);
      await _submit(tester);

      expect(server.api.writeLines, ['POST $gradProposePath']);
      expect(server.api.writes.single.body, {
        'note': 'Ready when you are',
        'share_with_friends': true,
      });
      // The match's graduation state was reloaded after the proposal.
      final calls = server.api.calls.map((c) => '${c.method} ${c.path}');
      expect(calls.last, 'GET $gradSnapshotPath');
      expect(find.byType(BottomSheet), findsNothing);
      expect(results, hasLength(1));
      final proposal = results.single!;
      expect(proposal.isOpen, isTrue);
      expect(proposal.viewerIsProposer, isTrue);
      expect(proposal.note, 'Ready when you are');
      expect(proposal.shareWithFriends, isTrue);
      expect(server.api.unhandled, isEmpty);
    });

    testWidgets(
      'a failed Ask them shows a readable error, keeps the note and '
      'share choice, re-enables, and the retry sends exactly once more '
      '[case:graduation.propose_graduation_sheet.graduation_submit.api_failure]',
      (tester) async {
        final server = GradServer();
        final results = await _openSheet(tester, server);
        server.api.on(
          'POST $gradProposePath',
          (_) => const QaReply(
            500,
            <String, dynamic>{},
            delay: Duration(milliseconds: 300),
          ),
        );

        await tester.enterText(
          _key('qa.graduation.note'),
          'Ready when you are',
        );
        await tester.tap(_key('qa.graduation.share_switch'));
        await qaSettle(tester);
        await tester.ensureVisible(_key('qa.graduation.submit'));
        await tester.tap(_key('qa.graduation.submit'));
        await tester.pump(const Duration(milliseconds: 50));
        expect(_submitEnabled(tester), isFalse, reason: 'locked in flight');
        await qaSettle(tester);

        expect(server.api.writeLines, ['POST $gradProposePath']);
        expect(
          tester.widget<Text>(_key('qa.graduation.error')).data,
          en.graduationProposeFailed,
        );
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(results, isEmpty);
        expect(_submitEnabled(tester), isTrue);
        expect(_fieldText(tester), 'Ready when you are');
        expect(_share(tester).value, isTrue);

        // Offline: the member is told they are offline.
        server.api.offline('POST $gradProposePath');
        await _submit(tester);
        expect(
          tester.widget<Text>(_key('qa.graduation.error')).data,
          en.networkOfflineTryAgain,
        );
        expect(_submitEnabled(tester), isTrue);

        server.install();
        await _submit(tester);

        expect(server.api.writeLines, List.filled(3, 'POST $gradProposePath'));
        expect(server.api.writes.last.body, {
          'note': 'Ready when you are',
          'share_with_friends': true,
        });
        expect(find.byType(BottomSheet), findsNothing);
        expect(results.single?.note, 'Ready when you are');
      },
    );
  });

  group('languages', () {
    testWidgets('the sheet renders in all 10 languages '
        '[case:graduation.propose_graduation_sheet.l10n]', (tester) async {
      final opened = <Graduation?>[];
      await qaExpectRendersInAllLocales(
        tester,
        api: () => GradServer().api,
        build: () => _Opener(opened),
        allow: {gradPartner},
        prepare: (tester, l) async {
          await tester.tap(_key('qa.test.open_sheet'));
          await qaSettle(tester);
        },
        expected: [
          (l) => l.graduationProposeTitle(gradPartner),
          (l) => l.graduationProposeBody(gradPartner),
          (l) => l.graduationNoteLabel,
          (l) => l.graduationTellFriends,
          (l) => l.graduationTellFriendsBody,
          (l) => l.graduationAskThem,
        ],
      );
    });
  });
}
