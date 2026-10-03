// Case ids stay whole in test names (the QA Lab reads them literally).
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verified_dating_app/core/i18n/app_locale_provider.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/auth/screens/welcome_screen.dart';
import 'package:verified_dating_app/features/common/widgets/language_picker.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';

// Language before sign-in (audit 2026-10-02, P0):
//  * signed-out screens offer the language list (globe + native name);
//  * a language picked signed out is saved to the account that signs in
//    next, even over an older stored value; a new account (no stored value)
//    gets the language the app is shown in; without a pick the account's
//    stored language wins;
//  * on the web a website link's `lang` parameter seeds the first choice.

class _SwitchableAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState();

  void signInAs(String userId) =>
      state = AuthState(isAuthenticated: true, userId: userId);
}

class _Account {
  _Account({required String storedLocale}) {
    settings['locale'] = storedLocale;
    api
      ..on(
        'GET /settings/me',
        (_) => qaOk({
          'settings': {...settings},
        }),
      )
      ..on('PATCH /settings/me', (c) {
        settings.addAll(c.body);
        return qaOk({
          'settings': {...settings},
        });
      });
  }

  final api = QaApi();
  final settings = <String, dynamic>{'theme': 'auto'};

  List<Object?> get savedLocales =>
      api.sent('PATCH', '/settings/me').map((c) => c.body['locale']).toList();
}

