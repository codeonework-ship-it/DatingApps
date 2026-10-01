import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/auth/providers/terms_provider.dart';
import 'package:verified_dating_app/features/auth/screens/auth_screen.dart';
import 'package:verified_dating_app/features/auth/screens/signup_screen.dart';
import 'package:verified_dating_app/features/auth/screens/user_agreement_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _SignedOutAuthNotifier extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(isAuthenticated: false, isLoading: false);
}

class _TermsStubNotifier extends TermsAcceptance {
  @override
  Future<bool> build() async => false;

  @override
  Future<bool> accept() async {
    state = const AsyncData(true);
    return true;
  }
}

Widget _buildHarness({
  required Widget child,
  required List<Override> overrides,
}) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    theme: AppTheme.darkTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

void main() {
  group('AuthScreen smoke', () {
    testWidgets('renders credential fields without layout exceptions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildHarness(
          child: const AuthScreen(),
          overrides: [
            authNotifierProvider.overrideWith(_SignedOutAuthNotifier.new),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Welcome back'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('qa.signin.username_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('qa.signin.password_field')),
        findsOneWidget,
      );
      expect(find.text('Sign in'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('SignupScreen smoke', () {
    testWidgets('rejects a one-character username before submitting signup', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildHarness(
          child: const SignupScreen(),
          overrides: [
            authNotifierProvider.overrideWith(_SignedOutAuthNotifier.new),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField).first, 'a');
      final submit = find.byKey(
        const ValueKey('qa.signup.create_account_button'),
      );
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      expect(
        find.text(
          'Username must be 3–30 characters using letters, numbers, _ or .',
        ),
        findsOneWidget,
      );
    });
    testWidgets('renders username and password signup without OTP', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildHarness(
          child: const SignupScreen(),
          overrides: [
            authNotifierProvider.overrideWith(_SignedOutAuthNotifier.new),
          ],
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const ValueKey('qa.signup.username_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('qa.signup.password_field')),
        findsOneWidget,
      );
      expect(find.text('Create account'), findsOneWidget);
      expect(find.textContaining('OTP'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('UserAgreementScreen smoke', () {
    testWidgets('renders agreement screen content and CTA', (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          child: const UserAgreementScreen(),
          overrides: [
            termsAcceptanceProvider.overrideWith(_TermsStubNotifier.new),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Terms and Conditions'), findsOneWidget);
      expect(
        find.text('I agree to the Terms & Privacy Policy'),
        findsOneWidget,
      );
      expect(find.text('I Accept and Continue'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
