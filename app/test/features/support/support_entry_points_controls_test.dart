// The ways into support (support_entry_points.dart) in every shipped locale:
// the Settings tile with its unread badge and open-request count, and the
// Help & Support button outside the main navigation.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/support/support_api.dart';
import 'package:verified_dating_app/features/support/widgets/support_entry_points.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';

QaApi supportApi({int unread = 0, int open = 0}) => QaApi()
  ..json('GET /support/tickets', {
    'success': true,
    'tickets': <dynamic>[],
    'unread_total': unread,
    'open_total': open,
  });

Widget entries() => const Scaffold(
  body: Column(children: [SupportEntryTile(), SupportCentreButton()]),
);

void main() {
  testWidgets('the Settings tile and the Help & Support button render in '
      'every shipped locale, with the unread replies or open requests, and '
      'nothing left in English [case:support.support_entry_points.l10n]', (
    t,
  ) async {
    // Unread replies: the subtitle and the badge say how many.
    await qaExpectRendersInAllLocales(
      t,
      supportApi(unread: 2, open: 1),
      entries,
      extra: [
        qaFlags({supportFeatureFlag: true}),
      ],
      expected: [
        (l) => l.settingsHelpSupportTitle,
        (l) => l.supportUnreadReplies(2),
      ],
      allow: {'2'},
    );
    // Nothing unread: the open requests instead.
    await qaExpectRendersInAllLocales(
      t,
      supportApi(open: 3),
      entries,
      extra: [
        qaFlags({supportFeatureFlag: true}),
      ],
      expected: [
        (l) => l.settingsHelpSupportTitle,
        (l) => l.supportOpenRequests(3),
      ],
    );
    // Requests switched off: the plain subtitle, and no request is made.
    final off = supportApi(unread: 2);
    await qaExpectRendersInAllLocales(
      t,
      off,
      entries,
      extra: [
        qaFlags({supportFeatureFlag: false}),
      ],
      expected: [
        (l) => l.settingsHelpSupportTitle,
        (l) => l.settingsHelpSupportSubtitle,
      ],
    );
    expect(off.sent('GET', '/support/tickets'), isEmpty);
  });
}
