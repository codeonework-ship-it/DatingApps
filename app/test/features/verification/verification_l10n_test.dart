import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/verification/screens/verification_landing_screen.dart';
import 'package:verified_dating_app/features/verification/screens/verification_status_screen.dart';
import 'package:verified_dating_app/features/verification/screens/verification_upload_id_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

/// Signed out: the verification provider resolves to "not started" without
/// calling the API.
class _SignedOutAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

Widget _app(Widget child, Locale locale) => ProviderScope(
  overrides: [authNotifierProvider.overrideWith(_SignedOutAuth.new)],
  child: MaterialApp(
    theme: AppTheme.darkTheme,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

void main() {
  testWidgets('verification landing speaks German', (tester) async {
    await tester.pumpWidget(
      _app(const VerificationLandingScreen(), const Locale('de')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ausweisprüfung'), findsOneWidget);
    expect(find.text('Sicher verifizieren'), findsOneWidget);
    expect(find.text('Sichere Verifizierung starten'), findsOneWidget);
  });

  testWidgets('ID upload step speaks German', (tester) async {
    await tester.pumpWidget(
      _app(const VerificationUploadIdScreen(), const Locale('de')),
    );
    await tester.pump();

    expect(find.text('Ausweis hochladen'), findsOneWidget);
    expect(find.text('Galerie'), findsOneWidget);
    expect(find.text('Kamera'), findsOneWidget);
    expect(find.text('Weiter'), findsOneWidget);
  });

  testWidgets('status keeps its automation id while the text is German', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const VerificationStatusScreen(), const Locale('de')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verifizierungsstatus'), findsOneWidget);
    expect(find.text('Nicht gestartet'), findsOneWidget);
    // The id is an identifier; what a screen reader says is the German title.
    final status = find.bySemanticsIdentifier(
      'qa.verification.status.Not Started',
    );
    expect(status, findsOneWidget);
    expect(
      tester.getSemantics(status).getSemanticsData().label,
      'Nicht gestartet',
    );
  });

  testWidgets('English status text is unchanged', (tester) async {
    await tester.pumpWidget(
      _app(const VerificationStatusScreen(), const Locale('en')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verification Status'), findsOneWidget);
    expect(find.text('Not Started'), findsOneWidget);
    expect(find.text('Start verification from Settings.'), findsOneWidget);
  });
}
