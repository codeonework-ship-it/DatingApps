// Case ids stay whole in test names (the QA Lab reads them literally).
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verified_dating_app/core/i18n/app_locale_provider.dart';
import 'package:verified_dating_app/features/common/screens/language_settings_screen.dart';

import '../../support/qa_api.dart';

// Language: each of the ten languages (and "use device language") is saved
// on the account (PATCH /settings/{me} {"locale": tag}, empty = device) and
// cached on the device so it applies before sign-in. A failed save keeps the
// previous choice and says so; the next pick still saves.

const _cacheKey = 'connect.locale';
const _device = 'qa.settings.language.device';

class _Account {
  _Account({String locale = ''}) {
    settings['locale'] = locale;
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
  final settings = <String, dynamic>{
    'show_age': true,
    'theme': 'dark:snow',
    'notify_likes': false,
  };

  void healthy() => api.on('PATCH /settings/me', (c) {
    settings.addAll(c.body);
    return qaOk({
      'settings': {...settings},
    });
  });
}

Future<ProviderContainer> _open(
  WidgetTester tester,
  _Account account, {
  Locale? chosen,
  Locale? locale,
}) async {
  await pumpQa(
    tester,
    account.api,
    const LanguageSettingsScreen(),
    locale: locale,
    extra: [
      appLocaleProvider.overrideWith(
        (ref) => AppLocaleNotifier(ref, initial: chosen),
      ),
    ],
  );
  return ProviderScope.containerOf(
    tester.element(find.byType(LanguageSettingsScreen)),
  );
}

bool _ticked(String key) => find
    .descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byIcon(Icons.check_circle_rounded),
    )
    .evaluate()
    .isNotEmpty;

Future<void> _pick(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(ValueKey(key)));
  await tester.pump();
  await tester.tap(find.byKey(ValueKey(key)));
  await qaSettle(tester, frames: 5);
}

List<Object?> _savedLocales(QaApi api) =>
    api.sent('PATCH', '/settings/me').map((c) => c.body['locale']).toList();