ProviderContainer _container(_Account account, {Locale? cached}) {
  final container = ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(_SwitchableAuth.new),
      apiClientProvider.overrideWithValue(account.api.dio),
      appLocaleProvider.overrideWith(
        (ref) => AppLocaleNotifier(ref, initial: cached),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<void> _signInAndLoad(ProviderContainer container) async {
  (container.read(authNotifierProvider.notifier) as _SwitchableAuth).signInAs(
    'me',
  );
  await container.read(appLocaleProvider.notifier).ensureLoaded();
}

Future<bool?> _pickedFlag() async => (await SharedPreferences.getInstance())
    .getBool('connect.locale.picked_before_sign_in');

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a new account gets the language picked before sign-in saved '
      '[case:l10n.language.pre_sign_in.new_account_saved]', () async {
    final account = _Account(storedLocale: '');
    final container = _container(account);

    await container.read(appLocaleProvider.notifier).select(const Locale('de'));
    // Signed out: nothing is sent, the pick is remembered on the device.
    expect(account.api.calls, isEmpty);
    expect(await _pickedFlag(), isTrue);

    await _signInAndLoad(container);

    expect(account.savedLocales, ['de']);
    expect(account.settings['locale'], 'de');
    expect(container.read(appLocaleProvider), const Locale('de'));
    expect(await _pickedFlag(), isNull, reason: 'the flag is cleared');
  });

  test('an explicit pick before sign-in wins over an older stored language '
      '[case:l10n.language.pre_sign_in.pick_wins]', () async {
    final account = _Account(storedLocale: 'fr');
    final container = _container(account);

    await container.read(appLocaleProvider.notifier).select(const Locale('pl'));
    await _signInAndLoad(container);

    expect(account.savedLocales, ['pl']);
    expect(container.read(appLocaleProvider), const Locale('pl'));
    expect(
      (await SharedPreferences.getInstance()).getString('connect.locale'),
      'pl',
    );
  });

  test('without a pick the stored language wins over the device cache '
      '[case:l10n.language.pre_sign_in.server_wins]', () async {
    SharedPreferences.setMockInitialValues({'connect.locale': 'it'});
    final account = _Account(storedLocale: 'fr');
    final container = _container(account, cached: const Locale('it'));

    await _signInAndLoad(container);

    expect(account.savedLocales, isEmpty);
    expect(container.read(appLocaleProvider), const Locale('fr'));
    expect(
      (await SharedPreferences.getInstance()).getString('connect.locale'),
      'fr',
    );
  });

  test('a cached language is saved to an account that has none '
      '[case:l10n.language.pre_sign_in.empty_server_takes_local]', () async {
    SharedPreferences.setMockInitialValues({'connect.locale': 'nl'});
    final account = _Account(storedLocale: '');
    final container = _container(account, cached: const Locale('nl'));

    await _signInAndLoad(container);

    expect(account.savedLocales, ['nl']);
    expect(container.read(appLocaleProvider), const Locale('nl'));
  });

  test('a failed save keeps the pick and retries at the next sign-in '
      '[case:l10n.language.pre_sign_in.save_failure_retries]', () async {
    final account = _Account(storedLocale: 'fr');
    account.api.fail('PATCH /settings/me');
    final container = _container(account);

    await container.read(appLocaleProvider.notifier).select(const Locale('es'));
    await _signInAndLoad(container);

    expect(account.savedLocales, ['es'], reason: 'one attempt was made');
    expect(container.read(appLocaleProvider), const Locale('es'));
    expect(await _pickedFlag(), isTrue, reason: 'kept for the next sign-in');
  });

  group('website lang parameter [case:l10n.language.web_lang_param]', () {
    test('is read from the query or the hash route', () {
      expect(
        appLocaleFromLaunchUri(
          Uri.parse('https://x.test/app/?lang=de#/signin'),
        ),
        const Locale('de'),
      );
      expect(
        appLocaleFromLaunchUri(Uri.parse('https://x.test/app/?lang=en-GB#/')),
        const Locale('en', 'GB'),
      );
      expect(
        appLocaleFromLaunchUri(
          Uri.parse('https://x.test/app/#/signup?lang=pl'),
        ),
        const Locale('pl'),
      );
      expect(
        appLocaleFromLaunchUri(Uri.parse('https://x.test/app/?lang=en')),
        const Locale('en', 'US'),
      );
      expect(
        appLocaleFromLaunchUri(Uri.parse('https://x.test/app/?lang=ja')),
        isNull,
      );
      expect(appLocaleFromLaunchUri(Uri.parse('https://x.test/app/')), isNull);
    });

    test('seeds the cache only when nothing is cached', () async {
      final uri = Uri.parse('https://x.test/app/?lang=fr#/signin');
      expect(await readCachedAppLocale(launchUri: uri), const Locale('fr'));
      expect(
        (await SharedPreferences.getInstance()).getString('connect.locale'),
        'fr',
      );
      // Not an explicit pick: the account's own language still wins later.
      expect(await _pickedFlag(), isNull);

      SharedPreferences.setMockInitialValues({'connect.locale': 'ru'});
      expect(await readCachedAppLocale(launchUri: uri), const Locale('ru'));
    });
  });

  test('an unsupported device language opens in English, not German '
      '[case:l10n.language.device_fallback_english]', () {
    const supported = AppLocalizations.supportedLocales;
    expect(
      resolveAppLocale([const Locale('ja', 'JP')], supported),
      const Locale('en'),
    );
    expect(
      resolveAppLocale([const Locale('en', 'AU')], supported),
      const Locale('en'),
    );
    expect(
      resolveAppLocale([const Locale('en', 'GB')], supported),
      const Locale('en', 'GB'),
    );
    expect(
      resolveAppLocale([const Locale('pt', 'BR')], supported),
      const Locale('pt'),
    );
    expect(
      resolveAppLocale([
        const Locale('ja'),
        const Locale('de', 'AT'),
      ], supported),
      const Locale('de'),
    );
    expect(resolveAppLocale(null, supported), const Locale('en'));
  });

  testWidgets('the welcome screen changes language before sign-in '
      '[case:l10n.language.welcome_picker]', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    final account = _Account(storedLocale: '');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_SwitchableAuth.new),
          apiClientProvider.overrideWithValue(account.api.dio),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: AppTheme.darkTheme,
            locale: ref.watch(appLocaleProvider) ?? const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const WelcomeScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final en = lookupAppLocalizations(const Locale('en'));
    final de = lookupAppLocalizations(const Locale('de'));
    expect(find.text(en.welcomeCreateAccount), findsOneWidget);
    // The button shows the current language by its own name and is spoken
    // as a sentence, not as its automation id.
    expect(find.text('English (US)'), findsOneWidget);
    final button = tester.getSemantics(
      find.bySemanticsIdentifier(LanguagePickerButton.qaId),
    );
    expect(button.label, en.languagePickerButtonSemantics('English (US)'));

    await tester.tap(find.byKey(const ValueKey(LanguagePickerButton.qaId)));
    await tester.pumpAndSettle();
    expect(find.text(en.languageIntroSignedOut), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('qa.language.option.de')));
    await tester.pumpAndSettle();

    // The sheet closed and the whole screen is German now.
    expect(find.byKey(const ValueKey('qa.language.option.de')), findsNothing);
    expect(find.text(de.welcomeCreateAccount), findsOneWidget);
    expect(find.text(en.welcomeCreateAccount), findsNothing);
    expect(find.text('Deutsch'), findsOneWidget);
    expect(account.api.calls, isEmpty, reason: 'no session, no request');
    expect(
      (await SharedPreferences.getInstance()).getString('connect.locale'),
      'de',
    );
    expect(await _pickedFlag(), isTrue);
    semantics.dispose();
  });
}
