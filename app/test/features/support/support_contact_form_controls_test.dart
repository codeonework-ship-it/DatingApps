// Control-level tests for the signed-out contact form
// (support_contact_form_screen.dart): every field, the topic chips, Back to
// sign in, and the screen-quality cases. Each test performs the real gesture
// against the recording fake BFF and asserts the payload sent, what the
// person sees, or that nothing was sent.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/support/screens/support_contact_form_screen.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';
import 'support_qa_world.dart';

final email = find.byKey(const Key('support_guest_email'));
final name = find.byKey(const Key('support_guest_name'));
final subject = find.byKey(const Key('support_guest_subject'));
final description = find.byKey(const Key('support_guest_description'));
final submit = find.byKey(const Key('support_guest_submit'));
final error = find.byKey(const Key('support_guest_error'));

Future<List<Object?>> pumpForm(WidgetTester t, SupportWorld w) => pumpQa(
  t,
  w.api,
  const SupportContactFormScreen(),
  size: const Size(900, 2400),
  launcher: true,
);

/// Fills every field validly; each argument overrides one field.
Future<void> fill(
  WidgetTester t, {
  String emailText = 'sam@x.io',
  String nameText = 'Sam',
  String category = 'account_login',
  String subjectText = 'Cannot finish sign up',
  String descriptionText = 'The code screen never loads.',
}) async {
  await t.enterText(email, emailText);
  await t.enterText(name, nameText);
  await tapIn(t, find.byKey(Key('support_guest_category_$category')));
  await t.enterText(subject, subjectText);
  await t.enterText(description, descriptionText);
}

Future<void> send(WidgetTester t) => tapIn(t, submit);

List<QaCall> contacts(SupportWorld w) => w.api.sent('POST', '/support/contact');

