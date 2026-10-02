// Control-level tests for the terms gate (UserAgreementScreen). The gate is
// driven through the real app root (`DatingApp`): the terms screen is shown
// in place of the app, so what happens around a save or a sign-out depends
// on the gate, not on the screen alone. Each test name carries its catalog
// case ids.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verified_dating_app/core/auth/auth_session_store.dart';
import 'package:verified_dating_app/core/i18n/app_locale_provider.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/auth/screens/user_agreement_screen.dart';
import 'package:verified_dating_app/features/auth/screens/welcome_screen.dart';
import 'package:verified_dating_app/features/common/providers/app_theme_provider.dart';
import 'package:verified_dating_app/features/profile/providers/profile_completion_provider.dart';
import 'package:verified_dating_app/main.dart';

import '../../support/qa_api.dart';

final _en = qaL10n(const Locale('en'));

/// A member who just created an account: the gate asks for the terms.
class _NewMember extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    isAuthenticated: true,
    isNewAccount: true,
    userId: 'me',
    username: 'me',
  );
}

class _PinnedTheme extends AppThemeNotifier {
  _PinnedTheme(super.ref);
  @override
  Future<void> ensureLoaded() async {}
}

class _PinnedLocale extends AppLocaleNotifier {
  _PinnedLocale(super.ref);
  @override
  Future<void> ensureLoaded() async {}
}

QaReply _slow(QaReply reply) => QaReply(
  reply.status,
  reply.body,
  offline: reply.offline,
  delay: const Duration(milliseconds: 400),
);

const _termsPath = '/users/me/agreements/terms';

QaApi _termsApi() => QaApi()
  ..json('GET $_termsPath', {
    'agreement': {'accepted': false},
  })
  ..json('PATCH $_termsPath', {
    'success': true,
    'agreement': {'accepted': true, 'terms_version': 'v1'},
  })
  ..json('POST /auth/logout', {'success': true})
  ..json('DELETE /notifications/me/devices/*', {'success': true});

Finder _key(String key) => find.byKey(ValueKey(key));

/// Pumps the real app root for a new member; the profile step after the
/// terms never finishes loading, so the gate's next screen is stable.
Future<void> _pumpGate(WidgetTester tester, QaApi api, {Locale? locale}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: qaOverrides(
        api,
        extra: [
          authNotifierProvider.overrideWith(_NewMember.new),
          appThemeProvider.overrideWith(_PinnedTheme.new),
          appLocaleProvider.overrideWith(
            (ref) => _PinnedLocale(ref)..state = locale,
          ),
          profileCompletionProvider.overrideWith(
            (ref) => Completer<ProfileCompletion>().future,
          ),
        ],
      ),
      child: const DatingApp(),
    ),
  );
  await qaSettle(tester);
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pump();
  await tester.tap(_key(key));
  await qaSettle(tester);
}

bool _ticked(WidgetTester tester) =>
    tester.widget<Checkbox>(_key('qa.terms.accept_checkbox_input')).value!;

GlassButton _continue(WidgetTester tester) =>
    tester.widget<GlassButton>(_key('qa.terms.continue_button'));

