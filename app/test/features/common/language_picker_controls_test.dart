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
import 'package:verified_dating_app/features/common/widgets/language_picker.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';

// The compact language button (globe only in app bars, globe + name on
// signed-out screens) opens the language sheet. A choice applies at once,
// closes the sheet, and is saved to the account when signed in
// (PATCH /settings/{me} {"locale": tag}); signed out it stays on the device
// and is carried into the next sign-in.

const _cacheKey = 'connect.locale';
const _pickedKey = 'connect.locale.picked_before_sign_in';
const _button = ValueKey(LanguagePickerButton.qaId);

final _en = qaL10n(const Locale('en'));

class _Auth extends AuthNotifier {
  _Auth(this.initial);
  final AuthState initial;
  @override
  AuthState build() => initial;
}

/// The member's account settings on the fake server.
QaApi _account() {
  final settings = <String, dynamic>{'locale': '', 'theme': 'dark:snow'};
  return QaApi()
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

/// A screen with the language button, inside an app that follows the chosen
/// language the way the real app does.
Future<ProviderContainer> _pump(
  WidgetTester tester,
  QaApi api, {
  required bool iconOnly,
  bool signedIn = false,
  Locale? chosen,
}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _Auth(
            signedIn
                ? const AuthState(
                    isAuthenticated: true,
                    userId: 'me',
                    username: 'me',
                  )
                : const AuthState(),
          ),
        ),
        apiClientProvider.overrideWithValue(api.dio),
        qaFlags(),
        appLocaleProvider.overrideWith(
          (ref) => AppLocaleNotifier(ref, initial: chosen),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          theme: AppTheme.lightTheme,
          locale: ref.watch(appLocaleProvider) ?? const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: AppBar(
              actions: [
                if (iconOnly) const LanguagePickerButton(iconOnly: true),
              ],
            ),
            body: Center(
              child: iconOnly ? const SizedBox() : const LanguagePickerButton(),
            ),
          ),
        ),
      ),
    ),
  );
  await qaSettle(tester, frames: 3);
  return ProviderScope.containerOf(tester.element(find.byType(Scaffold)));
}

