// Case ids stay whole in test names (the QA Lab reads them literally).
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/auth/auth_messages.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/auth/screens/auth_screen.dart';
import 'package:verified_dating_app/features/auth/screens/signup_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';

// Audit 2026-10-02 (P0): the sign-in and sign-up screens showed the server's
// English error (`data['error']`) as is. Server text stays English by owner
// policy, so the app maps every known reply (matched without regard to case
// or punctuation, error codes first) to its own translated message, and an
// unknown reply reads as the translated generic failure — never raw.

Override get _signedOut => authNotifierProvider.overrideWith(AuthNotifier.new);

final _de = lookupAppLocalizations(const Locale('de'));

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _signIn(WidgetTester tester, QaApi api) async {
  await pumpQa(
    tester,
    api,
    const AuthScreen(),
    locale: const Locale('de'),
    extra: [_signedOut],
  );
  await tester.enterText(_key('qa.signin.username_field'), 'asha');
  await tester.enterText(_key('qa.signin.password_field'), 'wrong-pass1');
  await tester.pump();
  await tester.tap(_key('qa.signin.login_button'));
  await qaSettle(tester);
}

Future<void> _signUp(WidgetTester tester, QaApi api) async {
  await pumpQa(
    tester,
    api,
    const SignupScreen(),
    locale: const Locale('de'),
    size: const Size(430, 1800),
    extra: [_signedOut],
  );
  await tester.enterText(_key('qa.signup.username_field'), 'asha_k');
  await tester.enterText(_key('qa.signup.password_field'), 'Password123');
  await tester.enterText(
    _key('qa.signup.confirm_password_field'),
    'Password123',
  );
  await tester.enterText(_key('qa.signup.name_field'), 'Asha K');
  await tester.pump();
  await tester.tap(_key('qa.signup.dob_field'));
  await tester.pumpAndSettle();
  // The date picker opens 25 years back; confirm it.
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await tester.tap(_key('qa.signup.gender.F'));
  await tester.pump();
  await tester.ensureVisible(_key('qa.signup.create_account_button'));
  await tester.tap(_key('qa.signup.create_account_button'));
  await qaSettle(tester);
}

void main() {
  group('sign-in errors in German', () {
    for (final (name, reply, expected) in <(String, QaReply, String)>[
      (
        'wrong credentials',
        qaError(
          401,
          message: 'invalid username or password',
          code: 'UNAUTHORIZED',
        ),
        _de.authErrorInvalidCredentials,
      ),
      (
        'Supabase wording, other case and punctuation',
        qaError(
          401,
          message: 'Invalid login credentials!',
          code: 'UNAUTHORIZED',
        ),
        _de.authErrorInvalidCredentials,
      ),
      (
        'suspended account',
        qaError(
          401,
          message: 'account is suspended or banned',
          code: 'UNAUTHORIZED',
        ),
        _de.authErrorAccountSuspended,
      ),
      (
        'locked account',
        qaError(
          401,
          message: 'Account temporarily locked; try again later',
          code: 'UNAUTHORIZED',
        ),
        _de.authErrorAccountLocked,
      ),
      (
        'rate limited (the code wins over the text)',
        qaError(429, message: 'slow down', code: 'TOO_MANY_REQUESTS'),
        _de.authErrorTooManyRequests,
      ),
      (
        'unknown server text',
        qaError(
          502,
          message: 'login failed: dial tcp 10.0.0.4:5432: connect: refused',
          code: 'BAD_GATEWAY',
        ),
        _de.authErrorSignInFailed,
      ),
      ('offline', qaOffline, _de.authErrorNetwork),
    ]) {
      testWidgets('$name [case:auth.l10n.signin_server_error]', (tester) async {
        final api = QaApi()..on('POST /auth/login', (_) => reply);
        await _signIn(tester, api);

        expect(api.sent('POST', '/auth/login'), hasLength(1));
        expect(find.text(expected), findsOneWidget);
        if (reply.body is Map) {
          final raw = (reply.body! as Map)['error'] as String;
          expect(find.textContaining(raw), findsNothing, reason: 'never raw');
        }
      });
    }
  });

  group('sign-up errors in German', () {
    for (final (name, reply, expected) in <(String, QaReply, String)>[
      (
        'username taken (409)',
        qaError(409, message: 'username is already taken', code: 'CONFLICT'),
        _de.authErrorUsernameTaken,
      ),
      (
        'username taken in a 200 reply',
        const QaReply(200, {
          'success': false,
          'error': 'Username is already taken.',
        }),
        _de.authErrorUsernameTaken,
      ),
      (
        'server-side age rule',
        qaError(
          400,
          message: 'provide a name and date of birth for an adult aged 18–80',
          code: 'BAD_REQUEST',
        ),
        _de.signupErrorAgeRange,
      ),
      (
        'server-side password rule (validation prefix)',
        qaError(
          400,
          message:
              'validation error: password must be 8-72 UTF-8 bytes and contain letters and numbers',
          code: 'BAD_REQUEST',
        ),
        _de.authErrorPasswordFormat,
      ),
      (
        'unknown server text',
        qaError(
          400,
          message: 'signup exploded: pq: duplicate key',
          code: 'BAD_REQUEST',
        ),
        _de.authErrorCreateAccountFailed,
      ),
    ]) {
      testWidgets('$name [case:auth.l10n.signup_server_error]', (tester) async {
        final api = QaApi()..on('POST /auth/signup', (_) => reply);
        await _signUp(tester, api);

        final sent = api.sent('POST', '/auth/signup');
        expect(sent, hasLength(1));
        expect(sent.single.body['username'], 'asha_k');
        expect(find.text(expected), findsOneWidget);
        final raw = (reply.body! as Map)['error'] as String;
        expect(find.textContaining(raw), findsNothing, reason: 'never raw');
      });
    }
  });

  test(
    'server replies map to message codes [case:auth.l10n.server_error_mapping]',
    () {
      String map(String? text, {String? code, int? status}) =>
          authMessageCodeForServerError(
            message: text,
            errorCode: code,
            statusCode: status,
            fallback: kAuthSignInFailedMessage,
          );
      expect(
        map('INVALID USERNAME OR PASSWORD'),
        kAuthInvalidCredentialsMessage,
      );
      expect(map('username is already taken'), kAuthUsernameTakenMessage);
      expect(map('User already registered'), kAuthUsernameTakenMessage);
      expect(
        map('friend introductions are unavailable'),
        kAuthAccountTypeUnavailableMessage,
      );
      expect(map('Email rate limit exceeded'), kAuthTooManyRequestsMessage);
      expect(map(null, status: 401), kAuthInvalidCredentialsMessage);
      expect(
        map('???', code: 'TOO_MANY_REQUESTS'),
        kAuthTooManyRequestsMessage,
      );
      expect(map('something new'), kAuthSignInFailedMessage);
      // Every code the provider produces has a translation in every language.
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = lookupAppLocalizations(locale);
        for (final code in kAuthMessageCodes) {
          final shown = localizedAuthMessage(l10n, code);
          expect(
            shown,
            isNot(l10n.commonSomethingWentWrongTryAgain),
            reason: '$locale $code',
          );
        }
      }
    },
  );
}