Future<bool?> _storedAcceptance() async =>
    (await SharedPreferences.getInstance()).getBool('termsAccepted_v1_me');

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: '');
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    AuthSessionStore.instance.clear();
  });
  tearDown(() {
    AuthSessionStore.instance.clear();
    dotenv.testLoad(fileInput: '');
  });

  testWidgets('Accepting the terms saves the agreement and the gate moves on '
      '[case:auth.user_agreement.terms_continue_button.action] '
      '[case:auth.user_agreement.terms_accept_checkbox.action]', (
    tester,
  ) async {
    final api = _termsApi();
    await _pumpGate(tester, api);
    expect(find.byType(UserAgreementScreen), findsOneWidget);
    expect(api.sent('GET', _termsPath), hasLength(1));
    expect(_ticked(tester), isFalse);
    expect(_continue(tester).onPressed, isNull, reason: 'needs the tick');

    // Tapping the agreement row (its text) ticks the box.
    await tester.ensureVisible(_key('qa.terms.accept_checkbox'));
    await tester.tap(find.text(_en.authTermsAgreeCheckbox));
    await qaSettle(tester);
    expect(_ticked(tester), isTrue);
    expect(_continue(tester).onPressed, isNotNull);

    await _tap(tester, 'qa.terms.continue_button');

    expect(api.writeLines, ['PATCH $_termsPath']);
    expect(api.writes.single.body, {'accepted': true, 'terms_version': 'v1'});
    expect(find.byType(UserAgreementScreen), findsNothing);
    expect(find.text(_en.gateLoadingProfile), findsOneWidget);
    expect(await _storedAcceptance(), isTrue);
  });

  testWidgets('The checkbox itself ticks and unticks '
      '[case:auth.user_agreement.terms_accept_checkbox_input.action]', (
    tester,
  ) async {
    final api = _termsApi();
    await _pumpGate(tester, api);

    await _tap(tester, 'qa.terms.accept_checkbox_input');
    expect(_ticked(tester), isTrue);
    expect(_continue(tester).onPressed, isNotNull);

    await _tap(tester, 'qa.terms.accept_checkbox_input');
    expect(_ticked(tester), isFalse);
    expect(_continue(tester).onPressed, isNull);
    expect(api.writes, isEmpty);
  });

  testWidgets(
    'REGRESSION: a failed save keeps the terms screen and the tick, says why '
    'and saves once '
    '[case:auth.user_agreement.terms_continue_button.api_failure]',
    (tester) async {
      // The save used to put the terms answer into a fresh loading state:
      // the gate swapped the screen for its loading page, so the failure
      // message was never shown and the tick was lost.
      final api = _termsApi()
        ..on('PATCH $_termsPath', (_) => _slow(qaError(500)));
      await _pumpGate(tester, api);
      await _tap(tester, 'qa.terms.accept_checkbox_input');

      final button = _key('qa.terms.continue_button');
      await tester.tap(button);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(UserAgreementScreen), findsOneWidget);
      expect(_continue(tester).isLoading, isTrue);
      expect(
        tester.widget<TextButton>(_key('qa.terms.sign_out')).onPressed,
        isNull,
        reason: 'no sign-out mid-save',
      );
      await tester.tap(button, warnIfMissed: false); // impatient second tap
      await qaSettle(tester);

      expect(api.writeLines, ['PATCH $_termsPath']);
      expect(qaSnackText(tester), _en.authTermsSaveFailed);
      expect(find.byType(UserAgreementScreen), findsOneWidget);
      expect(_ticked(tester), isTrue);
      expect(_continue(tester).onPressed, isNotNull);
      expect(_continue(tester).isLoading, isFalse);
      expect(await _storedAcceptance(), isNot(isTrue));

      // Offline: same message; the retry then goes through.
      api.offline('PATCH $_termsPath');
      ScaffoldMessenger.of(
        tester.element(find.byType(UserAgreementScreen)),
      ).clearSnackBars();
      await qaSettle(tester);
      await _tap(tester, 'qa.terms.continue_button');
      expect(qaSnackText(tester), _en.authTermsSaveFailed);
      expect(find.byType(UserAgreementScreen), findsOneWidget);

      api.json('PATCH $_termsPath', {'success': true});
      await _tap(tester, 'qa.terms.continue_button');
      expect(api.writeLines, List.filled(3, 'PATCH $_termsPath'));
      expect(find.byType(UserAgreementScreen), findsNothing);
    },
  );

  testWidgets(
    'Sign out removes this device from push, ends the session and shows '
    'Welcome '
    '[case:auth.user_agreement.terms_sign_out.action]',
    (tester) async {
      // Push is configured and this device registered for `me`.
      dotenv.testLoad(
        fileInput:
            'FIREBASE_API_KEY=k\nFIREBASE_APP_ID=a\n'
            'FIREBASE_PROJECT_ID=p\nFIREBASE_MESSAGING_SENDER_ID=s',
      );
      SharedPreferences.setMockInitialValues({
        'push.me.fcm.device_id': 'dev-7',
      });
      FlutterSecureStorage.setMockInitialValues({
        'connect.auth.refresh_token': 'refresh-me',
        'connect.auth.username': 'me',
      });
      AuthSessionStore.instance
        ..update(accessToken: 'access-me', refreshToken: 'refresh-me')
        ..identify(userId: 'me', username: 'me', isNewAccount: true);

      final api = _termsApi();
      await _pumpGate(tester, api);
      await _tap(tester, 'qa.terms.sign_out');

      expect(api.writeLines, [
        'DELETE /notifications/me/devices/dev-7',
        'POST /auth/logout',
      ]);
      expect(find.byType(UserAgreementScreen), findsNothing);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(
        _container(tester).read(authNotifierProvider).isAuthenticated,
        isFalse,
      );
      expect(AuthSessionStore.instance.accessToken, isNull);
      expect(
        await const FlutterSecureStorage().read(
          key: 'connect.auth.refresh_token',
        ),
        isNull,
      );
      expect(
        (await SharedPreferences.getInstance()).getString(
          'push.me.fcm.device_id',
        ),
        isNull,
      );
    },
  );

  testWidgets(
    'Sign out still signs out when the server or network fails, sending once '
    '[case:auth.user_agreement.terms_sign_out.api_failure]',
    (tester) async {
      dotenv.testLoad(
        fileInput:
            'FIREBASE_API_KEY=k\nFIREBASE_APP_ID=a\n'
            'FIREBASE_PROJECT_ID=p\nFIREBASE_MESSAGING_SENDER_ID=s',
      );
      SharedPreferences.setMockInitialValues({
        'push.me.fcm.device_id': 'dev-7',
      });
      AuthSessionStore.instance.update(
        accessToken: 'access-me',
        refreshToken: 'refresh-me',
      );
      final api = _termsApi()
        ..offline('DELETE /notifications/me/devices/*')
        ..fail('POST /auth/logout', status: 503);
      await _pumpGate(tester, api);
      await _tap(tester, 'qa.terms.sign_out');

      // Never stuck signed in on a gate the member declined.
      expect(api.writeLines, [
        'DELETE /notifications/me/devices/dev-7',
        'POST /auth/logout',
      ]);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(UserAgreementScreen), findsNothing);
      expect(AuthSessionStore.instance.accessToken, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Sign out offline (no session reachable) still lands on Welcome '
      '[case:auth.user_agreement.terms_sign_out.api_failure]', (tester) async {
    AuthSessionStore.instance.update(
      accessToken: 'access-me',
      refreshToken: 'refresh-me',
    );
    final api = _termsApi()..offline('POST /auth/logout');
    await _pumpGate(tester, api);
    await _tap(tester, 'qa.terms.sign_out');

    expect(api.writeLines, ['POST /auth/logout']);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(AuthSessionStore.instance.refreshToken, isNull);
  });

  testWidgets(
    'Terms render in every language [case:auth.user_agreement.l10n]',
    (tester) async {
      for (final locale in qaLocales) {
        final l10n = qaL10n(locale);
        await tester.pumpWidget(const SizedBox()); // fresh tree
        await pumpQa(
          tester,
          _termsApi(),
          const UserAgreementScreen(),
          locale: locale,
        );
        expect(find.text(l10n.authTermsTitle), findsOneWidget);
        expect(find.text(l10n.authTermsAgreeCheckbox), findsOneWidget);
        expect(find.text(l10n.webNavSignOut), findsOneWidget);
        expect(_continue(tester).label, l10n.authTermsAcceptButton);
        expect(tester.takeException(), isNull, reason: '$locale');
      }
    },
  );
}