Future<String?> _cached() async =>
    (await SharedPreferences.getInstance()).getString(_cacheKey);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final language in appLanguages) {
    final key = 'qa.settings.language.${language.tag}';
    testWidgets(
      'picking ${language.nativeName} saves "${language.tag}" '
      '[case:common.language_picker.check_circle_rounded_icon_check.action]',
      (tester) async {
        final account = _Account();
        final container = await _open(tester, account);
        expect(_ticked(_device), isTrue);

        await _pick(tester, key);

        // Only the language is sent; nothing else on the account changes.
        expect(account.api.sent('PATCH', '/settings/me').single.body, {
          'locale': language.tag,
        });
        expect(account.settings['theme'], 'dark:snow');
        expect(account.settings['notify_likes'], isFalse);
        expect(container.read(appLocaleProvider), language.locale);
        expect(_ticked(key), isTrue);
        expect(_ticked(_device), isFalse);
        expect(await _cached(), language.tag);
        expect(qaSnackText(tester), isNull);
      },
    );
  }

  testWidgets('Use device language clears the stored language '
      '[case:common.language_picker.use_device_language.action]', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({_cacheKey: 'fr'});
    final account = _Account(locale: 'fr');
    final container = await _open(tester, account, chosen: const Locale('fr'));
    expect(_ticked('qa.settings.language.fr'), isTrue);

    await _pick(tester, _device);

    expect(account.api.sent('PATCH', '/settings/me').single.body, {
      'locale': '',
    });
    expect(container.read(appLocaleProvider), isNull);
    expect(_ticked(_device), isTrue);
    expect(_ticked('qa.settings.language.fr'), isFalse);
    expect(await _cached(), isNull);
    expect(qaSnackText(tester), isNull);
  });

  // Regression (2026-10-02): after one failed save every later pick failed
  // at once without reaching the server, until the app was restarted.
  testWidgets(
    'a refused language keeps the previous one, explains, and the next pick '
    'saves [case:common.language_picker.check_circle_rounded_icon_check.api_failure]',
    (tester) async {
      final account = _Account();
      account.api.fail(
        'PATCH /settings/me',
        status: 400,
        message: 'locale is not supported',
      );
      final container = await _open(tester, account);
      final en = qaL10n(const Locale('en'));

      await _pick(tester, 'qa.settings.language.de');

      expect(_savedLocales(account.api), ['de']);
      // App-side message in the member's language (the server text is
      // developer wording).
      expect(qaSnackText(tester), en.languageSaveFailed);
      expect(container.read(appLocaleProvider), isNull);
      expect(_ticked(_device), isTrue);
      expect(_ticked('qa.settings.language.de'), isFalse);
      expect(await _cached(), isNull);

      account.healthy();
      await _pick(tester, 'qa.settings.language.de');

      expect(_savedLocales(account.api), ['de', 'de']);
      expect(account.settings['locale'], 'de');
      expect(container.read(appLocaleProvider), const Locale('de'));
      expect(_ticked('qa.settings.language.de'), isTrue);
      expect(await _cached(), 'de');
    },
  );

  testWidgets(
    'offline: picking a language keeps the previous one and explains '
    '[case:common.language_picker.check_circle_rounded_icon_check.api_failure]',
    (tester) async {
      SharedPreferences.setMockInitialValues({_cacheKey: 'it'});
      final account = _Account(locale: 'it');
      account.api.offline('PATCH /settings/me');
      final container = await _open(
        tester,
        account,
        chosen: const Locale('it'),
      );

      await _pick(tester, 'qa.settings.language.pl');

      expect(_savedLocales(account.api), ['pl']);
      expect(
        qaSnackText(tester),
        qaL10n(const Locale('en')).languageSaveFailed,
      );
      expect(container.read(appLocaleProvider), const Locale('it'));
      expect(_ticked('qa.settings.language.it'), isTrue);
      expect(await _cached(), 'it');
    },
  );

  // Regression (2026-10-02): with no connection at all (the account could
  // not even be read) the new language was applied and cached anyway while
  // the member was told it had not been saved.
  testWidgets(
    'fully offline: the language does not change and the member is told '
    '[case:common.language_picker.check_circle_rounded_icon_check.api_failure]',
    (tester) async {
      SharedPreferences.setMockInitialValues({_cacheKey: 'it'});
      final account = _Account(locale: 'it');
      account.api
        ..offline('GET /settings/me')
        ..offline('PATCH /settings/me');
      final container = await _open(
        tester,
        account,
        chosen: const Locale('it'),
      );

      await _pick(tester, 'qa.settings.language.pt');

      expect(
        qaSnackText(tester),
        qaL10n(const Locale('en')).languageSaveFailed,
      );
      expect(container.read(appLocaleProvider), const Locale('it'));
      expect(_ticked('qa.settings.language.it'), isTrue);
      expect(_ticked('qa.settings.language.pt'), isFalse);
      expect(await _cached(), 'it');

      // Connection back: the same pick reads the account and saves.
      account.api.on(
        'GET /settings/me',
        (_) => qaOk({
          'settings': {...account.settings},
        }),
      );
      account.healthy();
      await _pick(tester, 'qa.settings.language.pt');
      expect(_savedLocales(account.api), ['pt']);
      expect(container.read(appLocaleProvider), const Locale('pt'));
      expect(await _cached(), 'pt');
    },
  );

  testWidgets('Use device language refused: the chosen language stays '
      '[case:common.language_picker.use_device_language.api_failure]', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({_cacheKey: 'fr'});
    final account = _Account(locale: 'fr');
    account.api.fail('PATCH /settings/me', status: 503);
    final container = await _open(tester, account, chosen: const Locale('fr'));

    await _pick(tester, _device);

    expect(_savedLocales(account.api), ['']);
    expect(qaSnackText(tester), qaL10n(const Locale('en')).languageSaveFailed);
    expect(container.read(appLocaleProvider), const Locale('fr'));
    expect(_ticked('qa.settings.language.fr'), isTrue);
    expect(_ticked(_device), isFalse);
    expect(await _cached(), 'fr');
    expect(account.settings['locale'], 'fr');
  });

  testWidgets('Language renders in every shipped language '
      '[case:common.language_settings.l10n]', (tester) async {
    for (final locale in qaLocales) {
      final l10n = qaL10n(locale);
      await tester.pumpWidget(const SizedBox());
      await _open(tester, _Account(), locale: locale);
      expect(tester.takeException(), isNull, reason: '$locale');
      expect(find.text(l10n.languageTitle), findsOneWidget, reason: '$locale');
      expect(
        find.text(l10n.languageUseDevice),
        findsOneWidget,
        reason: '$locale',
      );
      // Language names are never translated: each is in its own language.
      for (final language in appLanguages) {
        expect(find.text(language.nativeName), findsOneWidget);
      }
    }
  });
}
