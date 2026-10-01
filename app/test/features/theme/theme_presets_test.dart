import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/theme_presets.dart';
import 'package:verified_dating_app/features/common/providers/app_theme_provider.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final light = la > lb ? la : lb;
  final dark = la > lb ? lb : la;
  return (light + 0.05) / (dark + 0.05);
}

void main() {
  test('every preset builds a readable theme with its palette installed', () {
    for (final preset in ThemePresets.all) {
      final theme = ThemePresets.themeFor(preset);
      expect(theme.brightness, preset.brightness, reason: preset.id);
      expect(theme.scaffoldBackgroundColor, preset.ground, reason: preset.id);
      expect(theme.colorScheme.primary, preset.primary, reason: preset.id);
      expect(theme.extension<ConnectPalette>()?.preset.id, preset.id);
      // Body text on the ground and on cards must stay legible.
      expect(
        _contrast(preset.ink, preset.ground),
        greaterThanOrEqualTo(7),
        reason: '${preset.id} ink on ground',
      );
      expect(
        _contrast(preset.ink, preset.paper),
        greaterThanOrEqualTo(7),
        reason: '${preset.id} ink on paper',
      );
      expect(
        _contrast(preset.inkMuted, preset.paper),
        greaterThanOrEqualTo(3.5),
        reason: '${preset.id} muted ink on paper',
      );
      // Button labels must read on the primary fill.
      expect(
        _contrast(preset.onPrimary, preset.primary),
        greaterThanOrEqualTo(3),
        reason: '${preset.id} label on primary',
      );
      expect(theme.textTheme.displaySmall?.fontFamily, preset.displayFamily);
    }
  });

  test('classic follows the mode; a themed preset fixes its brightness', () {
    const classicDark = AppThemeSelection(mode: AppThemeChoice.dark);
    expect(classicDark.themeMode, ThemeMode.dark);
    expect(
      classicDark.darkTheme.extension<ConnectPalette>()?.preset.id,
      'real-life-night',
    );
    expect(
      classicDark.lightTheme.extension<ConnectPalette>()?.preset.id,
      'real-life',
    );
    expect(classicDark.wireValue, 'dark');

    final neonGrid = AppThemeSelection.fromWire('light:neongrid');
    expect(neonGrid.presetId, 'neongrid');
    expect(neonGrid.themeMode, ThemeMode.dark);
    expect(
      neonGrid.darkTheme.extension<ConnectPalette>()?.preset.id,
      'neongrid',
    );
    expect(neonGrid.wireValue, 'light:neongrid');

    final deepField = AppThemeSelection.fromWire('auto:deepfield');
    expect(deepField.themeMode, ThemeMode.dark);
    expect(deepField.preset, same(ThemePresets.deepField));
    expect(deepField.wireValue, 'auto:deepfield');

    final love = AppThemeSelection.fromWire('dark:love');
    expect(love.themeMode, ThemeMode.light);
    expect(love.lightTheme.extension<ConnectPalette>()?.preset.id, 'love');

    expect(AppThemeSelection.fromWire('auto:nonsense').isClassic, isTrue);
    expect(AppThemeSelection.fromWire(null).presetId, ThemePresets.classicId);
  });

  test('themed presets ship under their original names', () {
    expect(
      ThemePresets.themed.map((p) => p.id),
      containsAll(<String>[
        'forge',
        'neongrid',
        'crimsonalloy',
        'circuit',
        'deepfield',
        'love',
        'rose',
        'petal',
        'calm',
      ]),
    );
    expect(ThemePresets.forge.label, 'Forge');
    expect(ThemePresets.neonGrid.label, 'Neon Grid');
    expect(ThemePresets.crimsonAlloy.label, 'Crimson Alloy');
    expect(ThemePresets.circuit.label, 'Circuit');
    expect(ThemePresets.deepField.label, 'Deep Field');
    expect(ThemePresets.love.label, 'Love');
    expect(ThemePresets.calm.label, 'Calm');
    expect(ThemePresets.rose.label, 'Rose');
    expect(ThemePresets.petal.label, 'Petal');
  });

  test(
    'legacy preset ids saved on the server resolve to the renamed looks',
    () {
      // Members who chose a look before the rename keep it; the selection
      // carries the new id so the next save migrates the stored value.
      const legacy = {
        'transformers': ThemePresets.forge,
        'tron': ThemePresets.neonGrid,
        'ironman': ThemePresets.crimsonAlloy,
        'digitronics': ThemePresets.circuit,
        'starwars': ThemePresets.deepField,
      };
      for (final MapEntry(key: oldId, value: preset) in legacy.entries) {
        final selection = AppThemeSelection.fromWire('dark:$oldId');
        expect(selection.isClassic, isFalse, reason: oldId);
        expect(selection.presetId, preset.id, reason: oldId);
        expect(selection.preset, same(preset), reason: oldId);
        expect(selection.wireValue, 'dark:${preset.id}', reason: oldId);
        expect(ThemePresets.byId(oldId), isNull, reason: oldId);
      }
      // Case and whitespace on the wire are normalised before the lookup.
      expect(
        AppThemeSelection.fromWire(' Auto:StarWars ').preset,
        same(ThemePresets.deepField),
      );
    },
  );

  test('Deep Field is a complete selectable dark preset', () {
    const preset = ThemePresets.deepField;

    expect(ThemePresets.themed, contains(same(preset)));
    expect(ThemePresets.byId('deepfield'), same(preset));
    expect(preset.brightness, Brightness.dark);
    expect(preset.swatch, hasLength(3));

    final theme = ThemePresets.themeFor(preset);
    final palette = theme.extension<ConnectPalette>();
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, preset.primary);
    expect(theme.colorScheme.secondary, preset.secondary);
    expect(palette?.preset, same(preset));
  });

  test('Calm is a light, still, single-accent preset', () {
    const preset = ThemePresets.calm;

    expect(ThemePresets.themed, contains(same(preset)));
    expect(ThemePresets.byId('calm'), same(preset));
    expect(preset.brightness, Brightness.light);
    expect(preset.reducedMotion, isTrue);
    // A flat ground: nothing for the backdrop to bloom toward.
    expect(preset.groundGlow, preset.ground);
    // One accent, so no bright secondary glow anywhere.
    expect(preset.secondary, preset.primary);
    // Well past the 7:1 AAA floor every preset meets, and the highest
    // contrast body text of any light preset. (A dark look with near-white
    // ink on near-black can always edge past an off-white ground, so dark
    // presets are not the comparison.)
    final calmContrast = _contrast(preset.ink, preset.ground);
    expect(calmContrast, greaterThanOrEqualTo(15));
    for (final other in ThemePresets.all) {
      if (other.id == preset.id || other.isDark) {
        continue;
      }
      expect(
        calmContrast,
        greaterThanOrEqualTo(_contrast(other.ink, other.ground)),
        reason: 'calm ink/ground vs ${other.id}',
      );
    }
    // Only Calm asks for stillness.
    for (final other in ThemePresets.all) {
      expect(other.reducedMotion, other.id == 'calm', reason: other.id);
    }

    final selection = AppThemeSelection.fromWire('dark:calm');
    expect(selection.themeMode, ThemeMode.light);
    expect(selection.lightTheme.extension<ConnectPalette>()?.preset.id, 'calm');
  });
}
