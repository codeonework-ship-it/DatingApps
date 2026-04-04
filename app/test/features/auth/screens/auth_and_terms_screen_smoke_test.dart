import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/auth/providers/terms_provider.dart';
import 'package:verified_dating_app/features/auth/screens/auth_screen.dart';
import 'package:verified_dating_app/features/auth/screens/user_agreement_screen.dart';

class _PhoneStepAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    isAuthenticated: false,
    isOtpSent: false,
    isLoading: false,
  );
}

class _OtpStepAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    isAuthenticated: false,
    isOtpSent: true,
    isLoading: false,
    phoneNumber: '+919876543210',
  );
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
  child: MaterialApp(home: child),
);

void main() {
  group('AuthScreen smoke', () {
    testWidgets('renders phone step without layout exceptions', (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          child: const AuthScreen(),
          overrides: [
            authNotifierProvider.overrideWith(_PhoneStepAuthNotifier.new),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Mobile number'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders OTP step without layout exceptions', (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          child: const AuthScreen(),
          overrides: [
            authNotifierProvider.overrideWith(_OtpStepAuthNotifier.new),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Code sent to'), findsOneWidget);
      expect(find.text('Verify & Continue'), findsOneWidget);
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
