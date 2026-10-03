// Control-level tests for the signed-in request form
// (support_ticket_form_screen.dart) not covered in support_ticket_form_test:
// the description limits, Open SOS on the safety topic, Back to Help &
// Support while requests are off, and the screen-quality cases.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/safety/screens/sos_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_form_screen.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';
import 'support_qa_world.dart';

final subject = find.byKey(const Key('support_subject'));
final description = find.byKey(const Key('support_description'));
final submit = find.byKey(const Key('submit_support_ticket'));

Future<List<Object?>> pumpForm(WidgetTester t, SupportWorld w) => pumpQa(
  t,
  w.api,
  const SupportTicketFormScreen(),
  size: const Size(900, 2400),
  launcher: true,
);

List<QaCall> creates(SupportWorld w) => w.api.sent('POST', '/support/tickets');

void main() {
  testWidgets(
    'What happened?: empty or spaces is refused before sending, 5000 '
    'characters is the limit, line breaks and emoji are kept '
    '[case:support.support_ticket_form.support_description_input.validation]',
    (t) async {
      final w = SupportWorld();
      await pumpForm(t, w);
      await tapIn(t, find.byKey(const Key('support_category_technical')));
      await t.enterText(subject, 'App crashes on chat');
      await tapIn(t, submit);
      expect(find.text(en.supportErrorDescriptionRequired), findsOneWidget);
      await t.enterText(description, '  \n   ');
      await tapIn(t, submit);
      expect(find.text(en.supportErrorDescriptionRequired), findsOneWidget);
      expect(creates(w), isEmpty);

      await t.enterText(description, 'x' * 5300);
      expect(fieldText(t, description), hasLength(5000));
      await t.enterText(description, ' Line one 😩\nLine two ');
      await tapIn(t, submit);
      expect(creates(w).single.body['description'], 'Line one 😩\nLine two');
    },
  );

  testWidgets(
    'With the safety topic, Open SOS opens the SOS screen and keeps the '
    'request as typed '
    '[case:support.support_ticket_form.open_sos.action]',
    (t) async {
      final w = SupportWorld();
      await pumpForm(t, w);
      await t.enterText(subject, 'Someone is following me');
      await tapIn(
        t,
        find.byKey(const Key('support_category_safety_harassment')),
      );
      await tapIn(t, find.text(en.supportOpenSos));
      expect(find.byType(SosScreen), findsOneWidget);

      await t.pageBack();
      await qaSettle(t);
      expect(find.byType(SupportTicketFormScreen), findsOneWidget);
      expect(fieldText(t, subject), 'Someone is following me');
      expect(creates(w), isEmpty);
    },
  );

  testWidgets(
    'While requests are switched off, Back to Help & Support closes the form '
    '[case:support.support_ticket_form.back_to_help_support.action]',
    (t) async {
      final w = SupportWorld();
      w.api.on(
        'POST /support/tickets',
        (_) => supportError(403, 'FEATURE_DISABLED'),
      );
      final popped = await pumpForm(t, w);
      await tapIn(t, find.byKey(const Key('support_category_technical')));
      await t.enterText(subject, 'App crashes on chat');
      await t.enterText(description, 'When I open a chat the app closes.');
      await tapIn(t, submit);
      expect(find.byKey(const Key('support_unavailable')), findsOneWidget);

      await tapIn(t, find.text(en.supportBackToHelp));
      expect(find.byType(SupportTicketFormScreen), findsNothing);
      expect(popped, hasLength(1));
    },
  );

  group('screen quality', () {
    testWidgets('lays out on phone and tablet, both themes '
        '[case:support.support_ticket_form.layout_matrix]', (t) async {
      await qaExpectLaysOutEverywhere(
        t,
        SupportWorld().api,
        SupportTicketFormScreen.new,
        loaded: submit,
      );
    });

    testWidgets('meets tap-target, label and contrast guidelines '
        '[case:support.support_ticket_form.a11y_guidelines]', (t) async {
      await qaExpectMeetsA11yGuidelines(
        t,
        SupportWorld().api,
        () =>
            const SupportTicketFormScreen(initialCategory: 'safety_harassment'),
        size: const Size(430, 1800),
        loaded: find.text(en.supportOpenSos),
      );
    });

    testWidgets('pushed, Back returns to Help & Support '
        '[case:support.support_ticket_form.back_affordance]', (t) async {
      await qaExpectBackReturns(
        t,
        SupportWorld().api,
        SupportTicketFormScreen.new,
        screen: SupportTicketFormScreen,
      );
    });

    testWidgets('renders in every shipped locale with nothing left in English '
        '[case:support.support_ticket_form.l10n]', (t) async {
      await qaExpectRendersInAllLocales(
        t,
        SupportWorld().api,
        () =>
            const SupportTicketFormScreen(initialCategory: 'safety_harassment'),
        size: const Size(430, 2000),
        expected: [
          (l) => l.supportFormTitle,
          (l) => l.supportFormCategorySection,
          (l) => l.supportCategorySafetyHarassment,
          (l) => l.supportSafetyNote,
          (l) => l.supportOpenSos,
          (l) => l.supportFormDetailsSection,
          (l) => l.supportFormSubjectLabel,
          (l) => l.supportFormDescriptionLabel,
          (l) => l.supportFormScreenshotsSection,
          (l) => l.supportAddScreenshot,
          (l) => l.supportSubmit,
        ],
        // German and Dutch use these words too ("Details", "Screenshots",
        // "Matches & chat" are their labels).
        allow: {'Matches & chat', 'DETAILS', 'SCREENSHOTS'},
      );
    });
  });
}
