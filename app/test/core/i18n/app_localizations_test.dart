import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/i18n/app_locale_provider.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/common/screens/settings_screen.dart';
import 'package:verified_dating_app/features/notifications/providers/notification_provider.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

/// The ten shipped locales, as the ARB files spell them.
const _arbLocales = <String>{
  'en',
  'en_GB',
  'de',
  'fr',
  'ru',
  'es',
  'it',
  'pt',
  'nl',
  'pl',
};

class _Auth extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(isAuthenticated: true, userId: 'qa-user');
}

// Skip push/socket bootstrap; the hub only needs the unread badge state.
class _Notifications extends NotificationNotifier {
  _Notifications(super.ref);
  @override
  Future<void> bootstrap() async {}
}

Dio _offlineApi() {
  final dio = Dio(BaseOptions(baseUrl: 'https://l10n.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response<dynamic>(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{'settings': <String, dynamic>{}},
        ),
      ),
    ),
  );
  return dio;
}

Map<String, dynamic> _readArb(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

void main() {
  // `flutter test` runs with the package root as the working directory.
  final l10nDir = Directory('lib/l10n');
  final template = File('lib/l10n/app_en.arb');

  group('ARB files', () {
    test('one file per shipped locale, and every locale is supported', () {
      final arbs = l10nDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.arb'))
          .toList();
      final locales = arbs
          .map((file) => _readArb(file)['@@locale'] as String)
          .toSet();
      expect(locales, _arbLocales);

      // The picker offers exactly these, and each resolves to a bundled
      // translation rather than falling back to English.
      for (final language in appLanguages) {
        final exact = language.locale;
        final resolved = AppLocalizations.supportedLocales.contains(exact)
            ? exact
            : Locale(exact.languageCode);
        expect(
          AppLocalizations.supportedLocales,
          contains(resolved),
          reason: '${language.tag} has no bundled translation',
        );
      }
    });

    test('every locale has exactly the template key set', () {
      final expected = _messageKeys(_readArb(template));
      expect(expected.length, greaterThan(150));

      for (final file in l10nDir.listSync().whereType<File>()) {
        if (!file.path.endsWith('.arb')) {
          continue;
        }
        final arb = _readArb(file);
        final keys = _messageKeys(arb);
        expect(
          keys.difference(expected),
          isEmpty,
          reason: '${file.path} has keys the template does not',
        );
        expect(
          expected.difference(keys),
          isEmpty,
          reason: '${file.path} is missing translations',
        );
        for (final key in keys) {
          expect(
            arb[key],
            isA<String>().having((s) => s.trim(), 'text', isNotEmpty),
            reason: '${file.path}: $key is empty',
          );
        }
      }
    });

    test('template documents every message', () {
      final arb = _readArb(template);
      for (final key in _messageKeys(arb)) {
        expect(
          arb['@$key'],
          isA<Map<String, dynamic>>().having(
            (meta) => meta['description'],
            'description',
            isA<String>().having((s) => s.trim(), 'text', isNotEmpty),
          ),
          reason: '$key has no @description',
        );
      }
    });
  });

  group('Settings hub', () {
    Future<void> pumpHub(WidgetTester tester, Locale locale) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(_Auth.new),
            apiClientProvider.overrideWithValue(_offlineApi()),
            notificationProvider.overrideWith(_Notifications.new),
            runtimeFeatureFlagsProvider.overrideWith(
              (ref) => Stream.value(RuntimeFeatureFlags.defaults),
            ),
          ],
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders in German', (tester) async {
      await pumpHub(tester, const Locale('de'));
      expect(find.text('Einstellungen'), findsOneWidget);
      // Below the Account section at the top: scroll to it.
      await tester.scrollUntilVisible(
        find.text('Sprache'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Sprache'), findsOneWidget);
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('renders in Russian', (tester) async {
      await pumpHub(tester, const Locale('ru'));
      expect(find.text('Настройки'), findsOneWidget);
      // Below the Account section at the top: scroll to it.
      await tester.scrollUntilVisible(
        find.text('Язык'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Язык'), findsOneWidget);
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('en-US and en-GB both resolve, GB keeping its spelling', (
      tester,
    ) async {
      await pumpHub(tester, const Locale('en', 'US'));
      expect(find.text('Settings'), findsOneWidget);
      final us = AppLocalizations.of(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(us.planAreaLabel, 'Area or neighborhood');

      await pumpHub(tester, const Locale('en', 'GB'));
      final gb = AppLocalizations.of(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(gb.planAreaLabel, 'Area or neighbourhood');
      expect(gb.settingsTitle, us.settingsTitle);
    });
  });

  group('locale tags', () {
    test('round-trip through the settings wire format', () {
      for (final language in appLanguages) {
        expect(appLocaleFromTag(language.tag), language.locale);
        expect(appLocaleToTag(language.locale), language.tag);
      }
      expect(appLocaleFromTag(''), isNull);
      expect(appLocaleFromTag(null), isNull);
      expect(appLocaleFromTag('EN-gb'), isNull);
      expect(appLocaleFromTag('xx'), isNull);
      expect(appLocaleToTag(null), '');
    });
  });
}
