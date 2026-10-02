// Case ids stay whole in test names (the QA Lab reads them literally).
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/theme_atmosphere.dart';
import 'package:verified_dating_app/features/common/providers/app_theme_provider.dart';
import 'package:verified_dating_app/features/common/screens/settings_screen.dart';

import '../../support/qa_api.dart';

// Appearance in Settings: Light / Dark / Match device and the looks strip.
// Each choice repaints at once and is stored on the account
// (PATCH /settings/{me} {"theme": "mode" | "mode:preset"}); a failed save
// puts the previous choice back and says so.

const _selector = ValueKey('qa.settings.theme_selector');

ValueKey<String> _preset(String id) => ValueKey('qa.settings.theme_preset.$id');

QaApi _server() => QaApi()
  ..on(
    'PATCH /settings/me',
    (c) => qaOk({
      'settings': {'theme': c.body['theme']},
    }),
  );

Future<ProviderContainer> _open(WidgetTester tester, QaApi api) async {
  await pumpQa(tester, api, const SettingsScreen());
  return ProviderScope.containerOf(tester.element(find.byType(SettingsScreen)));
}

Set<AppThemeChoice> _selected(WidgetTester tester) => tester
    .widget<SegmentedButton<AppThemeChoice>>(find.byKey(_selector))
    .selected;

Future<void> _tapSegment(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byKey(_selector), matching: find.text(label)),
  );
  await qaSettle(tester, frames: 5);
}

Future<void> _tapLook(WidgetTester tester, String id) async {
  await tester.ensureVisible(find.byKey(_preset(id)));
  await tester.pump();
  await tester.tap(find.byKey(_preset(id)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

bool _ticked(String id) => find
    .descendant(
      of: find.byKey(_preset(id)),
      matching: find.byIcon(Icons.check_circle),
    )
    .evaluate()
    .isNotEmpty;

List<Object?> _savedThemes(QaApi api) =>
    api.sent('PATCH', '/settings/me').map((c) => c.body['theme']).toList();

void main() {
  testWidgets(
    'Light, Dark and Match device are each saved to the account '
    '[case:common.settings.settings_theme_selector_selectionchanged.action]',
    (tester) async {
      final api = _server();
      final container = await _open(tester, api);
      expect(_selected(tester), {AppThemeChoice.light});

      final l10n = qaL10n(const Locale('en'));
      await _tapSegment(tester, l10n.settingsThemeDark);
      expect(_selected(tester), {AppThemeChoice.dark});
      expect(container.read(appThemeProvider).themeMode, ThemeMode.dark);

      await _tapSegment(tester, l10n.settingsThemeMatchDevice);
      expect(_selected(tester), {AppThemeChoice.auto});
      expect(container.read(appThemeProvider).themeMode, ThemeMode.system);

      await _tapSegment(tester, l10n.settingsThemeLight);
      expect(_selected(tester), {AppThemeChoice.light});

      expect(_savedThemes(api), ['dark', 'auto', 'light']);
      // Only the theme is sent: nothing else on the account is overwritten.
      expect(api.sent('PATCH', '/settings/me').first.body, {'theme': 'dark'});
      expect(qaSnackText(tester), isNull);
    },
  );

  testWidgets(
    'a theme the server refuses goes back and explains; the next try works '
    '[case:common.settings.settings_theme_selector_selectionchanged.api_failure]',
    (tester) async {
      final api = _server()..fail('PATCH /settings/me', status: 500);
      final container = await _open(tester, api);
      final l10n = qaL10n(const Locale('en'));

      await _tapSegment(tester, l10n.settingsThemeDark);

      expect(_savedThemes(api), ['dark']);
      expect(_selected(tester), {AppThemeChoice.light});
      expect(container.read(appThemeProvider).mode, AppThemeChoice.light);
      expect(qaSnackText(tester), l10n.settingsThemeSaveFailed);

      // The control stays usable: once the server is back the choice saves.
      api.on(
        'PATCH /settings/me',
        (c) => qaOk({
          'settings': {'theme': c.body['theme']},
        }),
      );
      await _tapSegment(tester, l10n.settingsThemeDark);
      expect(_savedThemes(api), ['dark', 'dark']);
      expect(_selected(tester), {AppThemeChoice.dark});
    },
  );

  testWidgets(
    'offline: the theme goes back and the member is told '
    '[case:common.settings.settings_theme_selector_selectionchanged.api_failure]',
    (tester) async {
      final api = _server()..offline('PATCH /settings/me');
      await _open(tester, api);
      final l10n = qaL10n(const Locale('en'));

      await _tapSegment(tester, l10n.settingsThemeMatchDevice);

      expect(_selected(tester), {AppThemeChoice.light});
      expect(qaSnackText(tester), l10n.settingsThemeSaveFailed);
      expect(_savedThemes(api), ['auto']);
    },
  );

  testWidgets('choosing a look saves it, plays its title card and ticks it '
      '[case:common.settings.settings_theme_preset_x.action]', (tester) async {
    final api = _server();
    final container = await _open(tester, api);
    expect(_ticked('classic'), isTrue);

    await _tapLook(tester, 'deepfield');

    expect(_savedThemes(api), ['light:deepfield']);
    expect(container.read(appThemeProvider).presetId, 'deepfield');
    expect(find.byType(ThemeTitleCard), findsOneWidget);
    // The title card closes itself after its hold.
    await tester.pump(kThemeTitleCardHold);
    await qaSettle(tester);
    expect(find.byType(ThemeTitleCard), findsNothing);
    expect(_ticked('deepfield'), isTrue);
    expect(_ticked('classic'), isFalse);

    // Tapping the chosen look again sends nothing.
    await _tapLook(tester, 'deepfield');
    await tester.pump(kThemeTitleCardHold);
    await qaSettle(tester);
    expect(_savedThemes(api), ['light:deepfield']);

    // Back to the classic pair.
    await _tapLook(tester, 'classic');
    await qaSettle(tester);
    expect(_savedThemes(api), ['light:deepfield', 'light']);
    expect(_ticked('classic'), isTrue);
    expect(find.byType(ThemeTitleCard), findsNothing);
  });

  testWidgets('a calm (reduced-motion) look saves without a title card '
      '[case:common.settings.settings_theme_preset_x.action]', (tester) async {
    final api = _server();
    await _open(tester, api);

    await _tapLook(tester, 'calm');
    await qaSettle(tester);

    expect(_savedThemes(api), ['light:calm']);
    expect(find.byType(ThemeTitleCard), findsNothing);
    expect(_ticked('calm'), isTrue);
  });

  testWidgets('a look the server refuses is not applied and the member is told '
      '[case:common.settings.settings_theme_preset_x.api_failure]', (
    tester,
  ) async {
    final api = _server()..fail('PATCH /settings/me', status: 503);
    final container = await _open(tester, api);
    final l10n = qaL10n(const Locale('en'));

    await _tapLook(tester, 'snow');
    await qaSettle(tester);

    expect(_savedThemes(api), ['light:snow']);
    expect(container.read(appThemeProvider).isClassic, isTrue);
    expect(find.byType(ThemeTitleCard), findsNothing);
    expect(_ticked('snow'), isFalse);
    expect(_ticked('classic'), isTrue);
    expect(qaSnackText(tester), l10n.settingsThemeSaveFailed);
  });
}
