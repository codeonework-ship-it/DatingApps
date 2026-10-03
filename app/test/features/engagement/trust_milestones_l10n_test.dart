import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/engagement/screens/trust_badges_screen.dart';

import '../../support/qa_api.dart';

void main() {
  testWidgets('trust milestones read as German labels, bookkeeping fields are '
      'hidden and unknown keys are humanized [case:l10n.trust_milestones.labels]', (
    tester,
  ) async {
    final de = qaL10n(const Locale('de'));
    final api = QaApi()
      ..json('GET /users/me/trust-badges', {
        'milestones': {
          'user_id': 'me',
          'communication_score': 81,
          'verification_consistent': true,
          'reply_speed_score': 64,
          'last_computed_at': '2026-10-01T10:00:00Z',
        },
        'badges': <Object>[],
        'history': <Object>[],
      });
    await pumpQa(
      tester,
      api,
      const TrustBadgesScreen(),
      locale: const Locale('de'),
    );
    expect(find.text('Kommunikation: 81'), findsOneWidget);
    expect(
      find.text(
        de.engagementTrustMilestoneLine(
          de.engagementTrustMilestoneVerification,
          de.commonYes,
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Reply speed: 64'), findsOneWidget);
    expect(find.textContaining('_score'), findsNothing);
    expect(find.textContaining('user_id'), findsNothing);
    expect(find.textContaining('last_computed_at'), findsNothing);
  });
}
