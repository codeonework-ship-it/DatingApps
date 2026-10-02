import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/couture.dart';
import 'package:verified_dating_app/core/theme/theme_presets.dart';
import 'package:verified_dating_app/core/widgets/connect_page.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final light = la > lb ? la : lb;
  final dark = la > lb ? lb : la;
  return (light + 0.05) / (dark + 0.05);
}

/// The finish every look shares: jewel-gradient primary actions with a trim
/// hairline, bevelled cards, and a second accent on chosen chips.
void main() {
  test('a button label reads across the whole action gradient', () {
    for (final p in ThemePresets.all) {
      // The fill runs primary -> jewel; the label must read at both ends
      // and in the middle, to the same floor the flat fill already met.
      for (final t in [0.0, 0.5, 1.0]) {
        expect(
          _contrast(p.onPrimary, Color.lerp(p.primary, p.jewel, t)!),
          greaterThanOrEqualTo(4),
          reason: '${p.id} label on the action gradient at $t',
        );
      }
      // The floating action wears the jewel.
      final theme = ThemePresets.themeFor(p);
      expect(theme.floatingActionButtonTheme.backgroundColor, p.jewel);
      expect(theme.floatingActionButtonTheme.foregroundColor, p.onPrimary);
    }
  });

  test('looks pair their primary with a second hue; Calm stays tonal', () {
    for (final p in ThemePresets.all) {
      final primaryHue = HSLColor.fromColor(p.primary).hue;
      final jewelHue = HSLColor.fromColor(p.jewel).hue;
      final apart = (primaryHue - jewelHue).abs();
      final distance = apart > 180 ? 360 - apart : apart;
      if (p.reducedMotion) {
        expect(distance, lessThan(12), reason: '${p.id} stays one accent');
      } else {
        expect(distance, greaterThan(12), reason: '${p.id} is one flat hue');
      }
    }
  });

  test('a chosen chip wears the second accent and stays readable', () {
    for (final p in ThemePresets.all) {
      final chips = ThemePresets.themeFor(p).chipTheme;
      expect(chips.selectedColor, p.secondaryTint, reason: p.id);
      expect(
        _contrast(chips.secondaryLabelStyle!.color!, p.secondaryTint),
        greaterThanOrEqualTo(4.5),
        reason: '${p.id} chosen chip label',
      );
    }
  });

  test('cards carry the bevelled hairline, equal between builds', () {
    final a = ThemePresets.themeFor(ThemePresets.rose).cardTheme.shape;
    final b = ThemePresets.themeFor(ThemePresets.rose).cardTheme.shape;
    expect(a, isA<CoutureBorder>());
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    final other = ThemePresets.themeFor(ThemePresets.snow).cardTheme.shape;
    expect(a, isNot(other));
    // Looks morph into each other: the hairline interpolates.
    final mid = ShapeBorder.lerp(a, other, 0.5);
    expect(mid, isA<CoutureBorder>());
    expect((mid! as CoutureBorder).colors, hasLength(3));
  });

  bool dressed(WidgetTester tester, String label) => tester
      .widgetList<CustomPaint>(
        find.ancestor(of: find.text(label), matching: find.byType(CustomPaint)),
      )
      .any((paint) => paint.painter is CoutureActionPainter);

  testWidgets('primary buttons are dressed; a custom fill is left alone', (
    tester,
  ) async {
    for (final preset in [
      ThemePresets.rose,
      ThemePresets.realLife,
      ThemePresets.calm,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemePresets.themeFor(preset),
          home: Scaffold(
            body: Column(
              children: [
                FilledButton(onPressed: () {}, child: const Text('Primary')),
                ElevatedButton(onPressed: () {}, child: const Text('Raised')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {},
                  child: const Text('Delete'),
                ),
                const FilledButton(onPressed: null, child: Text('Disabled')),
                GlassButton(label: 'Glass', onPressed: () {}),
                GlassButton(
                  label: 'Log out',
                  backgroundColor: Colors.red,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(dressed(tester, 'Primary'), isTrue, reason: preset.id);
      expect(dressed(tester, 'Raised'), isTrue, reason: preset.id);
      expect(dressed(tester, 'Glass'), isTrue, reason: preset.id);
      // A destructive red, a disabled button: never repainted in the look.
      expect(dressed(tester, 'Delete'), isFalse, reason: preset.id);
      expect(dressed(tester, 'Disabled'), isFalse, reason: preset.id);
      expect(dressed(tester, 'Log out'), isFalse, reason: preset.id);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a pressed primary button still fires and repaints', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.themeFor(ThemePresets.blueLotus),
        home: Scaffold(
          body: FilledButton(
            onPressed: () => taps++,
            child: const Text('Say hello'),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Say hello')),
    );
    await tester.pump(const Duration(milliseconds: 50));
    final painter = tester
        .widgetList<CustomPaint>(
          find.ancestor(
            of: find.text('Say hello'),
            matching: find.byType(CustomPaint),
          ),
        )
        .map((paint) => paint.painter)
        .whereType<CoutureActionPainter>()
        .single;
    expect(painter.pressed, isTrue);
    await gesture.up();
    await tester.pump();
    expect(taps, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('panels and headers fall back to the flat card with no look', (
    tester,
  ) async {
    Widget page(ThemeData theme) => MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Column(
          children: [
            const ConnectPageHeader(eyebrow: 'TODAY', title: 'Hello'),
            const ConnectSectionHeader(label: 'YOUR PACE', title: 'Three'),
            const ConnectPanel(child: Text('Panel')),
            const GlassContainer(child: Text('Glass')),
            ConnectNavTile(icon: Icons.star, title: 'Tile', onTap: () {}),
            const CoutureNavIcon(Icons.home_rounded, selected: true),
          ],
        ),
      ),
    );

    await tester.pumpWidget(page(ThemeData()));
    expect(tester.takeException(), isNull);
    // No look on the theme: no ornament, the plain bordered card.
    expect(
      find.descendant(
        of: find.byType(CoutureRule),
        matching: find.byType(DecoratedBox),
      ),
      findsNothing,
    );
    final flat = tester.widget<Container>(
      find.ancestor(of: find.text('Panel'), matching: find.byType(Container)),
    );
    expect((flat.decoration! as BoxDecoration).border, isNotNull);
    expect(flat.foregroundDecoration, isNull);

    await tester.pumpWidget(page(ThemePresets.themeFor(ThemePresets.rose)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(CoutureRule),
        matching: find.byType(DecoratedBox),
      ),
      findsNWidgets(2),
    );
    final couture = tester.widget<Container>(
      find.ancestor(of: find.text('Panel'), matching: find.byType(Container)),
    );
    expect(couture.foregroundDecoration, isA<ShapeDecoration>());
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
