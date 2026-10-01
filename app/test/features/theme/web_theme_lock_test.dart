import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/theme_presets.dart';
import 'package:verified_dating_app/features/common/providers/app_theme_provider.dart';

/// Guards the product decision that the browser app always wears Real life
/// (the public website's look), whatever preset the member saved.
void main() {
  ProviderContainer containerFor({required bool web}) {
    final container = ProviderContainer(
      overrides: [isWebBuildProvider.overrideWithValue(web)],
    );
    addTearDown(container.dispose);
    return container;
  }

  ThemePreset? paletteOf(ThemeData theme) =>
      theme.extension<ConnectPalette>()?.preset;

  test('web build ignores a saved preset and stays on Real life', () async {
    final container = containerFor(web: true);
    final notifier = container.read(appThemeProvider.notifier);
    // No signed-in user, so the choice applies locally without persisting.
    await notifier.selectPreset(ThemePresets.deepField.id);
    expect(
      container.read(appThemeProvider).presetId,
      ThemePresets.deepField.id,
    );

    expect(container.read(webThemeLockedProvider), isTrue);
    expect(container.read(appThemeModeProvider), ThemeMode.light);
    expect(paletteOf(container.read(appLightThemeProvider))?.id, 'real-life');
    expect(paletteOf(container.read(appDarkThemeProvider))?.id, 'real-life');
  });

  test('mobile build follows the saved preset', () async {
    final container = containerFor(web: false);
    await container
        .read(appThemeProvider.notifier)
        .selectPreset(ThemePresets.deepField.id);

    expect(container.read(webThemeLockedProvider), isFalse);
    expect(container.read(appThemeModeProvider), ThemeMode.dark);
    expect(
      paletteOf(container.read(appDarkThemeProvider))?.id,
      ThemePresets.deepField.id,
    );
  });
}
