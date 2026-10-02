import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/extensions/date_time_extensions.dart';
import 'package:verified_dating_app/core/i18n/app_l10n.dart';
import 'package:verified_dating_app/core/i18n/option_labels.dart';
import 'package:verified_dating_app/core/providers/network_quality_provider.dart';
import 'package:verified_dating_app/core/theme/theme_presets.dart';
import 'package:verified_dating_app/core/widgets/themed_screen_scaffold.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

void main() {
  group('appL10nFor', () {
    test('resolves a regional tag to its language', () {
      expect(appL10nFor(const Locale('de', 'AT')).localeName, 'de');
      expect(appL10nFor(const Locale('en', 'GB')).localeName, 'en_GB');
    });

    test('falls back to English for an unshipped language', () {
      expect(appL10nFor(const Locale('ja')).localeName, 'en');
    });
  });

  test('profile options keep their stored value and translate the label', () {
    final de = appL10nFor(const Locale('de'));
    final en = appL10nFor(const Locale('en'));
    expect(localizedProfileOption(en, 'Occasionally'), 'Occasionally');
    expect(localizedProfileOption(de, 'Occasionally'), 'Gelegentlich');
    expect(localizedProfileOption(de, 'Introvert'), 'Introvertiert');
    // Server master data the app does not know passes through untouched.
    expect(localizedProfileOption(de, 'Marathi'), 'Marathi');
  });

  test('look taglines translate; look names stay product names', () {
    final fr = appL10nFor(const Locale('fr'));
    expect(
      localizedPresetTagline(fr, ThemePresets.realLife),
      'Ivoire chaud, vert forêt et abricot.',
    );
    expect(ThemePresets.realLife.label, 'Today');
  });

  test('network advisories are rendered in the requested language', () {
    const state = NetworkQualityState(
      status: NetworkQualityStatus.offline,
      notice: NetworkQualityNotice.offline,
      message: 'No stable network connection.',
    );
    expect(
      state.localizedMessage(appL10nFor(const Locale('en'))),
      'No stable network connection. Reconnect to continue using the app.',
    );
    expect(
      state.localizedMessage(appL10nFor(const Locale('es'))),
      'No hay una conexión estable. Vuelve a conectarte para seguir usando '
      'la app.',
    );
  });

  test('time ago keeps English without l10n and translates with it', () {
    final threeHoursAgo = DateTime.now().subtract(const Duration(hours: 3));
    expect(threeHoursAgo.getTimeAgo(), '3 hours ago');
    expect(
      threeHoursAgo.getTimeAgo(appL10nFor(const Locale('de'))),
      'vor 3 Stunden',
    );
    expect(
      threeHoursAgo.getTimeAgo(appL10nFor(const Locale('ru'))),
      '3 часа назад',
    );
  });

  testWidgets('shared error state speaks German when the app does', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ThemedScreenScaffold(
          errorMessage: 'boom',
          onRetry: () {},
          body: const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.text('Etwas ist schiefgelaufen'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });

  testWidgets('shared widgets fall back to English without delegates', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ThemedScreenScaffold(isEmpty: true, body: SizedBox.shrink()),
      ),
    );

    expect(find.text('Nothing here yet'), findsOneWidget);
  });
}
