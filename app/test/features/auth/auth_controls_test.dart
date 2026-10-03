// Control-level tests for the signed-out entry: Welcome, Sign in and
// "Can't sign in?" (account recovery). Every test drives the real screen
// against the recording fake BFF and asserts what the member would see and
// what reached the server. Each test name carries its catalog case ids.
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verified_dating_app/core/auth/auth_session_store.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/auth/screens/account_recovery_screen.dart';
import 'package:verified_dating_app/features/auth/screens/auth_screen.dart';
import 'package:verified_dating_app/features/auth/screens/signup_screen.dart';
import 'package:verified_dating_app/features/auth/screens/welcome_screen.dart';
import 'package:verified_dating_app/features/common/screens/main_navigation_screen.dart';

import '../../support/qa_api.dart';

final _en = qaL10n(const Locale('en'));

/// Signed out: the real auth notifier with no stored session.
Override get _signedOut => authNotifierProvider.overrideWith(AuthNotifier.new);

/// [reply], held in flight long enough for a second tap to land.
QaReply _slow(QaReply reply) => QaReply(
  reply.status,
  reply.body,
  offline: reply.offline,
  delay: const Duration(milliseconds: 400),
);

Map<String, dynamic> _session(String userId) => {
  'success': true,
  'user_id': userId,
  'access_token': 'access-$userId',
  'refresh_token': 'refresh-$userId',
};

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

Future<String?> _storedRefreshToken() =>
    const FlutterSecureStorage().read(key: 'connect.auth.refresh_token');

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _type(WidgetTester tester, String key, String text) async {
  await tester.enterText(_key(key), text);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pump();
  await tester.tap(_key(key));
  await qaSettle(tester);
}

bool _obscured(WidgetTester tester, String fieldKey) => tester
    .widget<EditableText>(
      find.descendant(of: _key(fieldKey), matching: find.byType(EditableText)),
    )
    .obscureText;

bool _focused(WidgetTester tester, String fieldKey) =>
    tester.widget<TextField>(_key(fieldKey)).focusNode!.hasFocus;

