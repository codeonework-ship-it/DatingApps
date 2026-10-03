// Case ids stay whole in test names (the QA Lab reads them literally).
// ignore_for_file: lines_longer_than_80_chars

import 'dart:ui' show SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/auth/providers/terms_provider.dart';
import 'package:verified_dating_app/features/auth/screens/account_recovery_screen.dart';
import 'package:verified_dating_app/features/auth/screens/auth_screen.dart';
import 'package:verified_dating_app/features/auth/screens/signup_screen.dart';
import 'package:verified_dating_app/features/auth/screens/user_agreement_screen.dart';
import 'package:verified_dating_app/features/auth/screens/welcome_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_about_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';
import '../profile/support/profile_bff.dart';

// Audit 2026-10-02 (P0): automation ids such as 'qa.signin.login_button'
// were the controls' semantics labels, so TalkBack and VoiceOver read
// "qa dot signin dot login button". The ids are now semantics identifiers
// (Android resource-id, iOS accessibilityIdentifier) and every control keeps
// its translated spoken label.

class _TermsStub extends TermsAcceptance {
  @override
  Future<bool> build() async => false;
}

Override get _signedOut => authNotifierProvider.overrideWith(AuthNotifier.new);

/// Every semantics label in the tree (merged nodes included).
List<SemanticsNode> _nodes(WidgetTester tester) {
  final out = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    out.add(node);
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
  return out;
}

void _expectIdsNotSpoken(
  WidgetTester tester,
  Map<String, String Function(SemanticsNode)> expectations,
) {
  final nodes = _nodes(tester);
  final spokenIds = nodes
      .map((n) => n.label)
      .where((label) => label.contains('qa.'))
      .toList();
  expect(spokenIds, isEmpty, reason: 'qa ids must never be spoken');
  for (final entry in expectations.entries) {
    final matches = nodes.where((n) => n.identifier == entry.key).toList();
    expect(matches, hasLength(1), reason: entry.key);
    final spoken = entry.value(matches.single);
    expect(spoken.trim(), isNotEmpty, reason: '${entry.key} has a label');
  }
}

/// The node's own label, or the first labelled descendant (a button node
/// sits inside the id's container).
String _spoken(SemanticsNode node) {
  if (node.label.trim().isNotEmpty) {
    return node.label;
  }
  var found = '';
  node.visitChildren((child) {
    found = _spoken(child);
    return found.isEmpty;
  });
  return found;
}

void main() {
  final de = lookupAppLocalizations(const Locale('de'));

  testWidgets('welcome, sign-in and sign-up speak German, ids stay ids '
      '[case:l10n.a11y.auth_qa_ids_not_spoken]', (tester) async {
    final handle = tester.ensureSemantics();

    await pumpQa(
      tester,
      QaApi(),
      const WelcomeScreen(),
      locale: const Locale('de'),
      extra: [_signedOut],
    );
    _expectIdsNotSpoken(tester, {
      'qa.welcome.signup_button': _spoken,
      'qa.welcome.signin_button': _spoken,
      'qa.language.picker_button': _spoken,
    });
    expect(
      _spoken(
        tester.getSemantics(
          find.bySemanticsIdentifier('qa.welcome.signup_button'),
        ),
      ),
      contains(de.welcomeCreateAccount),
    );

    await pumpQa(
      tester,
      QaApi(),
      const AuthScreen(),
      locale: const Locale('de'),
      extra: [_signedOut],
    );
    _expectIdsNotSpoken(tester, {
      'qa.signin.username_field': _spoken,
      'qa.signin.password_field': _spoken,
      'qa.signin.login_button': _spoken,
    });
    expect(
      tester
          .getSemantics(find.bySemanticsIdentifier('qa.signin.username_field'))
          .label,
      contains(de.authUsernameHint),
    );
    expect(
      _spoken(
        tester.getSemantics(
          find.bySemanticsIdentifier('qa.signin.login_button'),
        ),
      ),
      contains(de.authSignIn),
    );

    await pumpQa(
      tester,
      QaApi(),
      const SignupScreen(),
      locale: const Locale('de'),
      size: const Size(430, 1800),
      extra: [_signedOut],
    );
    _expectIdsNotSpoken(tester, {
      'qa.signup.username_field': _spoken,
      'qa.signup.password_field': _spoken,
      'qa.signup.confirm_password_field': _spoken,
      'qa.signup.name_field': _spoken,
      'qa.signup.dob_field': _spoken,
      'qa.signup.create_account_button': _spoken,
    });
    expect(
      _spoken(
        tester.getSemantics(find.bySemanticsIdentifier('qa.signup.dob_field')),
      ),
      contains(de.signupDobPlaceholder),
    );
    // The id lands on the control itself, so taps by id hit it.
    expect(
      tester.getRect(
        find.bySemanticsIdentifier('qa.signup.create_account_button'),
      ),
      tester.getRect(
        find.byKey(const ValueKey('qa.signup.create_account_button')),
      ),
    );
    handle.dispose();
  });

  testWidgets('terms, recovery and setup speak German, ids stay ids '
      '[case:l10n.a11y.setup_qa_ids_not_spoken]', (tester) async {
    final handle = tester.ensureSemantics();

    await pumpQa(
      tester,
      QaApi(),
      const UserAgreementScreen(),
      locale: const Locale('de'),
      size: const Size(430, 1600),
      extra: [termsAcceptanceProvider.overrideWith(_TermsStub.new)],
    );
    _expectIdsNotSpoken(tester, {
      'qa.terms.accept_checkbox': _spoken,
      'qa.terms.continue_button': _spoken,
    });
    final checkbox = tester.getSemantics(
      find.bySemanticsIdentifier('qa.terms.accept_checkbox'),
    );
    expect(checkbox.label, contains(de.authTermsAgreeCheckbox));
    // The checkbox state is part of the same node.
    // ignore: deprecated_member_use
    expect(
      checkbox.getSemanticsData().hasFlag(SemanticsFlag.hasCheckedState),
      isTrue,
    );

    await tester.pumpWidget(const SizedBox());
    await pumpQa(
      tester,
      QaApi(),
      const AccountRecoveryScreen(),
      locale: const Locale('de'),
      extra: [_signedOut],
    );
    _expectIdsNotSpoken(tester, {});

    await tester.pumpWidget(const SizedBox());
    final api = QaApi();
    ProfileBff(api);
    await pumpQa(
      tester,
      api,
      const SetupAboutScreen(),
      locale: const Locale('de'),
      size: const Size(430, 2400),
      extra: qaMasterDataOverrides(),
    );
    _expectIdsNotSpoken(tester, {
      'qa.setup.about.bio_field': _spoken,
      'qa.setup.about.height_dropdown': _spoken,
      'qa.setup.about.education_dropdown': _spoken,
      'qa.setup.about.profession_field': _spoken,
      'qa.setup.about.drinking_dropdown': _spoken,
      'qa.setup.about.smoking_dropdown': _spoken,
    });
    expect(
      tester
          .getSemantics(
            find.bySemanticsIdentifier('qa.setup.about.height_dropdown'),
          )
          .label,
      contains(de.profileSetupHeightLabel),
    );
    handle.dispose();
  });
}