void main() {
  group('fields', () {
    testWidgets(
      'Your email is sent trimmed and the confirmation names it '
      '[case:support.support_contact_form.support_guest_email_input.action]',
      (t) async {
        final w = SupportWorld();
        await pumpForm(t, w);
        await fill(t, emailText: '  sam@example.org ');
        await send(t);
        expect(contacts(w).single.body['email'], 'sam@example.org');
        expect(
          find.text(
            en.supportGuestSentBody('CN-2026-000400', 'sam@example.org'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Your name (optional) is sent trimmed '
        '[case:support.support_contact_form.support_guest_name_input.action]', (
      t,
    ) async {
      final w = SupportWorld();
      await pumpForm(t, w);
      await fill(t, nameText: '  Sam Rivera ');
      await send(t);
      expect(contacts(w).single.body['name'], 'Sam Rivera');
    });

    testWidgets(
      'Your name: left empty or spaces it is sent empty, 100 characters is '
      'the limit, and emoji and right-to-left names are kept '
      '[case:support.support_contact_form.support_guest_name_input.validation]',
      (t) async {
        final w = SupportWorld();
        await pumpForm(t, w);
        await fill(t, nameText: '   ');
        await send(t);
        expect(contacts(w).single.body['name'], '');

        await t.pageBack();
        await qaSettle(t);
        await tapIn(t, find.byKey(const ValueKey('qa.test.launcher')));
        await t.enterText(name, 'n' * 120);
        expect(fieldText(t, name), hasLength(100));
        await fill(t, nameText: 'سارة 🌙');
        await send(t);
        expect(contacts(w).last.body['name'], 'سارة 🌙');
      },
    );

    testWidgets('A topic chip selects that topic, which is sent '
        '[case:support.support_contact_form.support_guest_category_x.action]', (
      t,
    ) async {
      final w = SupportWorld();
      await pumpForm(t, w);
      final chip = find.byKey(const Key('support_guest_category_verification'));
      expect(t.widget<ChoiceChip>(chip).selected, isFalse);
      await fill(t, category: 'verification');
      expect(t.widget<ChoiceChip>(chip).selected, isTrue);
      expect(
        t
            .widget<ChoiceChip>(
              find.byKey(const Key('support_guest_category_account_login')),
            )
            .selected,
        isFalse,
      );
      await send(t);
      expect(contacts(w).single.body['category'], 'verification');
    });

    testWidgets(
      'Subject is sent trimmed '
      '[case:support.support_contact_form.support_guest_subject_input.action]',
      (t) async {
        final w = SupportWorld();
        await pumpForm(t, w);
        await fill(t, subjectText: '  Code never arrives  ');
        await send(t);
        expect(contacts(w).single.body['subject'], 'Code never arrives');
      },
    );

    testWidgets(
      'Subject: under 4 characters or spaces is refused before sending, 120 '
      'characters is the limit '
      '[case:support.support_contact_form.support_guest_subject_input.validation]',
      (t) async {
        final w = SupportWorld();
        await pumpForm(t, w);
        await fill(t, subjectText: 'Hi');
        await send(t);
        expect(find.text(en.supportErrorSubjectLength(4, 120)), findsOneWidget);
        await t.enterText(subject, '      ');
        await send(t);
        expect(find.text(en.supportErrorSubjectLength(4, 120)), findsOneWidget);
        expect(contacts(w), isEmpty);

        await t.enterText(subject, 's' * 130);
        expect(fieldText(t, subject), hasLength(120));
        await send(t);
        expect(contacts(w).single.body['subject'], 's' * 120);
      },
    );

    testWidgets(
      'What happened? is sent trimmed with line breaks kept '
      '[case:support.support_contact_form.support_guest_description_input.action]',
      (t) async {
        final w = SupportWorld();
        await pumpForm(t, w);
        await fill(t, descriptionText: '  Step 1: open.\nStep 2: nothing.  ');
        await send(t);
        expect(
          contacts(w).single.body['description'],
          'Step 1: open.\nStep 2: nothing.',
        );
      },
    );

    testWidgets(
      'What happened?: empty or spaces is refused before sending, 5000 '
      'characters is the limit, emoji are kept '
      '[case:support.support_contact_form.support_guest_description_input.validation]',
      (t) async {
        final w = SupportWorld();
        await pumpForm(t, w);
        await fill(t, descriptionText: '');
        await send(t);
        expect(find.text(en.supportErrorDescriptionRequired), findsOneWidget);
        await t.enterText(description, '   \n  ');
        await send(t);
        expect(find.text(en.supportErrorDescriptionRequired), findsOneWidget);
        expect(contacts(w), isEmpty);

        await t.enterText(description, 'd' * 5200);
        expect(fieldText(t, description), hasLength(5000));
        await t.enterText(description, 'The app froze 😩 twice');
        await send(t);
        expect(error, findsNothing);
        expect(
          contacts(w).single.body['description'],
          'The app froze 😩 twice',
        );
      },
    );
  });

  testWidgets('Back to sign in, after sending, closes the form '
      '[case:support.support_contact_form.support_guest_back.action]', (
    t,
  ) async {
    final w = SupportWorld();
    final popped = await pumpForm(t, w);
    await fill(t);
    await send(t);
    expect(find.byKey(const Key('support_guest_done')), findsOneWidget);
    await tapIn(t, find.byKey(const Key('support_guest_back')));
    expect(find.byType(SupportContactFormScreen), findsNothing);
    expect(popped, hasLength(1));
    expect(contacts(w), hasLength(1));
  });

  group('screen quality', () {
    testWidgets('lays out on phone and tablet, both themes '
        '[case:support.support_contact_form.layout_matrix]', (t) async {
      await qaExpectLaysOutEverywhere(
        t,
        SupportWorld().api,
        SupportContactFormScreen.new,
        loaded: submit,
      );
    });

    testWidgets('meets tap-target, label and contrast guidelines '
        '[case:support.support_contact_form.a11y_guidelines]', (t) async {
      await qaExpectMeetsA11yGuidelines(
        t,
        SupportWorld().api,
        SupportContactFormScreen.new,
        size: const Size(430, 1600),
        loaded: submit,
      );
    });

    testWidgets('pushed from sign-in, Back returns there '
        '[case:support.support_contact_form.back_affordance]', (t) async {
      await qaExpectBackReturns(
        t,
        SupportWorld().api,
        SupportContactFormScreen.new,
        screen: SupportContactFormScreen,
      );
    });

    testWidgets('renders in every shipped locale with nothing left in English '
        '[case:support.support_contact_form.l10n]', (t) async {
      await qaExpectRendersInAllLocales(
        t,
        SupportWorld().api,
        SupportContactFormScreen.new,
        size: const Size(430, 1800),
        expected: [
          (l) => l.supportFormTitle,
          (l) => l.supportGuestSubtitle,
          (l) => l.supportGuestEmailLabel,
          (l) => l.supportGuestNameLabel,
          (l) => l.supportFormCategoryLabel,
          (l) => l.supportCategoryAccountLogin,
          (l) => l.supportCategoryOther,
          (l) => l.supportFormSubjectLabel,
          (l) => l.supportFormDescriptionLabel,
          (l) => l.supportSubmit,
        ],
        // Dutch uses the loanwords too: "Matches & chat" is the Dutch label.
        allow: {'Matches & chat'},
      );
    });
  });
}
