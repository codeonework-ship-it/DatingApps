import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';

/// Ground and ink must switch brightness together.
///
/// Regression guard for a shipped defect: label colours were made
/// theme-aware while `PostLoginBackdrop` and five other surfaces still painted
/// a hardcoded *light* gradient. Selecting the dark theme therefore repainted
/// every title to its on-dark cut and drew it on a near-white panel — titles
/// went near-white on near-white and the screens read as blank.
///
/// The failure was invisible to the existing suite because both halves were
/// individually correct; only their combination was wrong.
void main() {
  group('post-login ground follows theme brightness', () {
    testWidgets('dark theme resolves the dark ground', (tester) async {
      late Gradient resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              resolved = AppTheme.groundGradientOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved, same(AppTheme.postLoginGradientDark));
    });

    testWidgets('light theme resolves the light ground', (tester) async {
      late Gradient resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: Builder(
            builder: (context) {
              resolved = AppTheme.groundGradientOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved, same(AppTheme.postLoginGradient));
    });

    test('the two grounds sit on opposite sides of mid luminance', () {
      // The specific failure was a *light* ground under dark-theme ink, so
      // assert the separation rather than exact colours: the palette may be
      // retuned, but a dark ground that is not actually dark reintroduces the
      // bug verbatim.
      double meanLuminance(Gradient g) {
        final colors = (g as LinearGradient).colors;
        final total = colors.fold<double>(
          0,
          (sum, c) => sum + c.computeLuminance(),
        );
        return total / colors.length;
      }

      final dark = meanLuminance(AppTheme.postLoginGradientDark);
      final light = meanLuminance(AppTheme.postLoginGradient);

      expect(dark, lessThan(0.2), reason: 'dark ground must be genuinely dark');
      expect(
        light,
        greaterThan(0.6),
        reason: 'light ground must be genuinely light',
      );
    });
  });

  group('on-surface ink is legible against its own ground', () {
    /// WCAG relative-contrast ratio.
    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    test('dark theme body text clears 4.5:1 on the dark ground', () {
      final ink = AppTheme.darkTheme.colorScheme.onSurface;
      final ground =
          (AppTheme.postLoginGradientDark as LinearGradient).colors.last;
      expect(contrast(ink, ground), greaterThanOrEqualTo(4.5));
    });

    test('light theme body text clears 4.5:1 on the light ground', () {
      final ink = AppTheme.lightTheme.colorScheme.onSurface;
      final ground = (AppTheme.postLoginGradient as LinearGradient).colors.last;
      expect(contrast(ink, ground), greaterThanOrEqualTo(4.5));
    });
  });

  group('PostLoginBackdrop paints the ground it resolved', () {
    // The resolver being right is not the same as the widget using it: the
    // shipped defect was six call sites still painting a const light gradient
    // while the resolver did not exist. Assert the widget that every
    // authenticated screen — Settings included — actually renders through.
    Future<Gradient?> paintedGround(WidgetTester tester, ThemeMode mode) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          home: const Scaffold(body: PostLoginBackdrop(child: Text('content'))),
        ),
      );
      await tester.pump();
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(PostLoginBackdrop),
              matching: find.byType(Container),
            )
            .first,
      );
      return (container.decoration as BoxDecoration?)?.gradient;
    }

    testWidgets('dark theme paints the dark ground', (tester) async {
      expect(
        await paintedGround(tester, ThemeMode.dark),
        same(AppTheme.postLoginGradientDark),
      );
    });

    testWidgets('light theme paints the light ground', (tester) async {
      expect(
        await paintedGround(tester, ThemeMode.light),
        same(AppTheme.postLoginGradient),
      );
    });
  });
}
