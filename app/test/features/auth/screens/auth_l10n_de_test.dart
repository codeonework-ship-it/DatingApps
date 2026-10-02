import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/auth/auth_messages.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/auth/providers/terms_provider.dart';
import 'package:verified_dating_app/features/auth/screens/account_recovery_screen.dart';
import 'package:verified_dating_app/features/auth/screens/signup_screen.dart';
import 'package:verified_dating_app/features/auth/screens/user_agreement_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _SignedOutAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState();
}

class _ExpiredAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(error: kSessionExpiredMessage);
}

class _TermsStub extends TermsAcceptance {
  @override
  Future<bool> build() async => false;
}

Widget _app(Widget child, {Locale locale = const Locale('de')}) =>
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_SignedOutAuth.new),
        termsAcceptanceProvider.overrideWith(_TermsStub.new),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  testWidgets('sign-up form speaks German', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(const SignupScreen()));
    await tester.pump();

    expect(find.text('Erstelle dein Konto'), findsOneWidget);
    expect(find.text('Eindeutiger Benutzername'), findsOneWidget);
    expect(find.text('Geburtsdatum'), findsOneWidget);
    expect(find.text('Datum auswählen'), findsOneWidget);
    expect(find.text('Ich identifiziere mich als'), findsOneWidget);
    expect(find.text('Frau'), findsOneWidget);
    expect(find.text('Konto erstellen'), findsOneWidget);
    expect(find.text('Du hast schon ein Konto?'), findsOneWidget);
    expect(find.text('Create your account'), findsNothing);
    // Automation ids are never translated.
    expect(find.byKey(const ValueKey('qa.signup.username_field')), findsOne);
  });

  testWidgets('sign-up validation messages are German', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(const SignupScreen()));
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('qa.signup.username_field')),
      'a',
    );
    await tester.tap(
      find.byKey(const ValueKey('qa.signup.create_account_button')),
    );
    await tester.pump();

    expect(
      find.text(
        'Der Benutzername muss 3–30 Zeichen lang sein und darf nur '
        'Buchstaben, Ziffern, _ oder . enthalten.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('terms screen speaks German', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(const UserAgreementScreen()));
    await tester.pump();

    expect(find.text('Nutzungsbedingungen'), findsOneWidget);
    expect(find.text('Sei respektvoll und authentisch.'), findsOneWidget);
    expect(
      find.text(
        'Ich stimme den Nutzungsbedingungen und der Datenschutzerklärung zu',
      ),
      findsOneWidget,
    );
    expect(find.text('Akzeptieren und fortfahren'), findsOneWidget);
  });

  testWidgets('account recovery speaks German', (tester) async {
    await tester.pumpWidget(_app(const AccountRecoveryScreen()));
    await tester.pump();

    expect(find.text('Du kannst dich nicht anmelden?'), findsOneWidget);
    expect(find.text('Ich habe meinen Code'), findsOneWidget);
    expect(find.text('Wiederherstellungscode'), findsOneWidget);
    expect(find.text('Passwort zurücksetzen'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('qa.recovery.submit')));
    await tester.pump();
    expect(find.text('Gib deinen Benutzernamen ein.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('qa.recovery.username')),
      'asha',
    );
    await tester.tap(find.byKey(const ValueKey('qa.recovery.submit')));
    await tester.pump();
    expect(find.text('Gib deinen Wiederherstellungscode ein.'), findsOneWidget);
  });

  test('provider messages map to each language; server text passes', () {
    final de = lookupAppLocalizations(const Locale('de'));
    final en = lookupAppLocalizations(const Locale('en'));
    expect(
      localizedAuthMessage(de, kSessionExpiredMessage),
      'Du wurdest abgemeldet. Bitte melde dich erneut an.',
    );
    expect(
      localizedAuthMessage(en, kAuthInvalidCredentialsMessage),
      kAuthInvalidCredentialsMessage,
    );
    expect(localizedAuthMessage(de, 'Server said no'), 'Server said no');
  });

  testWidgets('the English session notice is unchanged', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authNotifierProvider.overrideWith(_ExpiredAuth.new)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) => Text(
              localizedAuthMessage(
                AppLocalizations.of(context),
                ref.watch(authNotifierProvider).error!,
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      find.text('You were signed out. Please sign in again.'),
      findsOneWidget,
    );
  });
}