Finder _option(String tag) => find.byKey(ValueKey('qa.language.option.$tag'));

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(_button));
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String tag) async {
  await tester.ensureVisible(_option(tag));
  await tester.pumpAndSettle();
  await tester.tap(_option(tag));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the globe button opens the language sheet; picking Deutsch '
      'saves it to the account, closes the sheet and switches the app '
      '[case:common.language_picker.language_rounded_icon_language_r.action]', (
    tester,
  ) async {
    final api = _account();
    final container = await _pump(tester, api, iconOnly: true, signedIn: true);
    // Globe only: the current language is in the tooltip.
    expect(find.byType(IconButton), findsOneWidget);
    expect(
      find.byTooltip(_en.languagePickerButtonSemantics('English (US)')),
      findsOneWidget,
    );
    expect(find.byType(BottomSheet), findsNothing);

    await _openSheet(tester);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text(_en.languageIntro), findsOneWidget);
    expect(_option('device'), findsOneWidget);
    expect(api.writes, isEmpty);

    await _choose(tester, 'de');

    expect(api.sent('PATCH', '/settings/me').single.body, {'locale': 'de'});
    expect(container.read(appLocaleProvider), const Locale('de'));
    // The sheet closed and the app now speaks German.
    expect(find.byType(BottomSheet), findsNothing);
    expect(_option('de'), findsNothing);
    final de = qaL10n(const Locale('de'));
    expect(
      find.byTooltip(de.languagePickerButtonSemantics('Deutsch')),
      findsOneWidget,
    );
    expect(qaSnackText(tester), isNull);
    expect((await SharedPreferences.getInstance()).getString(_cacheKey), 'de');
  });

  testWidgets('a refused save is explained inside the sheet, keeps the '
      'language, and picking again saves and closes the sheet '
      '[case:common.language_picker.language_rounded_icon_language_r.action]', (
    tester,
  ) async {
    final api = _account()..fail('PATCH /settings/me');
    final container = await _pump(tester, api, iconOnly: true, signedIn: true);
    await _openSheet(tester);

    await _choose(tester, 'nl');
    expect(api.sent('PATCH', '/settings/me').single.body, {'locale': 'nl'});
    expect(container.read(appLocaleProvider), isNull);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text(_en.languageSaveFailed).hitTestable(), findsOneWidget);
    expect(qaSnackText(tester), isNull);

    api.on('PATCH /settings/me', (c) => qaOk({'settings': c.body}));
    await _choose(tester, 'nl');
    expect(api.sent('PATCH', '/settings/me'), hasLength(2));
    expect(container.read(appLocaleProvider), const Locale('nl'));
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets(
    'the globe-and-name button opens the sheet; picking Français '
    'signed out applies on this device only and closes the sheet '
    '[case:common.language_picker.language_rounded_icon_language_r_2.action]',
    (tester) async {
      final api = _account();
      final container = await _pump(tester, api, iconOnly: false);
      expect(
        find.descendant(
          of: find.byKey(_button),
          matching: find.text('English (US)'),
        ),
        findsOneWidget,
      );

      await _openSheet(tester);
      expect(find.byType(BottomSheet), findsOneWidget);

      await _choose(tester, 'fr');

      // Signed out nothing is sent; the choice waits for the next sign-in.
      expect(api.calls, isEmpty);
      expect(container.read(appLocaleProvider), const Locale('fr'));
      expect(find.byType(BottomSheet), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(_button),
          matching: find.text('Français'),
        ),
        findsOneWidget,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_cacheKey), 'fr');
      expect(prefs.getBool(_pickedKey), isTrue);

      // Reopening shows the choice ticked; "Use device language" goes back.
      await _openSheet(tester);
      expect(
        find.descendant(
          of: _option('fr'),
          matching: find.byIcon(Icons.check_circle_rounded),
        ),
        findsOneWidget,
      );
      await _choose(tester, 'device');
      expect(container.read(appLocaleProvider), isNull);
      expect(find.byType(BottomSheet), findsNothing);
      expect(api.calls, isEmpty);
    },
  );

  testWidgets('the language sheet presents the signed-out intro, every '
      'language by its own name and "Use device language"; signed in it says '
      'the choice is saved to the account '
      '[case:common.language_picker.showmodalbottomsheet_open.action]', (
    tester,
  ) async {
    await _pump(tester, _account(), iconOnly: false);
    await _openSheet(tester);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text(_en.languageTitle), findsOneWidget);
    expect(find.text(_en.languageIntroSignedOut), findsOneWidget);
    expect(find.text(_en.languageIntro), findsNothing);
    expect(
      find.descendant(
        of: _option('device'),
        matching: find.text(_en.languageUseDevice),
      ),
      findsOneWidget,
    );
    for (final language in appLanguages) {
      await tester.ensureVisible(_option(language.tag));
      expect(
        find.descendant(
          of: _option(language.tag),
          matching: find.text(language.nativeName),
        ),
        findsOneWidget,
        reason: language.tag,
      );
    }
    // Following the device: that row is the ticked one.
    await tester.ensureVisible(_option('device'));
    expect(
      find.descendant(
        of: _option('device'),
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsOneWidget,
    );

    // Signed in, the same sheet promises the account-wide save.
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, _account(), iconOnly: false, signedIn: true);
    await _openSheet(tester);
    expect(find.text(_en.languageIntro), findsOneWidget);
    expect(find.text(_en.languageIntroSignedOut), findsNothing);
  });

  testWidgets('the button and the language sheet render translated, '
      'including a failed save '
      '[case:common.language_picker.l10n]', (tester) async {
    for (final locale in const [Locale('de'), Locale('pl')]) {
      final l10n = qaL10n(locale);
      final native = appLanguages
          .firstWhere((l) => l.locale == locale)
          .nativeName;
      await tester.pumpWidget(const SizedBox());
      final api = _account()..fail('PATCH /settings/me');
      await _pump(tester, api, iconOnly: true, signedIn: true, chosen: locale);
      expect(
        find.byTooltip(l10n.languagePickerButtonSemantics(native)),
        findsOneWidget,
        reason: '$locale',
      );

      await _openSheet(tester);
      expect(find.text(l10n.languageTitle), findsOneWidget);
      expect(find.text(l10n.languageIntro), findsOneWidget);
      expect(find.text(l10n.languageUseDevice), findsOneWidget);
      for (final english in [
        _en.languageTitle,
        _en.languageIntro,
        _en.languageUseDevice,
      ]) {
        expect(find.text(english), findsNothing, reason: '$locale: $english');
      }

      // A refused save keeps the language and explains in it, inside the
      // sheet (regression: a snack bar was hidden behind the sheet).
      await _choose(tester, 'it');
      expect(api.sent('PATCH', '/settings/me'), hasLength(1));
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text(l10n.languageTitle), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('qa.language.sheet.error')),
          matching: find.text(l10n.languageSaveFailed),
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.languageSaveFailed).hitTestable(), findsOneWidget);
      expect(find.text(_en.languageSaveFailed), findsNothing);
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });
}