/// Signing in lands on the app shell, which keeps polling; unmount it so no
/// timer outlives the test.
Future<void> _leaveApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await qaSettle(tester, frames: 30);
}

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: '');
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    AuthSessionStore.instance.clear();
  });
  tearDown(AuthSessionStore.instance.clear);

  group('Welcome', () {
    testWidgets('Create account opens dating sign-up '
        '[case:auth.welcome.welcome_signup_button.action]', (tester) async {
      await pumpQa(tester, QaApi(), const WelcomeScreen(), extra: [_signedOut]);
      await _tap(tester, 'qa.welcome.signup_button');

      final signup = tester.widget<SignupScreen>(find.byType(SignupScreen));
      expect(signup.introducer, isFalse);
      expect(find.text(_en.signupTitle), findsOneWidget);
      expect(find.byKey(const ValueKey('qa.signup.gender.F')), findsOne);
    });

    testWidgets('Just here to introduce friends opens the friend-only sign-up '
        '[case:auth.welcome.just_here_to_introduce_friends.action]', (
      tester,
    ) async {
      await pumpQa(tester, QaApi(), const WelcomeScreen(), extra: [_signedOut]);
      await _tap(tester, 'qa.welcome.introducer_button');

      final signup = tester.widget<SignupScreen>(find.byType(SignupScreen));
      expect(signup.introducer, isTrue);
      expect(find.text(_en.signupIntroducerTitle), findsOneWidget);
      expect(find.text(_en.signupCreateFriendAccount), findsOneWidget);
      // A friend-only account has no gender question.
      expect(find.byKey(const ValueKey('qa.signup.gender.F')), findsNothing);
    });

    testWidgets('Already a member? Sign in opens sign-in '
        '[case:auth.welcome.welcome_signin_button.action]', (tester) async {
      await pumpQa(tester, QaApi(), const WelcomeScreen(), extra: [_signedOut]);
      await _tap(tester, 'qa.welcome.signin_button');

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text(_en.authHeadline), findsOneWidget);
      expect(_key('qa.signin.username_field'), findsOneWidget);
    });

    testWidgets('Welcome renders in every language [case:auth.welcome.l10n]', (
      tester,
    ) async {
      for (final locale in qaLocales) {
        final l10n = qaL10n(locale);
        await tester.pumpWidget(const SizedBox()); // fresh tree
        await pumpQa(
          tester,
          QaApi(),
          const WelcomeScreen(),
          locale: locale,
          extra: [_signedOut],
        );
        expect(find.text(l10n.welcomeCreateAccount), findsOneWidget);
        expect(find.text(l10n.authWelcomeIntroducerLink), findsOneWidget);
        expect(find.text(l10n.welcomeBody), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$locale');
      }
    });
  });

  group('Sign in', () {
    testWidgets(
      'Sign in with valid credentials opens the app and keeps the session '
      '[case:auth.auth.signin_login_button.action]',
      (tester) async {
        final api = QaApi()
          ..on('POST /auth/login', (_) => qaOk(_session('asha-1')));
        final results = await pumpQa(
          tester,
          api,
          const AuthScreen(),
          launcher: true,
          extra: [_signedOut],
        );
        final button = _key('qa.signin.login_button');
        expect(tester.widget<GlassButton>(button).onPressed, isNull);

        await _type(tester, 'qa.signin.username_field', '  Asha.K ');
        expect(tester.widget<GlassButton>(button).onPressed, isNull);
        await _type(tester, 'qa.signin.password_field', 'Passw0rd!');
        expect(tester.widget<GlassButton>(button).onPressed, isNotNull);

        await _tap(tester, 'qa.signin.login_button');

        expect(api.writeLines, ['POST /auth/login']);
        expect(api.sent('POST', '/auth/login').single.body, {
          'username': 'asha.k',
          'password': 'Passw0rd!',
        });
        expect(results, [null], reason: 'sign-in closed');
        expect(find.byType(AuthScreen), findsNothing);
        expect(find.byType(MainNavigationScreen), findsOneWidget);
        final auth = _container(tester).read(authNotifierProvider);
        expect(auth.isAuthenticated, isTrue);
        expect(auth.userId, 'asha-1');
        expect(auth.username, 'asha.k');
        expect(AuthSessionStore.instance.accessToken, 'access-asha-1');
        expect(await _storedRefreshToken(), 'refresh-asha-1');
        await _leaveApp(tester);
      },
    );

    testWidgets('Done on the password keyboard signs in '
        '[case:auth.auth.signin_password_field_submit.action]', (tester) async {
      final api = QaApi()
        ..on('POST /auth/login', (_) => qaOk(_session('asha-1')));
      await pumpQa(
        tester,
        api,
        const AuthScreen(),
        launcher: true,
        extra: [_signedOut],
      );
      await _type(tester, 'qa.signin.username_field', 'asha');
      await _type(tester, 'qa.signin.password_field', 'Passw0rd!');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await qaSettle(tester);

      expect(api.sent('POST', '/auth/login').single.body, {
        'username': 'asha',
        'password': 'Passw0rd!',
      });
      expect(find.byType(AuthScreen), findsNothing);
      expect(find.byType(MainNavigationScreen), findsOneWidget);
      await _leaveApp(tester);
    });

    testWidgets('Next on the username keyboard moves to the password '
        '[case:auth.auth.signin_username_field_submitted.action]', (
      tester,
    ) async {
      final api = QaApi();
      await pumpQa(tester, api, const AuthScreen(), extra: [_signedOut]);
      await _type(tester, 'qa.signin.username_field', 'asha');
      expect(_focused(tester, 'qa.signin.username_field'), isTrue);

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(_focused(tester, 'qa.signin.password_field'), isTrue);
      expect(_focused(tester, 'qa.signin.username_field'), isFalse);
      expect(api.calls, isEmpty);
    });

    testWidgets('Sign-in username is checked before anything is sent '
        '[case:auth.auth.signin_username_field_submitted.validation]', (
      tester,
    ) async {
      final api = QaApi()
        ..on('POST /auth/login', (_) => qaOk(_session('asha-1')));
      await pumpQa(tester, api, const AuthScreen(), extra: [_signedOut]);

      // Characters a username cannot hold (here non-ASCII and punctuation)
      // are refused with the localized rule.
      await _type(tester, 'qa.signin.password_field', 'Passw0rd!');
      for (final bad in ['zoë', 'a', 'bad name!']) {
        await _type(tester, 'qa.signin.username_field', bad);
        await _tap(tester, 'qa.signin.login_button');
        expect(
          find.text(_en.authErrorUsernameFormat),
          findsOneWidget,
          reason: bad,
        );
      }

      // Blank username: the button stays off and the keyboard submit asks
      // for a username.
      await _type(tester, 'qa.signin.username_field', '   ');
      expect(
        tester.widget<GlassButton>(_key('qa.signin.login_button')).onPressed,
        isNull,
      );
      await tester.enterText(_key('qa.signin.password_field'), 'Passw0rd!');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await qaSettle(tester);
      expect(qaSnackText(tester), _en.authEnterUsername);
      expect(_focused(tester, 'qa.signin.username_field'), isTrue);
      expect(api.calls, isEmpty);
    });

    testWidgets('Sign-in password is required and sent byte-for-byte '
        '[case:auth.auth.signin_password_field_submit.validation]', (
      tester,
    ) async {
      final api = QaApi()
        ..on('POST /auth/login', (_) => qaOk(_session('asha-1')));
      await pumpQa(
        tester,
        api,
        const AuthScreen(),
        launcher: true,
        extra: [_signedOut],
      );
      await _type(tester, 'qa.signin.username_field', 'asha');
      await _type(tester, 'qa.signin.password_field', '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await qaSettle(tester);
      expect(qaSnackText(tester), _en.authEnterPassword);
      expect(api.calls, isEmpty);

      // Spaces and any script are part of the password: never trimmed.
      const password = ' Pässwörd ✓ 12 ';
      await _type(tester, 'qa.signin.password_field', password);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await qaSettle(tester);
      expect(api.sent('POST', '/auth/login').single.body['password'], password);
      await _leaveApp(tester);
    });

    testWidgets('Show password reveals and hides the password '
        '[case:auth.auth.hide_password_ontogglepassword.action]', (
      tester,
    ) async {
      await pumpQa(tester, QaApi(), const AuthScreen(), extra: [_signedOut]);
      await _type(tester, 'qa.signin.password_field', 'Passw0rd!');
      const toggle = ValueKey('qa.signin.password_visibility');
      expect(_obscured(tester, 'qa.signin.password_field'), isTrue);
      expect(
        tester.widget<IconButton>(find.byKey(toggle)).tooltip,
        _en.authShowPassword,
      );

      await tester.tap(find.byKey(toggle));
      await tester.pump();
      expect(_obscured(tester, 'qa.signin.password_field'), isFalse);
      expect(
        tester.widget<IconButton>(find.byKey(toggle)).tooltip,
        _en.authHidePassword,
      );

      await tester.tap(find.byKey(toggle));
      await tester.pump();
      expect(_obscured(tester, 'qa.signin.password_field'), isTrue);
    });

    testWidgets("Can't sign in? opens recovery with the typed username "
        '[case:auth.auth.signin_cant_sign_in.action]', (tester) async {
      final api = QaApi();
      await pumpQa(tester, api, const AuthScreen(), extra: [_signedOut]);
      await _type(tester, 'qa.signin.username_field', 'Asha');
      await _tap(tester, 'qa.signin.cant_sign_in');

      expect(find.byType(AccountRecoveryScreen), findsOneWidget);
      expect(find.text(_en.authCantSignIn), findsOneWidget);
      expect(
        tester.widget<TextField>(_key('qa.recovery.username')).controller!.text,
        'Asha',
      );
      expect(api.calls, isEmpty);
    });

    testWidgets('Back returns to the welcome screen '
        '[case:auth.auth.back_to_welcome.action]', (tester) async {
      // Pushed from Welcome: back closes sign-in.
      final results = await pumpQa(
        tester,
        QaApi(),
        const AuthScreen(),
        launcher: true,
        extra: [_signedOut],
      );
      await _tap(tester, 'qa.signin.back');
      expect(results, [null]);
      expect(find.byType(AuthScreen), findsNothing);
      expect(find.byKey(const ValueKey('qa.test.launcher')), findsOneWidget);

      // Opened as the first page (deep link): back shows Welcome.
      await tester.pumpWidget(const SizedBox()); // fresh tree
      await pumpQa(tester, QaApi(), const AuthScreen(), extra: [_signedOut]);
      await _tap(tester, 'qa.signin.back');
      expect(find.byType(AuthScreen), findsNothing);
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('A refused sign-in shows the reason, re-enables and sends once '
        '[case:auth.auth.signin_login_button.api_failure]', (tester) async {
      final api = QaApi()
        ..on(
          'POST /auth/login',
          (_) => _slow(
            qaError(
              401,
              message: 'invalid username or password',
              code: 'UNAUTHORIZED',
            ),
          ),
        );
      final results = await pumpQa(
        tester,
        api,
        const AuthScreen(),
        launcher: true,
        extra: [_signedOut],
      );
      await _type(tester, 'qa.signin.username_field', 'asha');
      await _type(tester, 'qa.signin.password_field', 'wrong-pass1');
      final button = _key('qa.signin.login_button');
      await tester.tap(button);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.widget<GlassButton>(button).isLoading, isTrue);
      expect(
        tester.widget<TextField>(_key('qa.signin.password_field')).enabled,
        isFalse,
      );
      await tester.tap(button, warnIfMissed: false); // impatient second tap
      await qaSettle(tester);

      expect(api.sent('POST', '/auth/login'), hasLength(1));
      // The server's English reason maps to the member's message, never
      // shown raw.
      expect(find.text('Invalid username or password.'), findsOneWidget);
      expect(find.text('invalid username or password'), findsNothing);
      expect(tester.widget<GlassButton>(button).onPressed, isNotNull);
      expect(tester.widget<GlassButton>(button).isLoading, isFalse);
      expect(
        tester.widget<TextField>(_key('qa.signin.password_field')).enabled,
        isTrue,
      );
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(results, isEmpty);
      expect(
        _container(tester).read(authNotifierProvider).isAuthenticated,
        isFalse,
      );
      expect(AuthSessionStore.instance.accessToken, isNull);
      expect(await _storedRefreshToken(), isNull);
    });

    testWidgets(
      'Sign-in during an outage or offline says so; the retry then works '
      '[case:auth.auth.signin_login_button.api_failure]',
      (tester) async {
        final api = QaApi()..fail('POST /auth/login', status: 503);
        await pumpQa(
          tester,
          api,
          const AuthScreen(),
          launcher: true,
          extra: [_signedOut],
        );
        await _type(tester, 'qa.signin.username_field', 'asha');
        await _type(tester, 'qa.signin.password_field', 'Passw0rd!');
        await _tap(tester, 'qa.signin.login_button');
        // The server's own outage text is not shown raw.
        expect(find.text(_en.authErrorSignInFailed), findsOneWidget);
        expect(find.text('Something broke on our side.'), findsNothing);

        api.offline('POST /auth/login');
        await _tap(tester, 'qa.signin.login_button');
        expect(find.text(_en.authErrorNetwork), findsOneWidget);
        expect(find.text(_en.authErrorSignInFailed), findsNothing);
        expect(api.sent('POST', '/auth/login'), hasLength(2));

        api.on('POST /auth/login', (_) => qaOk(_session('asha-1')));
        await _tap(tester, 'qa.signin.login_button');
        expect(api.sent('POST', '/auth/login'), hasLength(3));
        expect(find.byType(MainNavigationScreen), findsOneWidget);
        await _leaveApp(tester);
      },
    );

    testWidgets('Sign in renders in every language [case:auth.auth.l10n]', (
      tester,
    ) async {
      for (final locale in qaLocales) {
        final l10n = qaL10n(locale);
        await tester.pumpWidget(const SizedBox()); // fresh tree
        await pumpQa(
          tester,
          QaApi(),
          const AuthScreen(),
          locale: locale,
          extra: [_signedOut],
        );
        expect(find.text(l10n.authWelcomeBack), findsOneWidget);
        expect(find.text(l10n.authCantSignIn), findsOneWidget);
        expect(
          tester.widget<GlassButton>(_key('qa.signin.login_button')).label,
          l10n.authSignIn,
        );
        expect(tester.takeException(), isNull, reason: '$locale');
      }
    });
  });

  group("Can't sign in? (account recovery)", () {
    QaApi recoveryApi() => QaApi()
      ..on('POST /auth/password/recover', (_) => qaOk({'success': true}))
      ..on(
        'POST /auth/recovery/assistance',
        (_) => const QaReply(202, {
          'accepted': true,
          'message':
              'If this username belongs to a Connect account, our safety '
              'team will review the request.',
        }),
      );

    Future<List<Object?>> open(
      WidgetTester tester,
      QaApi api, {
      String username = 'Member_One',
    }) => pumpQa(
      tester,
      api,
      AccountRecoveryScreen(initialUsername: username),
      launcher: true,
      extra: [_signedOut],
    );

    testWidgets('A recovery code resets the password '
        '[case:auth.account_recovery.recovery_submit.action] '
        '[case:auth.account_recovery.recovery_username_input.action] '
        '[case:auth.account_recovery.recovery_code_input.action] '
        '[case:auth.account_recovery.recovery_new_password_input.action]', (
      tester,
    ) async {
      final api = recoveryApi();
      await open(tester, api);
      expect(
        tester.widget<TextField>(_key('qa.recovery.username')).controller!.text,
        'Member_One',
      );
      await _type(tester, 'qa.recovery.code', ' code-123 ');
      await _type(tester, 'qa.recovery.new_password', 'NewPassw0rd');
      await _tap(tester, 'qa.recovery.submit');

      expect(api.writeLines, ['POST /auth/password/recover']);
      expect(api.writes.single.body, {
        'username': 'member_one',
        'recovery_code': 'code-123',
        'new_password': 'NewPassw0rd',
      });
      expect(find.text(_en.authRecoveryResetDone), findsOneWidget);
      expect(_key('qa.recovery.submit'), findsNothing);
    });

    testWidgets('Back to sign in closes recovery '
        '[case:auth.account_recovery.back_to_sign_in.action]', (tester) async {
      final api = recoveryApi();
      final results = await open(tester, api);
      await _type(tester, 'qa.recovery.code', 'code-123');
      await _type(tester, 'qa.recovery.new_password', 'NewPassw0rd');
      await _tap(tester, 'qa.recovery.submit');
      expect(
        tester.widget<FilledButton>(_key('qa.recovery.back_to_sign_in')).child,
        isA<Text>().having(
          (t) => t.data,
          'label',
          _en.authRecoveryBackToSignIn,
        ),
      );

      await _tap(tester, 'qa.recovery.back_to_sign_in');
      expect(results, [null]);
      expect(find.byType(AccountRecoveryScreen), findsNothing);
    });

    testWidgets(
      'Choosing "I lost my code" swaps the form and clears the error '
      '[case:auth.account_recovery.i_have_my_code_onselectionchanged.action]',
      (tester) async {
        final api = recoveryApi();
        await open(tester, api);
        expect(_key('qa.recovery.code'), findsOneWidget);
        expect(_key('qa.recovery.message'), findsNothing);
        await _tap(tester, 'qa.recovery.submit');
        expect(find.text(_en.authRecoveryEnterCode), findsOneWidget);

        await tester.tap(find.text(_en.authRecoveryLostCode));
        await qaSettle(tester);
        expect(find.text(_en.authRecoveryEnterCode), findsNothing);
        expect(_key('qa.recovery.code'), findsNothing);
        expect(_key('qa.recovery.new_password'), findsNothing);
        expect(_key('qa.recovery.message'), findsOneWidget);
        expect(find.text(_en.authRecoveryLostCodeIntro), findsOneWidget);
        expect(find.text(_en.authRecoveryAskForHelp), findsOneWidget);

        await tester.tap(find.text(_en.authRecoveryHaveCode));
        await qaSettle(tester);
        expect(_key('qa.recovery.code'), findsOneWidget);
        expect(find.text(_en.authRecoveryResetPassword), findsOneWidget);
        expect(api.calls, isEmpty);
      },
    );

    testWidgets('Lost code asks the safety team with the optional note '
        '[case:auth.account_recovery.recovery_message_input.action]', (
      tester,
    ) async {
      final api = recoveryApi();
      await open(tester, api);
      await tester.tap(find.text(_en.authRecoveryLostCode));
      await qaSettle(tester);
      await _type(tester, 'qa.recovery.message', '  Last signed in Monday  ');
      await _tap(tester, 'qa.recovery.submit');

      expect(api.writeLines, ['POST /auth/recovery/assistance']);
      expect(api.writes.single.body, {
        'username': 'member_one',
        'message': 'Last signed in Monday',
      });
      expect(
        find.textContaining('our safety team will review the request'),
        findsOneWidget,
      );
    });

    testWidgets('The help note is optional, capped at 500 and keeps any script '
        '[case:auth.account_recovery.recovery_message_input.validation]', (
      tester,
    ) async {
      final api = QaApi()..on('POST /auth/recovery/assistance', (_) => qaOk());
      await open(tester, api);
      await tester.tap(find.text(_en.authRecoveryLostCode));
      await qaSettle(tester);

      await _type(tester, 'qa.recovery.message', 'x' * 600);
      expect(
        tester.widget<TextField>(_key('qa.recovery.message')).controller!.text,
        hasLength(500),
      );

      const note = 'Привет 👋 — ich heiße Zoë, 最后一次登录是周一';
      await _type(tester, 'qa.recovery.message', note);
      await _tap(tester, 'qa.recovery.submit');
      expect(api.writes.single.body['message'], note);
      // No message from the server: the app's own neutral answer.
      expect(find.text(_en.authRecoveryAssistanceDone), findsOneWidget);
    });

    testWidgets('Recovery needs a username; any script is kept '
        '[case:auth.account_recovery.recovery_username_input.validation]', (
      tester,
    ) async {
      final api = recoveryApi();
      await open(tester, api, username: '');
      await _type(tester, 'qa.recovery.code', 'code-123');
      await _type(tester, 'qa.recovery.new_password', 'NewPassw0rd');
      await _tap(tester, 'qa.recovery.submit');
      expect(find.text(_en.authRecoveryEnterUsername), findsOneWidget);

      await _type(tester, 'qa.recovery.username', '   ');
      await _tap(tester, 'qa.recovery.submit');
      expect(find.text(_en.authRecoveryEnterUsername), findsOneWidget);
      expect(api.calls, isEmpty);

      await _type(tester, 'qa.recovery.username', ' Zoë_Ünïcode ');
      await _tap(tester, 'qa.recovery.submit');
      expect(api.writes.single.body['username'], 'zoë_ünïcode');
    });

    testWidgets('Recovery code is required and sent trimmed '
        '[case:auth.account_recovery.recovery_code_input.validation]', (
      tester,
    ) async {
      final api = recoveryApi();
      await open(tester, api);
      await _type(tester, 'qa.recovery.new_password', 'NewPassw0rd');
      for (final blank in ['', '   ']) {
        await _type(tester, 'qa.recovery.code', blank);
        await _tap(tester, 'qa.recovery.submit');
        expect(find.text(_en.authRecoveryEnterCode), findsOneWidget);
      }
      expect(api.calls, isEmpty);

      await _type(tester, 'qa.recovery.code', ' ÄBC-123 ');
      await _tap(tester, 'qa.recovery.submit');
      expect(api.writes.single.body['recovery_code'], 'ÄBC-123');
    });

    testWidgets(
      'A new password must be strong; an accepted one is sent exactly '
      '[case:auth.account_recovery.recovery_new_password_input.validation]',
      (tester) async {
        final api = recoveryApi();
        await open(tester, api);
        await _type(tester, 'qa.recovery.code', 'code-123');
        for (final weak in [
          'short1',
          'lettersonly',
          '12345678',
          // 73 UTF-8 bytes: too long although only 37 characters.
          '${'é' * 36}1',
        ]) {
          await _type(tester, 'qa.recovery.new_password', weak);
          await _tap(tester, 'qa.recovery.submit');
          expect(
            find.text(_en.authRecoveryPasswordRule),
            findsOneWidget,
            reason: weak,
          );
        }
        expect(api.calls, isEmpty);

        const strong = 'Pässwörd 12';
        await _type(tester, 'qa.recovery.new_password', strong);
        await _tap(tester, 'qa.recovery.submit');
        expect(api.writes.single.body['new_password'], strong);
      },
    );

    testWidgets('Show password toggles the new password '
        '[case:auth.account_recovery.recovery_new_password.action]', (
      tester,
    ) async {
      await open(tester, recoveryApi());
      await _type(tester, 'qa.recovery.new_password', 'NewPassw0rd');
      const toggle = ValueKey('qa.recovery.password_visibility');
      expect(_obscured(tester, 'qa.recovery.new_password'), isTrue);
      expect(
        tester.widget<IconButton>(find.byKey(toggle)).tooltip,
        _en.authShowPassword,
      );

      await tester.tap(find.byKey(toggle));
      await tester.pump();
      expect(_obscured(tester, 'qa.recovery.new_password'), isFalse);
      expect(
        tester.widget<IconButton>(find.byKey(toggle)).tooltip,
        _en.authHidePassword,
      );

      await tester.tap(find.byKey(toggle));
      await tester.pump();
      expect(_obscured(tester, 'qa.recovery.new_password'), isTrue);
    });

    testWidgets(
      'A rejected code says so, re-enables and sends once; offline and help '
      'failures too '
      '[case:auth.account_recovery.recovery_submit.api_failure]',
      (tester) async {
        final api = QaApi()
          ..on(
            'POST /auth/password/recover',
            (_) => _slow(
              qaError(400, message: 'invalid or expired recovery code'),
            ),
          );
        await open(tester, api);
        await _type(tester, 'qa.recovery.code', 'wrong');
        await _type(tester, 'qa.recovery.new_password', 'NewPassw0rd');
        final submit = _key('qa.recovery.submit');
        await tester.tap(submit);
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.widget<FilledButton>(submit).onPressed, isNull);
        expect(find.text(_en.authRecoverySending), findsOneWidget);
        await tester.tap(submit, warnIfMissed: false);
        await qaSettle(tester);

        expect(api.writes, hasLength(1));
        expect(find.text(_en.authRecoveryInvalidCode), findsOneWidget);
        expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
        expect(find.text(_en.authRecoveryResetPassword), findsOneWidget);
        expect(
          tester.widget<TextField>(_key('qa.recovery.code')).controller!.text,
          'wrong',
          reason: 'what the member typed is kept for a retry',
        );

        api.offline('POST /auth/password/recover');
        await _tap(tester, 'qa.recovery.submit');
        expect(find.text(_en.authRecoveryOffline), findsOneWidget);

        await tester.tap(find.text(_en.authRecoveryLostCode));
        await qaSettle(tester);
        api.fail('POST /auth/recovery/assistance', status: 500);
        await _tap(tester, 'qa.recovery.submit');
        expect(find.text(_en.authRecoverySendFailed), findsOneWidget);
        expect(find.text(_en.authRecoveryAskForHelp), findsOneWidget);
        expect(api.writes, hasLength(3));
      },
    );

    testWidgets(
      'REGRESSION: a server outage during reset is not reported as a bad code '
      '[case:auth.account_recovery.recovery_submit.api_failure]',
      (tester) async {
        // The BFF error envelope carries `error` on every failure. A 503 used
        // to show "That recovery code is not valid or has expired."
        final api = QaApi()
          ..fail(
            'POST /auth/password/recover',
            status: 503,
            message: 'account recovery is unavailable',
          );
        await open(tester, api);
        await _type(tester, 'qa.recovery.code', 'code-123');
        await _type(tester, 'qa.recovery.new_password', 'NewPassw0rd');
        await _tap(tester, 'qa.recovery.submit');

        expect(api.writes, hasLength(1));
        expect(find.text(_en.authRecoveryInvalidCode), findsNothing);
        expect(find.text(_en.authRecoveryOffline), findsOneWidget);
      },
    );

    testWidgets('Account recovery renders in every language '
        '[case:auth.account_recovery.l10n]', (tester) async {
      for (final locale in qaLocales) {
        final l10n = qaL10n(locale);
        await tester.pumpWidget(const SizedBox()); // fresh tree
        await pumpQa(
          tester,
          QaApi(),
          const AccountRecoveryScreen(),
          locale: locale,
          extra: [_signedOut],
        );
        expect(find.text(l10n.authCantSignIn), findsOneWidget);
        expect(find.text(l10n.authRecoveryHaveCode), findsOneWidget);
        expect(find.text(l10n.authRecoveryCodeLabel), findsOneWidget);
        expect(find.text(l10n.authRecoveryResetPassword), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$locale');
      }
    });
  });
}
