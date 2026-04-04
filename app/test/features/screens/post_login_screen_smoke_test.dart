import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/widgets/themed_screen_scaffold.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';

/// Smoke tests to verify critical post-login screens render without crashing
/// on various viewport sizes. These do NOT test business logic — they verify
/// that widgets can be built on the framework without errors.
void main() {
  group('Post-login screen smoke tests', () {
    final viewports = <String, Size>{
      'compact phone': const Size(320, 640),
      'standard phone': const Size(400, 900),
      'wide phone': const Size(430, 932),
      'tablet portrait': const Size(768, 1024),
      'tablet landscape': const Size(1280, 800),
    };

    for (final entry in viewports.entries) {
      final name = entry.key;
      final size = entry.value;

      testWidgets('ThemedScreenScaffold (loading) renders on $name', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          const MaterialApp(
            home: ThemedScreenScaffold(
              isLoading: true,
              loadingMessage: 'Loading…',
              body: SizedBox.shrink(),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('ThemedScreenScaffold (error) renders on $name', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: ThemedScreenScaffold(
              errorMessage: 'Connection failed',
              onRetry: () {},
              body: const SizedBox.shrink(),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('ThemedScreenScaffold (empty) renders on $name', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          const MaterialApp(
            home: ThemedScreenScaffold(
              isEmpty: true,
              emptyTitle: 'Nothing to show',
              body: SizedBox.shrink(),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('ThemedScreenScaffold (pre-login) renders on $name', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          const MaterialApp(
            home: ThemedScreenScaffold(
              isPreLogin: true,
              body: Center(child: Text('Pre-Login Content')),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('PostLoginBackdrop renders crystal blooms', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PostLoginBackdrop(child: Text('Test'))),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
      expect(find.byType(CrystalBloom), findsNWidgets(3));
    });

    testWidgets('GlassButton renders with shiny effect', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassButton(
                label: 'Click me',
                shinyEffect: true,
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Click me'), findsOneWidget);
      await tester.tap(find.text('Click me'));
      expect(pressed, isTrue);
    });

    testWidgets('GlassContainer renders with crystalEffect', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.white.withValues(alpha: 0.84),
                blur: 14,
                crystalEffect: true,
                child: const Text('Glass Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Glass Content'), findsOneWidget);
    });

    testWidgets('AppTheme provides valid light/dark themes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: Text(
                  'Theme test',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Theme test'), findsOneWidget);
    });
  });
}
